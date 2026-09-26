import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/nas_entry.dart';
import '../domain/recycle.dart';
import 'browser_providers.dart';
import 'entry_widgets.dart';
import 'file_actions.dart';

/// Screen 24: `#recycle` je Share. Nur Shares, deren Papierkorb sich listen
/// lässt. Wiederherstellen = Verschieben an den Ursprungspfad; endgültig
/// löschen und „Leeren“ mit roter Bestätigung.
class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  String? _share;

  /// Unterordner im Papierkorb; `null` = oberste Ebene.
  String? _path;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final shares = ref.watch(sharesProvider).value ?? const <NasEntry>[];
    final bins = {
      for (final s in shares) s: ref.watch(recycleBinProvider(s.path)),
    };
    final loading =
        !ref.watch(sharesProvider).hasValue ||
        bins.values.any((b) => b.isLoading);
    final available = [
      for (final MapEntry(:key, :value) in bins.entries)
        if (value.value == RecycleBin.available) key.path,
    ];
    final hidden = [
      for (final MapEntry(:key, :value) in bins.entries)
        if (value.value == RecycleBin.unknown) key.name,
    ];
    final share = available.contains(_share) ? _share : available.firstOrNull;
    final root = share == null ? null : recycleFolder(share);
    final folder = _path ?? root;
    final entries = folder == null ? null : ref.watch(folderProvider(folder));

    return PopScope(
      canPop: _path == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _path = _up(_path!, root!));
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.trashTitle,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          actions: [
            if (root != null &&
                (ref.watch(folderProvider(root)).value?.entries.isNotEmpty ??
                    false))
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorSoft,
                ),
                onPressed: () => _empty(root),
                child: Text(l10n.trashEmptyAction),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            if (available.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in available)
                    ChoiceChip(
                      showCheckmark: false,
                      label: Text(s.substring(1)),
                      selected: s == share,
                      onSelected: (_) => setState(() {
                        _share = s;
                        _path = null;
                      }),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      [
                        if (loading)
                          l10n.trashChecking
                        else if (available.isEmpty)
                          l10n.trashNone
                        else
                          l10n.trashInfo,
                        if (hidden.isNotEmpty)
                          l10n.trashHidden(hidden.join(', ')),
                      ].join(' '),
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            if (_path case final path?)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.arrow_upward),
                title: Text(
                  restorePathOf(path)!.substring(1),
                  style: AppTheme.mono(),
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => setState(() => _path = _up(path, root!)),
              ),
            ...switch (entries) {
              null => const <Widget>[],
              AsyncData(:final value) when value.entries.isEmpty => [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(l10n.trashIsEmpty)),
                ),
              ],
              AsyncData(:final value) => [
                for (final e in value.entries)
                  _TrashRow(
                    entry: e,
                    onOpen: e.isDir
                        ? () => setState(() => _path = e.path)
                        : null,
                    onRestore: () => _restore(e, share!),
                    onDelete: () => _deleteForever([e], folder!),
                  ),
              ],
              AsyncError(:final error) => [
                ErrorPanel(
                  error: error,
                  onRetry: () => ref.invalidate(folderProvider(folder!)),
                ),
              ],
              _ => [
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            },
            const SizedBox(height: 24),
            Text(
              l10n.trashFooter,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  static String? _up(String path, String root) {
    final parent = parentPath(path);
    return parent == root ? null : parent;
  }

  Future<void> _restore(NasEntry e, String share) async {
    final l10n = AppLocalizations.of(context);
    final api = ref.read(fileOpsApiProvider);
    final dest = parentPath(restorePathOf(e.path)!);
    try {
      // Ursprungsordner kann inzwischen fehlen (selbst gelöscht).
      if (dest != share) {
        await api.createFolder(
          parentPath(dest),
          dest.substring(dest.lastIndexOf('/') + 1),
          forceParent: true,
        );
      }
    } catch (e) {
      if (mounted) showSnack(context, describeError(e, l10n));
      return;
    }
    if (!mounted) return;
    final done = await runWithProgress(
      context,
      l10n.restoring,
      pollTask(
        start: () => api.copyMoveStart([e.path], dest, move: true),
        status: api.copyMoveStatus,
        stop: api.copyMoveStop,
      ),
    );
    refreshFolders(ref, [parentPath(e.path), dest]);
    if (done && mounted) showSnack(context, l10n.restored(dest.substring(1)));
  }

  /// Zweite, rote Bestätigung (CONCEPT.md 8).
  Future<void> _deleteForever(List<NasEntry> entries, String folder) async {
    final l10n = AppLocalizations.of(context);
    final api = ref.read(fileOpsApiProvider);
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.errorSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.error),
        ),
        icon: Icon(Icons.delete_forever, color: AppColors.errorSoft),
        title: Text(
          l10n.deleteForeverTitle,
          style: TextStyle(color: AppColors.errorSoft),
        ),
        content: Text(
          entries.length == 1
              ? l10n.deleteForeverOne(entries.single.name)
              : l10n.deleteForeverMany(entries.length),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.text,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteForever),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final paths = [for (final e in entries) e.path];
    await runWithProgress(
      context,
      l10n.deleting(entries.length),
      pollTask(
        start: () => api.deleteStart(paths),
        status: api.deleteStatus,
        stop: api.deleteStop,
      ),
    );
    refreshFolders(ref, [folder]);
  }

  Future<void> _empty(String root) async {
    final entries = ref.read(folderProvider(root)).value?.entries;
    if (entries == null || entries.isEmpty) return;
    // ponytail: leert nur die geladenen Einträge (erste 500); bei mehr
    // bleibt der Rest für einen zweiten Durchgang.
    await _deleteForever(entries, root);
  }
}

class _TrashRow extends StatelessWidget {
  const _TrashRow({
    required this.entry,
    required this.onOpen,
    required this.onRestore,
    required this.onDelete,
  });

  final NasEntry entry;
  final VoidCallback? onOpen;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final origin = parentPath(restorePathOf(entry.path)!);
    final deleted = entry.ctime ?? entry.mtime;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: EntryIcon(entry),
      title: Text(entry.name, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          l10n.trashFrom(origin.substring(origin.lastIndexOf('/') + 1)),
          if (deleted != null) l10n.trashDeleted(formatRelative(deleted, l10n)),
          if (entry.size case final size?) formatSize(size, l10n.localeName),
        ].join(' · '),
        style: TextStyle(color: AppColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.restore,
            icon: const Icon(Icons.restore, color: AppColors.accent),
            onPressed: onRestore,
          ),
          IconButton(
            tooltip: l10n.deleteForever,
            icon: Icon(Icons.delete_outline, color: AppColors.errorSoft),
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: onOpen,
    );
  }
}
