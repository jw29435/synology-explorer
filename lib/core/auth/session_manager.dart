import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/syno_api_client.dart';
import '../network/syno_exception.dart';

/// Login, Geräte-Token und Re-Login für einen verbundenen Server.
///
/// Secrets je Server im Secure Storage: `sid`, `did` (Geräte-Token) und das
/// Passwort nur bei „Passwort merken". Kein automatischer Retry bei
/// Auth-Fehlern – DSM-Auto-Block würde das Konto sperren.
class SessionManager {
  SessionManager(this.client, this._storage, {required this.deviceName}) {
    client.onSessionExpired = _relogin;
  }

  final SynoApiClient client;
  final FlutterSecureStorage _storage;

  /// Name, unter dem das Gerät in DSM bei den vertrauenswürdigen Geräten steht.
  final String deviceName;

  Future<void>? _pendingRelogin;

  static const _secrets = ['sid', 'did', 'password'];

  static String _key(int serverId, String name) => 'server:$serverId:$name';

  static Future<void> clearSecrets(
    FlutterSecureStorage storage,
    int serverId,
  ) => Future.wait([
    for (final name in _secrets) storage.delete(key: _key(serverId, name)),
  ]);

  int get _serverId =>
      client.profile.id ?? (throw StateError('Profil nicht gespeichert'));

  Future<String?> _read(String name) =>
      _storage.read(key: _key(_serverId, name));

  Future<void> _write(String name, String value) =>
      _storage.write(key: _key(_serverId, name), value: value);

  bool get isLoggedIn => client.sid != null;

  /// Übernimmt eine gespeicherte SID. Ist sie abgelaufen, greift beim ersten
  /// Request der Re-Login.
  Future<void> restore() async => client.sid = await _read('sid');

  /// Wirft [SynoOtpRequired], wenn ein OTP nötig ist; dann mit [otp] erneut
  /// aufrufen. Mit Geräte-Token aus einem früheren Login entfällt das OTP.
  Future<void> login(
    String user,
    String password, {
    String? otp,
    bool rememberPassword = false,
  }) async {
    final data = await client.request('SYNO.API.Auth', 'login', {
      'account': user,
      'passwd': password,
      'session': 'FileStation',
      'format': 'sid',
      'otp_code': otp,
      'enable_device_token': 'yes',
      'device_name': deviceName,
      'device_id': await _read('did'),
    }) as Map;
    final sid = data['sid'] as String;
    client.sid = sid;
    await _write('sid', sid);
    // DSM 7 liefert den Geräte-Token als `device_id`, DSM 6 als `did`.
    if (data['device_id'] ?? data['did'] case final String did
        when did.isNotEmpty) {
      await _write('did', did);
    }
    if (rememberPassword) {
      await _write('password', password);
    } else {
      await _storage.delete(key: _key(_serverId, 'password'));
    }
  }

  /// Meldet am NAS ab und löscht SID, Geräte-Token und Passwort lokal – auch
  /// wenn das NAS nicht erreichbar ist.
  Future<void> logout() async {
    try {
      if (client.sid != null) {
        await client.request('SYNO.API.Auth', 'logout', {
          'session': 'FileStation',
        });
      }
    } on SynoException {
      // Lokal abmelden geht vor.
    } finally {
      client.sid = null;
      await clearSecrets(_storage, _serverId);
    }
  }

  /// Parallele Requests mit abgelaufener SID teilen sich einen Re-Login.
  Future<void> _relogin() => _pendingRelogin ??= _silentLogin().whenComplete(
    () => _pendingRelogin = null,
  );

  Future<void> _silentLogin() async {
    final password = await _read('password');
    if (password == null) {
      client.sid = null;
      throw const SynoSessionExpired();
    }
    await login(client.profile.user, password, rememberPassword: true);
  }
}
