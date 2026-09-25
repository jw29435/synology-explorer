import 'dart:convert';

import '../../../core/network/syno_api_client.dart';
import '../domain/nas_entry.dart';

/// Sortierschlüssel, Werte wie `sort_by` der API.
enum NasSortBy { name, mtime, size, type }

typedef NasPage = ({List<NasEntry> entries, int total});

/// `SYNO.FileStation.List`: Shared Folders und Ordnerinhalte.
class FileStationListApi {
  FileStationListApi(this._client);

  static const _api = 'SYNO.FileStation.List';

  final SynoApiClient _client;

  Future<List<NasEntry>> listShares() async {
    final data = await _client.request(_api, 'list_share', {
      'additional': jsonEncode(['real_path', 'owner', 'perm', 'volume_status']),
    }) as Map;
    return _entries(data['shares']);
  }

  Future<NasPage> list(
    String folderPath, {
    NasSortBy sortBy = NasSortBy.name,
    bool descending = false,
    int offset = 0,
    int limit = 500,
  }) async {
    final data = await _client.request(_api, 'list', {
      'folder_path': folderPath,
      'additional': jsonEncode(['size', 'time', 'type', 'perm']),
      'sort_by': sortBy.name,
      'sort_direction': descending ? 'desc' : 'asc',
      'offset': offset,
      'limit': limit,
    }) as Map;
    return (entries: _entries(data['files']), total: data['total'] as int);
  }

  static List<NasEntry> _entries(Object? list) => [
    for (final e in list as List) NasEntry.fromSyno(e as Map<String, dynamic>),
  ];
}
