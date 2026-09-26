import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../browser/presentation/browser_providers.dart';
import '../../servers/presentation/server_providers.dart';
import '../domain/playback_queue.dart';
import '../domain/sleep_timer.dart';
import 'audio_widgets.dart';
import 'playback_providers.dart';

/// Screen 12: Vollbild-Player über der Shell.
class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(audioControllerProvider);
    final controller = ref.read(audioControllerProvider.notifier);
    final text = Theme.of(context).textTheme;
    final track = s.track;

    // Queue geleert (Queue-Screen, Notification): Player schließen – nur
    // wenn er oben liegt, sonst träfe pop eine andere Route.
    if (track == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
          context.pop();
        }
      });
      return const Scaffold();
    }
    // Offline-Wiedergabe geht ohne Session – dann ohne Favoriten-Stern.
    final online = ref.watch(sessionProvider) != null;
    final favorite =
        online && (ref.watch(isFavoriteProvider(track.path)).value ?? false);
    final folderSegments = (s.folder ?? '')
        .split('/')
        .where((p) => p.isNotEmpty)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.collapse,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          l10n.playingFromFolder.toUpperCase(),
                          style: text.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          folderSegments.length > 1
                              ? folderSegments
                                    .skip(folderSegments.length - 2)
                                    .join(' › ')
                              : folderSegments.join(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.queueTitle,
                    icon: const Icon(Icons.queue_music),
                    onPressed: () => context.push(queueLocation),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, box) => CoverArt(
                      info: s.info,
                      size: box.maxWidth < box.maxHeight
                          ? box.maxWidth
                          : box.maxHeight,
                      radius: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          [
                            ?s.artist,
                            ?s.info?.album,
                            l10n.trackOf(
                              s.queue.index + 1,
                              s.queue.tracks.length,
                            ),
                          ].join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (online)
                    IconButton(
                      tooltip: favorite
                          ? l10n.actionFavoriteRemove
                          : l10n.actionFavoriteAdd,
                      icon: Icon(
                        favorite ? Icons.star : Icons.star_border,
                        color: favorite ? AppColors.accent : null,
                      ),
                      onPressed: () => ref
                          .read(localLibraryProvider)
                          .setFavorite(
                            ref.read(serverIdProvider),
                            track,
                            !favorite,
                          ),
                    ),
                ],
              ),
              if (s.error case final error?)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    describePlaybackError(error, l10n),
                    key: const Key('playback-error'),
                    style: const TextStyle(color: AppColors.errorSoft),
                  ),
                ),
              const SizedBox(height: 16),
              _Progress(state: s),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: s.shuffle ? l10n.shuffleOn : l10n.shuffleOff,
                    icon: Icon(
                      Icons.shuffle,
                      color: s.shuffle ? AppColors.accent : null,
                    ),
                    onPressed: () => controller.setShuffle(!s.shuffle),
                  ),
                  IconButton(
                    tooltip: l10n.previousTrack,
                    iconSize: 36,
                    icon: const Icon(Icons.skip_previous),
                    onPressed: controller.previous,
                  ),
                  PlayPauseButton(
                    state: s,
                    onPressed: controller.togglePlay,
                    large: true,
                  ),
                  IconButton(
                    tooltip: l10n.nextTrack,
                    iconSize: 36,
                    icon: const Icon(Icons.skip_next),
                    onPressed: controller.next,
                  ),
                  IconButton(
                    tooltip: switch (s.repeat) {
                      QueueRepeat.off => l10n.repeatOff,
                      QueueRepeat.one => l10n.repeatOne,
                      QueueRepeat.all => l10n.repeatAll,
                    },
                    icon: Icon(
                      s.repeat == QueueRepeat.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                      color: s.repeat == QueueRepeat.off
                          ? null
                          : AppColors.accent,
                    ),
                    onPressed: controller.cycleRepeat,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _ChipButton(
                      icon: Icons.bolt,
                      label: l10n.speedValue(
                        NumberFormat('0.0#', l10n.localeName).format(s.speed),
                      ),
                      onPressed: () => _pickSpeed(context, ref),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _SleepButton(state: s)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ChipButton(
                      icon: Icons.queue_music,
                      label: l10n.queueButton(s.queue.tracks.length),
                      onPressed: () => context.push(queueLocation),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickSpeed(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(audioControllerProvider.notifier);
    final current = ref.read(audioControllerProvider).speed;
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(l10n.speedTitle)),
            for (final speed in AudioController.speeds)
              ListTile(
                title: Text(
                  l10n.speedValue(
                    NumberFormat('0.0#', l10n.localeName).format(speed),
                  ),
                ),
                trailing: speed == current
                    ? const Icon(Icons.check, color: AppColors.accent)
                    : null,
                onTap: () {
                  controller.setSpeed(speed);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Fortschritt mit Zeiten. Beim Ziehen läuft nur die Anzeige mit; gesprungen
/// wird erst beim Loslassen (sonst ein Range-Request je Frame).
class _Progress extends ConsumerStatefulWidget {
  const _Progress({required this.state});

  final AudioState state;

  @override
  ConsumerState<_Progress> createState() => _ProgressState();
}

class _ProgressState extends ConsumerState<_Progress> {
  Duration? _drag;

  @override
  Widget build(BuildContext context) {
    final position =
        _drag ?? ref.watch(positionProvider).value ?? Duration.zero;
    final duration = widget.state.duration ?? Duration.zero;
    final clamped = position > duration ? duration : position;
    final mono = AppTheme.mono(
      Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: AppColors.textSecondary),
    );
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: AppColors.surfaceRaised,
            thumbColor: AppColors.background,
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            key: const Key('progress'),
            max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
            value: clamped.inMilliseconds.toDouble(),
            onChanged: duration == Duration.zero
                ? null
                : (v) =>
                      setState(() => _drag = Duration(milliseconds: v.round())),
            onChangeEnd: (v) {
              setState(() => _drag = null);
              ref
                  .read(audioControllerProvider.notifier)
                  .seek(Duration(milliseconds: v.round()));
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formatDuration(clamped), style: mono),
            Text('-${formatDuration(duration - clamped)}', style: mono),
          ],
        ),
      ],
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.text;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        foregroundColor: color,
        backgroundColor: active ? AppColors.accentSurface : null,
        side: BorderSide(color: active ? AppColors.accent : AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Sleep-Timer-Knopf; die Restzeit läuft über den Positions-Stream mit.
class _SleepButton extends ConsumerWidget {
  const _SleepButton({required this.state});

  final AudioState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ref.watch(positionProvider);
    final endsAt = state.sleepEndsAt;
    final label = switch (endsAt) {
      _ when state.sleepEndOfTrack => l10n.sleepEndOfTrackShort,
      final endsAt? => l10n.sleepMinutes(
        (endsAt.difference(DateTime.now()).inSeconds / 60).ceil().clamp(1, 999),
      ),
      null => l10n.sleep,
    };
    return _ChipButton(
      key: const Key('sleep-button'),
      icon: Icons.timer_outlined,
      label: label,
      active: endsAt != null || state.sleepEndOfTrack,
      onPressed: () => _pick(context, ref),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(audioControllerProvider.notifier);
    Widget option(String label, VoidCallback onTap) => ListTile(
      title: Text(label),
      onTap: () {
        onTap();
        Navigator.of(context).pop();
      },
    );
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(l10n.sleepTitle)),
            for (final minutes in SleepTimer.presets)
              option(
                l10n.sleepOption(minutes),
                () => controller.setSleep(Duration(minutes: minutes)),
              ),
            option(l10n.sleepEndOfTrack, controller.setSleepEndOfTrack),
            option(l10n.sleepOff, () => controller.setSleep(null)),
          ],
        ),
      ),
    );
  }
}
