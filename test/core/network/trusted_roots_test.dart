import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/core/network/trusted_roots.dart';

String _fingerprint(String pem) => sha256
    .convert(
      base64.decode(
        pem
            .split('\n')
            .where((l) => l.isNotEmpty && !l.startsWith('-----'))
            .join(),
      ),
    )
    .bytes
    .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    .join(':');

void main() {
  test('gebündelte Root ist die offizielle ISRG Root X2', () {
    expect(
      _fingerprint(bundledRootsPem.single),
      '69:72:9B:8E:15:A8:6E:FC:17:7A:57:AF:B7:17:1D:FC:'
      '64:AD:D2:8C:2F:CA:8C:F1:50:7E:34:45:3C:CB:14:70',
    );
    // Auch dort, wo das System X2 schon kennt, darf das Hinzufügen nicht werfen.
    expect(trustedSecurityContext, returnsNormally);
  });

  group('zusätzliche Roots', () {
    late HttpServer server;

    setUp(() async {
      server = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv4,
        0,
        SecurityContext()
          ..useCertificateChain('test/fixtures/tls/extra-root.crt')
          ..usePrivateKey('test/fixtures/tls/extra-root.key'),
      );
      server.listen(
        (req) => req.response
          ..write('ok')
          ..close(),
      );
    });
    tearDown(() => server.close(force: true));

    Future<String> get(SecurityContext context) async {
      final client = HttpClient(context: context);
      addTearDown(client.close);
      final req = await client.getUrl(
        Uri.parse('https://127.0.0.1:${server.port}/'),
      );
      return (await req.close()).transform(utf8.decoder).join();
    }

    test('ohne die Root schlägt die normale Prüfung fehl', () {
      expect(
        get(trustedSecurityContext(extraRootsPem: const [])),
        throwsA(isA<HandshakeException>()),
      );
    });

    test('mit der Root besteht sie – ohne badCertificateCallback', () async {
      final pem = File('test/fixtures/tls/extra-root.crt').readAsStringSync();
      expect(await get(trustedSecurityContext(extraRootsPem: [pem])), 'ok');
    });
  });
}
