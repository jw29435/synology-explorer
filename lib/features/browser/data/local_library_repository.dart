import 'package:drift/drift.dart';

import '../../../core/storage/app_database.dart';
import '../domain/nas_entry.dart';

/// Favoriten und „Zuletzt geöffnet“ – nur lokal auf dem Gerät (drift).
class LocalLibraryRepository {
  LocalLibraryRepository(this._db);

  static const maxRecent = 50;

  final AppDatabase _db;

  Stream<List<NasEntry>> favorites(int serverId) =>
      (_db.select(_db.favorites)
            ..where((f) => f.serverId.equals(serverId))
            ..orderBy([(f) => OrderingTerm.asc(f.addedAt)]))
          .watch()
          .map((rows) => [for (final r in rows) _entry(r.path, r.isDir)]);

  Stream<bool> isFavorite(int serverId, String path) =>
      (_db.select(_db.favorites)
            ..where((f) => f.serverId.equals(serverId) & f.path.equals(path)))
          .watchSingleOrNull()
          .map((row) => row != null);

  Future<void> setFavorite(int serverId, NasEntry entry, bool favorite) async {
    if (favorite) {
      await _db
          .into(_db.favorites)
          .insertOnConflictUpdate(
            FavoritesCompanion.insert(
              serverId: serverId,
              path: entry.path,
              isDir: entry.isDir,
              addedAt: DateTime.now(),
            ),
          );
    } else {
      await (_db.delete(_db.favorites)..where(
            (f) => f.serverId.equals(serverId) & f.path.equals(entry.path),
          ))
          .go();
    }
  }

  Stream<List<({NasEntry entry, DateTime openedAt})>> recent(int serverId) =>
      (_db.select(_db.recentFiles)
            ..where((r) => r.serverId.equals(serverId))
            // rowid statt Zeit: DateTime hat in drift nur Sekunden-Auflösung.
            ..orderBy([(r) => OrderingTerm.desc(r.rowId)])
            ..limit(maxRecent))
          .watch()
          .map(
            (rows) => [
              for (final r in rows)
                (entry: _entry(r.path, false), openedAt: r.openedAt),
            ],
          );

  /// Merkt [path] als geöffnet und hält die Liste bei [maxRecent] Einträgen.
  Future<void> addRecent(int serverId, String path) =>
      _db.transaction(() async {
        await _db
            .into(_db.recentFiles)
            .insertOnConflictUpdate(
              RecentFilesCompanion.insert(
                serverId: serverId,
                path: path,
                openedAt: DateTime.now(),
              ),
            );
        final keep = _db.selectOnly(_db.recentFiles)
          ..addColumns([_db.recentFiles.path])
          ..where(_db.recentFiles.serverId.equals(serverId))
          ..orderBy([OrderingTerm.desc(_db.recentFiles.rowId)])
          ..limit(maxRecent);
        await (_db.delete(_db.recentFiles)..where(
              (r) => r.serverId.equals(serverId) & r.path.isNotInQuery(keep),
            ))
            .go();
      });

  static NasEntry _entry(String path, bool isDir) {
    final name = path.substring(path.lastIndexOf('/') + 1);
    return NasEntry(
      path: path,
      name: name,
      isDir: isDir,
      type: isDir ? NasFileType.folder : NasFileType.fromName(name),
    );
  }
}
