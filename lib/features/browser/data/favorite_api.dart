import '../../../core/network/syno_api_client.dart';

/// Ein Favorit des NAS-Kontos (`SYNO.FileStation.Favorite`). [broken]: Ziel
/// fehlt oder ist kein Ordner – DSM führt nur Ordner als gültige Favoriten.
typedef NasFavorite = ({String path, String name, bool isDir, bool broken});

/// Favoriten des Kontos auf dem NAS – dieselben wie in DS File.
class FileStationFavoriteApi {
  FileStationFavoriteApi(this._client);

  final SynoApiClient _client;

  static const _api = 'SYNO.FileStation.Favorite';

  Future<List<NasFavorite>> list() async {
    final data =
        await _client.request(_api, 'list', {'status_filter': 'all'}) as Map;
    return [
      for (final f in (data['favorites'] as List).cast<Map>())
        (
          path: f['path'] as String,
          name: f['name'] as String,
          isDir: f['isdir'] as bool? ?? false,
          broken: f['status'] != 'valid',
        ),
    ];
  }

  /// DSM meldet einen schon vorhandenen Favoriten mit Fehler 800.
  Future<void> add(String path, String name) =>
      _client.request(_api, 'add', {'path': path, 'name': name});

  /// Entfernt den Favoriten zu [path] – auch einen, den DS File angelegt hat.
  Future<void> delete(String path) =>
      _client.request(_api, 'delete', {'path': path});
}
