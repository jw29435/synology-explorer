import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import '../../tool/mock_nas/mock_nas.dart';

void main() {
  late Handler handler;
  setUp(() => handler = mockNasHandler(Directory('test/fixtures')));

  Future<Map<String, dynamic>> call(String query, {String? body}) async {
    final url = Uri.parse('http://nas/webapi/entry.cgi?$query');
    final response = await handler(
      body == null ? Request('GET', url) : Request('POST', url, body: body),
    );
    expect(response.statusCode, 200);
    return jsonDecode(await response.readAsString()) as Map<String, dynamic>;
  }

  int? code(Map<String, dynamic> json) => json['error']?['code'] as int?;

  const creds = 'account=$mockUser&passwd=$mockPassword';

  test('liefert Fixture für api/method per GET', () async {
    final json = await call('api=SYNO.API.Info&version=1&method=query');
    expect(json['success'], isTrue);
    expect(json['data']['SYNO.API.Auth']['maxVersion'], 7);
  });

  test('Login: falsches Passwort 400, OTP fehlt 403, OTP falsch 404', () async {
    const login = 'api=SYNO.API.Auth&method=login';
    expect(code(await call('', body: '$login&account=x&passwd=y')), 400);
    expect(code(await call('', body: '$login&$creds')), 403);
    expect(code(await call('', body: '$login&$creds&otp_code=000000')), 404);
  });

  test('Login mit OTP oder Geräte-Token liefert jeweils neue SID', () async {
    const login = 'api=SYNO.API.Auth&method=login&$creds';
    final a = await call('', body: '$login&otp_code=$mockOtp');
    final did = a['data']['did'] as String;
    final b = await call('', body: '$login&device_id=$did');
    expect(b['success'], isTrue);
    expect(b['data']['sid'], isNot(a['data']['sid']));
  });

  test('ohne gültige _sid → 119, nach Logout ebenso', () async {
    const shares = 'api=SYNO.FileStation.List&method=list_share';
    expect(code(await call(shares)), 119);
    final login = await call(
      '',
      body: 'api=SYNO.API.Auth&method=login&$creds&otp_code=$mockOtp',
    );
    final sid = login['data']['sid'];
    expect((await call('$shares&_sid=$sid'))['success'], isTrue);
    await call('api=SYNO.API.Auth&method=logout&_sid=$sid');
    expect(code(await call('$shares&_sid=$sid')), 119);
  });

  test('unbekannte API → 102, unbekannte Methode → 103', () async {
    expect(code(await call('api=SYNO.Nope&method=x')), 102);
    expect(code(await call('api=SYNO.API.Auth&method=nope')), 103);
    expect(code(await call('api=..&method=pubspec')), 102);
  });

  test('andere Pfade → 404', () async {
    final response = await handler(Request('GET', Uri.parse('http://nas/x')));
    expect(response.statusCode, 404);
  });
}
