import 'package:drift/drift.dart';

import '../../../core/network/syno_exception.dart';
import '../../../core/storage/app_database.dart';
import '../domain/nas_entry.dart';
import 'favorite_api.dart';

/// Ein Favorit für Screen 05: Ordner vom NAS (wie in DS File) oder lokal
/// markierte Datei; [broken], wenn das NAS das Ziel nicht (mehr) findet.
typedef FavoriteItem = ({NasEntry entry, String name, bool broken});

/// Favoriten und „Zuletzt geöffnet“ in drift. Ordner-Favoriten kommen vom NAS
/// (`SYNO.FileStation.Favorite`, hier nur gespiegelt – Offline und sofortige
/// Anzeige); Datei-Favoriten bleiben lokal, weil DSM Dateien als Favorit nur
/// als `broken` führt. „Zuletzt geöffnet“ ist rein lokal.
class LocalLibraryRepository {
  LocalLibraryRepository(this._db);

  static const maxRecent = 50;

  final AppDatabase _db;

  Stream<List<FavoriteItem>> favorites(int serverId) =>
      (_db.select(_db.favorites)
            ..where((f) => f.serverId.equals(serverId))
            ..orderBy([(f) => OrderingTerm.asc(f.addedAt)]))
          .watch()
          .map(
            (rows) => [
              for (final r in rows)
                (
                  entry: _entry(r.path, r.isDir),
                  name: r.name ?? _entry(r.path, r.isDir).name,
                  broken: r.broken,
                ),
            ],
          );

  /// Spiegelt die Favoriten des NAS-Kontos ([nas], sonst frisch per `list`)
  /// in den Cache. Ersetzt dabei auch frühere lokale Ordner-Favoriten.
  Future<void> syncFavorites(
    int serverId,
    FileStationFavoriteApi api, [
    List<NasFavorite>? nas,
  ]) async {
    final list = nas ?? await api.list();
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.delete(
        _db.favorites,
      )..where((f) => f.serverId.equals(serverId) & (f.remote | f.isDir))).go();
      for (final (i, f) in list.indexed) {
        await _db
            .into(_db.favorites)
            .insertOnConflictUpdate(
              FavoritesCompanion.insert(
                serverId: serverId,
                path: f.path,
                isDir: f.isDir,
                // Reihenfolge wie auf dem NAS.
                addedAt: now.add(Duration(seconds: i)),
                name: Value(f.name),
                remote: const Value(true),
                broken: Value(f.broken),
              ),
            );
      }
    });
  }

  /// Ordner-Favorit auf dem NAS setzen bzw. entfernen. Erst `list`, dann nur
  /// `add`, wenn er fehlt, bzw. `delete`, wenn er da ist – so arbeitet die App
  /// immer auf dem bekannten Stand des NAS (Lehre aus SPIKE.md) und löst keine
  /// überflüssigen Aufrufe aus. Fehler 800 („schon vorhanden“, z. B. von DS
  /// File zwischen `list` und `add` angelegt) gilt als Erfolg. Scheitert der
  /// Aufruf (z. B. 105), bleibt der Cache unverändert und der Fehler geht raus.
  Future<void> setFolderFavorite(
    int serverId,
    FileStationFavoriteApi api,
    NasEntry folder,
    bool favorite,
  ) async {
    final exists = (await api.list()).any((f) => f.path == folder.path);
    if (favorite && !exists) {
      try {
        await api.add(folder.path, folder.name);
      } on SynoUnknown catch (e) {
        if (e.code != 800) rethrow;
      }
    } else if (!favorite && exists) {
      await api.delete(folder.path);
    }
    await syncFavorites(serverId, api);
  }

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
  /// `insertOrReplace` löscht die alte Zeile und vergibt eine neue rowid –
  /// die rowid bestimmt die Reihenfolge (DateTime hat nur Sekunden).
  Future<void> addRecent(int serverId, String path) =>
      _db.transaction(() async {
        await _db
            .into(_db.recentFiles)
            .insert(
              mode: InsertMode.insertOrReplace,
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
