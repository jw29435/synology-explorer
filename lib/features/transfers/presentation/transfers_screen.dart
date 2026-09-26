import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../../app/theme.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../browser/domain/nas_entry.dart';
import '../../browser/presentation/entry_widgets.dart';
import '../domain/transfer.dart';
import 'transfer_providers.dart';

/// Text zu einem Fehler aus `transfers.error` (siehe [transferErrorTag]).
String describeTransferError(String? tag, AppLocalizations l10n) {
  final [name, ...rest] = (tag ?? '').split(':');
  final code = int.tryParse(rest.firstOrNull ?? '');
  return switch (name) {
    'SynoNetworkError' when code != null => l10n.errorHttp(code),
    'SynoNetworkError' => l10n.errorNetwork,
    'SynoSessionExpired' => l10n.errorSessionExpired,
    'SynoUnauthorized' => l10n.errorUnauthorized,
    'SynoAccountLocked' => l10n.errorAccountLocked,
    'SynoPermissionDenied' => l10n.errorPermission,
    'SynoNotFound' => l10n.errorNotFound,
    'SynoAlreadyExists' => l10n.errorExists,
    'SynoUnknown' when code != null => l10n.errorCode(code),
    'local' => l10n.errorLocalFile,
    _ => l10n.errorGeneric,
  };
}

/// Screen 20: Transfers mit Tabs Aktiv/Fertig.
class TransfersScreen extends ConsumerStatefulWidget {
  const TransfersScreen({super.key});

  @override
  ConsumerState<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends ConsumerState<TransfersScreen> {
  var _showDone = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final queue = ref.watch(transferQueueProvider);
    final all = ref.watch(transfersProvider).value ?? const <Transfer>[];
    final done = [
      for (final t in all.reversed)
        if (t.state == TransferState.done) t,
    ];
    final active = [
      for (final t in all)
        if (t.state != TransferState.done) t,
    ];
    final shown = _showDone ? done : active;
    final canPauseAll = active.any(
      (t) =>
          t.state == TransferState.queued || t.state == TransferState.running,
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Text(
          l10n.tabTransfers,
          style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_showDone && done.isNotEmpty)
            TextButton(onPressed: queue.clearDone, child: Text(l10n.clearList))
          else if (!_showDone && canPauseAll)
            TextButton(onPressed: queue.pauseAll, child: Text(l10n.pauseAll)),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Row(
            children: [
              ChoiceChip(
                showCheckmark: false,
                label: Text(l10n.transfersActive(active.length)),
                selected: !_showDone,
                onSelected: (_) => setState(() => _showDone = false),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                showCheckmark: false,
                label: Text(l10n.transfersDone(done.length)),
                selected: _showDone,
                onSelected: (_) => setState(() => _showDone = true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  _showDone ? l10n.transfersNoneDone : l10n.transfersNone,
                ),
              ),
            ),
          for (final t in shown)
            _showDone ? _DoneRow(transfer: t) : _TransferCard(transfer: t),
          if (!_showDone)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                l10n.transfersFooter,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

String _name(String path) => path.substring(path.lastIndexOf('/') + 1);

class _TransferCard extends ConsumerWidget {
  const _TransferCard({required this.transfer});

  final Transfer transfer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final queue = ref.read(transferQueueProvider);
    final t = transfer;
    final download = t.kind == TransferKind.download;
    final failed = t.state == TransferState.failed;
    final total = t.bytesTotal;
    final progress = total == null || total == 0 ? null : t.bytesDone / total;
    final color = failed || t.state == TransferState.paused
        ? AppColors.textMuted
        : download
        ? AppColors.accent
        : AppColors.success;
    final amount = total == null
        ? formatSize(t.bytesDone, locale)
        : l10n.bytesOf(
            formatSize(t.bytesDone, locale),
            formatSize(total, locale),
          );
    final target = download
        ? l10n.transferToOffline
        : l10n.transferToFolder(parentPath(t.remotePath).substring(1));
    final subtitle = switch (t.state) {
      TransferState.failed => l10n.transferFailed(
        describeTransferError(t.error, l10n),
      ),
      TransferState.paused => '${l10n.transferPaused} · $amount',
      TransferState.queued => '$target · ${l10n.transferQueued}',
      _ => '$target · $amount',
    };
    final speed = queue.speedOf(t.id);
    final right = switch (t.state) {
      TransferState.running when speed != null && speed > 0 => [
        '${formatSize(speed.round(), locale)}/s',
        if (total != null)
          l10n.remaining(
            formatRemaining(((total - t.bytesDone) / speed).round(), l10n),
          ),
      ].join(' · '),
      TransferState.failed || TransferState.paused
          when download && t.bytesDone > 0 =>
        l10n.resumesWithRange,
      _ => '',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: failed ? AppColors.error : AppColors.textMuted,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.background,
                child: Icon(
                  failed
                      ? Icons.error_outline
                      : download
                      ? Icons.download
                      : Icons.upload,
                  color: failed
                      ? AppColors.errorSoft
                      : download
                      ? AppColors.info
                      : AppColors.success,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name(t.remotePath),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: failed
                            ? AppColors.errorSoft
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (failed)
                OutlinedButton(
                  onPressed: () => queue.retry(t.id),
                  child: Text(l10n.retry),
                )
              else if (t.state == TransferState.paused)
                IconButton(
                  tooltip: l10n.resume,
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => queue.retry(t.id),
                )
              else
                IconButton(
                  tooltip: l10n.pause,
                  icon: const Icon(Icons.pause),
                  onPressed: () => queue.pause(t.id),
                ),
              IconButton(
                tooltip: l10n.cancel,
                icon: const Icon(Icons.close),
                onPressed: () => queue.cancel(t.id),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: LinearProgressIndicator(
              value: progress ?? (t.state == TransferState.running ? null : 0),
              color: color,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      if (progress != null) '${(progress * 100).floor()} %',
                      if (failed) amount,
                    ].join(' · '),
                    style: AppTheme.mono(
                      const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    right,
                    textAlign: TextAlign.end,
                    style: AppTheme.mono(
                      const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// „8 s“, „3 min“, „2 h“.
String formatRemaining(int seconds, AppLocalizations l10n) => seconds < 60
    ? l10n.durationSeconds(seconds)
    : seconds < 3600
    ? l10n.durationMinutes((seconds / 60).ceil())
    : l10n.durationHours((seconds / 3600).ceil());

class _DoneRow extends StatelessWidget {
  const _DoneRow({required this.transfer});

  final Transfer transfer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = transfer;
    final download = t.kind == TransferKind.download;
    final type = NasFileType.fromName(t.remotePath);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(typeIcon(type), color: typeColor(type)),
      title: Text(_name(t.remotePath), overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          download
              ? l10n.transferToOffline
              : l10n.transferToFolder(parentPath(t.remotePath).substring(1)),
          if (t.bytesTotal case final size?) formatSize(size, l10n.localeName),
        ].join(' · '),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        download ? Icons.download_done : Icons.cloud_done_outlined,
        color: AppColors.success,
      ),
      onTap: download ? () => OpenFilex.open(t.localPath) : null,
    );
  }
}
