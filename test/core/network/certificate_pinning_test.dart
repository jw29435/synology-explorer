import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/core/network/certificate_pinning.dart';
import 'package:nuvo_explorer/core/network/syno_api_client.dart';
import 'package:nuvo_explorer/features/servers/domain/server_profile.dart';

import '../../helpers/mock_nas_server.dart';

/// HTTPS-Server mit selbstsigniertem Test-Zertifikat, der nur API.Info kennt.
Future<HttpServer> startTls(String cert) async {
  final context = SecurityContext()
    ..useCertificateChain('test/fixtures/tls/$cert.crt')
    ..usePrivateKey('test/fixtures/tls/$cert.key');
  final server = await HttpServer.bindSecure(
    InternetAddress.loopbackIPv4,
    0,
    context,
  );
  final info = await File('test/fixtures/SYNO.API.Info/query.json')
      .readAsString();
  server.listen(
    (req) => req.response
      ..write(info)
      ..close(),
  );
  return server;
}

/// Unabhängig vom Code unter Test: SHA-256 über das DER aus der PEM-Datei.
String fingerprintOf(String cert) {
  final pem = File('test/fixtures/tls/$cert.crt').readAsStringSync();
  final b64 = pem.split('\n').where((l) => !l.startsWith('-----')).join();
  return sha256
      .convert(base64.decode(b64))
      .bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(':');
}

void main() {
  late Map<String, String> secure;
  late CertificatePinStore pins;
  late HttpServer server;

  setUp(() async {
    secure = {};
    FlutterSecureStorage.setMockInitialValues(secure);
    pins = CertificatePinStore(const FlutterSecureStorage());
    await pins.load();
    server = await startTls('nas-a');
  });
  tearDown(() => server.close(force: true));

  SynoApiClient client({String? externalUrl}) => SynoApiClient(
    ServerProfile(
      name: 'NAS',
      lanUrl: 'https://127.0.0.1:${server.port}',
      externalUrl: externalUrl,
      user: 'johann',
    ),
    pins,
  );

  test('unbekanntes Zertifikat → UntrustedCertificateException', () async {
    final e = await client().connect().then<Object?>(
      (_) => null,
      onError: (Object e) => e,
    );
    expect(e, isA<UntrustedCertificateException>());
    e as UntrustedCertificateException;
    expect(e.host, '127.0.0.1');
    expect(e.port, server.port);
    expect(e.issuer, contains('Test nas-a'));
    expect(e.validTo.isAfter(e.validFrom), isTrue);
    expect(e.fingerprint, fingerprintOf('nas-a'));
    expect(secure, isEmpty, reason: 'nichts ohne Bestätigung pinnen');
  });

  test('nach Bestätigung gepinnt und persistiert', () async {
    await pins.pin('127.0.0.1', server.port, fingerprintOf('nas-a'));
    final c = client();
    await c.connect();
    expect(c.activeUrl?.scheme, 'https');

    // Neuer Store liest den Pin aus dem Secure Storage.
    final reloaded = CertificatePinStore(const FlutterSecureStorage());
    await reloaded.load();
    expect(reloaded.pinFor('127.0.0.1', server.port), fingerprintOf('nas-a'));
  });

  test('abweichender Fingerprint → harter Fehler', () async {
    await pins.pin('127.0.0.1', server.port, fingerprintOf('nas-b'));
    await expectLater(
      client().connect(),
      throwsA(
        isA<CertificateMismatchException>().having(
          (e) => e.fingerprint,
          'fingerprint',
          fingerprintOf('nas-a'),
        ),
      ),
    );
    expect(pins.pinFor('127.0.0.1', server.port), fingerprintOf('nas-b'));
  });

  test('Zertifikatsfehler im LAN → kein Fallback auf extern', () async {
    final external = await MockNasServer.start();
    addTearDown(external.close);
    await expectLater(
      client(externalUrl: external.url).connect(),
      throwsA(isA<UntrustedCertificateException>()),
    );
    expect(external.requests, isEmpty);
  });
}
