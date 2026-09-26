import 'dart:async';

import '../../../core/network/syno_exception.dart';
import '../../../core/storage/app_database.dart';
import '../../browser/data/file_station_list_api.dart';
import '../../browser/domain/nas_entry.dart';
import '../../transfers/data/transfer_queue.dart';
import '../../transfers/domain/transfer.dart';
import '../domain/auto_upload_config.dart';
import 'auto_upload_repository.dart';
import 'camera_roll.dart';

/// Wohin ein Lauf hochlädt: die Queue einer angemeldeten Session.
typedef UploadTarget = ({TransferQueue queue, FileStationListApi listApi});

/// Angemeldet ist ein anderer Server als der des Auto-Uploads.
class OtherServerActive implements Exception {
  const OtherServerActive();
}

/// Gründe (Spalte `note`), warum ein Lauf nicht oder nur teilweise lief.
abstract final class AutoUploadNote {
  static const noPermission = 'noPermission';
  static const noWifi = 'noWifi';
  static const notCharging = 'notCharging';
  static const noWritePermission = 'noWritePermission';
  static const noTarget = 'noTarget';
  static const sessionExpired = 'sessionExpired';
  static const unreachable = 'unreachable';
  static const otherServer = 'otherServer';
  static const error = 'error';

  static String of(Object error) => switch (error) {
    OtherServerActive() => otherServer,
    SynoSessionExpired() ||
    SynoUnauthorized() ||
    SynoAccountLocked() => sessionExpired,
    SynoOtpRequired() || SynoOtpInvalid() => sessionExpired,
    SynoPermissionDenied() => noWritePermission,
    SynoNotFound() => noTarget,
    SynoNetworkError() => unreachable,
    _ => AutoUploadNote.error,
  };
}

/// Ein Auto-Upload-Lauf: neue Aufnahmen seit dem Cursor ermitteln,
/// Bedingungen prüfen, über die TransferQueue hochladen, protokollieren.
/// Läuft in der App (Start, „Jetzt ausführen“) und im Hintergrund-Task.
class AutoUploader {
  AutoUploader(
    this._repo,
    this._camera, {
    required this.isUnmetered,
    required this.isCharging,
  });

  final AutoUploadRepository _repo;
  final CameraRoll _camera;
  final Future<bool> Function() isUnmetered;
  final Future<bool> Function() isCharging;

  /// [connect] liefert die Queue für den Server des Auto-Uploads (erst,
  /// wenn es etwas hochzuladen gibt – kein Login alle 15 min). [manual]
  /// („Jetzt ausführen“) ignoriert „Nur im WLAN“ und „Nur beim Laden“.
  /// Wartet höchstens [wait] auf die Uploads, dann bleiben sie in der Queue.
  Future<void> run(
    Future<UploadTarget> Function(int serverId) connect, {
    bool manual = false,
    Duration wait = const Duration(hours: 12),
  }) async {
    final config = await _repo.read();
    if (!config.ready || !await _repo.tryLock()) return;
    final serverId = config.serverId!;
    UploadTarget? target;
    int? run;
    final ids = <int>[];
    var leftover = const <int>[];
    try {
      if (!await _camera.hasAccess(videos: config.includeVideos)) {
        await _repo.log(note: AutoUploadNote.noPermission);
        return;
      }
      // Zeitpunkt vor der Abfrage: Was währenddessen sichtbar wird, liegt
      // im Fenster des nächsten Laufs.
      final checkedAt = DateTime.now();
      final cursor = config.cursor ?? UploadCursor(checkedAt);
      final pending = pendingAssets(
        await _camera.since(cursor.windowStart, videos: config.includeVideos),
        cursor,
        includeVideos: config.includeVideos,
      );
      await _repo.markChecked();
      // Übrig gebliebene Uploads (Hintergrundlauf beendet) laufen auch ohne
      // neue Aufnahme weiter.
      leftover = await _repo.queuedUploads(serverId);
      if (pending.isEmpty && leftover.isEmpty) {
        await _repo.update(
          (c) => c.copyWith(cursor: cursor.checkedAt(checkedAt)),
        );
        return;
      }

      final waiting = pending.length + leftover.length;
      final blocked = manual
          ? null
          : config.wifiOnly && !await isUnmetered()
          ? AutoUploadNote.noWifi
          : config.chargingOnly && !await isCharging()
          ? AutoUploadNote.notCharging
          : null;
      if (blocked != null) {
        await _repo.log(waiting: waiting, note: blocked);
        return;
      }

      final UploadTarget t;
      try {
        t = target = await connect(serverId);
        final folder = await t.listApi.getInfo(config.targetPath!);
        if (folder.perm == NasPerm.readOnly) {
          throw const SynoPermissionDenied(407);
        }
      } catch (e) {
        await _repo.log(waiting: waiting, note: AutoUploadNote.of(e));
        return;
      }

      for (final asset in pending) {
        // Einreihen und Fortschritt in einer Transaktion: Stirbt der Prozess
        // dazwischen, gibt es weder Lücke noch Doppel.
        Future<void> markDone() => _repo.update(
          (c) => c.copyWith(
            cursor: (c.cursor ?? cursor).advance(asset, DateTime.now()),
          ),
        );
        final original = await _camera.original(asset.id);
        if (original == null) {
          await markDone(); // Inzwischen gelöscht: gilt als erledigt.
          continue;
        }
        ids.add(
          await t.queue.enqueueUpload(
            localPath: original.file.path,
            remotePath: '${config.folderFor(asset.created)}/${original.name}',
            overwrite: false,
            size: await original.file.length(),
            alsoWrite: markDone,
          ),
        );
      }
      await _repo.update(
        (c) => c.copyWith(cursor: (c.cursor ?? cursor).checkedAt(checkedAt)),
      );
      if (ids.isNotEmpty) run = await _repo.log(files: ids.length);
    } finally {
      await _repo.unlock();
    }

    // Warten ohne Sperre: Der nächste Lauf darf schon neue Aufnahmen
    // einreihen.
    final queue = target.queue..kick();
    final result = await _await(queue, [...ids, ...leftover], wait);
    if (run != null) {
      await _repo.finish(
        run,
        failed: result.failed,
        bytes: result.bytes,
        note: result.denied ? AutoUploadNote.noWritePermission : null,
      );
    }
    // Temporäre Kopien der Originale erst weg, wenn nichts sie mehr braucht.
    if (!await _repo.hasOpenUploads(serverId)) {
      try {
        await _camera.clearCache();
      } catch (_) {
        // Aufräumen ist Zusatz.
      }
    }
  }

  /// Wartet, bis keiner der Transfers [ids] mehr wartet oder läuft
  /// (fertig, fehlgeschlagen, pausiert oder abgebrochen).
  static Future<({int failed, int bytes, bool denied})> _await(
    TransferQueue queue,
    List<int> ids,
    Duration wait,
  ) async {
    const open = {TransferState.queued, TransferState.running};
    List<Transfer> mine = const [];
    try {
      await queue
          .watch()
          .map((all) => mine = [...all.where((t) => ids.contains(t.id))])
          .firstWhere((ts) => ts.every((t) => !open.contains(t.state)))
          .timeout(wait);
    } on TimeoutException {
      // Rest bleibt in der Queue und läuft später weiter.
    }
    final failed = mine.where((t) => t.state == TransferState.failed);
    return (
      failed: failed.length,
      bytes: mine
          .where((t) => t.state == TransferState.done)
          .fold(0, (s, t) => s + (t.bytesTotal ?? 0)),
      denied: failed.any(
        (t) => t.error?.startsWith('SynoPermissionDenied') ?? false,
      ),
    );
  }
}
