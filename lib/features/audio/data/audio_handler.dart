import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../../l10n/app_localizations.dart';

/// Brücke zwischen just_audio und dem Betriebssystem (Android-Foreground-
/// Service mit Notification, iOS Now Playing, Sperrbildschirm, Bluetooth,
/// Kopfhörertasten). Queue-Logik liegt im AudioController; Vor/Zurück/Stop
/// leitet der Handler über [onSkipToNext] usw. dorthin weiter.
class AppAudioHandler extends BaseAudioHandler with SeekHandler {
  AppAudioHandler({AudioPlayer? player}) : player = player ?? AudioPlayer() {
    this.player.playbackEventStream.listen(
      (_) => _broadcast(),
      onError: (Object _) => _broadcast(),
    );
    this.player.playingStream.listen((_) => _broadcast());
    this.player.speedStream.listen((_) => _broadcast());
  }

  final AudioPlayer player;

  /// Play von außen (Sperrbildschirm, Bluetooth, Kopfhörer) läuft über den
  /// Controller, damit dort WLAN-Regel und Session geprüft werden.
  Future<void> Function()? onPlay;
  Future<void> Function()? onSkipToNext;
  Future<void> Function()? onSkipToPrevious;
  Future<void> Function()? onStop;

  /// Einmal beim App-Start (vor `runApp`).
  static Future<AppAudioHandler> init() {
    final l10n = lookupAppLocalizations(
      AppLocalizations.supportedLocales.firstWhere(
        (l) =>
            l.languageCode == PlatformDispatcher.instance.locale.languageCode,
        orElse: () => const Locale('de'),
      ),
    );
    return AudioService.init(
      builder: () => AppAudioHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'de.jw29435.nuvo_explorer.audio',
        androidNotificationChannelName: l10n.audioChannelName,
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  }

  @override
  Future<void> play() => onPlay?.call() ?? player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToNext() async => onSkipToNext?.call();

  @override
  Future<void> skipToPrevious() async => onSkipToPrevious?.call();

  @override
  Future<void> stop() async {
    await onStop?.call();
    await super.stop();
  }

  void _broadcast() {
    final playing = player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: switch (player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: playing,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
      ),
    );
  }
}
