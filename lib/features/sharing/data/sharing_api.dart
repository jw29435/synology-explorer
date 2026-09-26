import 'dart:convert';

import '../../../core/network/syno_api_client.dart';
import '../domain/share_link.dart';

/// `SYNO.FileStation.Sharing`: Freigabelinks anlegen, auflisten, löschen.
class SharingApi {
  SharingApi(this._client);

  static const _api = 'SYNO.FileStation.Sharing';
  final SynoApiClient _client;

  /// Ein Link je Pfad.
  Future<List<ShareLink>> create(
    List<String> paths, {
    String? password,
    DateTime? expiresAt,
  }) async {
    final data = await _client.request(_api, 'create', {
      'path': jsonEncode(paths),
      if (password != null && password.isNotEmpty) 'password': password,
      'date_expired': dateExpiredParam(expiresAt),
    }) as Map;
    return _links(data);
  }

  Future<List<ShareLink>> list() async {
    final data = await _client.request(_api, 'list', {
      'offset': 0,
      'limit': 500,
      'sort_by': 'date_expired',
      'force_clean': false,
    }) as Map;
    return _links(data);
  }

  Future<void> delete(List<String> ids) =>
      _client.request(_api, 'delete', {'id': jsonEncode(ids)});

  static List<ShareLink> _links(Map data) => [
    for (final l in data['links'] as List? ?? const [])
      ShareLink.fromSyno(l as Map<String, dynamic>),
  ];
}
