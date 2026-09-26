import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/core/network/syno_exception.dart';
import 'package:synology_explorer/core/storage/app_database.dart';
import 'package:synology_explorer/features/transfers/data/transfer_api.dart';
import 'package:synology_explorer/features/transfers/data/transfer_queue.dart';
import 'package:synology_explorer/features/transfers/domain/transfer.dart';
import 'package:synology_explorer/features/transfers/presentation/transfer_notifications.dart';

/// Download schreibt [content] ab `offset`; jeder Aufruf wartet auf ein
/// eigenes Tor, bis der Test es öffnet (oder wirft [failWith]).
class FakeTransferApi implements TransferApi {
  final content = List.generate(1000, (i) => i % 256);
  final downloads = <({String path, int offset})>[];
  final uploads = <({String folder, String name, bool overwrite})>[];
  final gates = <Completer<void>>[];
  Object? failWith;
  bool gated = false;

  int get running => gates.where((g) => !g.isCompleted).length;

  Future<void> _gate(CancelToken? token) async {
    if (!gated) return;
    final gate = Completer<void>();
    gates.add(gate);
    token?.whenCancel.then((e) {
      if (!gate.isCompleted) gate.completeError(e);
    });
    await gate.future;
  }

  void openAll() {
    for (final g in gates) {
      if (!g.isCompleted) g.complete();
    }
  }

  @override
  Future<int?> download(
    String remotePath,
    File file, {
    int offset = 0,
    CancelToken? cancelToken,
    void Function(int done, int? total)? onProgress,
  }) async {
    downloads.add((path: remotePath, offset: offset));
    await _gate(cancelToken);
    if (rangeNotSatisfiable && offset > 0) {
      rangeNotSatisfiable = false;
      throw const SynoNetworkError(statusCode: 416);
    }
    if (failWith case final e?) {
      failWith = null;
      // Halber Download bleibt als .part liegen.
      await file.writeAsBytes(
        content.sublist(offset, 400),
        mode: FileMode.append,
      );
      throw e;
    }
    await file.writeAsBytes(content.sublist(offset), mode: FileMode.append);
    onProgress?.call(content.length, content.length);
    return content.length;
  }

  @override
  Future<String> upload(
    File file,
    String folder,
    String name, {
    required bool overwrite,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onProgress,
  }) async {
    uploads.add((folder: folder, name: name, overwrite: overwrite));
    await _gate(cancelToken);
    if (failWith case final e?) {
      failWith = null;
      throw e;
    }
    return overwrite ? name : 'x (1).jpg';
  }

  @override
  Future<String> freeName(String folder, String name) async => name;

  /// Was `getinfo` als Änderungszeit auf dem NAS meldet.
  DateTime? remoteMtime;

  /// Einmal 416 bei einem Range-Request (Teil passt nicht mehr).
  bool rangeNotSatisfiable = false;

  @override
  Future<DateTime?> mtime(String path) async => remoteMtime;
}

