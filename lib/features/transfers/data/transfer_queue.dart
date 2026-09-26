import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/storage/app_database.dart';
import '../domain/transfer.dart';
import 'transfer_api.dart';

/// Persistente Download-/Upload-Queue in drift.
///
/// Der Worker läuft nur mit [api] (angemeldeter Server [serverId]) und
/// bearbeitet höchstens [maxParallel] Transfers gleichzeitig. Downloads
/// schreiben nach `<localPath>.part` und setzen per HTTP-Range fort; fertige
/// Downloads landen in [OfflineFiles]. Uploads starten auf Datei-Ebene neu.
/// Kein automatisches Wiederholen: Fehler bleiben stehen, bis der Nutzer
/// „Wiederholen“ tippt. Nach einem Auth-Fehler startet der Worker nichts mehr
/// (DSM-Auto-Block, siehe SessionManager).
class TransferQueue {
  TransferQueue(this._db, {this.api, this.serverId, this.maxParallel = 2});

  final AppDatabase _db;
  final TransferApi? api;
  final int? serverId;
  final int maxParallel;

  final _running = <int, ({CancelToken token, Future<void> done})>{};
  final _speed = <int, double>{};
  Future<void>? _draining;
  bool _again = false;
  bool _halted = false;
  bool _disposed = false;

  /// Wie oft Fortschritt höchstens in die DB geschrieben wird.
  static const progressInterval = Duration(milliseconds: 500);

  $TransfersTable get _t => _db.transfers;

