import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nuvo_explorer/core/network/media_proxy.dart';
import 'package:nuvo_explorer/core/network/syno_api_client.dart';
import 'package:nuvo_explorer/core/network/syno_exception.dart';

class _MockClient extends Mock implements SynoApiClient {}

void main() {
  late _MockClient client;
  late MediaProxy proxy;
  late HttpClient http;
  final data = Uint8List.fromList(List.generate(100, (i) => i));

  setUpAll(() => registerFallbackValue(CancelToken()));

  setUp(() async {
    client = _MockClient();
    // Wie DSM: auf Range antwortet der Download mit 206 + Content-Range.
    when(
      () => client.requestStream(
        any(),
        any(),
        any(),
        start: any(named: 'start'),
        end: any(named: 'end'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((call) async {
      final start = call.namedArguments[#start] as int;
      final end = (call.namedArguments[#end] as int?) ?? data.length;
      return ResponseBody(
        Stream.value(data.sublist(start, end)),
        206,
        headers: {
          'content-type': ['video/mp4'],
          'content-length': ['${end - start}'],
          'content-range': ['bytes $start-${end - 1}/${data.length}'],
        },
      );
    });
    proxy = await MediaProxy.start(client, '/video/Drohne 01.mp4');
    http = HttpClient();
    addTearDown(() async {
      http.close(force: true);
      await proxy.close();
    });
  });

  Future<(HttpClientResponse, List<int>)> get(Uri url, {String? range}) async {
    final request = await http.getUrl(url);
    if (range != null) request.headers.set(HttpHeaders.rangeHeader, range);
    final response = await request.close();
    final body = await response.expand((c) => c).toList();
    return (response, body);
  }

  test('lauscht nur auf Loopback, URL ohne SID mit zufälligem Token', () async {
    expect(proxy.address, InternetAddress.loopbackIPv4);
    expect(proxy.url.host, '127.0.0.1');
    expect(proxy.url.toString(), isNot(contains('sid')));
    expect(proxy.url.pathSegments.first.length, greaterThanOrEqualTo(40));
    final other = await MediaProxy.start(client, '/video/x.mp4');
    addTearDown(other.close);
    expect(other.url.pathSegments.first, isNot(proxy.url.pathSegments.first));
  });

  test('Range wird weitergereicht: 206 mit Content-Range', () async {
    final (res, body) = await get(proxy.url, range: 'bytes=10-19');
    expect(res.statusCode, 206);
    expect(res.headers.value('content-range'), 'bytes 10-19/100');
    expect(res.headers.value('accept-ranges'), 'bytes');
    expect(res.headers.contentType?.mimeType, 'video/mp4');
    expect(body, data.sublist(10, 20));
    verify(
      () => client.requestStream(
        'SYNO.FileStation.Download',
        'download',
        {'path': '/video/Drohne 01.mp4', 'mode': 'open'},
        start: 10,
        end: 20,
        cancelToken: any(named: 'cancelToken'),
      ),
    ).called(1);

    final (open, rest) = await get(proxy.url, range: 'bytes=90-');
    expect(open.statusCode, 206);
    expect(open.headers.value('content-range'), 'bytes 90-99/100');
    expect(rest, data.sublist(90));
  });

  test('ohne Range: ganze Datei als 200', () async {
    final (res, body) = await get(proxy.url);
    expect(res.statusCode, 200);
    expect(res.headers.contentLength, 100);
    expect(body, data);
  });

  test(
    'allow=false (Streaming nur im WLAN) → 403, ohne das NAS zu fragen',
    () async {
      var allowed = false;
      final gated = await MediaProxy.start(
        client,
        '/music/a.mp3',
        allow: () async => allowed,
      );
      addTearDown(gated.close);
      final (res, _) = await get(gated.url, range: 'bytes=0-');
      expect(res.statusCode, 403);
      verifyNever(
        () => client.requestStream(
          any(),
          any(),
          any(),
          start: any(named: 'start'),
          end: any(named: 'end'),
          cancelToken: any(named: 'cancelToken'),
        ),
      );
      allowed = true;
      final (ok, body) = await get(gated.url, range: 'bytes=0-9');
      expect(ok.statusCode, 206);
      expect(body, data.sublist(0, 10));
    },
  );

  test('falsches Token → 403, ohne das NAS zu fragen', () async {
    final wrong = proxy.url.replace(
      pathSegments: [base64Url.encode(List.filled(32, 7)), 'x.mp4'],
    );
    final (res, _) = await get(wrong);
    expect(res.statusCode, 403);
    final (root, _) = await get(proxy.url.replace(path: '/'));
    expect(root.statusCode, 403);
    verifyNever(
      () => client.requestStream(
        any(),
        any(),
        any(),
        start: any(named: 'start'),
        end: any(named: 'end'),
        cancelToken: any(named: 'cancelToken'),
      ),
    );
  });

  test('Fehler vom NAS werden zu HTTP-Status', () async {
    when(
      () => client.requestStream(
        any(),
        any(),
        any(),
        start: any(named: 'start'),
        end: any(named: 'end'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenThrow(const SynoSessionExpired(119));
    final (res, _) = await get(proxy.url, range: 'bytes=0-');
    expect(res.statusCode, 502);
    // Der Player unterscheidet darüber Session, Netz und Rechte (E2E-027).
    expect(proxy.lastError, isA<SynoSessionExpired>());

    // Klappt die nächste Anfrage, ist der Fehler vorbei (E2E-028).
    when(
      () => client.requestStream(
        any(),
        any(),
        any(),
        start: any(named: 'start'),
        end: any(named: 'end'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) async => ResponseBody(Stream.value(data), 200));
    await get(proxy.url);
    expect(proxy.lastError, isNull);
  });

  test('Backpressure: langsamer Client zieht nicht die ganze Datei, '
      'Abbruch beendet den Upstream', () async {
    const chunk = 64 * 1024;
    const chunks = 1024; // 64 MB
    var produced = 0;
    var upstreamClosed = false;
    Stream<Uint8List> source() async* {
      try {
        for (var i = 0; i < chunks; i++) {
          produced++;
          yield Uint8List(chunk);
        }
      } finally {
        upstreamClosed = true;
      }
    }

    when(
      () => client.requestStream(
        any(),
        any(),
        any(),
        start: any(named: 'start'),
        end: any(named: 'end'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer(
      (_) async => ResponseBody(
        source(),
        206,
        headers: {
          'content-length': ['${chunk * chunks}'],
          'content-range': ['bytes 0-${chunk * chunks - 1}/${chunk * chunks}'],
        },
      ),
    );
    final request = await http.getUrl(proxy.url);
    request.headers.set(HttpHeaders.rangeHeader, 'bytes=0-');
    final response = await request.close();
    final firstChunk = Completer<void>();
    final sub = response.listen((_) {
      if (!firstChunk.isCompleted) firstChunk.complete();
    });
    await firstChunk.future;
    sub.pause(); // Player pausiert
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final whilePaused = produced;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    // Nach dem Füllen der Socket-Puffer liest der Proxy nicht weiter.
    expect(produced, whilePaused);
    expect(produced, lessThan(chunks ~/ 2));
    expect(upstreamClosed, isFalse);

    await sub.cancel();
    http.close(force: true); // Player trennt die Verbindung
    for (var i = 0; i < 50 && !upstreamClosed; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(upstreamClosed, isTrue);
    expect(produced, lessThan(chunks));
  });

  test('Upstream wird nach jeder Antwort und bei HEAD abgebrochen', () async {
    CancelToken token() =>
        verify(
              () => client.requestStream(
                any(),
                any(),
                any(),
                start: any(named: 'start'),
                end: any(named: 'end'),
                cancelToken: captureAny(named: 'cancelToken'),
              ),
            ).captured.last
            as CancelToken;

    await get(proxy.url, range: 'bytes=0-9');
    expect(token().isCancelled, isTrue);

    final head = await (await http.headUrl(proxy.url)).close();
    await head.drain<void>();
    expect(head.statusCode, 200);
    expect(head.headers.contentLength, 100);
    expect(token().isCancelled, isTrue);
  });
}
