import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../audio/presentation/audio_widgets.dart';
import '../../browser/domain/nas_entry.dart';
import '../../browser/presentation/browser_providers.dart';
import '../../browser/presentation/entry_widgets.dart';
import 'docx_viewer_screen.dart';
import 'image_viewer_screen.dart';
import 'pdf_viewer_screen.dart';
import 'text_viewer_screen.dart';
import 'video_player_screen.dart';
import 'viewer_common.dart';

/// `extra` der Viewer-Route für eine Offline-Datei: geht ohne Session.
class LocalView {
  const LocalView(this.entry, this.local);

  final NasEntry entry;
  final LocalFile local;
}

/// Offline-Datei (Screen 21) im passenden Viewer öffnen, Audio im Player.
Future<bool> openOffline(BuildContext context, OfflineFile file) async {
  final name = file.remotePath.substring(file.remotePath.lastIndexOf('/') + 1);
  final entry = NasEntry(
    path: file.remotePath,
    name: name,
    isDir: false,
    type: NasFileType.fromName(name),
    size: file.size,
    mtime: file.mtime,
  );
  if (entry.type == NasFileType.audio) {
    await playOfflineAudio(context, entry, File(file.localPath), file.serverId);
    return true;
  }
  unawaited(
    context.push(
      viewerLocation(entry.path),
      extra: LocalView(entry, LocalFile(File(file.localPath), file.serverId)),
    ),
  );
  return true;
}

/// Route der Viewer (Vollbild über der Shell) für [path].
String viewerLocation(String path) =>
    Uri(path: '/view', queryParameters: {'path': path}).toString();

/// Wählt den Viewer nach Dateityp. Fehlen Größe/Änderungszeit (z. B. aus
/// „Zuletzt geöffnet“), kommen sie erst per `getinfo`.
class ViewerScreen extends ConsumerWidget {
  const ViewerScreen({super.key, required this.path, this.entry});

  final String path;
  final NasEntry? entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entry case final e? when e.mtime != null) return viewerFor(e);
    return switch (ref.watch(entryInfoProvider(path))) {
      AsyncData(:final value) => viewerFor(value),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: ErrorPanel(
          error: error,
          onRetry: () => ref.invalidate(entryInfoProvider(path)),
        ),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }

  static Widget viewerFor(NasEntry e, {LocalFile? local}) => switch (e.type) {
    NasFileType.image => ImageViewerScreen(entry: e, local: local),
    NasFileType.video => VideoPlayerScreen(entry: e, local: local),
    NasFileType.pdf => PdfViewerScreen(entry: e, local: local),
    NasFileType.text => TextViewerScreen(entry: e, local: local),
    NasFileType.docx => DocxViewerScreen(entry: e, local: local),
    _ => OpenWithScreen(entry: e, autoStart: true, local: local),
  };
}

/// Generisch: Datei in den Cache laden und an eine andere App übergeben.
/// Mit [autoStart] beginnt der Download sofort und die Datei öffnet sich
/// danach einmal automatisch; sonst erst per Knopf (z. B. Text > 5 MB).
class OpenWithScreen extends ConsumerStatefulWidget {
  const OpenWithScreen({
    super.key,
    required this.entry,
    this.hint,
    this.autoStart = false,
    this.local,
  });

  final NasEntry entry;
  final String? hint;
  final bool autoStart;
  final LocalFile? local;

  @override
  ConsumerState<OpenWithScreen> createState() => _OpenWithScreenState();
}

class _OpenWithScreenState extends ConsumerState<OpenWithScreen> {
  late bool _started = widget.autoStart;
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entry = widget.entry;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: ViewerTitle(entry.name, entrySubtitle(entry, l10n)),
      ),
      body: !_started
          ? _panel(context, () => setState(() => _started = true))
          : CachedFileView(
              entry: entry,
              local: widget.local,
              builder: (context, file) {
                if (!_opened) {
                  _opened = true;
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => withFile(
                      context,
                      ref,
                      entry,
                      openWith,
                      local: widget.local,
                    ),
                  );
                }
                return _panel(
                  context,
                  () => withFile(
                    context,
                    ref,
                    entry,
                    openWith,
                    local: widget.local,
                  ),
                );
              },
            ),
    );
  }

  Widget _panel(BuildContext context, VoidCallback onOpen) {
    final l10n = AppLocalizations.of(context);
    final entry = widget.entry;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(typeIcon(entry.type), size: 56, color: typeColor(entry.type)),
            const SizedBox(height: 16),
            Text(entry.name, textAlign: TextAlign.center),
            if (entry.size case final size?)
              Text(
                formatSize(size, l10n.localeName),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            const SizedBox(height: 16),
            Text(
              widget.hint ?? l10n.openWithHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.openWith),
              onPressed: onOpen,
            ),
          ],
        ),
      ),
    );
  }
}
