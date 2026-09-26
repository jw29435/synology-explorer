import 'dart:io';
import 'dart:typed_data';

import '../../../core/network/syno_api_client.dart';
import '../../../core/network/syno_exception.dart';
import '../../../core/storage/media_cache.dart';
import '../domain/nas_entry.dart';

/// Vorschaubilder über `SYNO.FileStation.Thumb` mit Disk-Cache
/// ([MediaCache]: Hash-Dateinamen, LRU nach Größe).
///
/// `size=small` (160 px), weil DSM 7.2 für `xl` 404 liefert und für `medium`
/// ohne vorhandenes Vorschaubild teils das Original (docs/SPIKE.md).
class ThumbnailCache {
  ThumbnailCache(
    this._client,
    Future<Directory> dir, {
    this.maxBytes = 500 << 20,
  }) : _store = MediaCache(dir, maxBytes: maxBytes);

  final SynoApiClient _client;
  final MediaCache _store;
  final int maxBytes;

  /// Schlüssel, für die das NAS kein Bild liefert – nicht erneut anfragen.
  final _failed = <String>{};

  static bool supports(NasEntry e) =>
      e.type == NasFileType.image || e.type == NasFileType.video;

  Future<Uint8List> load(NasEntry entry) async {
    final key =
        '${_client.profile.id}|${entry.path}|'
        '${entry.mtime?.millisecondsSinceEpoch}';
    if (_failed.contains(key)) throw StateError('kein Vorschaubild');
    try {
      final file = await _store.file(key, (target) async {
        final bytes = await _client.requestBytes(
          'SYNO.FileStation.Thumb',
          'get',
          {'path': entry.path, 'size': 'small'},
        );
        await target.writeAsBytes(bytes, flush: true);
      });
      return await file.readAsBytes();
    } on SynoException catch (e) {
      if (_permanent(e)) _failed.add(key);
      rethrow;
    }
  }

  /// Nur Antworten des NAS (HTTP-Status wie 404, API-Fehler) gelten für die
  /// Session als endgültig – Netzwerkfehler und abgelaufene Sessions nicht.
  static bool _permanent(SynoException e) => switch (e) {
    SynoNetworkError(:final statusCode) => statusCode != null,
    SynoSessionExpired() => false,
    _ => true,
  };
}