void main() {
  late AppDatabase db;
  late FakeTransferApi api;
  late Directory dir;
  late TransferQueue queue;

  TransferQueue newQueue() => TransferQueue(db, api: api, serverId: 1);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    api = FakeTransferApi();
    dir = await Directory.systemTemp.createTemp('transfers');
    queue = newQueue();
  });
  tearDown(() async {
    await queue.dispose();
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<List<Transfer>> rows() => db.select(db.transfers).get();

  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> until(bool Function() done) async {
    for (var i = 0; i < 200 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(done(), isTrue);
  }

  Future<Transfer> waitState(TransferState state, {int index = 0}) async {
    late Transfer t;
    for (var i = 0; i < 200; i++) {
      t = (await rows())[index];
      if (t.state == state) return t;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    fail('Zustand ${t.state} statt $state');
  }

  Future<void> download(String name) => queue.enqueueDownload(
    remotePath: '/music/$name',
    localPath: '${dir.path}/$name',
    size: 1000,
    mtime: DateTime.utc(2026, 9, 1),
  );

  test('höchstens zwei Transfers gleichzeitig', () async {
    api.gated = true;
    for (final n in ['a', 'b', 'c']) {
      await download(n);
    }
    await until(() => api.running == 2);
    await settle();
    expect(api.downloads.map((d) => d.path), ['/music/a', '/music/b']);
    expect((await rows()).map((t) => t.state), [
      TransferState.running,
      TransferState.running,
      TransferState.queued,
    ]);

    api.gates.first.complete();
    await until(() => api.downloads.length == 3);
    expect(api.running, 2);
    api.openAll();
    await waitState(TransferState.done, index: 2);
  });

  test('fertiger Download landet im Offline-Bereich', () async {
    await download('a.flac');
    final t = await waitState(TransferState.done);
    expect(t.bytesDone, 1000);
    final offline = await db.select(db.offlineFiles).getSingle();
    expect(offline.remotePath, '/music/a.flac');
    expect(offline.size, 1000);
    expect(offline.mtime!.isAtSameMomentAs(DateTime.utc(2026, 9, 1)), isTrue);
    expect(await File('${dir.path}/a.flac').readAsBytes(), api.content);
    expect(File('${dir.path}/a.flac.part').existsSync(), isFalse);
  });

  test('Resume: vorhandene .part-Datei → Download ab ihrer Länge', () async {
    await File('${dir.path}/a.flac.part')
        .writeAsBytes(api.content.sublist(0, 300));
    await download('a.flac');
    await waitState(TransferState.done);
    expect(api.downloads.single.offset, 300);
    expect(await File('${dir.path}/a.flac').readAsBytes(), api.content);
  });

  test('Fehler → failed mit Grund; Wiederholen setzt per Range fort', () async {
    api.failWith = const SynoNetworkError();
    await download('a.flac');
    final failed = await waitState(TransferState.failed);
    expect(failed.error, 'SynoNetworkError');
    expect(failed.bytesDone, 400);

    await queue.retry(failed.id);
    await waitState(TransferState.done);
    expect(api.downloads.map((d) => d.offset), [0, 400]);
    expect(await File('${dir.path}/a.flac').readAsBytes(), api.content);
  });

  test(
    'Auth-Fehler: keine weiteren Starts, kein automatisches Wiederholen',
    () async {
      await queue.dispose();
      queue = TransferQueue(db, api: api, serverId: 1, maxParallel: 1);
      api.failWith = const SynoSessionExpired();
      await download('a');
      await download('b');
      await waitState(TransferState.failed);
      await settle();
      expect(api.downloads, hasLength(1));
      expect((await rows())[1].state, TransferState.queued);
      expect((await rows())[0].error, 'SynoSessionExpired');
    },
  );

  test(
    'Persistenz: laufender Transfer wird nach Neustart fortgesetzt',
    () async {
      await queue.dispose();
      // Stand wie nach einem App-Kill mitten im Download.
      await db
          .into(db.transfers)
          .insert(
            TransfersCompanion.insert(
              serverId: 1,
              kind: TransferKind.download,
              remotePath: '/music/a.flac',
              localPath: '${dir.path}/a.flac',
              state: TransferState.running,
              createdAt: DateTime.now(),
              bytesDone: const Value(200),
            ),
          );
      await File('${dir.path}/a.flac.part')
          .writeAsBytes(api.content.sublist(0, 200));

      queue = newQueue();
      await queue.start();
      await waitState(TransferState.done);
      expect(api.downloads.single.offset, 200);
    },
  );

  test('Pause bricht ab und behält den Teil-Download', () async {
    api.gated = true;
    await download('a');
    await until(() => api.running == 1);
    final id = (await rows()).single.id;
    await queue.pause(id);
    expect((await rows()).single.state, TransferState.paused);

    api.gated = false;
    await queue.retry(id);
    await waitState(TransferState.done);
  });

  test('Abbrechen entfernt Transfer und .part-Datei', () async {
    api.gated = true;
    await File('${dir.path}/a.part').writeAsBytes([1, 2, 3]);
    await download('a');
    await until(() => api.running == 1);
    await queue.cancel((await rows()).single.id);
    expect(await rows(), isEmpty);
    expect(File('${dir.path}/a.part').existsSync(), isFalse);
  });

  test('Upload übernimmt den freien Namen vom NAS', () async {
    final file = File('${dir.path}/x.jpg')..writeAsBytesSync([1, 2, 3]);
    await queue.enqueueUpload(
      localPath: file.path,
      remotePath: '/photo/Handy/x.jpg',
      overwrite: false,
    );
    final t = await waitState(TransferState.done);
    expect(api.uploads.single, (
      folder: '/photo/Handy',
      name: 'x.jpg',
      overwrite: false,
    ));
    expect(t.remotePath, '/photo/Handy/x (1).jpg');
    expect(t.bytesDone, 3);
  });

  test('derselbe Download wird nicht doppelt eingereiht', () async {
    api.gated = true;
    await download('a');
    await download('a');
    expect(await rows(), hasLength(1));
    api.openAll();
  });

  test('ohne Server (keine Session) startet nichts', () async {
    await queue.dispose();
    queue = TransferQueue(db);
    await db
        .into(db.transfers)
        .insert(
          TransfersCompanion.insert(
            serverId: 1,
            kind: TransferKind.download,
            remotePath: '/a',
            localPath: '${dir.path}/a',
            state: TransferState.queued,
            createdAt: DateTime.now(),
          ),
        );
    await queue.start();
    await settle();
    expect(api.downloads, isEmpty);
  });

  test('Alle pausieren mit mehr als zwei: nichts startet nach, kein '
      'Doppel-Worker nach Fortsetzen', () async {
    api.gated = true;
    for (final n in ['a', 'b', 'c', 'd']) {
      await download(n);
    }
    await until(() => api.running == 2);
    await queue.pauseAll();
    await settle();
    expect(
      (await rows()).map((t) => t.state),
      everyElement(TransferState.paused),
    );
    expect(api.downloads.map((d) => d.path), ['/music/a', '/music/b']);

    final c = (await rows())[2].id;
    await queue.retry(c);
    await until(() => api.running == 1);
    await settle();
    expect(api.downloads.where((d) => d.path == '/music/c'), hasLength(1));
    expect(api.running, 1);
    api.openAll();
    await waitState(TransferState.done, index: 2);
    expect((await rows())[3].state, TransferState.paused);
  });

  test(
    'suspend (Serverwechsel): Laufende pausiert, Wartende bleiben',
    () async {
      api.gated = true;
      for (final n in ['a', 'b', 'c']) {
        await download(n);
      }
      await until(() => api.running == 2);
      await queue.suspend();
      expect((await rows()).map((t) => t.state), [
        TransferState.paused,
        TransferState.paused,
        TransferState.queued,
      ]);
      api.openAll();
    },
  );

  test('Fortsetzen nach Änderung auf dem NAS beginnt neu', () async {
    await File('${dir.path}/a.flac.part')
        .writeAsBytes(api.content.sublist(0, 300));
    api.remoteMtime = DateTime.utc(2026, 9, 20);
    await download('a.flac'); // mtime 1.9. aus dem Listing
    await waitState(TransferState.done);
    expect(api.downloads.single.offset, 0);
    expect(await File('${dir.path}/a.flac').readAsBytes(), api.content);
    final offline = await db.select(db.offlineFiles).getSingle();
    expect(offline.mtime!.isAtSameMomentAs(DateTime.utc(2026, 9, 20)), isTrue);
  });

  test('416 beim Fortsetzen: .part verwerfen, bei 0 neu', () async {
    await File('${dir.path}/a.flac.part')
        .writeAsBytes(api.content.sublist(0, 300));
    api
      ..remoteMtime = DateTime.utc(2026, 9, 1)
      ..rangeNotSatisfiable = true;
    await download('a.flac');
    await waitState(TransferState.done);
    expect(api.downloads.map((d) => d.offset), [300, 0]);
    expect(await File('${dir.path}/a.flac').readAsBytes(), api.content);
  });

  test('Benachrichtigung nur, solange etwas läuft', () {
    Transfer t(TransferState state) => Transfer(
      id: state.index,
      serverId: 1,
      kind: TransferKind.download,
      remotePath: '/a',
      localPath: '/a',
      bytesDone: 0,
      state: state,
      overwrite: false,
      createdAt: DateTime(2026),
    );
    expect(notifiedTransfers([t(TransferState.queued)]), isEmpty);
    expect(
      notifiedTransfers([t(TransferState.queued), t(TransferState.failed)]),
      isEmpty,
    );
    expect(
      notifiedTransfers([
        t(TransferState.running),
        t(TransferState.queued),
        t(TransferState.done),
      ]).map((t) => t.state),
      [TransferState.running, TransferState.queued],
    );
  });

  test('Fehler-Tags', () {
    expect(
      transferErrorTag(const SynoNetworkError(statusCode: 502)),
      'SynoNetworkError:502',
    );
    expect(
      transferErrorTag(const SynoPermissionDenied(407)),
      'SynoPermissionDenied:407',
    );
    expect(transferErrorTag(const FileSystemException('x')), 'local');
  });
}
