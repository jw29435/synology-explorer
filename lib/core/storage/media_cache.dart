import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Datei-Cache mit LRU-Verdrängung nach Gesamtgröße (Medien, Vorschaubilder).
///
/// Dateinamen sind SHA-256-Hashes des Schlüssels plus Endung – keine Pfade im
/// Klartext (CONCEPT.md Abschnitt 8); die Endung brauchen „Öffnen mit“ und
/// Teilen für den MIME-Typ. Die Änderungszeit der Datei dient als letzter
/// Zugriff: Jeder Treffer setzt sie neu, verdrängt wird die älteste.
class MediaCache {
  MediaCache(this._dir, {required this.maxBytes, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Future<Directory> _dir;
  final DateTime Function() _now;

  /// Limit aus den Einstellungen; darüber wird bis auf das Limit verdrängt.
  final int maxBytes;

  final _pending = <String, Future<File>>{};
  int? _size;

  /// Datei zu [key] aus dem Cache oder über [fetch] neu geladen. [fetch]
  /// schreibt in die übergebene (temporäre) Datei; erst danach wird sie unter
  /// dem endgültigen Namen sichtbar. Gleichzeitige Anfragen teilen sich einen
  /// Ladevorgang.
  Future<File> file(
    String key,
    Future<void> Function(File target) fetch, {
    String extension = '',
  }) {
    final hash = sha256.convert(utf8.encode(key)).toString();
    final name = extension.isEmpty ? hash : '$hash.$extension';
    // Block statt Pfeil: whenComplete würde sonst auf die entfernte (eigene)
    // Future warten.
    return _pending[name] ??= _load(name, fetch).whenComplete(() {
      _pending.remove(name);
    });
  }

  Future<File> _load(String name, Future<void> Function(File) fetch) async {
    final dir = await _dir;
    final file = File('${dir.path}/$name');
    if (await file.exists()) {
      await file.setLastModified(_now());
      return file;
    }
    await dir.create(recursive: true);
    // Atomar: halb geschriebene Dateien dürfen nie als Treffer gelten.
    final tmp = File('${file.path}.tmp');
    try {
      await fetch(tmp);
      await tmp.setLastModified(_now());
      await tmp.rename(file.path);
    } catch (_) {
      if (await tmp.exists()) await tmp.delete();
      rethrow;
    }
    // Beim ersten Mal zählt der Scan die neue Datei schon mit.
    _size = _size == null ? await _usage(dir) : _size! + await file.length();
    if (_size! > maxBytes) _size = await _prune(dir, keep: file.path);
    return file;
  }

  /// Verdrängt sofort bis unter [limit] (nach dem Senken in den
  /// Einstellungen, bevor ein Cache mit dem neuen Limit entsteht).
  Future<void> trim(int limit) async {
    final dir = await _dir;
    if (!await dir.exists()) return;
    _size = await _usage(dir);
    if (_size! > limit) _size = await _prune(dir, keep: '', limit: limit);
  }

  static Future<int> _usage(Directory dir) async {
    var sum = 0;
    await for (final f in dir.list()) {
      if (f is File) sum += await f.length();
    }
    return sum;
  }

  /// Löscht die am längsten nicht benutzten Dateien, bis der Cache unter
  /// 80 % des Limits liegt – mit Luft, damit nicht jede neue Datei am Limit
  /// wieder das ganze Verzeichnis durchgeht. [keep] (gerade geladen) bleibt, auch wenn sie allein zu groß
  /// ist – sie wird ja gleich angezeigt.
  Future<int> _prune(Directory dir, {required String keep, int? limit}) async {
    final files = [
      for (final f in await dir.list().toList())
        if (f is File && !f.path.endsWith('.tmp'))
          (file: f, stat: await f.stat()),
    ]..sort((a, b) => a.stat.modified.compareTo(b.stat.modified));
    var sum = files.fold(0, (s, f) => s + f.stat.size);
    for (final f in files) {
      if (sum <= (limit ?? maxBytes) * 0.8) break;
      if (f.file.path == keep) continue;
      await f.file.delete();
      sum -= f.stat.size;
    }
    return sum;
  }
}
