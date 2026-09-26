import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:photo_view/photo_view.dart';

import '../../../app/theme.dart';
import '../../../core/network/syno_exception.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../browser/domain/nas_entry.dart';
import '../../browser/presentation/browser_providers.dart';
import '../../browser/presentation/entry_sheets.dart';
import '../../browser/presentation/entry_widgets.dart';
import '../../browser/presentation/file_actions.dart';
import 'nas_image.dart';
import 'viewer_common.dart';
import 'viewer_providers.dart';

bool _isHeic(NasEntry e) {
  final name = e.name.toLowerCase();
  return name.endsWith('.heic') || name.endsWith('.heif');
}

/// Screen 15: Galerie über alle Bilder des Ordners mit Zoom, Vorladen des
/// nächsten Bilds, Overlay (Tippen blendet ein/aus) und Thumbnail-Streifen.
class ImageViewerScreen extends ConsumerStatefulWidget {
  const ImageViewerScreen({super.key, required this.entry, this.local});

  final NasEntry entry;

  /// Offline-Kopie: nur dieses Bild, ohne Favorit/Info (brauchen das NAS).
  final LocalFile? local;

  @override
  ConsumerState<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends ConsumerState<ImageViewerScreen> {
  static const _thumbExtent = 60.0;

  PageController? _pages;
  final _strip = ScrollController();
  late NasEntry _current = widget.entry;
  bool _overlay = true;

  /// Pixelmaße der dekodierten Bilder je Pfad.
  final _sizes = <String, Size>{};

  @override
  void dispose() {
    _pages?.dispose();
    _strip.dispose();
    super.dispose();
  }

  /// Längere Bildschirmseite in Pixeln; größer wird nicht dekodiert.
  int _maxDimension = 2048;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size =
        MediaQuery.sizeOf(context) * MediaQuery.devicePixelRatioOf(context);
    _maxDimension = size.longestSide.ceil();
  }

  NasImage _image(NasEntry e) => widget.local == null
      ? NasImage(
          e,
          ref.read(mediaRepositoryProvider),
          ref.read(thumbnailCacheProvider),
          maxDimension: _maxDimension,
          onSize: _onSize,
        )
      : NasImage(
          e,
          null,
          null,
          maxDimension: _maxDimension,
          onSize: _onSize,
          local: widget.local!.file,
        );

  void _onSize(NasEntry e, int width, int height) {
    if (mounted && !_sizes.containsKey(e.path)) {
      setState(
        () => _sizes[e.path] = Size(width.toDouble(), height.toDouble()),
      );
    }
  }

  /// Bilder des Ordners in der Sortierung des Browsers; fehlt das Bild dort
  /// (z. B. jenseits der geladenen Seite), nur dieses eine.
  List<NasEntry>? _gallery() {
    // Offline: nur diese Datei, ohne NAS.
    if (widget.local != null) return [widget.entry];
    final folder = ref.watch(folderProvider(parentPath(widget.entry.path)));
    if (folder.isLoading && !folder.hasValue) return null;
    final images = [
      for (final e in folder.value?.entries ?? const <NasEntry>[])
        if (e.type == NasFileType.image && !_deleted.contains(e.path)) e,
    ];
    return images.any((e) => e.path == _current.path) ? images : [_current];
  }

  /// Gelöschte Bilder; der Ordner lädt nach dem Löschen erst neu.
  final _deleted = <String>{};

