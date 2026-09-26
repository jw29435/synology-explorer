import 'dart:io';

import 'package:drift/drift.dart';

import '../../../core/storage/app_database.dart';

/// Offline-Dateien (Screen 21): `<Documents>/offline/<serverId>/<NAS-Pfad>`,
/// Einträge in [OfflineFiles]. Geschrieben werden sie von der TransferQueue.
class OfflineStore {
  OfflineStore(this._db, this._root);

  final AppDatabase _db;
  final Future<Directory> _root;

  /// Lokaler Pfad für [remotePath]; lehnt `..` ab, damit kein NAS-Pfad aus
  /// dem Offline-Verzeichnis herausführt.
  Future<String> localPathFor(int serverId, String remotePath) async {
    if (!remotePath.startsWith('/') || remotePath.split('/').contains('..')) {
      throw ArgumentError.value(remotePath, 'remotePath');
    }
    return '${(await _root).path}/$serverId$remotePath';
  }

  Stream<List<OfflineFile>> watchAll() => (_db.select(
    _db.offlineFiles,
  )..orderBy([(f) => OrderingTerm.asc(f.remotePath)])).watch();

  Stream<bool> isOffline(int serverId, String remotePath) =>
      (_db.select(_db.offlineFiles)..where(
            (f) =>
                f.serverId.equals(serverId) & f.remotePath.equals(remotePath),
          ))
          .watchSingleOrNull()
          .map((f) => f != null);

  /// Löscht die lokale Kopie von [remotePath] samt Eintrag.
  Future<void> remove(int serverId, String remotePath) async {
    final where = _db.delete(_db.offlineFiles)
      ..where(
        (f) => f.serverId.equals(serverId) & f.remotePath.equals(remotePath),
      );
    final file =
        await (_db.select(_db.offlineFiles)..where(
              (f) =>
                  f.serverId.equals(serverId) & f.remotePath.equals(remotePath),
            ))
            .getSingleOrNull();
    if (file == null) return;
    try {
      await File(file.localPath).delete();
    } on FileSystemException {
      // Schon weg – Eintrag trotzdem entfernen.
    }
    await where.go();
  }
}
