import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../browser/domain/nas_entry.dart';
import '../../browser/presentation/entry_widgets.dart';
import '../data/track_info_loader.dart';
import 'playback_providers.dart';

/// Route von Screen 12 (Now Playing) und 13 (Queue).
const nowPlayingLocation = '/player';
const queueLocation = '/player/queue';

/// Spielt [folder] ab [startPath] und bietet per Snackbar „Fortsetzen bei
/// mm:ss“ an, wenn für den Starttitel eine Position gespeichert ist.
Future<void> startPlayback(
  BuildContext context,
  String folder, {
  String? startPath,
  bool recursive = false,
}) async {
  // Alles vor dem ersten await holen: Aufrufer wie das Sheet 09 sind danach
  // schon geschlossen, ihr `ref`/`context` ist dann nicht mehr gültig.
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final controller = container.read(audioControllerProvider.notifier);
  void show(String text, [SnackBarAction? action]) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      // Mit Aktion bliebe die Snackbar sonst stehen, bis man sie wegwischt.
      SnackBar(content: Text(text), action: action, persist: false),
    );
  try {
    final resume = await controller.playFolder(
      folder,
      startPath: startPath,
      recursive: recursive,
    );
    if (!container.read(audioControllerProvider).active) {
      return show(l10n.noAudioInFolder);
    }
    if (resume == null) return;
    show(
      l10n.resumeAt(formatDuration(resume)),
      SnackBarAction(
        label: l10n.resumeAction,
        onPressed: () => controller.seek(resume),
      ),
    );
  } catch (e) {
    show(describePlaybackError(e, l10n));
  }
}

/// Offline-Kopie (Screen 21) im Player – ohne Netz und ohne Session.
Future<void> playOfflineAudio(
  BuildContext context,
  NasEntry entry,
  File file,
  int serverId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final controller = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(audioControllerProvider.notifier);
  try {
    final resume = await controller.playLocal(entry, file, serverId);
    if (resume == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.resumeAt(formatDuration(resume))),
          persist: false,
          action: SnackBarAction(
            label: l10n.resumeAction,
            onPressed: () => controller.seek(resume),
          ),
        ),
      );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(describePlaybackError(e, l10n))),
    );
  }
}

/// Spielt die Audiodatei [entry] im Kontext ihres Ordners.
Future<void> playAudioEntry(BuildContext context, NasEntry entry) =>
    startPlayback(context, parentPath(entry.path), startPath: entry.path);

/// Text zu Wiedergabefehlern (eigene und SynoException).
String describePlaybackError(Object error, AppLocalizations l10n) =>
    switch (error) {
      WifiRequired() => l10n.errorWifiRequired,
      NotPlayable() => l10n.errorNotPlayable,
      StreamFailed() => l10n.errorStreamFailed,
      _ => describeError(error, l10n),
    };

/// Cover oder Platzhalter (zweifarbige Fläche wie in den Mockups).
class CoverArt extends StatelessWidget {
  const CoverArt({super.key, this.info, required this.size, this.radius = 12});

  final TrackInfo? info;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cover = info?.cover;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.square(
        dimension: size,
        child: cover != null
            ? Image.file(
                cover,
                fit: BoxFit.cover,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                errorBuilder: (_, _, _) => const _Placeholder(),
              )
            : const _Placeholder(),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  // stretch: ColoredBox ohne Kind hätte sonst die Breite 0.
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(flex: 58, child: ColoredBox(color: AppColors.coverTop)),
      Expanded(flex: 42, child: ColoredBox(color: AppColors.coverBottom)),
    ],
  );
}

/// Mini-Player in der Shell (64 px): Fortschritt, Cover, Titel, Play/Pause,
/// Weiter. Tippen öffnet Now Playing.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(audioControllerProvider);
    final controller = ref.read(audioControllerProvider.notifier);
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final duration = s.duration;
    final progress = duration == null || duration == Duration.zero
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      child: InkWell(
        key: const Key('mini-player'),
        onTap: () => context.push(nowPlayingLocation),
        child: SizedBox(
          height: 64,
          child: Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                color: AppColors.accent,
                backgroundColor: Colors.transparent,
              ),
              Expanded(
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    CoverArt(info: s.info, size: 44, radius: 10),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            [
                              ?s.artist,
                              if (duration != null)
                                '${formatDuration(position)} / ${formatDuration(duration)}',
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PlayPauseButton(state: s, onPressed: controller.togglePlay),
                    IconButton(
                      tooltip: l10n.nextTrack,
                      icon: const Icon(Icons.skip_next),
                      onPressed: controller.next,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Play/Pause mit Ladeanzeige; [large] ist der runde Knopf in Screen 12.
class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({
    super.key,
    required this.state,
    required this.onPressed,
    this.large = false,
  });

  final AudioState state;
  final VoidCallback onPressed;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final icon = state.loading
        ? SizedBox.square(
            dimension: large ? 32 : 20,
            child: const CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Icon(
            state.playing ? Icons.pause : Icons.play_arrow,
            size: large ? 40 : null,
          );
    final tooltip = state.playing ? l10n.pause : l10n.play;
    if (!large) {
      return IconButton(
        key: const Key('play-pause'),
        tooltip: tooltip,
        icon: icon,
        onPressed: onPressed,
      );
    }
    return Tooltip(
      message: tooltip,
      child: Material(
        key: const Key('play-pause'),
        color: AppColors.accentStrong,
        shape: const CircleBorder(),
        elevation: 8,
        shadowColor: AppColors.accent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 76,
            child: Center(
              child: IconTheme.merge(
                data: const IconThemeData(color: AppColors.text),
                child: icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// „Zur Queue hinzufügen“ mit Rückmeldung; startet, wenn nichts läuft.
Future<void> enqueueEntry(BuildContext context, NasEntry entry) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final controller = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(audioControllerProvider.notifier);
  String message;
  try {
    await controller.enqueue(entry);
    message = l10n.queueAdded;
  } catch (e) {
    message = describePlaybackError(e, l10n);
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Hörbuch-Modus eines Ordners (Sheet 09): merkt Titel und Position.
class AudiobookSwitch extends ConsumerWidget {
  const AudiobookSwitch({super.key, required this.folder});

  final String folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final on = ref.watch(isAudiobookProvider(folder)).value ?? false;
    return SwitchListTile(
      key: const Key('audiobook-mode'),
      secondary: const Icon(Icons.menu_book_outlined),
      title: Text(l10n.audiobookMode),
      subtitle: Text(l10n.audiobookModeHint),
      value: on,
      onChanged: (value) => ref
          .read(audioControllerProvider.notifier)
          .setAudiobook(folder, value),
    );
  }
}

/// „Ordner abspielen“ im Kopf von Screen 06 (ohne Unterordner).
class PlayFolderChip extends ConsumerWidget {
  const PlayFolderChip({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return TextButton.icon(
      key: const Key('play-folder'),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 44),
        foregroundColor: AppColors.accent,
        backgroundColor: AppColors.accentSurface,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: const StadiumBorder(),
      ),
      icon: const Icon(Icons.play_arrow),
      label: Text(l10n.playFolder, overflow: TextOverflow.ellipsis),
      onPressed: () => startPlayback(context, path),
    );
  }
}