  /// Löschen wie in Sheet 09 (mit Bestätigung), danach das nächste Bild
  /// bzw. das vorige; war es das letzte, schließt der Viewer.
  Future<void> _delete(List<NasEntry> images, int index) async {
    final entry = images[index];
    if (!await deleteEntries(context, ref, [entry]) || !mounted) return;
    final rest = [...images]..removeAt(index);
    if (rest.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final next = rest[index.clamp(0, rest.length - 1)];
    setState(() {
      _deleted.add(entry.path);
      _current = next;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pages?.jumpToPage(rest.indexOf(next));
    });
  }

  void _onPage(List<NasEntry> images, int index) {
    setState(() => _current = images[index]);
    if (index + 1 < images.length) {
      precacheImage(_image(images[index + 1]), context);
    }
    if (_strip.hasClients) {
      final width = _strip.position.viewportDimension;
      _strip.animateTo(
        (index * _thumbExtent - (width - _thumbExtent) / 2).clamp(
          0,
          _strip.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _gallery();
    if (images == null) {
      // Zurück auch, solange der Ordner lädt.
      return const AnnotatedRegion(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(child: CircularProgressIndicator()),
              _Dark(child: SafeArea(child: BackButton())),
            ],
          ),
        ),
      );
    }
    final index = images.indexWhere((e) => e.path == _current.path);
    if (_pages == null) {
      _pages = PageController(initialPage: index);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onPage(images, index);
      });
    }
    // Schwarzer Grund: Statusleiste hell, auch im hellen Design.
    return AnnotatedRegion(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Tippen auch während des Ladens oder bei Fehlern.
            GestureDetector(
              onTap: () => setState(() => _overlay = !_overlay),
              child: PhotoViewGestureDetectorScope(
                axis: Axis.horizontal,
                child: PageView.builder(
                  controller: _pages,
                  itemCount: images.length,
                  onPageChanged: (i) => _onPage(images, i),
                  itemBuilder: (context, i) => PhotoView(
                    key: ValueKey(images[i].path),
                    imageProvider: _image(images[i]),
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 4,
                    loadingBuilder: (context, _) => Center(
                      child: widget.local == null
                          ? EntryIcon(images[i], size: 160)
                          : const CircularProgressIndicator(),
                    ),
                    errorBuilder: (context, error, _) =>
                        _ImageError(entry: images[i], error: error),
                  ),
                ),
              ),
            ),
            if (_overlay) ...[
              _TopBar(
                entry: _current,
                index: index,
                total: images.length,
                online: widget.local == null,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _BottomBar(
                  entry: _current,
                  size: _sizes[_current.path],
                  images: images,
                  index: index,
                  strip: _strip,
                  thumbExtent: _thumbExtent,
                  onSelect: (i) => _pages!.jumpToPage(i),
                  onDelete: () => _delete(images, index),
                  local: widget.local,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Leisten über dem Bild: immer hell auf dunklem Scrim, auch im hellen
/// Design. Nur um die Leisten, damit Dialoge und Sheets (Info, Löschen) im
/// App-Design bleiben.
class _Dark extends StatelessWidget {
  const _Dark({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.dark,
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.entry,
    required this.index,
    required this.total,
    required this.online,
  });

  final NasEntry entry;
  final int index;
  final int total;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Dark(
      child: ColoredBox(
        color: AppColors.playScrim,
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              const BackButton(),
              Expanded(
                child: ViewerTitle(
                  entry.name,
                  l10n.imageOf('${index + 1}', '$total'),
                ),
              ),
              if (online)
                IconButton(
                  tooltip: l10n.actionInfo,
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => showEntryInfo(context, entry),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar({
    required this.entry,
    required this.size,
    required this.images,
    required this.index,
    required this.strip,
    required this.thumbExtent,
    required this.onSelect,
    required this.onDelete,
    this.local,
  });

  final NasEntry entry;
  final Size? size;
  final List<NasEntry> images;
  final int index;
  final ScrollController strip;
  final double thumbExtent;
  final ValueChanged<int> onSelect;
  final VoidCallback onDelete;
  final LocalFile? local;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favorite =
        local == null &&
        (ref.watch(isFavoriteProvider(entry.path)).value ?? false);
    final info = [
      if (size case final s?) '${s.width.round()} × ${s.height.round()}',
      if (entry.mtime case final t?) formatDate(t, l10n),
      if (entry.size case final b?) formatSize(b, l10n.localeName),
    ].join(' · ');

    Widget action(
      IconData icon,
      String label,
      VoidCallback? onTap, {
      Color? color,
    }) => Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );

    return _Dark(
      child: ColoredBox(
        color: AppColors.playScrim,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (info.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Text(
                    info,
                    style: TextStyle(color: Neutrals.dark.textSecondary),
                  ),
                ),
              if (images.length > 1)
                SizedBox(
                  height: thumbExtent + 16,
                  child: ListView.builder(
                    controller: strip,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemExtent: thumbExtent,
                    itemCount: images.length,
                    itemBuilder: (context, i) => GestureDetector(
                      onTap: () => onSelect(i),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: i == index
                                ? AppColors.accent
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: EntryIcon(images[i], size: thumbExtent - 12),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Row(
                  children: [
                    action(
                      Icons.share_outlined,
                      l10n.actionShare,
                      () => withFile(
                        context,
                        ref,
                        entry,
                        (f) => shareFile(f, entry),
                        local: local,
                      ),
                    ),
                    action(
                      Icons.download_outlined,
                      l10n.actionSaveToPhotos,
                      () => withFile(context, ref, entry, local: local, (
                        f,
                      ) async {
                        final messenger = ScaffoldMessenger.of(context);
                        if (!await Gal.hasAccess()) await Gal.requestAccess();
                        await Gal.putImage(f.path);
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(content: Text(l10n.savedToPhotos)),
                          );
                      }),
                    ),
                    if (local == null)
                      action(
                        favorite ? Icons.star : Icons.star_border,
                        l10n.actionFavorite,
                        () => ref
                            .read(localLibraryProvider)
                            .setFavorite(
                              ref.read(serverIdProvider),
                              entry,
                              !favorite,
                            ),
                        color: favorite ? AppColors.accent : null,
                      ),
                    if (local == null)
                      action(
                        Icons.delete_outline,
                        l10n.actionDeleteShort,
                        onDelete,
                        color: Neutrals.dark.errorSoft,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError({required this.entry, required this.error});

  final NasEntry entry;
  final Object error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cause = error is ImageUnavailable
        ? (error as ImageUnavailable).cause
        : error;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              typeIcon(entry.type),
              size: 56,
              color: Neutrals.dark.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              _isHeic(entry)
                  ? l10n.heicUnavailable
                  : cause is SynoException
                  ? describeError(cause, l10n)
                  : l10n.imageUnavailable,
              textAlign: TextAlign.center,
              style: TextStyle(color: Neutrals.dark.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
