import 'package:drift/drift.dart';

import '../../../core/storage/app_database.dart';
import '../../settings/data/settings_repository.dart';
import '../domain/auto_upload_config.dart';

/// Einstellungen, Fortschritt (Cursor) und Protokoll des Auto-Uploads.
class AutoUploadRepository {
  AutoUploadRepository(this._db) : _settings = SettingsRepository(_db);

  final AppDatabase _db;
  final SettingsRepository _settings;

  static const _config = 'autoUpload';
  static const _lock = 'autoUploadLock';
  static const _lastCheck = 'autoUploadLastCheck';

  Stream<AutoUploadConfig> watch() =>
      _settings.watch(_config).map(AutoUploadConfig.decode);

  Future<AutoUploadConfig> read() async =>
      AutoUploadConfig.decode(await _settings.read(_config));

  /// Ändert die Einstellungen atomar (der Lauf schreibt parallel den Cursor).
  Future<AutoUploadConfig> update(
    AutoUploadConfig Function(AutoUploadConfig) change,
  ) => _db.transaction(() async {
    final next = change(await read());
    await _settings.write(_config, next.encode());
    return next;
  });

  /// Nur ein Lauf gleichzeitig (App oder Hintergrund); nach 15 min gilt eine
  /// Sperre als verwaist (Prozess beendet).
  Future<bool> tryLock() =>
      _settings.tryLock(_lock, stale: const Duration(minutes: 15));

  Future<void> unlock() => _settings.write(_lock, null);

  Future<void> markChecked() =>
      _settings.write(_lastCheck, '${DateTime.now().millisecondsSinceEpoch}');

  Stream<DateTime?> watchLastCheck() => _settings
      .watch(_lastCheck)
      .map(
        (v) => v == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(int.parse(v)),
      );

  $AutoUploadRunsTable get _runs => _db.autoUploadRuns;

  /// Neuester Eintrag zuerst, höchstens 100.
  Stream<List<AutoUploadRun>> watchRuns() =>
      (_db.select(_runs)
            ..orderBy([(r) => OrderingTerm.desc(r.id)])
            ..limit(100))
          .watch();

  /// Summe aller gesicherten Dateien und Bytes.
  Stream<({int files, int bytes})> watchTotals() {
    final files = _runs.files.sum();
    final failed = _runs.failed.sum();
    final bytes = _runs.bytes.sum();
    return (_db.selectOnly(
      _runs,
    )..addColumns([files, failed, bytes])).watchSingle().map(
      (r) => (
        files: (r.read(files) ?? 0) - (r.read(failed) ?? 0),
        bytes: r.read(bytes) ?? 0,
      ),
    );
  }

  /// Protokolliert einen Lauf. Hängt er wie der letzte an derselben
  /// Bedingung ([note]), wird der letzte Eintrag nur aktualisiert – sonst
  /// stünde bei „wartet auf WLAN“ alle 15 min eine neue Zeile da.
  Future<int> log({int files = 0, int waiting = 0, String? note}) async {
    final last =
        await (_db.select(_runs)
              ..orderBy([(r) => OrderingTerm.desc(r.id)])
              ..limit(1))
            .getSingleOrNull();
    final entry = AutoUploadRunsCompanion.insert(
      startedAt: DateTime.now(),
      files: Value(files),
      waiting: Value(waiting),
      note: Value(note),
    );
    if (last != null && note != null && last.note == note && last.files == 0) {
      await (_db.update(
        _runs,
      )..where((r) => r.id.equals(last.id))).write(entry);
      return last.id;
    }
    return _db.into(_runs).insert(entry);
  }

  /// Ergebnis eines Laufs, sobald seine Uploads beendet sind.
  Future<void> finish(int run, {int failed = 0, int bytes = 0, String? note}) =>
      (_db.update(_runs)..where((r) => r.id.equals(run))).write(
        AutoUploadRunsCompanion(
          failed: Value(failed),
          bytes: Value(bytes),
          note: Value(note),
        ),
      );
}
