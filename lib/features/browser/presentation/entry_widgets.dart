import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/network/syno_exception.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../viewers/presentation/viewer_screen.dart';
import '../../audio/presentation/audio_widgets.dart';
import '../data/thumbnail_cache.dart';
import '../domain/nas_entry.dart';
import '../../servers/presentation/server_providers.dart';
import 'browser_providers.dart';

/// Route des Ordner-Screens (06/07) für [path].
String folderLocation(String path) =>
    Uri(path: '/files/folder', queryParameters: {'path': path}).toString();

/// Übergeordneter Ordner, z. B. `/music/Alben` für `/music/Alben/x.flac`.
String parentPath(String path) => path.substring(0, path.lastIndexOf('/'));

/// Ordner öffnen bzw. Datei als geöffnet merken und nach Typ öffnen:
/// Audio im Player (M2), alles andere im passenden Viewer (15–19) bzw.
/// „Öffnen mit“.
void openEntry(BuildContext context, WidgetRef ref, NasEntry entry) {
  if (entry.isDir) {
    context.push(folderLocation(entry.path));
    return;
  }
  ref
      .read(localLibraryProvider)
      .addRecent(ref.read(serverIdProvider), entry.path);
  switch (entry.type) {
    case NasFileType.audio:
      playAudioEntry(context, entry);
    default:
      context.push(viewerLocation(entry.path), extra: entry);
  }
}

IconData typeIcon(NasFileType type) => switch (type) {
  NasFileType.folder => Icons.folder_outlined,
  NasFileType.audio => Icons.music_note_outlined,
  NasFileType.image => Icons.image_outlined,
  NasFileType.video => Icons.movie_outlined,
  NasFileType.pdf => Icons.picture_as_pdf_outlined,
  NasFileType.text => Icons.article_outlined,
  NasFileType.docx => Icons.description_outlined,
  NasFileType.other => Icons.insert_drive_file_outlined,
};

Color typeColor(NasFileType type) => switch (type) {
  NasFileType.folder => AppColors.accent,
  NasFileType.audio => AppColors.info,
  NasFileType.image => AppColors.success,
  NasFileType.video => AppColors.info,
  NasFileType.pdf || NasFileType.docx => AppColors.errorSoft,
  NasFileType.text || NasFileType.other => AppColors.textSecondary,
};

/// Kleines Label über Abschnitten, z. B. „FREIGEGEBENE ORDNER“.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.padding = EdgeInsets.zero});

  final String text;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    ),
  );
}

/// Typ-Icon in einer abgerundeten Kachel; bei Bildern/Videos das
/// Vorschaubild vom NAS, falls es eins liefert. Mit [label] steht der Name
/// unter dem Icon (Grid ohne Vorschaubild).
class EntryIcon extends ConsumerWidget {
  const EntryIcon(this.entry, {super.key, this.size = 40, this.label = false});

  final NasEntry entry;
  final double size;
  final bool label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconSize = label ? 36.0 : size * 0.55;
    final Widget icon = Center(
      child: label
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    typeIcon(entry.type),
                    color: typeColor(entry.type),
                    size: iconSize,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : Icon(
              typeIcon(entry.type),
              color: typeColor(entry.type),
              size: iconSize,
            ),
    );
    final Widget child = ThumbnailCache.supports(entry)
        ? Image(
            image: NasThumbnail(entry, ref.watch(thumbnailCacheProvider)),
            fit: BoxFit.cover,
            width: label ? null : size,
            height: label ? null : size,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, sync) =>
                frame == null ? icon : child,
            errorBuilder: (context, error, stack) => icon,
          )
        : icon;
    return ClipRRect(
      borderRadius: BorderRadius.circular(label ? 14 : size * 0.25),
      child: ColoredBox(
        color: AppColors.surface,
        child: label
            ? SizedBox.expand(child: child)
            : SizedBox.square(dimension: size, child: child),
      ),
    );
  }
}

/// Vorschaubild über [ThumbnailCache]; Schlüssel ist Pfad + Änderungszeit.
@immutable
class NasThumbnail extends ImageProvider<NasThumbnail> {
  const NasThumbnail(this.entry, this.cache);

  final NasEntry entry;
  final ThumbnailCache cache;

  @override
  Future<NasThumbnail> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    NasThumbnail key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _load(decode),
    scale: 1,
    debugLabel: entry.path,
  );

  Future<ui.Codec> _load(ImageDecoderCallback decode) async =>
      decode(await ui.ImmutableBuffer.fromUint8List(await cache.load(entry)));

  @override
  bool operator ==(Object other) =>
      other is NasThumbnail &&
      identical(other.cache, cache) &&
      other.entry.path == entry.path &&
      other.entry.mtime == entry.mtime;

  @override
  int get hashCode => Object.hash(cache, entry.path, entry.mtime);
}

/// Fehlerzustand mit „Erneut versuchen“; bei abgelaufener Session führt der
/// Button zur Anmeldung.
class ErrorPanel extends ConsumerWidget {
  const ErrorPanel({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Anmeldung nötig: kein „Erneut versuchen“, das nur wieder scheitert.
    final expired = error is SynoSessionExpired || error is SynoUnauthorized;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: AppColors.errorSoft),
          const SizedBox(height: 8),
          Text(describeError(error, l10n), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: expired
                ? () {
                    // Session schon verworfen (E2E-012): Server-Liste.
                    // Sonst Formular per push, Zurück führt hierher.
                    final session = ref.read(sessionProvider);
                    if (session == null) {
                      context.go('/servers');
                    } else {
                      context.push('/servers/${session.client.profile.id}');
                    }
                  }
                : onRetry,
            child: Text(expired ? l10n.signIn : l10n.retry),
          ),
        ],
      ),
    );
  }
}
