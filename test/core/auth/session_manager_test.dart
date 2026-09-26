import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';
import 'package:synology_explorer/core/auth/session_manager.dart';
import 'package:synology_explorer/core/network/certificate_pinning.dart';
import 'package:synology_explorer/core/network/syno_api_client.dart';
import 'package:synology_explorer/core/network/syno_exception.dart';
import 'package:synology_explorer/features/browser/data/file_station_list_api.dart';
import 'package:synology_explorer/features/servers/domain/server_profile.dart';

import '../../../tool/mock_nas/mock_nas.dart';
import '../../helpers/mock_nas_server.dart';

void main() {
  late MockNasServer nas;
  late Map<String, String> secure;

  setUp(() async {
    nas = await MockNasServer.start();
    secure = {};
    FlutterSecureStorage.setMockInitialValues(secure);
  });
  tearDown(() => nas.close());

  Future<SessionManager> session() async {
    const storage = FlutterSecureStorage();
    final client = SynoApiClient(
      ServerProfile(id: 7, name: 'NAS', lanUrl: nas.url, user: mockUser),
      CertificatePinStore(storage),
    );
    await client.connect();
    return SessionManager(client, storage, deviceName: 'Testgerät');
  }

  Iterable<Map<String, String>> logins() => nas.calls('SYNO.API.Auth', 'login');

  test('Device-Token-Flow: OTP einmal, danach per device_id', () async {
    final s = await session();
    await expectLater(
      s.login(mockUser, mockPassword),
      throwsA(isA<SynoOtpRequired>()),
    );
    await expectLater(
      s.login(mockUser, mockPassword, otp: '000000'),
      throwsA(isA<SynoOtpInvalid>()),
    );
    expect(s.isLoggedIn, isFalse);

    await s.login(mockUser, mockPassword, otp: mockOtp);
    expect(logins().last, containsPair('otp_code', mockOtp));
    expect(logins().last, isNot(contains('device_id')));
    expect(logins().last, containsPair('session', 'FileStation'));
    expect(logins().last, containsPair('format', 'sid'));
    expect(logins().last, containsPair('enable_device_token', 'yes'));
    expect(logins().last, containsPair('device_name', 'Testgerät'));
    final did = secure['server:7:did'];
    expect(did, isNotNull);
    expect(secure['server:7:sid'], s.client.sid);

    // Nächste Sitzung: kein OTP nötig, Geräte-Token geht mit.
    final next = await session();
    await next.login(mockUser, mockPassword);
    expect(logins().last, containsPair('device_id', did));
    expect(next.isLoggedIn, isTrue);
  });

  test('falsches Passwort → genau ein Login-Request, kein Retry', () async {
    final s = await session();
    await expectLater(
      s.login(mockUser, 'falsch', otp: mockOtp),
      throwsA(isA<SynoUnauthorized>()),
    );
    expect(logins(), hasLength(1));
    expect(secure, isEmpty);
  });

  test('Passwort nur mit rememberPassword gespeichert', () async {
    final s = await session();
    await s.login(mockUser, mockPassword, otp: mockOtp);
    expect(secure, isNot(contains('server:7:password')));
    await s.login(mockUser, mockPassword, rememberPassword: true);
    expect(secure['server:7:password'], mockPassword);
    await s.login(mockUser, mockPassword);
    expect(secure, isNot(contains('server:7:password')));
  });

  test('gespeicherte SID wird übernommen', () async {
    final s = await session();
    await s.login(mockUser, mockPassword, otp: mockOtp);
    final restored = await session();
    await restored.restore();
    expect(restored.client.sid, s.client.sid);
    await FileStationListApi(restored.client).listShares();
    expect(logins(), hasLength(1));
  });

  test('abgelaufene SID + gemerktes Passwort → stiller Re-Login', () async {
    final s = await session();
    await s.login(mockUser, mockPassword, otp: mockOtp, rememberPassword: true);
    s.client.sid = 'abgelaufen';

    final shares = await FileStationListApi(s.client).listShares();
    expect(shares, isNotEmpty);
    expect(logins(), hasLength(2));
    expect(logins().last, isNot(contains('otp_code')));
    expect(secure['server:7:sid'], s.client.sid);
  });

  test('parallele Requests teilen sich einen Re-Login', () async {
    final s = await session();
    await s.login(mockUser, mockPassword, otp: mockOtp, rememberPassword: true);
    s.client.sid = 'abgelaufen';
    final api = FileStationListApi(s.client);
    await Future.wait([api.listShares(), api.listShares(), api.list('/x')]);
    expect(logins(), hasLength(2));
  });

  test('stiller Re-Login scheitert → keine weiteren Login-Versuche', () async {
    final s = await session();
    await s.login(mockUser, mockPassword, otp: mockOtp, rememberPassword: true);
    // Passwort wurde inzwischen am NAS geändert.
    secure['server:7:password'] = 'veraltet';
    s.client.sid = 'abgelaufen';
    final api = FileStationListApi(s.client);

    await expectLater(api.listShares(), throwsA(isA<SynoSessionExpired>()));
    expect(logins(), hasLength(2), reason: 'genau ein stiller Versuch');
    for (var i = 0; i < 5; i++) {
      await expectLater(api.listShares(), throwsA(isA<SynoSessionExpired>()));
    }
    expect(logins(), hasLength(2), reason: 'danach kein Login mehr');
    expect(s.isLoggedIn, isFalse);
    expect(secure, isNot(contains('server:7:password')));
  });

  test('abgelaufene SID ohne Passwort → sessionExpired, kein Login', () async {
    final s = await session();
    await s.login(mockUser, mockPassword, otp: mockOtp);
    s.client.sid = 'abgelaufen';
    await expectLater(
      FileStationListApi(s.client).listShares(),
      throwsA(isA<SynoSessionExpired>()),
    );
    expect(logins(), hasLength(1));
    expect(s.isLoggedIn, isFalse);
  });

  test('105 ohne gemerktes Passwort: Rechtefehler, Session bleibt', () async {
    final s = await session();
    await s.login(mockUser, mockPassword, otp: mockOtp);
    final sid = s.client.sid;
    nas.intercept = (p) => p['folder_path'] == '/verboten'
        ? Response.ok(
            '{"success": false, "error": {"code": 105}}',
            headers: {'content-type': 'application/json'},
          )
        : null;
    final api = FileStationListApi(s.client);

    await expectLater(
      api.list('/verboten'),
      throwsA(isA<SynoPermissionDenied>()),
    );
    expect(s.client.sid, sid, reason: 'nicht abgemeldet');
    expect(logins(), hasLength(1));
    await api.listShares();
  });

  test('logout ruft die API und löscht SID, DID und Passwort', () async {
    final s = await session();
    await s.login(mockUser, mockPassword, otp: mockOtp, rememberPassword: true);
    final sid = s.client.sid;
    await s.logout();
    expect(nas.calls('SYNO.API.Auth', 'logout').single['_sid'], sid);
    expect(secure, isEmpty);
    expect(s.isLoggedIn, isFalse);
  });

  test('logout ohne Netz löscht trotzdem lokal', () async {
    final s = await session();
    await s.login(mockUser, mockPassword, otp: mockOtp);
    await nas.close();
    await s.logout();
    expect(secure, isEmpty);
  });
}
