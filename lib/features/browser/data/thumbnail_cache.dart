import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../../core/network/syno_api_client.dart';
import '../domain/nas_entry.dart';

/// Vorschaubilder über `SYNO.FileStation.Thumb` mit Disk-Cache. Dateinamen
/// sind SHA-256-Hashes (keine Pfade im Klartext, CONCEPT.md Abschnitt 8).
///
/// `size=small` (160 px), weil DSM 7.2 für `xl` 404 liefert und für `medium`
/// ohne vorhandenes Vorschaubild teils das Original (docs/SPIKE.md).
class ThumbnailCache {
  ThumbnailCache(this._client, this._dir, {this.maxBytes = 500 << 20});

  final SynoApiClient _client;
  final Future<Directory> _dir;
  final int maxBytes;

  /// Schlüssel, für die das NAS kein Bild liefert – nicht erneut anfragen.
  final _failed = <String>{};
  int? _size;

  static bool supports(NasEntry e) =>
      e.type == NasFileType.image || e.type == NasFileType.video;

  Future<Uint8List> load(NasEntry entry) async {
    final key = sha256
        .convert(
          utf8.encode(
            '${_client.profile.id}|${entry.path}|'
            '${entry.mtime?.millisecondsSinceEpoch}',
          ),
        )
        .toString();
    if (_failed.contains(key)) throw StateError('kein Vorschaubild');
    final dir = await _dir;
    final file = File('${dir.path}/$key');
    if (await file.exists()) return file.readAsBytes();
    final Uint8List bytes;
    try {
      bytes = await _client.requestBytes('SYNO.FileStation.Thumb', 'get', {
        'path': entry.path,
        'size': 'small',
      });
    } catch (_) {
      _failed.add(key);
      rethrow;
    }
    await dir.create(recursive: true);
    await file.writeAsBytes(bytes);
    _size = (_size ?? await _usage(dir)) + bytes.length;
    if (_size! > maxBytes) _size = await _prune(dir);
    return bytes;
  }

  static Future<int> _usage(Directory dir) async {
    var sum = 0;
    await for (final f in dir.list()) {
      if (f is File) sum += await f.length();
    }
    return sum;
  }

  /// Löscht die ältesten Dateien, bis der Cache unter 80 % des Limits liegt.
  Future<int> _prune(Directory dir) async {
    final files = [
      for (final f in await dir.list().toList())
        if (f is File) (file: f, stat: await f.stat()),
    ]..sort((a, b) => a.stat.modified.compareTo(b.stat.modified));
    var sum = files.fold(0, (s, f) => s + f.stat.size);
    for (final f in files) {
      if (sum <= maxBytes * 0.8) break;
      await f.file.delete();
      sum -= f.stat.size;
    }
    return sum;
  }
}
