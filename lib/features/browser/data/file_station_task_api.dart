import 'dart:convert';

import '../../../core/network/syno_api_client.dart';
import '../domain/nas_entry.dart';

/// Stand eines Search-Tasks. Fertig ist er erst mit `finished` **und**
/// `total` (siehe docs/SPIKE.md).
typedef SearchPage = ({List<NasEntry> entries, int? total, bool finished});

typedef DirSize = ({bool finished, int files, int dirs, int bytes});

// Task-IDs müssen JSON-kodiert (in Anführungszeichen) gesendet werden. Roh
// findet DSM 7.2 den Task nur manchmal – Search meldet dann ewig
// `finished: true` ohne `total`, DirSize Fehler 599.
String _task(String id) => jsonEncode(id);

/// `SYNO.FileStation.Search`: asynchrone Namenssuche.
class FileStationSearchApi {
  FileStationSearchApi(this._client);

  static const _api = 'SYNO.FileStation.Search';
  final SynoApiClient _client;

  /// Startet eine rekursive Suche in [folders]. [extensions] schränkt auf
  /// Dateiendungen ein (DSM kennt als `filetype` nur file/dir/all).
  Future<String> start(
    List<String> folders,
    String pattern, {
    List<String> extensions = const [],
  }) async {
    final data = await _client.request(_api, 'start', {
      'folder_path': jsonEncode(folders),
      'recursive': 'true',
      if (pattern.isNotEmpty) 'pattern': pattern,
      if (extensions.isNotEmpty) 'extension': extensions.join(','),
    }) as Map;
    return data['taskid'] as String;
  }

  Future<SearchPage> list(String taskId, {int limit = 500}) async {
    final data = await _client.request(_api, 'list', {
      'taskid': _task(taskId),
      'offset': 0,
      'limit': limit,
      'additional': jsonEncode(['size', 'time', 'type']),
    }) as Map;
    return (
      entries: [
        for (final e in data['files'] as List? ?? const [])
          NasEntry.fromSyno(e as Map<String, dynamic>),
      ],
      total: data['total'] as int?,
      finished: data['finished'] == true,
    );
  }

  Future<void> stop(String taskId) =>
      _client.request(_api, 'stop', {'taskid': _task(taskId)});

  Future<void> clean(String taskId) =>
      _client.request(_api, 'clean', {'taskid': _task(taskId)});
}

/// `SYNO.FileStation.DirSize`: Ordnergröße asynchron berechnen.
class FileStationDirSizeApi {
  FileStationDirSizeApi(this._client);

  static const _api = 'SYNO.FileStation.DirSize';
  final SynoApiClient _client;

  Future<String> start(String path) async {
    final data = await _client.request(_api, 'start', {
      'path': jsonEncode([path]),
    }) as Map;
    return data['taskid'] as String;
  }

  Future<DirSize> status(String taskId) async {
    final data =
        await _client.request(_api, 'status', {'taskid': _task(taskId)}) as Map;
    return (
      finished: data['finished'] == true,
      files: data['num_file'] as int? ?? 0,
      dirs: data['num_dir'] as int? ?? 0,
      bytes: data['total_size'] as int? ?? 0,
    );
  }

  Future<void> stop(String taskId) =>
      _client.request(_api, 'stop', {'taskid': _task(taskId)});
}
