import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../data/file_station_task_api.dart';
import '../domain/nas_entry.dart';
import 'browser_providers.dart';
import 'entry_widgets.dart';

/// Screen 09: Kontextmenü einer Datei bzw. eines Ordners. Nur Öffnen,
/// Favorit und Info funktionieren in M1; der Rest ist sichtbar, aber mit
/// Hinweis auf den Meilenstein deaktiviert.
Future<void> showEntryActions(
  BuildContext context,
  WidgetRef ref,
  NasEntry entry,
) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (sheetContext) => _EntryActionsSheet(
    entry: entry,
    onOpen: () => openEntry(context, ref, entry),
    onInfo: () => showEntryInfo(context, entry),
  ),
);

class _EntryActionsSheet extends ConsumerWidget {
  const _EntryActionsSheet({
    required this.entry,
    required this.onOpen,
    required this.onInfo,
  });

  final NasEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favorite = ref.watch(isFavoriteProvider(entry.path)).value ?? false;
    final audio = entry.type == NasFileType.audio;

    Widget item(
      IconData icon,
      String label, {
      VoidCallback? onTap,
      String? later,
      Color? color,
      Widget? trailing,
    }) {
      final tile = ListTile(
        enabled: later == null,
        leading: Icon(icon, color: later == null ? color : null),
        title: Text(
          label,
          style: later == null && color != null
              ? TextStyle(color: color)
              : null,
        ),
        trailing: trailing,
        onTap: onTap == null
            ? null
            : () {
                Navigator.of(context).pop();
                onTap();
              },
      );
      if (later == null) return tile;
      return Tooltip(
        message: l10n.availableFrom(later),
        triggerMode: TooltipTriggerMode.tap,
        child: tile,
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHeader(entry: entry),
            const Divider(height: 1),
            item(Icons.open_in_new, l10n.actionOpen, onTap: onOpen),
            if (audio)
              item(Icons.play_arrow, l10n.actionPlayFromHere, later: 'M2'),
            if (audio || entry.isDir)
              item(Icons.playlist_play, l10n.actionPlayFolder, later: 'M2'),
            if (audio) item(Icons.playlist_add, l10n.actionQueue, later: 'M2'),
            const Divider(indent: 20, endIndent: 20),
            item(Icons.download_outlined, l10n.actionDownload, later: 'M4'),
            item(
              Icons.cloud_download_outlined,
              l10n.actionOffline,
              later: 'M4',
              trailing: const Switch(value: false, onChanged: null),
            ),
            item(
              favorite ? Icons.star : Icons.star_border,
              favorite ? l10n.actionFavoriteRemove : l10n.actionFavoriteAdd,
              color: favorite ? AppColors.accent : null,
              onTap: () => ref
                  .read(localLibraryProvider)
                  .setFavorite(ref.read(serverIdProvider), entry, !favorite),
            ),
            item(Icons.link, l10n.actionShareLink, later: 'M4'),
            const Divider(indent: 20, endIndent: 20),
            item(Icons.edit_outlined, l10n.actionRename, later: 'M4'),
            item(Icons.drive_file_move_outline, l10n.actionMove, later: 'M4'),
            item(Icons.copy_outlined, l10n.actionCopy, later: 'M4'),
            item(Icons.info_outline, l10n.actionInfo, onTap: onInfo),
            const Divider(indent: 20, endIndent: 20),
            item(
              Icons.delete_outline,
              l10n.actionDelete,
              later: 'M4',
              color: AppColors.errorSoft,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.entry});

  final NasEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 8, 12),
      child: Row(
        children: [
          EntryIcon(entry, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entrySubtitle(entry, l10n),
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.close,
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// „31,1 MB · FLAC · 12.05.2026“ bzw. „Ordner · 12.05.2026“.
String entrySubtitle(NasEntry e, AppLocalizations l10n) => [
  if (e.isDir) l10n.infoFolder,
  if (e.size case final size?) formatSize(size, l10n.localeName),
  if (!e.isDir && e.name.contains('.'))
    e.name.substring(e.name.lastIndexOf('.') + 1).toUpperCase(),
  if (e.mtime case final mtime?) formatDate(mtime, l10n),
].join(' · ');

/// Screen 10: Datei-Info über `getinfo`; bei Ordnern Größe per DirSize.
Future<void> showEntryInfo(BuildContext context, NasEntry entry) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => _EntryInfoSheet(entry: entry),
    );

class _EntryInfoSheet extends ConsumerWidget {
  const _EntryInfoSheet({required this.entry});

  final NasEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final info = ref.watch(entryInfoProvider(entry.path));
    final e = info.value ?? entry;
    final locale = l10n.localeName;

    final rows = <(String, Widget)>[
      (l10n.infoPath, Text(e.path, style: AppTheme.mono())),
      if (e.isDir)
        (l10n.infoSize, _DirSizeRow(path: e.path))
      else if (e.size case final size?)
        (
          l10n.infoSize,
          Text(
            l10n.infoSizeBytes(
              formatSize(size, locale),
              formatInt(size, locale),
            ),
          ),
        ),
      if (e.crtime case final t?)
        (l10n.infoCreated, Text(formatDateTime(t, l10n))),
      if (e.mtime case final t?)
        (l10n.infoModified, Text(formatDateTime(t, l10n))),
      if (e.owner case final owner?)
        (l10n.infoOwner, Text([owner, ?e.group].join(' · '))),
      if (e.perm case final perm?)
        (
          l10n.infoPerm,
          Text(
            [
              if (e.posix case final p?) posixString(p),
              'ACL: ${perm == NasPerm.readWrite ? l10n.permReadWrite : l10n.permReadOnly}',
            ].join(' · '),
            style: AppTheme.mono(),
          ),
        ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(entry: e),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (info.isLoading) const LinearProgressIndicator(),
                  if (info.error case final error?)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        describeError(error, l10n),
                        style: const TextStyle(color: AppColors.errorSoft),
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        for (final (i, (label, value)) in rows.indexed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: i == 0
                                ? null
                                : const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: AppColors.border),
                                    ),
                                  ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 88,
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(child: value),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.copy_outlined),
                          label: Text(l10n.copyPath),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: e.path),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.pathCopied)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.done),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// POSIX-Modus als `rwxrwxr-x`; DSM liefert ihn als Dezimalzahl mit
/// Oktalziffern (775).
String posixString(int posix) {
  final digits = posix.toString().padLeft(3, '0');
  return [
    for (final d in digits.substring(digits.length - 3).split(''))
      for (final (bit, char) in [(4, 'r'), (2, 'w'), (1, 'x')])
        int.parse(d) & bit != 0 ? char : '-',
  ].join();
}

class _DirSizeRow extends ConsumerWidget {
  const _DirSizeRow({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final size = ref.watch(dirSizeProvider(path));
    final locale = l10n.localeName;
    String text(DirSize s) => l10n.dirSizeResult(
      formatSize(s.bytes, locale),
      formatInt(s.files, locale),
      formatInt(s.dirs, locale),
    );
    return switch (size) {
      null => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          icon: const Icon(Icons.calculate_outlined),
          label: Text(l10n.computeSize),
          onPressed: () => ref.read(dirSizeProvider(path).notifier).start(),
        ),
      ),
      AsyncData(:final value) when value.finished => Text(text(value)),
      AsyncError(:final error) => Text(
        describeError(error, l10n),
        style: const TextStyle(color: AppColors.errorSoft),
      ),
      _ => Row(
        children: [
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          if (size.value case final partial?)
            Expanded(child: Text(text(partial))),
        ],
      ),
    };
  }
}
