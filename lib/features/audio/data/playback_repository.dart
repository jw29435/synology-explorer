import 'package:drift/drift.dart';

import '../../../core/storage/app_database.dart';

/// Hörbuch-Ordner und die Einstellung „Streaming nur im WLAN“ – lokal in
/// drift. Positionen: `PlaybackPositionRepository` (gemeinsam mit Video).
class PlaybackRepository {
  PlaybackRepository(this._db);

  static const _wifiOnlyKey = 'streamingWifiOnly';

  final AppDatabase _db;

  SimpleSelectStatement<$AudiobookFoldersTable, AudiobookFolder> _audiobook(
    int serverId,
    String folder,
  ) =>
      _db.select(_db.audiobookFolders)
        ..where((a) => a.serverId.equals(serverId) & a.path.equals(folder));

  Stream<bool> watchAudiobook(int serverId, String folder) =>
      _audiobook(serverId, folder).watchSingleOrNull().map((r) => r != null);

  Future<void> setAudiobook(int serverId, String folder, bool on) async {
    if (on) {
      await _db
          .into(_db.audiobookFolders)
          .insert(
            AudiobookFoldersCompanion.insert(serverId: serverId, path: folder),
            mode: InsertMode.insertOrIgnore,
          );
    } else {
      await (_db.delete(_db.audiobookFolders)
            ..where((a) => a.serverId.equals(serverId) & a.path.equals(folder)))
          .go();
    }
  }

  /// Zuletzt gespielter Titel eines Hörbuch-Ordners; `null` bei normalen
  /// Ordnern.
  Future<String?> lastTrack(int serverId, String folder) async =>
      (await _audiobook(serverId, folder).getSingleOrNull())?.lastTrack;

  /// Merkt [track] nur, wenn [folder] im Hörbuch-Modus ist.
  Future<void> setLastTrack(int serverId, String folder, String track) =>
      (_db.update(_db.audiobookFolders)
            ..where((a) => a.serverId.equals(serverId) & a.path.equals(folder)))
          .write(AudiobookFoldersCompanion(lastTrack: Value(track)));

  Stream<bool> watchWifiOnly() =>
      (_db.select(_db.settings)..where((s) => s.key.equals(_wifiOnlyKey)))
          .watchSingleOrNull()
          .map((r) => r?.value == 'true');

  Future<bool> wifiOnly() => watchWifiOnly().first;

  Future<void> setWifiOnly(bool on) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: _wifiOnlyKey, value: '$on'),
      );
}