  /// Alle Transfers, älteste zuerst.
  Stream<List<Transfer>> watch() =>
      (_db.select(_t)..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
          .watch();

  /// Aktuelle Geschwindigkeit in Byte/s, solange der Transfer läuft.
  double? speedOf(int id) => _speed[id];

  /// Nach einem App-Neustart: Was beim Beenden lief, wieder einreihen.
  Future<void> start() async {
    await (_db.update(_t)
          ..where((t) => t.state.equalsValue(TransferState.running)))
        .write(const TransfersCompanion(state: Value(TransferState.queued)));
    _pump();
  }

  /// Reiht einen Download nach [localPath] ein, außer derselbe Pfad wartet
  /// oder läuft schon.
  Future<void> enqueueDownload({
    required String remotePath,
    required String localPath,
    int? size,
    DateTime? mtime,
  }) async {
    final server = serverId ?? (throw StateError('Kein Server'));
    final pending =
        await (_db.select(_t)..where(
              (t) =>
                  t.serverId.equals(server) &
                  t.kind.equalsValue(TransferKind.download) &
                  t.remotePath.equals(remotePath) &
                  t.state.equalsValue(TransferState.done).not(),
            ))
            .get();
    if (pending.isNotEmpty) return;
    await _db
        .into(_t)
        .insert(
          TransfersCompanion.insert(
            serverId: server,
            kind: TransferKind.download,
            remotePath: remotePath,
            localPath: localPath,
            bytesTotal: Value(size),
            remoteMtime: Value(mtime),
            state: TransferState.queued,
            createdAt: DateTime.now(),
          ),
        );
    _pump();
  }

  /// Reiht den Upload von [localPath] als [remotePath] (Ordner/Name) ein.
  Future<void> enqueueUpload({
    required String localPath,
    required String remotePath,
    required bool overwrite,
    int? size,
  }) async {
    await _db
        .into(_t)
        .insert(
          TransfersCompanion.insert(
            serverId: serverId ?? (throw StateError('Kein Server')),
            kind: TransferKind.upload,
            remotePath: remotePath,
            localPath: localPath,
            bytesTotal: Value(size),
            overwrite: Value(overwrite),
            state: TransferState.queued,
            createdAt: DateTime.now(),
          ),
        );
    _pump();
  }

  Future<void> pause(int id) async {
    await _stop(id);
    // Nur, wenn er nicht gerade noch fertig geworden ist.
    await (_db.update(_t)..where(
          (t) =>
              t.id.equals(id) &
              t.state.isInValues([TransferState.queued, TransferState.running]),
        ))
        .write(const TransfersCompanion(state: Value(TransferState.paused)));
  }

  Future<void> pauseAll() async {
    await Future.wait([
      for (final id in [..._running.keys]) _stop(id),
    ]);
    await (_db.update(_t)..where(
          (t) =>
              t.state.isInValues([TransferState.queued, TransferState.running]),
        ))
        .write(const TransfersCompanion(state: Value(TransferState.paused)));
  }

  /// Fortsetzen (pausiert) bzw. Wiederholen (fehlgeschlagen). Downloads
  /// setzen an der `.part`-Datei an, Uploads beginnen neu.
  Future<void> retry(int id) async {
    _halted = false;
    await _update(
      id,
      const TransfersCompanion(
        state: Value(TransferState.queued),
        error: Value(null),
      ),
    );
    _pump();
  }

  /// Bricht ab und entfernt den Transfer samt Teil-Download.
  Future<void> cancel(int id) async {
    await _stop(id);
    final t = await (_db.select(
      _t,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    await (_db.delete(_t)..where((t) => t.id.equals(id))).go();
    if (t != null && t.kind == TransferKind.download) {
      await _deleteQuietly(File('${t.localPath}.part'));
    }
  }

  /// Entfernt fertige Transfers aus der Liste (die Dateien bleiben).
  Future<void> clearDone() => (_db.delete(
    _t,
  )..where((t) => t.state.equalsValue(TransferState.done))).go();

  /// Bricht laufende Transfers ab (Zustand bleibt `running` und wird beim
  /// nächsten [start] wieder eingereiht) und wartet, bis sie beendet sind.
  Future<void> dispose() async {
    _disposed = true;
    final runs = [..._running.values];
    for (final r in runs) {
      r.token.cancel();
    }
    await Future.wait([for (final r in runs) r.done]);
  }

  Future<void> _stop(int id) async {
    final run = _running[id];
    if (run == null) return;
    run.token.cancel();
    await run.done;
  }

  Future<void> _update(int id, TransfersCompanion values) =>
      (_db.update(_t)..where((t) => t.id.equals(id))).write(values);

  void _pump() {
    _again = true;
    _draining ??= _drain().whenComplete(() => _draining = null);
  }

  Future<void> _drain() async {
    final api = this.api;
    final server = serverId;
    while (_again) {
      _again = false;
      while (api != null &&
          server != null &&
          !_halted &&
          !_disposed &&
          _running.length < maxParallel) {
        final next =
            await (_db.select(_t)
                  ..where(
                    (t) =>
                        t.serverId.equals(server) &
                        t.state.equalsValue(TransferState.queued),
                  )
                  ..orderBy([
                    (t) => OrderingTerm.asc(t.createdAt),
                    (t) => OrderingTerm.asc(t.id),
                  ])
                  ..limit(1))
                .getSingleOrNull();
        if (next == null) break;
        await _update(
          next.id,
          const TransfersCompanion(state: Value(TransferState.running)),
        );
        final token = CancelToken();
        final done = Completer<void>();
        _running[next.id] = (token: token, done: done.future);
        unawaited(_run(api, next, token).whenComplete(done.complete));
      }
    }
  }

  Future<void> _run(TransferApi api, Transfer t, CancelToken token) async {
    var lastWrite = DateTime.now();
    var sample = (at: DateTime.now(), bytes: t.bytesDone);
    void progress(int done, int? total) {
      final now = DateTime.now();
      final ms = now.difference(sample.at).inMilliseconds;
      if (ms >= 1000) {
        final rate = (done - sample.bytes) * 1000 / ms;
        final old = _speed[t.id];
        _speed[t.id] = old == null ? rate : old * 0.5 + rate * 0.5;
        sample = (at: now, bytes: done);
      }
      if (now.difference(lastWrite) < progressInterval || token.isCancelled) {
        return;
      }
      lastWrite = now;
      unawaited(
        _update(
          t.id,
          TransfersCompanion(
            bytesDone: Value(done),
            bytesTotal: total == null ? const Value.absent() : Value(total),
          ),
        ),
      );
    }

    try {
      switch (t.kind) {
        case TransferKind.download:
          final part = File('${t.localPath}.part');
          await part.parent.create(recursive: true);
          final offset = await part.exists() ? await part.length() : 0;
          sample = (at: DateTime.now(), bytes: offset);
          await api.download(
            t.remotePath,
            part,
            offset: offset,
            cancelToken: token,
            onProgress: progress,
          );
          await part.rename(t.localPath);
          final size = await File(t.localPath).length();
          await _db.transaction(() async {
            await _db
                .into(_db.offlineFiles)
                .insertOnConflictUpdate(
                  OfflineFilesCompanion.insert(
                    serverId: t.serverId,
                    remotePath: t.remotePath,
                    localPath: t.localPath,
                    mtime: Value(t.remoteMtime),
                    size: size,
                  ),
                );
            await _finish(t.id, size);
          });
        case TransferKind.upload:
          final file = File(t.localPath);
          final size = await file.length();
          final slash = t.remotePath.lastIndexOf('/');
          final folder = t.remotePath.substring(0, slash);
          final name = await api.upload(
            file,
            folder,
            t.remotePath.substring(slash + 1),
            overwrite: t.overwrite,
            cancelToken: token,
            onProgress: progress,
          );
          if (token.isCancelled) return;
          await _update(
            t.id,
            TransfersCompanion(remotePath: Value('$folder/$name')),
          );
          await _finish(t.id, size);
      }
    } catch (e) {
      // Pause/Abbruch: Zustand setzt der Aufrufer.
      if (token.isCancelled) {
        if (t.kind == TransferKind.download) {
          await _update(
            t.id,
            TransfersCompanion(bytesDone: Value(await _partLength(t))),
          );
        }
        return;
      }
      if (isAuthError(e)) _halted = true;
      await _update(
        t.id,
        TransfersCompanion(
          state: const Value(TransferState.failed),
          error: Value(transferErrorTag(e)),
          bytesDone: t.kind == TransferKind.download
              ? Value(await _partLength(t))
              : const Value(0),
        ),
      );
    } finally {
      _running.remove(t.id);
      _speed.remove(t.id);
      _pump();
    }
  }

  Future<void> _finish(int id, int size) => _update(
    id,
    TransfersCompanion(
      state: const Value(TransferState.done),
      bytesDone: Value(size),
      bytesTotal: Value(size),
      error: const Value(null),
    ),
  );

  Future<int> _partLength(Transfer t) async {
    final part = File('${t.localPath}.part');
    return await part.exists() ? part.length() : 0;
  }
}

Future<void> _deleteQuietly(File file) async {
  try {
    await file.delete();
  } on FileSystemException {
    // Schon weg.
  }
}
