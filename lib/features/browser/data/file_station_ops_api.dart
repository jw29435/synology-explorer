import 'dart:convert';

import '../../../core/network/syno_api_client.dart';
import '../../../core/network/syno_exception.dart';

/// Stand eines CopyMove-/Delete-Tasks; [progress] 0…1, falls bekannt.
typedef TaskProgress = ({bool finished, double? progress});

// Wie bei Search/DirSize: Task-IDs JSON-kodiert (docs/SPIKE.md).
String _task(String id) => jsonEncode(id);

/// Schreibende File-Station-Aufrufe: CreateFolder, Rename, CopyMove, Delete.
class FileStationOpsApi {
  FileStationOpsApi(this._client);

  final SynoApiClient _client;

  /// Legt [name] in [parent] an; mit [forceParent] auch fehlende Eltern
  /// (und ohne Fehler, wenn der Ordner schon existiert).
  Future<void> createFolder(
    String parent,
    String name, {
    bool forceParent = false,
  }) => _client.request('SYNO.FileStation.CreateFolder', 'create', {
    'folder_path': jsonEncode([parent]),
    'name': jsonEncode([name]),
    'force_parent': forceParent,
  });

  Future<void> rename(String path, String name) =>
      _client.request('SYNO.FileStation.Rename', 'rename', {
        'path': jsonEncode([path]),
        'name': jsonEncode([name]),
      });

  /// Kopiert bzw. verschiebt ([move]) [paths] nach [dest]. Ohne
  /// [overwrite] meldet DSM vorhandene Ziele als Fehler 414.
  Future<String> copyMoveStart(
    List<String> paths,
    String dest, {
    required bool move,
    bool overwrite = false,
  }) async {
    final data = await _client.request('SYNO.FileStation.CopyMove', 'start', {
      'path': jsonEncode(paths),
      'dest_folder_path': jsonEncode(dest),
      'remove_src': move,
      if (overwrite) 'overwrite': true,
      'accurate_progress': true,
    }) as Map;
    return data['taskid'] as String;
  }

  Future<TaskProgress> copyMoveStatus(String taskId) async => _progress(
    await _client.request('SYNO.FileStation.CopyMove', 'status', {
      'taskid': _task(taskId),
    }) as Map,
    'SYNO.FileStation.CopyMove',
  );

  Future<void> copyMoveStop(String taskId) => _client.request(
    'SYNO.FileStation.CopyMove',
    'stop',
    {'taskid': _task(taskId)},
  );

  /// Löscht [paths] (landet im `#recycle`, falls der Share einen hat).
  Future<String> deleteStart(List<String> paths) async {
    final data = await _client.request('SYNO.FileStation.Delete', 'start', {
      'path': jsonEncode(paths),
      'accurate_progress': true,
    }) as Map;
    return data['taskid'] as String;
  }

  Future<TaskProgress> deleteStatus(String taskId) async => _progress(
    await _client.request('SYNO.FileStation.Delete', 'status', {
      'taskid': _task(taskId),
    }) as Map,
    'SYNO.FileStation.Delete',
  );

  Future<void> deleteStop(String taskId) => _client.request(
    'SYNO.FileStation.Delete',
    'stop',
    {'taskid': _task(taskId)},
  );

  /// DSM 7.2.1 meldet Fehler einzelner Pfade als `errors` in einem sonst
  /// erfolgreichen `status` (`finished: true`, `status: FAIL`).
  static TaskProgress _progress(Map data, String api) {
    if ((data['errors'] as List?)?.firstOrNull case {'code': final int code}) {
      throw SynoException.fromCode(code, api: api);
    }
    final progress = data['progress'];
    return (
      finished: data['finished'] == true,
      progress: progress is num ? progress.toDouble().clamp(0, 1) : null,
    );
  }
}
