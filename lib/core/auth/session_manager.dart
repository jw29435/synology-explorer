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

  /// Wird gerufen, wenn der stille Re-Login scheitert: Die Session ist dann
  /// endgültig weg, der Nutzer muss sich aktiv anmelden.
  void Function()? onSessionLost;

  static const _secrets = ['sid', 'did', 'password'];

  static String _key(int serverId, String name) => 'server:$serverId:$name';

  static Future<void> clearSecrets(
    FlutterSecureStorage storage,
    int serverId,
  ) => Future.wait([
    for (final name in _secrets) storage.delete(key: _key(serverId, name)),
  ]);

  /// Ob für [serverId] ein Passwort gemerkt ist („Passwort merken“).
  static Future<bool> hasRememberedPassword(
    FlutterSecureStorage storage,
    int serverId,
  ) => storage.containsKey(key: _key(serverId, 'password'));

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
  /// aufrufen. Mit Geräte-Token aus einem früheren Login entfällt das OTP;
  /// [trustDevice] fordert einen solchen Token an.
  Future<void> login(
    String user,
    String password, {
    String? otp,
    bool rememberPassword = false,
    bool trustDevice = true,
  }) async {
    final data = await client.request('SYNO.API.Auth', 'login', {
      'account': user,
      'passwd': password,
      'session': 'FileStation',
      'format': 'sid',
      'otp_code': otp,
      'enable_device_token': trustDevice ? 'yes' : 'no',
      'device_name': deviceName,
      'device_id': await _read('did'),
    }) as Map;
    final sid = data['sid'] as String;
    client.sid = sid;
    await _write('sid', sid);
    // DSM 7 liefert den Geräte-Token als `device_id`, DSM 6 als `did`.
    if (data['device_id'] ?? data['did'] case final String did
        when trustDevice && did.isNotEmpty) {
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
  ///
  /// 105 („keine Berechtigung“) kann auch ein reiner Rechtefehler sein: Ohne
  /// gemerktes Passwort bleibt die Session dann bestehen und der Fehler geht
  /// als solcher raus, statt den Nutzer abzumelden.
  Future<void> _relogin(SynoException cause) async {
    final before = client.sid;
    if (cause is SynoPermissionDenied && !await _hasPassword()) throw cause;
    // Während des Nachsehens hat ein paralleler Request neu angemeldet.
    if (client.sid != before && client.sid != null) return;
    return _pendingRelogin ??= _silentLogin().whenComplete(
      () => _pendingRelogin = null,
    );
  }

  Future<bool> _hasPassword() =>
      _storage.containsKey(key: _key(_serverId, 'password'));

  /// Scheitert der stille Login an der Anmeldung selbst (Passwort geändert,
  /// Konto gesperrt, OTP nötig), wird das gemerkte Passwort verworfen: Jeder
  /// weitere Request endet dann ohne Login-Versuch mit [SynoSessionExpired],
  /// bis sich der Nutzer aktiv anmeldet (DSM-Auto-Block).
  Future<void> _silentLogin() async {
    final password = await _read('password');
    if (password == null) await _lose();
    try {
      await login(client.profile.user, password, rememberPassword: true);
    } on SynoException catch (e) {
      if (e is SynoNetworkError) rethrow;
      await _storage.delete(key: _key(_serverId, 'password'));
      await _lose();
    }
  }

  /// Session verwerfen – auch die gespeicherte SID, sonst übernähme der
  /// nächste Verbindungsaufbau sie wieder – und [onSessionLost] melden.
  Future<Never> _lose() async {
    client.sid = null;
    await _storage.delete(key: _key(_serverId, 'sid'));
    onSessionLost?.call();
    throw const SynoSessionExpired();
  }
}
