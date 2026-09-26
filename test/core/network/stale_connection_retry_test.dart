import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/core/network/certificate_pinning.dart';
import 'package:nuvo_explorer/core/network/syno_api_client.dart';
import 'package:nuvo_explorer/core/network/syno_exception.dart';
import 'package:nuvo_explorer/features/servers/domain/server_profile.dart';

/// Echter Server: Die nächsten [drops] Anfragen (außer API-Info) werden vor
/// dem Header hart geschlossen – wie eine tote Keep-alive-Verbindung nach
/// WLAN aus/an („Connection closed before full header was received“).
void main() {
  late HttpServer server;
  late SynoApiClient client;
  late int drops;
  late List<String> calls;

  setUp(() async {
    drops = 0;
    calls = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final params = {
        ...request.uri.queryParameters,
        ...Uri.splitQueryString(await utf8.decodeStream(request)),
      };
      final api = params['api']!;
      if (api != 'SYNO.API.Info') calls.add('$api/${params['method']}');
      if (api != 'SYNO.API.Info' && drops > 0) {
        drops--;
        (await request.response.detachSocket(writeHeaders: false)).destroy();
        return;
      }
      final res = request.response;
      if (api == 'SYNO.FileStation.Download') {
        res.headers.contentType = ContentType('audio', 'mpeg');
        res.add(List.filled(10, 7));
      } else {
        res.headers.contentType = ContentType.json;
        res.write(
          jsonEncode({
            'success': true,
            'data': api == 'SYNO.API.Info'
                ? {
                    for (final a in [
                      'SYNO.API.Auth',
                      'SYNO.FileStation.List',
                      'SYNO.FileStation.Rename',
                      'SYNO.FileStation.Download',
                    ])
                      a: {'maxVersion': 2, 'path': 'entry.cgi'},
                  }
                : {'files': <Object>[], 'total': 0, 'sid': 's'},
          }),
        );
      }
      await res.close();
    });
    FlutterSecureStorage.setMockInitialValues({});
    client = SynoApiClient(
      ServerProfile(
        id: 1,
        name: 'Test',
        lanUrl: 'http://127.0.0.1:${server.port}',
        user: 'johann',
      ),
      CertificatePinStore(const FlutterSecureStorage()),
    );
    await client.connect();
    addTearDown(() async {
      client.close();
      await server.close(force: true);
    });
  });

  Future<dynamic> list() =>
      client.request('SYNO.FileStation.List', 'list', {'folder_path': '/a'});

  test('Lese-Request: tote Verbindung → genau ein zweiter Versuch', () async {
    drops = 1;
    expect((await list() as Map)['total'], 0);
    expect(calls, ['SYNO.FileStation.List/list', 'SYNO.FileStation.List/list']);
  });

  test('zweiter Fehler geht raus, kein dritter Versuch', () async {
    drops = 2;
    await expectLater(list(), throwsA(isA<SynoNetworkError>()));
    expect(calls, hasLength(2));
  });

  test('Stream-Download (Range) wird ebenfalls wiederholt', () async {
    drops = 1;
    final body = await client.requestStream(
      'SYNO.FileStation.Download',
      'download',
      {'path': '/a.mp3', 'mode': 'open'},
    );
    expect(await body.stream.expand((c) => c).toList(), List.filled(10, 7));
    expect(calls, hasLength(2));
  });

  test('schreibende Operation wird nie wiederholt', () async {
    drops = 1;
    await expectLater(
      client.request('SYNO.FileStation.Rename', 'rename', {
        'path': '/a',
        'name': 'b',
      }),
      throwsA(isA<SynoNetworkError>()),
    );
    expect(calls, ['SYNO.FileStation.Rename/rename']);
  });

  test('Login wird nie wiederholt (DSM-Auto-Block)', () async {
    drops = 1;
    await expectLater(
      client.request('SYNO.API.Auth', 'login', {
        'account': 'johann',
        'passwd': 'x',
      }),
      throwsA(isA<SynoNetworkError>()),
    );
    expect(calls, ['SYNO.API.Auth/login']);
  });

  test('nur „Verbindung geschlossen/zurückgesetzt“ zählt', () {
    final options = RequestOptions();
    DioException error(Object cause, [DioExceptionType? type]) => DioException(
      requestOptions: options,
      type: type ?? DioExceptionType.connectionError,
      error: cause,
    );
    expect(
      SynoApiClient.isStaleConnection(
        error(
          const HttpException(
            'Connection closed before full header was received',
          ),
        ),
      ),
      isTrue,
    );
    expect(
      SynoApiClient.isStaleConnection(
        error(
          const SocketException('reset', osError: OSError('reset', 104)),
          DioExceptionType.unknown,
        ),
      ),
      isTrue,
    );
    // Connection refused, Timeout, Abbruch: kein Retry.
    expect(
      SynoApiClient.isStaleConnection(
        error(const SocketException('refused', osError: OSError('x', 111))),
      ),
      isFalse,
    );
    expect(
      SynoApiClient.isStaleConnection(
        error('timeout', DioExceptionType.receiveTimeout),
      ),
      isFalse,
    );
    expect(
      SynoApiClient.isStaleConnection(
        error(
          const HttpException('Connection closed before full header'),
          DioExceptionType.cancel,
        ),
      ),
      isFalse,
    );
  });
}
