import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

/// Mock-Konto mit aktiver 2FA.
const mockUser = 'johann';
const mockPassword = 'geheim';
const mockOtp = '123456';

/// Bedient `/webapi/entry.cgi` (GET-Query oder POST-Formular) mit
/// `<fixtures>/<api>/<method>.json` bzw. binär mit `<method>.jpg`
/// (z. B. `SYNO.FileStation.Thumb/get.jpg`). Unbekannte API/Methode liefern die
/// Synology-Fehlercodes 102/103 – wie DSM mit HTTP 200.
///
/// `SYNO.API.Auth login` prüft Passwort, OTP und Geräte-Token (`device_id`)
/// und vergibt je Login eine neue SID; `logout` macht sie ungültig. Alle
/// anderen APIs außer `SYNO.API.Info` brauchen eine gültige `_sid`, sonst 119.
Handler mockNasHandler(Directory fixtures) {
  final sids = <String>{};
  var logins = 0;

  Future<String> read(String path) =>
      File('${fixtures.path}/$path').readAsString();

  Future<Response> login(Map<String, String> params) async {
    if (params['account'] != mockUser || params['passwd'] != mockPassword) {
      return _json(await read('SYNO.API.Auth/login.400.json'));
    }
    final ok = jsonDecode(await read('SYNO.API.Auth/login.json'));
    if (params['device_id'] != ok['data']['device_id']) {
      final otp = params['otp_code'] ?? '';
      if (otp.isEmpty) return _json(await read('SYNO.API.Auth/login.403.json'));
      if (otp != mockOtp) {
        return _json(await read('SYNO.API.Auth/login.404.json'));
      }
    }
    final sid = 'mock-sid-${++logins}';
    sids.add(sid);
    ok['data']['sid'] = sid;
    return _json(jsonEncode(ok));
  }

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
    if (api == 'SYNO.API.Auth' && method == 'login') return login(params);

    final apiDir = Directory('${fixtures.path}/$api');
    final json = File('${apiDir.path}/$method.json');
    final jpg = File('${apiDir.path}/$method.jpg');
    // Pfadbestandteile aus der Anfrage dürfen nicht aus fixtures/ herausführen.
    final safe = !'$api/$method'.contains('..') && !api.contains('/');
    final file = !safe
        ? null
        : await json.exists()
        ? json
        : await jpg.exists()
        ? jpg
        : null;
    if (file == null) {
      final code = safe && await apiDir.exists() ? 103 : 102;
      return _json(
        jsonEncode({
          'success': false,
          'error': {'code': code},
        }),
      );
    }
    if (api != 'SYNO.API.Info' && !sids.contains(params['_sid'])) {
      return _json(await read('errors/119.json'));
    }
    if (api == 'SYNO.API.Auth' && method == 'logout') {
      sids.remove(params['_sid']);
    }
    if (file == jpg) {
      return Response.ok(
        await file.readAsBytes(),
        headers: {'content-type': 'image/jpeg'},
      );
    }
    return _json(await file.readAsString());
  };
}

Response _json(String body) =>
    Response.ok(body, headers: {'content-type': 'application/json'});
