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
    final did = a['data']['device_id'] as String;
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

  group('MockNasControl', () {
    late MockNasControl control;
    late String sid;

    setUp(() async {
      control = MockNasControl();
      handler = mockNasHandler(Directory('test/fixtures'), control: control);
      final login = await call(
        '',
        body: 'api=SYNO.API.Auth&method=login&$creds&otp_code=$mockOtp',
      );
      sid = login['data']['sid'] as String;
    });

    test('expireSessions → 119, rejectLogin → 400', () async {
      const shares = 'api=SYNO.FileStation.List&method=list_share';
      control.expireSessions();
      expect(code(await call('$shares&_sid=$sid')), 119);
      control.rejectLogin = true;
      expect(
        code(await call('', body: 'api=SYNO.API.Auth&method=login&$creds')),
        400,
      );
    });

    test('denyWrites: Delete-status FAIL mit errors[0], Sharing 407', () async {
      control.denyWrites = 407;
      final start = await call(
        'api=SYNO.FileStation.Delete&method=start&_sid=$sid&path=["/music/a"]',
      );
      final task = jsonEncode(start['data']['taskid']);
      final status = await call(
        'api=SYNO.FileStation.Delete&method=status&_sid=$sid&taskid=$task',
      );
      expect(status['data']['status'], 'FAIL');
      expect(status['data']['errors'][0]['code'], 407);
      expect(
        code(
          await call(
            'api=SYNO.FileStation.Sharing&method=create&_sid=$sid'
            '&path=["/music/a"]',
          ),
        ),
        407,
      );
    });

    test(
      '#recycle: music listbar ohne Gelöschtes, photo 407, sonst 408',
      () async {
        Future<Map<String, dynamic>> list(String folder) => call(
          'api=SYNO.FileStation.List&method=list&_sid=$sid'
          '&folder_path=${Uri.encodeQueryComponent(folder)}',
        );
        final names = [
          for (final f in (await list('/music/#recycle'))['data']['files'])
            f['name'],
        ];
        expect(names, ['Alben', 'Demo Sturmflut.mp3']);
        expect(code(await list('/photo/#recycle')), 407);
        expect(code(await list('/video/#recycle')), 408);

        await call(
          'api=SYNO.FileStation.Delete&method=start&_sid=$sid'
          '&path=${Uri.encodeQueryComponent('["/music/#recycle/Alben"]')}',
        );
        final after = (await list('/music/#recycle'))['data']['files'] as List;
        expect(after.map((f) => f['name']), ['Demo Sturmflut.mp3']);
      },
    );

    test('Download: Inhalt je Pfad, 502 als HTML', () async {
      control
        ..files['/a.txt'] = utf8.encode('hallo')
        ..downloadErrors['/b.txt'] = 502;
      Future<Response> download(String path) async => handler(
        Request(
          'GET',
          Uri.parse(
            'http://nas/webapi/entry.cgi?api=SYNO.FileStation.Download'
            '&method=download&_sid=$sid&path=$path',
          ),
        ),
      );
      expect(await (await download('/a.txt')).readAsString(), 'hallo');
      final missing = await download('/b.txt');
      expect(missing.statusCode, 502);
      expect(missing.headers['content-type'], 'text/html');
    });
  });
}
