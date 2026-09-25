import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/core/network/syno_exception.dart';

void main() {
  test('Login-Codes von SYNO.API.Auth', () {
    SynoException auth(int code) =>
        SynoException.fromCode(code, api: 'SYNO.API.Auth');
    expect(auth(400), isA<SynoUnauthorized>());
    expect(auth(401), isA<SynoAccountLocked>());
    expect(auth(407), isA<SynoAccountLocked>());
    expect(auth(402), isA<SynoPermissionDenied>());
    expect(auth(403), isA<SynoOtpRequired>());
    expect(auth(404), isA<SynoOtpInvalid>());
    expect(auth(119), isA<SynoSessionExpired>());
  });

  test('gleiche Codes bedeuten bei File Station etwas anderes', () {
    SynoException fs(int code) =>
        SynoException.fromCode(code, api: 'SYNO.FileStation.List');
    expect(fs(105), isA<SynoPermissionDenied>());
    expect(fs(106), isA<SynoSessionExpired>());
    expect(fs(107), isA<SynoSessionExpired>());
    expect(fs(119), isA<SynoSessionExpired>());
    expect(fs(407), isA<SynoPermissionDenied>());
    expect(fs(408), isA<SynoNotFound>());
    expect(fs(400), isA<SynoUnknown>());
    expect(fs(403), isA<SynoUnknown>());
    expect(fs(414), isA<SynoUnknown>().having((e) => e.code, 'code', 414));
  });
}
