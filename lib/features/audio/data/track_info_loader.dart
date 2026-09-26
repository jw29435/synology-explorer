import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import '../../../core/storage/media_cache.dart';
import '../../browser/domain/nas_entry.dart';

/// Tags und Cover eines Titels.
class TrackInfo {
  const TrackInfo({this.title, this.artist, this.album, this.cover});

  final String? title;
  final String? artist;
  final String? album;

  /// Lokale Bilddatei; `null` = Platzhalter.
  final File? cover;
}

/// Namen, unter denen ein Ordner-Cover gesucht wird (ohne Groß/klein).
const folderCoverNames = {
  'folder.jpg',
  'folder.jpeg',
  'folder.png',
  'cover.jpg',
  'cover.jpeg',
  'cover.png',
};

/// Cover-Kette: 1. eingebettetes Bild (ID3/FLAC/MP4) aus den ersten
/// [prefixBytes] der Datei, 2. `folder.jpg`/`cover.jpg` im Ordner,
/// 3. Platzhalter (`cover == null`). Tags und Bilder liegen im [cache]
/// (LRU mit Größenlimit); Schlüssel sind Pfad und mtime.
class TrackInfoLoader {
  TrackInfoLoader({
    required this.download,
    required this.thumbnail,
    required this.cache,
  });

  /// Lädt eine Datei, höchstens die ersten [maxBytes] (Range).
  final Future<Uint8List> Function(String path, {int? maxBytes}) download;

  /// Vorschaubild über `SYNO.FileStation.Thumb`.
  final Future<Uint8List> Function(NasEntry entry) thumbnail;

  final MediaCache cache;

  static const prefixBytes = 1 << 20;

  /// Größere Ordner-Cover kommen als Vorschaubild statt im Original.
  static const maxCoverBytes = 5 << 20;

  static String _key(NasEntry e) =>
      '${e.path}|${e.mtime?.millisecondsSinceEpoch}';

  Future<TrackInfo> load(NasEntry track, {NasEntry? folderCover}) async {
    final key = _key(track);
    // Netzwerkfehler gehen raus; der Cache legt dann nichts an.
    final tags = await cache.file('tags|$key', (target) async {
      final parsed = await _parsePrefix(track);
      if (parsed.cover case final bytes?) {
        await cache.file(
          'cover|$key',
          (t) => t.writeAsBytes(bytes, flush: true),
          extension: 'img',
        );
      }
      await target.writeAsString(
        jsonEncode({
          'title': parsed.title,
          'artist': parsed.artist,
          'album': parsed.album,
          'cover': parsed.cover != null,
        }),
        flush: true,
      );
    }, extension: 'json');
    final m = jsonDecode(await tags.readAsString()) as Map<String, dynamic>;
    final File? cover;
    if (m['cover'] == true) {
      // Bild inzwischen verdrängt: aus dem Dateianfang neu holen.
      cover = await _quietly(
        () => cache.file('cover|$key', (target) async {
          final bytes = (await _parsePrefix(track)).cover;
          if (bytes == null) throw StateError('kein Cover');
          await target.writeAsBytes(bytes, flush: true);
        }, extension: 'img'),
      );
    } else if (folderCover != null) {
      cover = await _quietly(
        () => cache.file('folder|${_key(folderCover)}', (target) async {
          final size = folderCover.size;
          final bytes = size != null && size <= maxCoverBytes
              ? await download(folderCover.path)
              : await thumbnail(folderCover);
          await target.writeAsBytes(bytes, flush: true);
        }, extension: 'img'),
      );
    } else {
      cover = null;
    }
    return TrackInfo(
      title: m['title'] as String?,
      artist: m['artist'] as String?,
      album: m['album'] as String?,
      cover: cover,
    );
  }

  static Future<File?> _quietly(Future<File> Function() load) async {
    try {
      return await load();
    } catch (_) {
      return null;
    }
  }

  static final _random = Random();

  /// Lädt den Dateianfang und liest die Tags in einem Isolate.
  Future<_Parsed> _parsePrefix(NasEntry track) async {
    final prefix = await download(track.path, maxBytes: prefixBytes);
    final ext = track.name.contains('.')
        ? track.name.substring(track.name.lastIndexOf('.'))
        : '';
    // Eindeutig: gleichzeitige Loads dürfen sich nicht in die Quere kommen.
    final part = File(
      '${Directory.systemTemp.path}/se-tags-'
      '${DateTime.now().microsecondsSinceEpoch}${_random.nextInt(1 << 32)}$ext',
    );
    await part.writeAsBytes(prefix, flush: true);
    try {
      return await Isolate.run(() => _parse(part.path));
    } finally {
      await part.delete();
    }
  }
}

typedef _Parsed = ({
  String? title,
  String? artist,
  String? album,
  Uint8List? cover,
});

/// Tags aus einem (abgeschnittenen) Dateianfang. Kaputte oder
/// abgeschnittene Tags sind kein Fehler, sondern „keine Tags“.
_Parsed _parse(String path) {
  try {
    final m = readMetadata(File(path), getImage: true);
    final pictures = m.pictures;
    final front = pictures
        .where((p) => p.pictureType == PictureType.coverFront)
        .firstOrNull;
    String? text(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
    return (
      title: text(m.title),
      artist: text(m.artist),
      album: text(m.album),
      cover: (front ?? pictures.firstOrNull)?.bytes,
    );
  } catch (_) {
    return (title: null, artist: null, album: null, cover: null);
  }
}
