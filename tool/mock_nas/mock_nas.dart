import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

/// Bedient `/webapi/entry.cgi` (GET-Query oder POST-Formular) mit
/// `<fixtures>/<api>/<method>.json`. Unbekannte API/Methode liefern die
/// Synology-Fehlercodes 102/103 – wie DSM mit HTTP 200.
Handler mockNasHandler(Directory fixtures) {
  return (Request request) async {
    if (request.url.path != 'webapi/entry.cgi') {
      return Response.notFound('not found');
    }
    final params = {...request.url.queryParameters};
    if (request.method == 'POST') {
      params.addAll(Uri.splitQueryString(await request.readAsString()));
    }
    final api = params['api'] ?? '';
    final method = params['method'] ?? '';
    final apiDir = Directory('${fixtures.path}/$api');
    final file = File('${apiDir.path}/$method.json');
    // Pfadbestandteile aus der Anfrage dürfen nicht aus fixtures/ herausführen.
    final safe = !'$api/$method'.contains('..') && !api.contains('/');
    if (safe && await file.exists()) {
      return _json(await file.readAsString());
    }
    final code = safe && await apiDir.exists() ? 103 : 102;
    return _json(
      jsonEncode({
        'success': false,
        'error': {'code': code},
      }),
    );
  };
}

Response _json(String body) =>
    Response.ok(body, headers: {'content-type': 'application/json'});
