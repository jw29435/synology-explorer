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
///
/// Mit Zustand statt Fixture (M4): CopyMove/Delete/DirSize als Tasks, die
/// beim zweiten `status` fertig sind; Upload (Multipart, merkt sich Pfade,
/// die `getinfo` mit mehreren Pfaden dann kennt); Sharing create/list/delete;
/// Download mit HTTP-Range über [mockFileSize] Byte Testdaten.
Handler mockNasHandler(Directory fixtures) {
  final sids = <String>{};
  var logins = 0;
  final tasks = <String, int>{};
  var taskCount = 0;
  final uploaded = <String>{};
  final links = <Map<String, Object?>>[];
  var linkCount = 0;

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

  /// Asynchroner Task: `status` meldet erst 50 %, beim zweiten Mal fertig.
  Future<Response> task(
    String api,
    String method,
    Map<String, String> p,
  ) async {
    final kind = api.split('.').last.toLowerCase();
    if (method == 'start') {
      final id = 'mock-$kind-${++taskCount}';
      tasks[id] = 0;
      return _ok({'taskid': id});
    }
    final id = _taskId(p['taskid']);
    final polls = tasks[id];
    if (id == null || polls == null) return _error(599);
    if (method == 'stop') {
      tasks.remove(id);
      return _ok(null);
    }
    final finished = polls >= 1;
    tasks[id] = polls + 1;
    if (finished) tasks.remove(id);
    if (api == 'SYNO.FileStation.DirSize') {
      final done = jsonDecode(await read('$api/status.json'))['data'] as Map;
      return _ok({
        ...done,
        'finished': finished,
        if (!finished) 'total_size': (done['total_size'] as int) ~/ 2,
      });
    }
    return _ok({
      'finished': finished,
      'progress': finished ? 1 : 0.5,
      'path': '',
      'processing_path': '',
    });
  }

  Response sharing(String method, Map<String, String> p, Uri url) {
    switch (method) {
      case 'create':
        final created = [
          for (final path in (jsonDecode(p['path']!) as List).cast<String>())
            {
              'id': 'mockLink${++linkCount}',
              'url': '${url.origin}/sharing/mockLink$linkCount',
              'name': path.substring(path.lastIndexOf('/') + 1),
              'path': path,
              'isFolder': !path.split('/').last.contains('.'),
              'has_password': (p['password'] ?? '').isNotEmpty,
              'date_expired': p['date_expired'] ?? '',
              'status': 'valid',
            },
        ];
        links.addAll(created);
        return _ok({'links': created});
      case 'list':
        return _ok({'links': links, 'offset': 0, 'total': links.length});
      case 'delete':
        final ids = (jsonDecode(p['id']!) as List).toSet();
        links.removeWhere((l) => ids.contains(l['id']));
        return _ok(null);
    }
    return _error(103);
  }

  Response download(Map<String, String> p, String? range) {
    final data = mockFileBytes();
    final start = int.tryParse(
      RegExp(r'bytes=(\d+)-').firstMatch(range ?? '')?.group(1) ?? '',
    );
    if (start == null) {
      return Response.ok(
        data,
        headers: {'content-type': 'application/octet-stream'},
      );
    }
    return Response(
      206,
      body: data.sublist(start),
      headers: {
        'content-type': 'application/octet-stream',
        'content-range': 'bytes $start-${data.length - 1}/${data.length}',
      },
    );
  }

  return (Request request) async {
    if (request.url.path != 'webapi/entry.cgi') {
      return Response.notFound('not found');
    }
    final params = {...request.url.queryParameters};
    final type = request.headers['content-type'] ?? '';
    List<int> body = const [];
    if (request.method == 'POST') {
      body = await request.read().expand((c) => c).toList();
      if (!type.startsWith('multipart/')) {
        params.addAll(Uri.splitQueryString(utf8.decode(body)));
      }
    }
    final api = params['api'] ?? '';
    final method = params['method'] ?? '';
    if (api == 'SYNO.API.Auth' && method == 'login') return login(params);

    const stateful = {
      'SYNO.FileStation.CopyMove',
      'SYNO.FileStation.Delete',
      'SYNO.FileStation.DirSize',
      'SYNO.FileStation.Upload',
      'SYNO.FileStation.Sharing',
      'SYNO.FileStation.Download',
    };
    final paths = api == 'SYNO.FileStation.List' && method == 'getinfo'
        ? (jsonDecode(params['path'] ?? '[]') as List).cast<String>()
        : const <String>[];
    if (stateful.contains(api) || paths.length > 1) {
      if (!sids.contains(params['_sid'])) {
        return _json(await read('errors/119.json'));
      }
      switch (api) {
        case 'SYNO.FileStation.Upload':
          final parts = _multipart(type, body);
          final name = parts['file'];
          if (name == null) return _error(401);
          uploaded.add('${parts['path']}/$name');
          return _ok({'blSkip': false, 'file': name, 'pid': 1, 'progress': 1});
        case 'SYNO.FileStation.Sharing':
          return sharing(method, params, request.requestedUri);
        case 'SYNO.FileStation.Download':
          return download(params, request.headers['range']);
        case 'SYNO.FileStation.List':
          // Mehrere Pfade (freier Name beim Upload): nur Hochgeladenes gibt es.
          return _ok({
            'files': [
              for (final path in paths)
                uploaded.contains(path)
                    ? {
                        'isdir': false,
                        'name': path.split('/').last,
                        'path': path,
                      }
                    : {'code': 408, 'path': path},
            ],
          });
        default:
          return task(api, method, params);
      }
    }

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

Response _ok(Object? data) =>
    _json(jsonEncode({'success': true, 'data': ?data}));

Response _error(int code) => _json(
  jsonEncode({
    'success': false,
    'error': {'code': code},
  }),
);

/// Task-IDs kommen JSON-kodiert (`"id"`), wie DSM 7.2 sie braucht.
String? _taskId(String? raw) =>
    raw != null && raw.startsWith('"') ? jsonDecode(raw) as String : null;

/// Größe der Testdatei, die `Download` für jeden Pfad liefert.
const mockFileSize = 256 * 1024;

/// Deterministischer Inhalt der Testdatei (Byte i = i mod 251).
List<int> mockFileBytes() => [for (var i = 0; i < mockFileSize; i++) i % 251];

/// Minimaler Multipart-Parser: Textfelder als Wert, Dateifelder als
/// Dateiname.
Map<String, String> _multipart(String contentType, List<int> body) {
  final boundary = RegExp(r'boundary=(.+)$').firstMatch(contentType)?.group(1);
  if (boundary == null) return const {};
  final result = <String, String>{};
  for (final part in latin1.decode(body).split('--$boundary')) {
    final split = part.indexOf('\r\n\r\n');
    if (split < 0) continue;
    final head = part.substring(0, split);
    final name = RegExp(r'name="([^"]*)"').firstMatch(head)?.group(1);
    if (name == null) continue;
    final filename = RegExp(r'filename="([^"]*)"').firstMatch(head)?.group(1);
    result[name] =
        filename ??
        utf8.decode(latin1.encode(part.substring(split + 4).trimRight()));
  }
  return result;
}
