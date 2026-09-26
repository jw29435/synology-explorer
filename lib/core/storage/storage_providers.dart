import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_database.dart';

/// Secure Storage aller Secrets (SID, Geräte-Token, Passwort, Pins).
///
/// iOS: lesbar ab der ersten Entsperrung nach dem Start, damit der
/// Auto-Upload im Hintergrund auch bei gesperrtem Gerät die SID lesen kann;
/// nur auf diesem Gerät (kein Keychain-Sync, kein Backup-Transfer).
const appSecureStorage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => appSecureStorage,
);

/// Einmalig: Einträge aus der Zeit vor [appSecureStorage] (iOS-Standard
/// „nur entsperrt“) auf die neue Zugriffsstufe umziehen. Der Keychain kennt
/// einen Schlüssel nur einmal, egal mit welcher Stufe – deshalb erst mit der
/// alten Stufe löschen, dann neu schreiben.
Future<void> migrateSecureStorage({
  FlutterSecureStorage legacy = const FlutterSecureStorage(),
  FlutterSecureStorage target = appSecureStorage,
}) async {
  const marker = 'storage:accessibility';
  if (await target.read(key: marker) == 'first_unlock_this_device') return;
  final entries = {...await legacy.readAll()};
  for (final MapEntry(:key, :value) in entries.entries) {
    await legacy.delete(key: key);
    await target.write(key: key, value: value);
  }
  await target.write(key: marker, value: 'first_unlock_this_device');
}

/// Öffnet die App-Datenbank. Geteilt über Isolates: Der Auto-Upload im
/// Hintergrund (eigene Engine) nutzt dieselbe Verbindung wie die App.
AppDatabase openAppDatabase() => AppDatabase(
  driftDatabase(
    name: 'synology_explorer',
    native: const DriftNativeOptions(shareAcrossIsolates: true),
  ),
);

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = openAppDatabase();
  ref.onDispose(db.close);
  return db;
});
