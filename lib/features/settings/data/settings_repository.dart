import 'package:drift/drift.dart';

import '../../../core/storage/app_database.dart';

/// App-Einstellungen als Schlüssel/Wert in drift (Tabelle `settings`, dieselbe
/// wie „Streaming nur im WLAN“ im `PlaybackRepository`).
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const themeMode = 'themeMode';
  static const locale = 'locale';
  static const cacheLimitMb = 'cacheLimitMb';

  SimpleSelectStatement<$SettingsTable, Setting> _row(String key) =>
      _db.select(_db.settings)..where((s) => s.key.equals(key));

  Stream<String?> watch(String key) =>
      _row(key).watchSingleOrNull().map((r) => r?.value);

  Future<String?> read(String key) async =>
      (await _row(key).getSingleOrNull())?.value;

  /// Setzt [key]; `null` entfernt ihn (= Standardwert).
  Future<void> write(String key, String? value) => value == null
      ? (_db.delete(_db.settings)..where((s) => s.key.equals(key))).go()
      : _db
            .into(_db.settings)
            .insertOnConflictUpdate(
              SettingsCompanion.insert(key: key, value: value),
            );

  /// Einfache Sperre über Isolates hinweg (App und Hintergrund-Task teilen
  /// die Datenbank): `true`, wenn [key] frei oder älter als [stale] war.
  Future<bool> tryLock(String key, {required Duration stale}) =>
      _db.transaction(() async {
        final held = int.tryParse(await read(key) ?? '');
        final now = DateTime.now().millisecondsSinceEpoch;
        if (held != null && now - held < stale.inMilliseconds) return false;
        await write(key, '$now');
        return true;
      });
}
