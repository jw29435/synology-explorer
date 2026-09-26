import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/core/network/certificate_pinning.dart';
import 'package:nuvo_explorer/core/network/syno_api_client.dart';
import 'package:nuvo_explorer/core/network/syno_exception.dart';
import 'package:nuvo_explorer/features/audio/data/track_info_loader.dart';
import 'package:nuvo_explorer/features/servers/domain/server_profile.dart';

/// Echter Server, dessen Download nach den Headern und ein paar Bytes
/// hängen bleibt – wie eine tote TCP-Verbindung ohne Reset.
void main() {
  late HttpServer server;
  late SynoApiClient client;
  late bool stall;
  final open = <HttpResponse>[];

  setUp(() async {
    stall = true;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final params = {
        ...request.uri.queryParameters,
        ...Uri.splitQueryString(await utf8.decodeStream(request)),
      };
      final res = request.response;
      if (params['api'] == 'SYNO.API.Info') {
        res.headers.contentType = ContentType.json;
        res.write(
          jsonEncode({
            'success': true,
            'data': {
              'SYNO.FileStation.Download': {
                'maxVersion': 2,
                'path': 'entry.cgi',
              },
            },
          }),
        );
        return res.close();
      }
      res
        ..headers.contentType = ContentType('audio', 'mpeg')
        ..contentLength = 1000;
      res.add(List.filled(10, 1));
      await res.flush();
      if (stall) {
        open.add(res); // nie beendet
        return;
      }
      res.add(List.filled(990, 1));
      await res.close();
    });
    FlutterSecureStorage.setMockInitialValues({});
    client = SynoApiClient(
      ServerProfile(
        id: 1,
        name: 'NAS',
        lanUrl: 'http://127.0.0.1:${server.port}',
        user: 'u',
      ),
      CertificatePinStore(const FlutterSecureStorage()),
    );
    await client.connect();
    addTearDown(() async {
      client.close();
      await server.close(force: true);
    });
  });

  test('hängender Download bricht nach dem Timeout ab', () async {
    final watch = Stopwatch()..start();
    await expectLater(
      downloadBytes(
        client,
        '/a.mp3',
        timeout: const Duration(milliseconds: 300),
      ),
      throwsA(isA<SynoNetworkError>()),
    );
    expect(watch.elapsed, lessThan(const Duration(seconds: 5)));

    // Danach geht ein neuer Load ganz normal.
    stall = false;
    final bytes = await downloadBytes(client, '/a.mp3');
    expect(bytes, hasLength(1000));
  });
}
