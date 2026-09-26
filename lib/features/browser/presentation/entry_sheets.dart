import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../data/file_station_task_api.dart';
import '../domain/nas_entry.dart';
import '../../sharing/presentation/share_link_sheet.dart';
import '../../transfers/presentation/transfer_providers.dart';
import 'browser_providers.dart';
import 'entry_widgets.dart';
import 'file_actions.dart';

/// Screen 09: Kontextmenü einer Datei bzw. eines Ordners. Die Aktionen
/// laufen nach dem Schließen des Sheets mit [context]/[ref] des Aufrufers.
Future<void> showEntryActions(
  BuildContext context,
  WidgetRef ref,
  NasEntry entry,
) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (sheetContext) =>
      _EntryActionsSheet(entry: entry, outer: context, outerRef: ref),
);

class _EntryActionsSheet extends ConsumerWidget {
  const _EntryActionsSheet({
    required this.entry,
    required this.outer,
    required this.outerRef,
  });

  final NasEntry entry;
  final BuildContext outer;
  final WidgetRef outerRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favorite = ref.watch(isFavoriteProvider(entry.path)).value ?? false;
    final audio = entry.type == NasFileType.audio;
    // Shared Folder selbst: nicht laden, umbenennen, verschieben, löschen.
    final share = entry.path.lastIndexOf('/') == 0;
    // ACL ohne Schreibrecht: Umbenennen/Verschieben scheitern sonst mit 407.
    // Löschen bleibt, weil DSM das eigene ACL-Recht `del` prüft.
    final readOnly = entry.perm == NasPerm.readOnly
        ? l10n.noWritePermission
        : null;
    final offline =
        !entry.isDir &&
        (ref.watch(isOfflineProvider(entry.path)).value ?? false);
    // Aus: lokale Kopie löschen; an: in den Offline-Bereich laden.
    Future<void> toggleOffline() async {
      if (offline) {
        await outerRef
            .read(offlineStoreProvider)
            .remove(outerRef.read(serverIdProvider), entry.path);
      } else {
        await downloadEntries(outer, outerRef, [entry]);
      }
    }

    /// [disabled]: Grund, warum der Eintrag nicht geht (Tooltip beim Tippen).
    Widget item(
      IconData icon,
      String label, {
      VoidCallback? onTap,
      String? disabled,
      Color? color,
      Widget? trailing,
    }) {
      final tile = ListTile(
        enabled: disabled == null,
        leading: Icon(icon, color: disabled == null ? color : null),
        title: Text(
          label,
          style: disabled == null && color != null
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
      if (disabled == null) return tile;
      return Tooltip(
        message: disabled,
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
            item(
              Icons.open_in_new,
              l10n.actionOpen,
              onTap: () => openEntry(outer, outerRef, entry),
            ),
            if (audio)
              item(
                Icons.play_arrow,
                l10n.actionPlayFromHere,
                disabled: l10n.availableFrom('M2'),
              ),
            if (audio || entry.isDir)
              item(
                Icons.playlist_play,
                l10n.actionPlayFolder,
                disabled: l10n.availableFrom('M2'),
              ),
            if (audio)
              item(
                Icons.playlist_add,
                l10n.actionQueue,
                disabled: l10n.availableFrom('M2'),
              ),
            const Divider(indent: 20, endIndent: 20),
            // Ganze Shares nicht versehentlich komplett laden.
            if (!share) ...[
              item(
                Icons.download_outlined,
                l10n.actionDownload,
                onTap: () => downloadEntries(outer, outerRef, [entry]),
              ),
              if (entry.isDir)
                item(
                  Icons.cloud_download_outlined,
                  l10n.actionOffline,
                  onTap: () => downloadEntries(outer, outerRef, [entry]),
                )
              else
                item(
                  Icons.cloud_download_outlined,
                  l10n.actionOffline,
                  trailing: Switch(
                    value: offline,
                    onChanged: (_) => toggleOffline(),
                  ),
                  onTap: toggleOffline,
                ),
            ],
            item(
              favorite ? Icons.star : Icons.star_border,
              favorite ? l10n.actionFavoriteRemove : l10n.actionFavoriteAdd,
              color: favorite ? AppColors.accent : null,
              onTap: () => ref
                  .read(localLibraryProvider)
                  .setFavorite(ref.read(serverIdProvider), entry, !favorite),
            ),
            item(
              Icons.link,
              l10n.actionShareLink,
              onTap: () => showShareLinkSheet(outer, outerRef, [entry]),
            ),
            const Divider(indent: 20, endIndent: 20),
            if (!share) ...[
              item(
                Icons.edit_outlined,
                l10n.actionRename,
                disabled: readOnly,
                onTap: () => renameEntry(outer, outerRef, entry),
              ),
              item(
                Icons.drive_file_move_outline,
                l10n.actionMove,
                disabled: readOnly,
                onTap: () =>
                    copyMoveEntries(outer, outerRef, [entry], move: true),
              ),
            ],
            item(
              Icons.copy_outlined,
              l10n.actionCopy,
              onTap: () =>
                  copyMoveEntries(outer, outerRef, [entry], move: false),
            ),
            item(
              Icons.info_outline,
              l10n.actionInfo,
              onTap: () => showEntryInfo(outer, entry),
            ),
            if (!share) ...[
              const Divider(indent: 20, endIndent: 20),
              item(
                Icons.delete_outline,
                l10n.actionDelete,
                color: AppColors.errorSoft,
                onTap: () => deleteEntries(outer, outerRef, [entry]),
              ),
            ],
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
