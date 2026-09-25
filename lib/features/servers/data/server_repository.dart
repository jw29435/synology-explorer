import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/auth/session_manager.dart';
import '../../../core/network/certificate_pinning.dart';
import '../../../core/network/syno_api_client.dart';
import '../../../core/storage/app_database.dart';
import '../domain/server_profile.dart';

class ServerRepository {
  ServerRepository(this._db, this._storage, this._pins, {String? deviceName})
    : deviceName =
          deviceName ?? 'Synology Explorer (${Platform.operatingSystem})';

  final AppDatabase _db;
  final FlutterSecureStorage _storage;
  final CertificatePinStore _pins;
  final String deviceName;

  Future<List<ServerProfile>> all() async => [
    for (final row in await _db.select(_db.servers).get()) _toProfile(row),
  ];

  /// Speichert ein neues Profil und liefert es mit ID zurück.
  Future<ServerProfile> add(ServerProfile profile) async {
    final id = await _db.into(_db.servers).insert(_toCompanion(profile));
    return profile.copyWith(id: id);
  }

  Future<void> update(ServerProfile profile) => (_db.update(
    _db.servers,
  )..where((s) => s.id.equals(profile.id!))).write(_toCompanion(profile));

  /// Löscht Profil und dessen Secrets. Zertifikat-Pins bleiben (je Host).
  Future<void> remove(int id) async {
    await (_db.delete(_db.servers)..where((s) => s.id.equals(id))).go();
    await SessionManager.clearSecrets(_storage, id);
  }

  /// Verbindet (Adresswahl + API-Info) und übernimmt eine gespeicherte SID.
  /// Danach ggf. [SessionManager.login] aufrufen.
  Future<SessionManager> connect(ServerProfile profile) async {
    await _pins.load();
    final client = SynoApiClient(profile, _pins);
    try {
      await client.connect();
    } catch (_) {
      client.close();
      rethrow;
    }
    final session = SessionManager(client, _storage, deviceName: deviceName);
    await session.restore();
    return session;
  }

  static ServerProfile _toProfile(Server row) => ServerProfile(
    id: row.id,
    name: row.name,
    lanUrl: row.lanUrl,
    externalUrl: row.externalUrl,
    user: row.user,
  );

  static ServersCompanion _toCompanion(ServerProfile p) =>
      ServersCompanion.insert(
        name: p.name,
        lanUrl: p.lanUrl,
        externalUrl: Value(p.externalUrl),
        user: p.user,
      );
}
