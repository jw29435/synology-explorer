import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/core/network/certificate_pinning.dart';
import 'package:nuvo_explorer/core/network/syno_api_client.dart';
import 'package:nuvo_explorer/core/network/syno_exception.dart';
import 'package:nuvo_explorer/features/servers/domain/server_profile.dart';

/// Echter Dio-Client gegen einen lokalen Server, der Downloads als großen,
/// lazy erzeugten Stream liefert (mit Backpressure).
void main() {
  const chunk = 64 * 1024;
  late HttpServer server;
  late SynoApiClient client;
  late int produced;
  late bool upstreamDone;
  late ({String type, List<int> body})? download;

  Stream<List<int>> big(int chunks) async* {
    try {
      for (var i = 0; i < chunks; i++) {
        produced++;
        yield Uint8List(chunk);
      }
    } finally {
      upstreamDone = true;
    }
  }

  setUp(() async {
    produced = 0;
    upstreamDone = false;
    download = null;
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
      } else if (download case final d?) {
        res.headers.set('content-type', d.type);
        res.add(d.body);
      } else {
        res.headers.set('content-type', 'video/mp4');
        try {
          await res.addStream(big(256)); // 16 MB
        } catch (_) {
          // Client hat abgebrochen.
        }
      }
      await res.close().catchError((_) {});
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
      receiveTimeout: const Duration(milliseconds: 200),
    );
    await client.connect();
    addTearDown(() async {
      client.close();
      await server.close(force: true);
    });
  });

  Future<ResponseBody> stream({CancelToken? cancel}) => client.requestStream(
    'SYNO.FileStation.Download',
    'download',
    {'path': '/video/a.mp4', 'mode': 'open'},
    cancelToken: cancel,
  );

  test(
    'Pause länger als der Receive-Timeout bricht den Stream nicht ab',
    () async {
      final body = await stream();
      var received = 0;
      final done = Completer<void>();
      late StreamSubscription<List<int>> sub;
      sub = body.stream.listen(
        (data) => received += data.length,
        onError: done.completeError,
        onDone: done.complete,
      );
      sub.pause(); // Player pausiert
      await Future<void>.delayed(const Duration(milliseconds: 700));
      sub.resume();
      await done.future;
      expect(received, 256 * chunk);
    },
  );

  test('CancelToken beendet den Transfer vom Server', () async {
    final cancel = CancelToken();
    final body = await stream(cancel: cancel);
    final first = Completer<void>();
    body.stream.listen((_) {
      if (!first.isCompleted) first.complete();
    }, onError: (_) {});
    await first.future;
    cancel.cancel();
    for (var i = 0; i < 50 && !upstreamDone; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(upstreamDone, isTrue);
    expect(produced, lessThan(256));
  });

  test('heruntergeladene JSON-Datei ist kein API-Fehler', () async {
    final file = utf8.encode('{"name": "config", "success": "ja"}');
    download = (type: 'application/json', body: file);
    final body = await stream();
    expect(await body.stream.expand((c) => c).toList(), file);
  });

  test('echter DSM-Fehler als JSON wird zur SynoException', () async {
    download = (
      type: 'application/json; charset=utf-8',
      body: utf8.encode('{"success": false, "error": {"code": 119}}'),
    );
    await expectLater(stream(), throwsA(isA<SynoSessionExpired>()));
  });
}
