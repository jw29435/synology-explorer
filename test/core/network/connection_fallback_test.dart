import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:nuvo_explorer/core/network/certificate_pinning.dart';
import 'package:nuvo_explorer/core/network/syno_api_client.dart';
import 'package:nuvo_explorer/core/network/syno_exception.dart';
import 'package:nuvo_explorer/features/servers/domain/server_profile.dart';

import '../../helpers/mock_nas_server.dart';

void main() {
  late MockNasServer external;
  setUp(() async => external = await MockNasServer.start());
  tearDown(() => external.close());

  SynoApiClient client(String lanUrl, {bool withExternal = true}) =>
      SynoApiClient(
        ServerProfile(
          name: 'NAS',
          lanUrl: lanUrl,
          externalUrl: withExternal ? external.url : null,
          user: 'johann',
        ),
        CertificatePinStore(const FlutterSecureStorage()),
      );

  /// Port, auf dem garantiert niemand lauscht.
  Future<String> refusedUrl() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return 'http://127.0.0.1:$port';
  }

  test('LAN verweigert → extern, aktive Adresse als Stream', () async {
    final c = client(await refusedUrl());
    final active = c.activeUrlChanges.first;
    await c.connect();
    expect(c.activeUrl, Uri.parse(external.url));
    expect(await active, Uri.parse(external.url));
    expect(external.calls('SYNO.API.Info', 'query'), hasLength(1));
  });

  test('LAN antwortet nicht → nach 2 s extern', () async {
    // Nimmt Verbindungen an, sendet aber nie etwas.
    final silent = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final held = <Socket>[];
    silent.listen(held.add);
    addTearDown(() async {
      for (final s in held) {
        s.destroy();
      }
      await silent.close();
    });

    final watch = Stopwatch()..start();
    final c = client('http://127.0.0.1:${silent.port}');
    await c.connect();
    expect(c.activeUrl, Uri.parse(external.url));
    expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
  });

  Future<String> lanAnswering(Response response) async {
    final lan = await io.serve(
      (Request _) => response,
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(() => lan.close(force: true));
    return 'http://127.0.0.1:${lan.port}';
  }

  test('HTTP-Fehler im LAN → kein Fallback', () async {
    final c = client(await lanAnswering(Response.internalServerError()));
    await expectLater(
      c.connect(),
      throwsA(isA<SynoNetworkError>().having((e) => e.statusCode, 'http', 500)),
    );
    expect(external.requests, isEmpty);
    expect(c.activeUrl, isNull);
  });

  test('API-Fehler im LAN → kein Fallback', () async {
    final c = client(
      await lanAnswering(Response.ok('{"success":false,"error":{"code":100}}')),
    );
    await expectLater(c.connect(), throwsA(isA<SynoUnknown>()));
    expect(external.requests, isEmpty);
  });

  test('ohne externe Adresse → Netzwerkfehler', () async {
    final c = client(await refusedUrl(), withExternal: false);
    await expectLater(c.connect(), throwsA(isA<SynoNetworkError>()));
  });

  test('LAN erreichbar → LAN bleibt aktiv', () async {
    final lan = await MockNasServer.start();
    addTearDown(lan.close);
    final c = client(lan.url);
    await c.connect();
    expect(c.activeUrl, Uri.parse(lan.url));
    expect(external.requests, isEmpty);
  });
}
