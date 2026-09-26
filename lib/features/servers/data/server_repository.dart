import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/auth/session_manager.dart';
import '../../../core/network/certificate_pinning.dart';
import '../../../core/network/syno_api_client.dart';
import '../../../core/storage/app_database.dart';
import '../../autoupload/data/auto_upload_repository.dart';
import '../../transfers/domain/transfer.dart';
import '../domain/server_profile.dart';

class ServerRepository {
  ServerRepository(this._db, this._storage, this._pins, {String? deviceName})
    : deviceName = deviceName ?? 'Nuvo Explorer (${Platform.operatingSystem})';

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

  /// Löscht Profil, alle Daten mit dieser Server-ID (Favoriten, Verlauf,
  /// Transfers, Offline-Dateien samt `offline/<id>/` auf der Platte,
  /// Wiedergabepositionen, Hörbuch-Ordner, eine Auto-Upload-Konfiguration)
  /// und Secrets. Zertifikat-Pins bleiben (je Host).
  Future<void> remove(int id) async {
    // Offline-Ordner `<root>/<id>` aus den lokalen Pfaden ableiten
    // (`<root>/<id><NAS-Pfad>`, siehe OfflineStore.localPathFor); fertige
    // Dateien und `.part`-Reste laufender Downloads liegen dort.
    final offline = await (_db.select(
      _db.offlineFiles,
    )..where((f) => f.serverId.equals(id))).get();
    final downloads =
        await (_db.select(_db.transfers)..where(
              (t) =>
                  t.serverId.equals(id) &
                  t.kind.equalsValue(TransferKind.download),
            ))
            .get();
    final dirs = <String>{
      for (final (local, remote) in [
        for (final f in offline) (f.localPath, f.remotePath),
        for (final t in downloads) (t.localPath, t.remotePath),
      ])
        if (local.endsWith(remote))
          if (local.substring(0, local.length - remote.length) case final dir
              when dir.endsWith('/$id'))
            dir,
    };
    await _db.transaction(() async {
      await (_db.delete(_db.servers)..where((s) => s.id.equals(id))).go();
      await (_db.delete(
        _db.favorites,
      )..where((f) => f.serverId.equals(id))).go();
      await (_db.delete(
        _db.recentFiles,
      )..where((r) => r.serverId.equals(id))).go();
      await (_db.delete(
        _db.transfers,
      )..where((t) => t.serverId.equals(id))).go();
      await (_db.delete(
        _db.offlineFiles,
      )..where((f) => f.serverId.equals(id))).go();
      await (_db.delete(
        _db.playbackPositions,
      )..where((p) => p.serverId.equals(id))).go();
      await (_db.delete(
        _db.audiobookFolders,
      )..where((a) => a.serverId.equals(id))).go();
      await AutoUploadRepository(_db).forgetServer(id);
    });
    for (final dir in dirs) {
      try {
        await Directory(dir).delete(recursive: true);
      } on FileSystemException {
        // Schon weg.
      }
    }
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
