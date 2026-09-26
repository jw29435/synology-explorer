import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../browser/domain/nas_entry.dart';
import '../../browser/presentation/entry_widgets.dart';
import 'viewer_providers.dart';

/// Offline-Kopie (Screen 21), die ein Viewer statt des NAS nutzt – ohne
/// Session und ohne Medien-Cache.
class LocalFile {
  const LocalFile(this.file, this.serverId);

  final File file;
  final int serverId;
}

/// Titelzeile der Viewer: Dateiname und darunter eine Info-Zeile.
class ViewerTitle extends StatelessWidget {
  const ViewerTitle(this.title, this.subtitle, {super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          subtitle,
          overflow: TextOverflow.ellipsis,
          style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// „Ordner · Größe“, z. B. `dokumente/Verein · 84 KB`.
String entrySubtitle(NasEntry entry, AppLocalizations l10n) => [
  parentPath(entry.path).replaceFirst('/', ''),
  if (entry.size case final size?) formatSize(size, l10n.localeName),
].where((s) => s.isNotEmpty).join(' · ');

/// Lädt [entry] in den Cache (mit Fortschritt) und baut dann [builder].
class CachedFileView extends ConsumerWidget {
  const CachedFileView({
    super.key,
    required this.entry,
    required this.builder,
    this.local,
  });

  final NasEntry entry;
  final Widget Function(BuildContext context, File file) builder;

  /// Offline-Kopie: direkt anzeigen, nichts laden.
  final LocalFile? local;

  @override
  Widget build(BuildContext context, WidgetRef ref) => local != null
      ? builder(context, local!.file)
      : switch (ref.watch(cachedFileProvider(entry))) {
          AsyncData(value: (file: final file?, progress: _)) => builder(
            context,
            file,
          ),
          AsyncError(:final error) => Center(
            child: ErrorPanel(
              error: error,
              onRetry: () => ref.invalidate(cachedFileProvider(entry)),
            ),
          ),
          AsyncValue(:final value) => DownloadProgress(
            entry: entry,
            progress: value?.progress,
          ),
        };
}

/// Ladebalken mit „x von y“ während des Downloads in den Cache.
class DownloadProgress extends StatelessWidget {
  const DownloadProgress({super.key, required this.entry, this.progress});

  final NasEntry entry;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = entry.size;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(typeIcon(entry.type), size: 48, color: typeColor(entry.type)),
            const SizedBox(height: 16),
            Text(l10n.viewerLoading),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              borderRadius: BorderRadius.circular(4),
            ),
            if (size != null && progress != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.downloadProgress(
                  formatSize((size * progress!).round(), l10n.localeName),
                  formatSize(size, l10n.localeName),
                ),
                style: AppTheme.mono(TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Teilt die lokale Kopie unter dem Originalnamen (Cache-Dateien heißen
/// nach ihrem Hash).
Future<void> shareFile(File file, NasEntry entry) => SharePlus.instance.share(
  ShareParams(files: [XFile(file.path)], fileNameOverrides: [entry.name]),
);

/// Übergibt die lokale Kopie an eine andere App; wirft [OpenWithFailed],
/// wenn keine App sie öffnen kann.
Future<void> openWith(File file) async {
  final result = await OpenFilex.open(file.path);
  if (result.type != ResultType.done) throw const OpenWithFailed();
}

class OpenWithFailed implements Exception {
  const OpenWithFailed();
}

/// Lädt [entry] (meist schon im Cache) und führt [action] aus; Fehler
/// erscheinen als Snackbar.
Future<void> withFile(
  BuildContext context,
  WidgetRef ref,
  NasEntry entry,
  Future<void> Function(File file) action, {
  LocalFile? local,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    await action(
      local?.file ?? await ref.read(mediaRepositoryProvider).file(entry),
    );
  } catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            e is OpenWithFailed ? l10n.openWithFailed : describeError(e, l10n),
          ),
        ),
      );
  }
}

/// Teilen-Knopf für die App-Leiste.
class ShareButton extends ConsumerWidget {
  const ShareButton(this.entry, {super.key, this.local});

  final NasEntry entry;
  final LocalFile? local;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: AppLocalizations.of(context).actionShare,
    icon: const Icon(Icons.share_outlined),
    onPressed: () =>
        withFile(context, ref, entry, (f) => shareFile(f, entry), local: local),
  );
}

/// Schriftgrößen, die „Aa“ der Reihe nach durchschaltet (Faktor auf die
/// Systemeinstellung).
const fontScales = [1.0, 1.2, 1.4, 0.85];

/// „Aa“-Knopf: schaltet [scale] auf die nächste Stufe aus [fontScales].
class FontScaleButton extends StatelessWidget {
  const FontScaleButton({
    super.key,
    required this.scale,
    required this.onChanged,
  });

  final double scale;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppLocalizations.of(context).fontSize,
    icon: const Icon(Icons.text_fields),
    onPressed: () => onChanged(
      fontScales[(fontScales.indexOf(scale) + 1) % fontScales.length],
    ),
  );
}

/// Vergrößert allen Text in [child] um [scale].
class FontScale extends StatelessWidget {
  const FontScale({super.key, required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(
        MediaQuery.textScalerOf(context).scale(1) * scale,
      ),
    ),
    child: child,
  );
}
