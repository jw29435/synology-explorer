import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_database.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

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
