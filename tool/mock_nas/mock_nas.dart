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
///
/// Für die E2E-Flows: Search als Task (Treffer aus `Search/list.json` nach
/// Muster gefiltert, Endungen ignoriert; mit [searchTotalLate] meldet das erste `list`
/// `finished` noch ohne `total`, wie DSM), `list` in [mockPhotoFolder] mit
/// Paging und Sortierung, `getinfo` mit einem Pfad übernimmt Name, Pfad und
/// Ordner-Art aus der Anfrage.
///
/// `list` auf `/music/#recycle` liefert `recycle/music.json`
/// (ohne Gelöschtes und Verschobenes), `/photo/#recycle` 407 (nur für
/// Administratoren), andere Papierkörbe 408. Fehlerfälle schaltet [control].
Handler mockNasHandler(
  Directory fixtures, {
  MockNasControl? control,
  bool searchTotalLate = false,
}) {
  final nas = control ?? MockNasControl();
  final sids = nas._sids;
  var logins = 0;
  final tasks = <String, int>{};
  var taskCount = 0;
  final uploaded = <String>{};
  final links = <Map<String, Object?>>[];
  var linkCount = 0;
  final searches = <String, ({String pattern, int polls})>{};
  // Aus dem Papierkorb gelöscht oder verschoben (wiederhergestellt).
  final removed = <String>{};

  Future<String> read(String path) =>
      File('${fixtures.path}/$path').readAsString();

  Future<Response> login(Map<String, String> params) async {
    if (nas.rejectLogin ||
        params['account'] != mockUser ||
        params['passwd'] != mockPassword) {
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
    final denied = api == 'SYNO.FileStation.DirSize' ? null : nas.denyWrites;
    if (method == 'start') {
      if (denied == null &&
          (api == 'SYNO.FileStation.Delete' || p['remove_src'] == 'true')) {
        removed.addAll((jsonDecode(p['path'] ?? '[]') as List).cast());
      }
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
    // DSM 7.2.1: Fehler einzelner Pfade im erfolgreichen `status`.
    if (denied != null) {
      tasks.remove(id);
      return _ok({
        'finished': true,
        'status': 'FAIL',
        'errors': [
          {'code': denied, 'path': ''},
        ],
        'progress': 1,
      });
    }
    return _ok({
      'finished': finished,
      'progress': finished ? 1 : 0.5,
      'path': '',
      'processing_path': '',
    });
  }

  Future<Response> search(String method, Map<String, String> p) async {
    if (method == 'start') {
      final id = 'mock-search-${++taskCount}';
      searches[id] = (pattern: (p['pattern'] ?? '').toLowerCase(), polls: 0);
      return _ok({'has_not_index_share': false, 'taskid': id});
    }
    final id = _taskId(p['taskid']);
    final task = searches[id];
    if (id == null || task == null) return _error(599);
    switch (method) {
      case 'stop':
        return _ok(null);
      case 'clean':
        searches.remove(id);
        return _ok(null);
      case 'list':
        searches[id] = (pattern: task.pattern, polls: task.polls + 1);
        final data = jsonDecode(
          await read('SYNO.FileStation.Search/list.json'),
        );
        final files = [
          for (final f in (data['data']['files'] as List).cast<Map>())
            if ((f['name'] as String).toLowerCase().contains(task.pattern)) f,
        ];
        return _ok({
          'files': files,
          'finished': true,
          'offset': 0,
          if (!searchTotalLate || task.polls > 0) 'total': files.length,
        });
    }
    return _error(103);
  }

  /// [mockPhotoCount] Bilder, per offset/limit (0 = alle) und Richtung;
  /// Name, Größe und Datum steigen mit der Nummer.
  Response photos(Map<String, String> p) {
    final offset = int.parse(p['offset'] ?? '0');
    final limit = int.parse(p['limit'] ?? '0');
    final numbers = [for (var n = 1; n <= mockPhotoCount; n++) n];
    final sorted = p['sort_direction'] == 'desc' ? numbers.reversed : numbers;
    return _ok({
      'files': [
        for (final n in sorted.skip(offset).take(limit > 0 ? limit : 1 << 30))
          {
            'isdir': false,
            'name': mockPhotoName(n),
            'path': '$mockPhotoFolder/${mockPhotoName(n)}',
            'additional': {
              'size': 1000000 + n,
              'time': {'mtime': 1778580000 + n * 60},
              'type': 'JPG',
            },
          },
      ],
      'offset': offset,
      'total': mockPhotoCount,
    });
  }

  /// Favoriten wie DSM: `add` auf Vorhandenes → 800, `delete` auf Fehlendes
  /// → Erfolg; Dateien und fehlende Pfade gelten als `broken`.
  List<Map<String, Object?>>? favorites;
  Future<Response> favorite(String method, Map<String, String> p) async {
    favorites ??= [
      for (final f
          in (jsonDecode(
                    await read('SYNO.FileStation.Favorite/list.json'),
                  )['data']['favorites']
                  as List)
              .cast<Map<String, Object?>>())
        f,
    ];
    final list = favorites!;
    final path = p['path'] ?? '';
    switch (method) {
      case 'list':
        return _ok({'favorites': list, 'offset': 0, 'total': list.length});
      case 'add':
        if (list.any((f) => f['path'] == path)) {
          return _json(
            jsonEncode({
              'success': false,
              'error': {
                'code': 800,
                'errors': [
                  {'code': 800, 'name': p['name'], 'path': path},
                ],
              },
            }),
          );
        }
        final dir = !path.split('/').last.contains('.');
        list.add({
          'isdir': dir,
          'name': p['name'] ?? path.split('/').last,
          'path': path,
          'status': dir ? 'valid' : 'broken',
        });
        return _ok(null);
      case 'delete':
        list.removeWhere((f) => f['path'] == path);
        return _ok(null);
    }
    return _error(103);
  }

  nas._favoriteAdd = (path, name) =>
      favorite('add', {'path': path, 'name': name});

  Response sharing(String method, Map<String, String> p, Uri url) {
    switch (method) {
      case 'create':
        if (nas.denyWrites case final code?) return _error(code);
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
    final path = p['path'] ?? '';
    switch (nas.downloadErrors[path]) {
      case 502:
        return Response(
          502,
          body: '<html><body>502 Bad Gateway</body></html>',
          headers: {'content-type': 'text/html'},
        );
      case final int code:
        return _error(code);
    }
    final data = nas.files[path] ?? mockFileBytes();
    final start = int.tryParse(
      RegExp(r'bytes=(\d+)-').firstMatch(range ?? '')?.group(1) ?? '',
    );
    if (start != null && start >= data.length) {
      return Response(
        416,
        headers: {'content-range': 'bytes */${data.length}'},
      );
    }
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

  Future<Response> recycle(String folder) async {
    switch (_shareOf(folder)) {
      case '/music':
        final data =
            jsonDecode(await read('recycle/music.json'))['data'] as Map;
        final files = [
          for (final f in data['files'] as List)
            if (_parentOf(f['path'] as String) == folder &&
                !removed.contains(f['path']))
              f,
        ];
        return _ok({'files': files, 'offset': 0, 'total': files.length});
      case '/photo':
        return _error(407);
    }
    return _error(408);
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

    final photoList =
        api == 'SYNO.FileStation.List' &&
        method == 'list' &&
        params['folder_path'] == mockPhotoFolder;
    if (api == 'SYNO.FileStation.Search' || photoList) {
      if (!sids.contains(params['_sid'])) {
        return _json(await read('errors/119.json'));
      }
      return photoList ? photos(params) : search(method, params);
    }

    const stateful = {
      'SYNO.FileStation.CopyMove',
      'SYNO.FileStation.Delete',
      'SYNO.FileStation.DirSize',
      'SYNO.FileStation.Upload',
      'SYNO.FileStation.Sharing',
      'SYNO.FileStation.Download',
      'SYNO.FileStation.Favorite',
    };
    final paths = api == 'SYNO.FileStation.List' && method == 'getinfo'
        ? (jsonDecode(params['path'] ?? '[]') as List).cast<String>()
        : const <String>[];
    if (stateful.contains(api) || paths.length > 1) {
      if (!sids.contains(params['_sid'])) {
        return _json(await read('errors/119.json'));
      }
      switch (api) {
        case 'SYNO.FileStation.Favorite':
          if (nas.denyFavorites case final code?) return _error(code);
          return favorite(method, params);
        case 'SYNO.FileStation.Upload':
          if (nas.denyWrites case final code?) return _error(code);
          final parts = parseMultipart(type, body);
          final name = parts['file'];
          if (name == null) return _error(401);
          final target = '${parts['path']}/$name';
          // Wie DSM: vorhanden + overwrite=false → still überspringen,
          // ohne overwrite → Fehler 414, overwrite=true → ersetzen.
          if (uploaded.contains(target)) {
            switch (parts['overwrite']) {
              case 'false':
                return _ok({'blSkip': true, 'file': name});
              case null:
                return _error(414);
            }
          }
          uploaded.add(target);
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

    if (api == 'SYNO.FileStation.List' && method == 'list') {
      final folder = params['folder_path'] ?? '';
      if (folder.contains('/#recycle')) {
        if (!sids.contains(params['_sid'])) {
          return _json(await read('errors/119.json'));
        }
        return recycle(folder);
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
    if (api == 'SYNO.FileStation.List' && method == 'getinfo') {
      final path =
          (jsonDecode(params['path'] ?? '[]') as List).single as String;
      // Wie DSM: fehlende Datei (Download → 502) meldet getinfo als 408.
      if (nas.downloadErrors[path] == 502) {
        return _ok({
          'files': [
            {'code': 408, 'path': path},
          ],
        });
      }
      final info = jsonDecode(await file.readAsString());
      final name = path.split('/').last;
      info['data']['files'][0]
        ..['path'] = path
        ..['name'] = name
        ..['isdir'] = !name.contains('.');
      return _json(jsonEncode(info));
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

/// Schalter für Fehlerfälle und Testdaten des Mock-NAS (E2E-Tests).
class MockNasControl {
  final _sids = <String>{};

  /// Alle Logins scheitern mit 400 (z. B. Passwort auf dem NAS geändert).
  bool rejectLogin = false;

  /// Fehlercode für schreibende Aktionen (Upload, CopyMove, Delete,
  /// Sharing create), z. B. 407 wie beim Testkonto ohne Schreibrecht.
  /// CopyMove/Delete melden ihn wie DSM 7.2.1 im `status` (`FAIL`,
  /// `errors[0].code`), die anderen als Fehler der Anfrage.
  int? denyWrites;

  /// Download-Inhalt je NAS-Pfad (sonst [mockFileBytes]).
  final files = <String, List<int>>{};

  /// Download-Fehler je NAS-Pfad: 502 = HTTP 502 mit HTML-Seite (DSM bei
  /// fehlender Datei), sonst dieser DSM-Fehlercode als JSON.
  final downloadErrors = <String, int>{};

  /// Fehlercode für alle `SYNO.FileStation.Favorite`-Aufrufe (z. B. 105).
  int? denyFavorites;

  /// Legt einen Favoriten an wie DS File auf einem anderen Gerät.
  Future<void> favoritesAdd(String path, String name) async =>
      _favoriteAdd?.call(path, name);
  Future<void> Function(String path, String name)? _favoriteAdd;

  /// Macht alle SIDs ungültig (Session abgelaufen → 119).
  void expireSessions() => _sids.clear();
}

String _shareOf(String path) => '/${path.split('/')[1]}';

String _parentOf(String path) => path.substring(0, path.lastIndexOf('/'));

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

/// Share, dessen `list` [mockPhotoCount] Bilder mit Paging liefert.
const mockPhotoFolder = '/photo';
const mockPhotoCount = 520;

/// `IMG_0001.jpg` … für Bild [n] in [mockPhotoFolder].
String mockPhotoName(int n) => 'IMG_${'$n'.padLeft(4, '0')}.jpg';

/// Größe der Testdatei, die `Download` für jeden Pfad liefert.
const mockFileSize = 256 * 1024;

/// Deterministischer Inhalt der Testdatei (Byte i = i mod 251).
List<int> mockFileBytes() => [for (var i = 0; i < mockFileSize; i++) i % 251];

/// Minimaler Multipart-Parser: Textfelder als Wert, Dateifelder als
/// Dateiname. Auch für die Test-Hilfe, die Anfragen mitschreibt.
Map<String, String> parseMultipart(String contentType, List<int> body) {
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
