import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

import '../../tool/mock_nas/mock_nas.dart';

/// Mock-NAS auf einem freien Loopback-Port; merkt sich alle Parameter
/// (Query, Formular bzw. Multipart-Felder – bei Dateien der Dateiname –,
/// bei Range-Anfragen auch `range`) jeder Anfrage.
class MockNasServer {
  MockNasServer._(this._server, this.requests, this.control);

  static Future<MockNasServer> start() async {
    final requests = <Map<String, String>>[];
    final control = MockNasControl();
    final handler = mockNasHandler(
      Directory('test/fixtures'),
      control: control,
    );
    late final MockNasServer nas;
    final server = await io.serve(
      (Request request) async {
        final body = await request.read().expand((c) => c).toList();
        final type = request.headers['content-type'] ?? '';
        final multipart = type.startsWith('multipart/');
        final params = {
          ...request.url.queryParameters,
          if (multipart) ...parseMultipart(type, body),
          if (body.isNotEmpty && !multipart)
            ...Uri.splitQueryString(utf8.decode(body)),
          'range': ?request.headers['range'],
        };
        requests.add(params);
        return nas.intercept?.call(params) ??
            handler(request.change(body: body));
      },
      InternetAddress.loopbackIPv4,
      0,
    );
    return nas = MockNasServer._(server, requests, control);
  }

  final HttpServer _server;
  final List<Map<String, String>> requests;

  /// Fehlerfälle und Download-Inhalte des Mock-NAS.
  final MockNasControl control;

  /// Antwortet statt des Mock-NAS, wenn es nicht `null` liefert (z. B. ein
  /// eigenes Ordner-Listing für einen Test).
  Response? Function(Map<String, String> params)? intercept;

  String get url => 'http://127.0.0.1:${_server.port}';

  Iterable<Map<String, String>> calls(String api, String method) =>
      requests.where((r) => r['api'] == api && r['method'] == method);

  Future<void> close() => _server.close(force: true);
}
