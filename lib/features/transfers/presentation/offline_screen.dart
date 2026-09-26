import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/share_origin.dart';
import '../../../l10n/app_localizations.dart';
import '../../browser/domain/nas_entry.dart';
import '../../browser/presentation/entry_widgets.dart';
import '../../browser/presentation/file_actions.dart';
import '../../viewers/presentation/viewer_screen.dart';
import 'transfer_providers.dart';

/// Screen 21: Offline-Dateien nach Ordner gruppiert, Speicherbalken,
/// Entfernen („Bearbeiten“). Öffnen immer lokal; mit Verbindung wird die
/// mtime auf dem NAS verglichen.
class OfflineScreen extends ConsumerStatefulWidget {
  const OfflineScreen({super.key});

  @override
  ConsumerState<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends ConsumerState<OfflineScreen> {
  var _editing = false;
  final _expanded = <String>{};

  /// Zeilen je Gruppe, bevor „+ n weitere“ erscheint.
  static const _collapsed = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final files = ref.watch(offlineFilesProvider).value ?? const [];
    final changed = ref.watch(offlineChangedProvider).value ?? const {};
    final groups = <String, List<OfflineFile>>{};
    for (final f in files) {
      groups
          .putIfAbsent('${f.serverId}:${parentPath(f.remotePath)}', () => [])
          .add(f);
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Text(
          l10n.tabOffline,
          style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (files.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _editing = !_editing),
              child: Text(_editing ? l10n.done : l10n.edit),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const _StorageCard(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_done_outlined, color: AppColors.success),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    files.isEmpty ? l10n.offlineEmpty : l10n.offlineInfo,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          for (final MapEntry(key: key, value: group) in groups.entries) ...[
            const SizedBox(height: 16),
            _GroupHeader(
              folder: parentPath(group.first.remotePath),
              bytes: group.fold(0, (s, f) => s + f.size),
              onRemove: _editing ? () => _remove(group) : null,
            ),
            for (final f
                in _expanded.contains(key) ? group : group.take(_collapsed))
              _FileRow(
                file: f,
                changed: changed[f.remotePath],
                onRemove: _editing ? () => _remove([f]) : null,
              ),
            if (!_expanded.contains(key) && group.length > _collapsed)
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _expanded.add(key)),
                    child: Text(l10n.moreItems(group.length - _collapsed)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _remove(List<OfflineFile> files) async {
    final store = ref.read(offlineStoreProvider);
    for (final f in files) {
      await store.remove(f.serverId, f.remotePath);
    }
  }
}

class _StorageCard extends ConsumerWidget {
  const _StorageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final usage = ref.watch(storageUsageProvider).value;
    final offline = usage?.offline ?? 0;
    final cache = usage?.cache ?? 0;
    final total = offline + cache;
    Widget legend(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textMuted),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.storageUsed,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(formatSize(total, locale), style: AppTheme.mono()),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (offline > 0)
                    Expanded(
                      flex: offline,
                      child: const ColoredBox(color: AppColors.accent),
                    ),
                  if (cache > 0)
                    Expanded(
                      flex: cache,
                      child: const ColoredBox(color: AppColors.info),
                    ),
                  if (total == 0)
                    const Expanded(child: ColoredBox(color: AppColors.border)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 4,
            children: [
              legend(
                AppColors.accent,
                l10n.storageOffline(formatSize(offline, locale)),
              ),
              legend(
                AppColors.info,
                l10n.storageCache(formatSize(cache, locale)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.folder,
    required this.bytes,
    required this.onRemove,
  });

  final String folder;
  final int bytes;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        const Icon(Icons.folder_outlined, color: AppColors.accent),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            folder.substring(1).replaceAll('/', ' / '),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        Text(
          formatSize(bytes, l10n.localeName),
          style: AppTheme.mono(const TextStyle(color: AppColors.textSecondary)),
        ),
        if (onRemove != null)
          IconButton(
            tooltip: l10n.offlineRemove,
            icon: const Icon(Icons.delete_outline, color: AppColors.errorSoft),
            onPressed: onRemove,
          ),
      ],
    );
  }
}

class _FileRow extends ConsumerWidget {
  const _FileRow({
    required this.file,
    required this.changed,
    required this.onRemove,
  });

  final OfflineFile file;

  /// Neue Änderungszeit auf dem NAS, falls die Datei dort geändert wurde.
  final DateTime? changed;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = file.remotePath.substring(
      file.remotePath.lastIndexOf('/') + 1,
    );
    final type = NasFileType.fromName(name);
    final changed = this.changed;
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 24, right: 0),
      leading: Icon(typeIcon(type), color: typeColor(type)),
      title: Text(name, overflow: TextOverflow.ellipsis),
      subtitle: changed == null
          ? null
          : InkWell(
              onTap: () => _update(context, ref, changed),
              child: Text(
                l10n.offlineChanged,
                style: const TextStyle(color: AppColors.errorSoft),
              ),
            ),
      trailing: onRemove != null
          ? IconButton(
              tooltip: l10n.offlineRemove,
              icon: const Icon(
                Icons.remove_circle_outline,
                color: AppColors.errorSoft,
              ),
              onPressed: onRemove,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatSize(file.size, l10n.localeName),
                  style: AppTheme.mono(
                    const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                // System-Share-Sheet: „In Dateien sichern“, Downloads usw.
                Builder(
                  builder: (button) => IconButton(
                    tooltip: l10n.export,
                    icon: const Icon(Icons.ios_share),
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(file.localPath)],
                        sharePositionOrigin: shareOrigin(button),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      onTap: () async {
        if (!await openOffline(context, file) && context.mounted) {
          showSnack(context, l10n.openFailed);
        }
      },
    );
  }

  /// Lädt die geänderte Datei neu herunter (ersetzt die lokale Kopie).
  Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    DateTime mtime,
  ) async {
    await ref
        .read(transferQueueProvider)
        .enqueueDownload(
          remotePath: file.remotePath,
          localPath: file.localPath,
          mtime: mtime,
        );
    if (context.mounted) {
      showSnack(context, AppLocalizations.of(context).downloadsQueued(1));
    }
  }
}
