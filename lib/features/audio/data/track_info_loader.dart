import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:crypto/crypto.dart';

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
/// 3. Platzhalter (`cover == null`). Ergebnisse liegen auf der Platte;
/// Schlüssel ist ein Hash aus Pfad und mtime.
class TrackInfoLoader {
  TrackInfoLoader({
    required this.download,
    required this.thumbnail,
    required this.dir,
  });

  /// Lädt eine Datei, höchstens die ersten [maxBytes] (Range).
  final Future<Uint8List> Function(String path, {int? maxBytes}) download;

  /// Vorschaubild über `SYNO.FileStation.Thumb`.
  final Future<Uint8List> Function(NasEntry entry) thumbnail;

  /// Cache-Ordner.
  final Future<Directory> dir;

  static const prefixBytes = 1 << 20;

  /// Größere Ordner-Cover kommen als Vorschaubild statt im Original.
  static const maxCoverBytes = 5 << 20;

  // ponytail: kein Größenlimit für den Cover-Cache; liegt im Cache-Ordner, den
  // das OS leeren darf. LRU wie beim Thumbnail-Cache, falls er zu groß wird.

  Future<TrackInfo> load(NasEntry track, {NasEntry? folderCover}) async {
    final tags = await _tags(track);
    if (tags.cover != null || folderCover == null) return tags;
    return TrackInfo(
      title: tags.title,
      artist: tags.artist,
      album: tags.album,
      cover: await _folderCover(folderCover),
    );
  }

  static String _key(NasEntry e) => sha256
      .convert(utf8.encode('${e.path}|${e.mtime?.millisecondsSinceEpoch}'))
      .toString();

  Future<TrackInfo> _tags(NasEntry track) async {
    final cache = await dir;
    final key = _key(track);
    final json = File('${cache.path}/$key.json');
    final image = File('${cache.path}/$key.img');
    if (await json.exists()) {
      final m = jsonDecode(await json.readAsString()) as Map<String, dynamic>;
      return TrackInfo(
        title: m['title'] as String?,
        artist: m['artist'] as String?,
        album: m['album'] as String?,
        cover: await image.exists() ? image : null,
      );
    }
    // Netzwerkfehler gehen raus und werden nicht gecacht.
    final prefix = await download(track.path, maxBytes: prefixBytes);
    await cache.create(recursive: true);
    final ext = track.name.contains('.')
        ? track.name.substring(track.name.lastIndexOf('.'))
        : '';
    // Eindeutig: zwei gleichzeitige Loads desselben Titels dürfen sich nicht
    // die Datei unter den Füßen wegziehen.
    final part = File('${cache.path}/$key.${_unique()}.part$ext');
    await part.writeAsBytes(prefix, flush: true);
    final parsed = await Isolate.run(() => _parse(part.path));
    await part.delete();
    if (parsed.cover case final bytes?) await _write(image, bytes);
    await _write(
      json,
      utf8.encode(
        jsonEncode({
          'title': parsed.title,
          'artist': parsed.artist,
          'album': parsed.album,
        }),
      ),
    );
    return TrackInfo(
      title: parsed.title,
      artist: parsed.artist,
      album: parsed.album,
      cover: parsed.cover == null ? null : image,
    );
  }

  Future<File?> _folderCover(NasEntry entry) async {
    final cache = await dir;
    final image = File('${cache.path}/${_key(entry)}.img');
    if (await image.exists()) return image;
    try {
      final size = entry.size;
      final bytes = size != null && size <= maxCoverBytes
          ? await download(entry.path)
          : await thumbnail(entry);
      await cache.create(recursive: true);
      await _write(image, bytes);
      return image;
    } catch (_) {
      return null;
    }
  }

  static final _random = Random();
  static String _unique() =>
      '${DateTime.now().microsecondsSinceEpoch}${_random.nextInt(1 << 32)}';

  /// Atomar schreiben: halbe Dateien dürfen nie als Cache-Treffer gelten.
  static Future<void> _write(File file, List<int> bytes) async {
    final tmp = File('${file.path}.${_unique()}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(file.path);
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
