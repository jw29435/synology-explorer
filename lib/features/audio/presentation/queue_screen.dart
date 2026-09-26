import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/playback_queue.dart';
import 'audio_widgets.dart';
import 'playback_providers.dart';

/// Screen 13: aktueller Titel und „Als Nächstes“ mit Drag-Reorder,
/// Wischen/× zum Entfernen und „Leeren“.
class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(audioControllerProvider);
    final controller = ref.read(audioControllerProvider.notifier);
    final text = Theme.of(context).textTheme;
    final queue = s.queue;
    final current = queue.current;
    final first = queue.index + 1;
    final upcoming = queue.isEmpty ? 0 : queue.tracks.length - first;
    final label = text.labelLarge?.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.collapse,
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.queueTitle),
        actions: [
          TextButton(
            onPressed: queue.isEmpty
                ? null
                : () {
                    controller.clear();
                    context.pop();
                  },
            child: Text(l10n.queueClear),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (current != null)
            Container(
              key: const Key('queue-current'),
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentSurface,
                border: Border.all(color: AppColors.accent),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CoverArt(info: s.info, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.queueNowPlaying.toUpperCase(),
                          style: text.labelMedium?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          [
                            ?s.artist,
                            if (s.duration case final d?) formatDuration(d),
                          ].join(' · '),
                          style: text.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.graphic_eq, color: AppColors.accent),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.queueUpNext(upcoming).toUpperCase(),
                    style: label,
                  ),
                ),
                Text(
                  [
                    if (s.shuffle) l10n.shuffleSummary,
                    switch (s.repeat) {
                      QueueRepeat.off => l10n.repeatSummaryOff,
                      QueueRepeat.one => l10n.repeatSummaryOne,
                      QueueRepeat.all => l10n.repeatSummaryAll,
                    },
                  ].join(' · '),
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: upcoming,
              // Indizes der Liste sind relativ zum ersten kommenden Titel.
              onReorderItem: (from, to) =>
                  controller.move(first + from, first + to),
              itemBuilder: (context, i) {
                final index = first + i;
                final track = queue.tracks[index];
                return Dismissible(
                  key: ValueKey('${track.path}#$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: AppColors.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete_outline),
                  ),
                  onDismissed: (_) => controller.removeAt(index),
                  child: ListTile(
                    contentPadding: const EdgeInsets.only(left: 20, right: 4),
                    minVerticalPadding: 10,
                    leading: SizedBox(
                      width: 28,
                      child: Text(
                        '${index + 1}',
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    title: Text(
                      trackName(track.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      [
                        folderName(track.path),
                        if (track.size case final size?)
                          formatSize(size, l10n.localeName),
                      ].join(' · '),
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    onTap: () => controller.jumpTo(index),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.queueRemove,
                          icon: const Icon(Icons.close),
                          onPressed: () => controller.removeAt(index),
                        ),
                        ReorderableDragStartListener(
                          index: i,
                          child: const SizedBox.square(
                            dimension: 48,
                            child: Icon(Icons.drag_handle),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              l10n.queueHint(queue.isEmpty ? 0 : queue.index),
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
