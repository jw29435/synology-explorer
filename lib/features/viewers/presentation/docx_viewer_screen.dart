import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../browser/domain/nas_entry.dart';
import '../docx/docx_parser.dart';
import '../docx/docx_view.dart';
import 'viewer_common.dart';

/// Geparstes DOCX aus dem Cache, in einem eigenen Isolate (große Dokumente
/// blockieren sonst die Oberfläche).
final _docxProvider = FutureProvider.autoDispose.family<DocxDocument, String>((
  ref,
  path,
) async {
  final bytes = await File(path).readAsBytes();
  return Isolate.run(() => parseDocx(bytes));
});

/// Screen 19: DOCX-Lesemodus mit Hinweis-Banner, „Herunterladen“ und
/// „Öffnen mit“.
class DocxViewerScreen extends ConsumerStatefulWidget {
  const DocxViewerScreen({super.key, required this.entry, this.local});

  final NasEntry entry;
  final LocalFile? local;

  @override
  ConsumerState<DocxViewerScreen> createState() => _DocxViewerScreenState();
}

class _DocxViewerScreenState extends ConsumerState<DocxViewerScreen> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entry = widget.entry;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: ViewerTitle(entry.name, entrySubtitle(entry, l10n)),
        actions: [
          FontScaleButton(
            scale: _scale,
            onChanged: (s) => setState(() => _scale = s),
          ),
          ShareButton(entry, local: widget.local),
          const SizedBox(width: 8),
        ],
      ),
      body: CachedFileView(
        entry: entry,
        local: widget.local,
        builder: (context, file) => FontScale(
          scale: _scale,
          child: switch (ref.watch(_docxProvider(file.path))) {
            AsyncData(:final value) => DocxView(
              value,
              header: const _ReadingModeBanner(),
            ),
            AsyncError() => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.docxUnreadable, textAlign: TextAlign.center),
              ),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Expanded(
                  // Die Transfer-Queue (Download, Offline) kommt mit M4.
                  child: Tooltip(
                    message: l10n.availableFrom('M4'),
                    triggerMode: TooltipTriggerMode.tap,
                    child: OutlinedButton.icon(
                      style: _buttonStyle,
                      icon: const Icon(Icons.download_outlined),
                      label: Text(l10n.actionDownload),
                      onPressed: null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: _buttonStyle,
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l10n.openWith),
                    onPressed: () => withFile(
                      context,
                      ref,
                      entry,
                      openWith,
                      local: widget.local,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static final _buttonStyle = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class _ReadingModeBanner extends StatelessWidget {
  const _ReadingModeBanner();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.accentSurface,
      border: Border.all(color: AppColors.accent.withValues(alpha: 0.6)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: AppColors.accent),
        const SizedBox(width: 12),
        Expanded(child: Text(AppLocalizations.of(context).docxBanner)),
      ],
    ),
  );
}
