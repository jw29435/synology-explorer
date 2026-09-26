import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../browser/data/thumbnail_cache.dart';
import '../../browser/domain/nas_entry.dart';
import '../data/media_repository.dart';

/// Kein Bild aus keiner Quelle; [cause] ist der letzte Fehler.
class ImageUnavailable implements Exception {
  const ImageUnavailable(this.cause);

  final Object? cause;
}

/// Fallback-Kette: die erste Quelle, deren Bytes sich dekodieren lassen.
/// Scheitern alle, kommt [ImageUnavailable].
Future<T> firstDecodable<T>(
  Iterable<Future<Uint8List> Function()> sources,
  Future<T> Function(Uint8List bytes) decode,
) async {
  Object? last;
  for (final source in sources) {
    try {
      return await decode(await source());
    } catch (e) {
      last = e;
    }
  }
  throw ImageUnavailable(last);
}

/// Zielgröße, damit die längere Seite höchstens [max] Pixel hat;
/// Seitenverhältnis bleibt, kleinere Bilder bleiben unverändert.
ui.TargetImageSize fitWithin(int width, int height, int max) {
  final longest = width > height ? width : height;
  if (longest <= max) return const ui.TargetImageSize();
  return width >= height
      ? ui.TargetImageSize(width: max)
      : ui.TargetImageSize(height: max);
}

/// Vollbild aus dem Original im Medien-Cache. Was Flutter selbst nicht
/// kennt (HEIC), dekodiert die Engine über den Plattform-Decoder
/// (Android 9+, iOS). Geht das nicht, bleibt das kleine Vorschaubild vom NAS
/// (`Thumb size=small`; `xl` liefert DSM 7.2 nicht, docs/SPIKE.md).
///
/// Dekodiert wird höchstens auf [maxDimension] Pixel an der längeren Seite:
/// Ein 12-MP-Foto bräuchte sonst ~48 MB Speicher, auf Bildschirmgröße nur
/// einen Bruchteil. [onSize] meldet die Originalmaße (Info-Zeile).
/// Mit [local] (Offline-Kopie) kommt das Original von dort, ohne NAS.
@immutable
class NasImage extends ImageProvider<NasImage> {
  const NasImage(
    this.entry,
    this.media,
    this.thumbs, {
    required this.maxDimension,
    this.onSize,
    this.local,
  }) : assert(media != null || local != null);

  final NasEntry entry;
  final MediaRepository? media;
  final ThumbnailCache? thumbs;
  final File? local;
  final int maxDimension;
  final void Function(NasEntry entry, int width, int height)? onSize;

  @override
  Future<NasImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(NasImage key, ImageDecoderCallback decode) {
    Uint8List? original;
    return MultiFrameImageStreamCompleter(
      codec: firstDecodable(
        [
          () async => original = await (local ?? await media!.file(entry))
              .readAsBytes(),
          if (thumbs case final thumbs?) () => thumbs.load(entry),
        ],
        (bytes) async => decode(
          await ui.ImmutableBuffer.fromUint8List(bytes),
          getTargetSize: (width, height) {
            if (identical(bytes, original)) onSize?.call(entry, width, height);
            return fitWithin(width, height, maxDimension);
          },
        ),
      ),
      scale: 1,
      debugLabel: entry.path,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NasImage &&
      identical(other.media, media) &&
      other.local?.path == local?.path &&
      other.entry.path == entry.path &&
      other.entry.mtime == entry.mtime &&
      other.maxDimension == maxDimension;

  @override
  int get hashCode =>
      Object.hash(media, local?.path, entry.path, entry.mtime, maxDimension);
}
