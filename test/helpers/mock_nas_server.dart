import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

import '../../tool/mock_nas/mock_nas.dart';

/// Mock-NAS auf einem freien Loopback-Port; merkt sich alle Parameter
/// (Query + Formular) jeder Anfrage.
class MockNasServer {
  MockNasServer._(this._server, this.requests);

  static Future<MockNasServer> start() async {
    final requests = <Map<String, String>>[];
    final handler = mockNasHandler(Directory('test/fixtures'));
    final server = await io.serve(
      (Request request) async {
        final body = await request.readAsString();
        requests.add({
          ...request.url.queryParameters,
          if (body.isNotEmpty) ...Uri.splitQueryString(body),
        });
        return handler(request.change(body: body));
      },
      InternetAddress.loopbackIPv4,
      0,
    );
    return MockNasServer._(server, requests);
  }

  final HttpServer _server;
  final List<Map<String, String>> requests;

  String get url => 'http://127.0.0.1:${_server.port}';

  Iterable<Map<String, String>> calls(String api, String method) =>
      requests.where((r) => r['api'] == api && r['method'] == method);

  Future<void> close() => _server.close(force: true);
}
