import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../../../app/theme.dart';
import '../../../core/network/media_proxy.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/utils/format.dart';
import '../../../l10n/app_localizations.dart';
import '../../browser/domain/nas_entry.dart';
import '../../browser/presentation/browser_providers.dart';
import '../data/playback_position_repository.dart';
import 'viewer_common.dart';
import 'viewer_providers.dart';

/// Screen 16: Streaming mit media_kit (Seek per HTTP-Range) im
/// Landscape-Vollbild. Doppeltipp ±10 s, Wischen rechts Lautstärke, links
/// Helligkeit; Position wie bei Audio alle 5 s und bei Pause gespeichert.
class VideoPlayerScreen extends ConsumerStatefulWidget {
  const VideoPlayerScreen({super.key, required this.entry, this.local});

  final NasEntry entry;

  /// Offline-Kopie: direkt aus der Datei, ohne Proxy und Session.
  final LocalFile? local;

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  static const _skip = Duration(seconds: 10);

  final _player = Player();
  late final _video = VideoController(_player);
  late final PlaybackPositionRepository _positions;
  final _subscriptions = <StreamSubscription<Object?>>[];
  Timer? _saveTimer;
  Timer? _hideTimer;

  /// Gespeicherte Position, bei der die Wiedergabe begonnen hat; solange
  /// gesetzt, steht der Hinweis „Bei mm:ss fortsetzen?“ im Bild.
  Duration? _resumedAt;
  bool _controls = true;
  bool _error = false;

  /// Liefert dem Player die Bytes; die SID steht nie in seiner URL.
  MediaProxy? _proxy;
  bool _landscape = true;
  double? _seeking;
  double? _doubleTapX;

  /// Beim Wischen: Lautstärke bzw. Helligkeit (0…1) für die Anzeige.
  ({bool volume, double value})? _gesture;
  double _brightness = 0.5;

  @override
  void initState() {
    super.initState();
    _positions = PlaybackPositionRepository(
      ref.read(appDatabaseProvider),
      widget.local?.serverId ?? ref.read(serverIdProvider),
    );
    _setLandscape(true);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    ScreenBrightness.instance.application.then((b) => _brightness = b);
    // Ein setState für alle Player-Änderungen; gelesen wird player.state.
    final s = _player.stream;
    for (final stream in <Stream<Object?>>[
      s.playing,
      s.position,
      s.duration,
      s.buffer,
      s.rate,
      s.tracks,
      s.track,
      s.height,
    ]) {
      _subscriptions.add(stream.listen((_) => _refresh()));
    }
    _subscriptions
      ..add(
        s.playing.listen((playing) {
          if (!playing) unawaited(_savePosition());
          _scheduleHide();
        }),
      )
      ..add(
        s.completed.listen((done) {
          if (done) unawaited(_positions.clear(widget.entry));
        }),
      )
      // Nur solange nichts läuft: sonst sind es meist harmlose Meldungen.
      ..add(
        s.error.listen((_) {
          if (_player.state.duration == Duration.zero) {
            setState(() => _error = true);
          }
        }),
      );
    _start();
  }

  Future<void> _start() async {
    final Duration? saved;
    try {
      saved = await _positions.load(widget.entry);
      if (!mounted) return;
      if (widget.local case final local?) {
        await _player.open(Media(local.file.path, start: saved));
      } else {
        final proxy = await ref
            .read(mediaRepositoryProvider)
            .stream(widget.entry);
        if (!mounted) {
          unawaited(proxy.close());
          return;
        }
        _proxy = proxy;
        await _player.open(Media(proxy.url.toString(), start: saved));
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
      return;
    }
    if (!mounted) return;
    setState(() => _resumedAt = saved);
    _saveTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _savePosition(),
    );
  }

  /// Merkt die Position; am Anfang und kurz vor Schluss gibt es nichts
  /// fortzusetzen.
  Future<void> _savePosition() {
    final position = _player.state.position;
    final duration = _player.state.duration;
    if (duration == Duration.zero) return Future.value();
    return PlaybackPositionRepository.worthKeeping(position, duration)
        ? _positions.save(widget.entry, position)
        : _positions.clear(widget.entry);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _setLandscape(bool landscape) {
    _landscape = landscape;
    SystemChrome.setPreferredOrientations(
      landscape
          ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : [DeviceOrientation.portraitUp],
    );
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!_controls || !_player.state.playing) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _player.state.playing) setState(() => _controls = false);
    });
  }

  void _toggleControls() {
    setState(() => _controls = !_controls);
    _scheduleHide();
  }

  void _seekBy(Duration delta) {
    final target = _player.state.position + delta;
    final end = _player.state.duration;
    _player.seek(
      target < Duration.zero
          ? Duration.zero
          : (end > Duration.zero && target > end ? end : target),
    );
    _scheduleHide();
  }

  void _drag(DragUpdateDetails d, BoxConstraints box) {
    final volume = d.localPosition.dx > box.maxWidth / 2;
    final delta = -d.delta.dy / (box.maxHeight * 0.8);
    if (volume) {
      final v = (_player.state.volume / 100 + delta).clamp(0.0, 1.0);
      _player.setVolume(v * 100);
      setState(() => _gesture = (volume: true, value: v));
    } else {
      _brightness = (_brightness + delta).clamp(0.0, 1.0);
      ScreenBrightness.instance.setApplicationScreenBrightness(_brightness);
      setState(() => _gesture = (volume: false, value: _brightness));
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _saveTimer?.cancel();
    unawaited(_savePosition());
    for (final s in _subscriptions) {
      s.cancel();
    }
    _player.dispose().whenComplete(() => _proxy?.close());
    SystemChrome.setPreferredOrientations([]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    ScreenBrightness.instance.resetApplicationScreenBrightness();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = _player.state;
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, box) => Stack(
          fit: StackFit.expand,
          children: [
            Video(controller: _video, controls: NoVideoControls),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleControls,
              onDoubleTapDown: (d) => _doubleTapX = d.localPosition.dx,
              onDoubleTap: () => _seekBy(
                (_doubleTapX ?? 0) < box.maxWidth / 2 ? -_skip : _skip,
              ),
              onVerticalDragUpdate: (d) => _drag(d, box),
              onVerticalDragEnd: (_) => setState(() => _gesture = null),
            ),
            if (_error)
              Center(
                child: _Pill(
                  icon: Icons.error_outline,
                  text: l10n.videoUnavailable,
                ),
              ),
            if (_gesture case (:final volume, :final value))
              Center(
                child: _Pill(
                  icon: volume ? Icons.volume_up : Icons.brightness_6,
                  text: volume
                      ? l10n.volumePercent('${(value * 100).round()}')
                      : l10n.brightnessPercent('${(value * 100).round()}'),
                ),
              ),
            if (_controls) ...[
              _topBar(context, l10n, state),
              _centerControls(l10n, state),
              Align(
                alignment: Alignment.bottomCenter,
                child: _bottomBar(context, l10n, state),
              ),
            ],
            if (_resumedAt case final at?)
              Align(
                alignment: const Alignment(0, -0.55),
                child: _ResumeCard(
                  at: at,
                  onResume: () => setState(() => _resumedAt = null),
                  onRestart: () {
                    _player.seek(Duration.zero);
                    setState(() => _resumedAt = null);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, AppLocalizations l10n, PlayerState s) {
    final subtitles = s.tracks.subtitle
        .where((t) => t.id != 'auto' && t.id != 'no')
        .toList();
    final subtitlesOn = s.track.subtitle.id != 'no';
    final info = [
      if (s.height case final h? when h > 0) '${h}p',
      if (widget.entry.size case final size?) formatSize(size, l10n.localeName),
    ].join(' · ');
    return Align(
      alignment: Alignment.topCenter,
      child: ColoredBox(
        color: AppColors.playScrim,
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              const BackButton(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.entry.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (info.isNotEmpty)
                      Text(
                        info,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              if (subtitles.isNotEmpty)
                IconButton(
                  tooltip: l10n.subtitles,
                  isSelected: subtitlesOn,
                  icon: const Icon(Icons.subtitles_off_outlined),
                  selectedIcon: const Icon(Icons.subtitles),
                  onPressed: () => _player.setSubtitleTrack(
                    subtitlesOn ? SubtitleTrack.no() : subtitles.first,
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _centerControls(AppLocalizations l10n, PlayerState s) {
    Widget round(
      IconData icon,
      String tooltip,
      VoidCallback onPressed, {
      double size = 56,
    }) => IconButton(
      tooltip: tooltip,
      iconSize: size * 0.5,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.playScrim,
        fixedSize: Size.square(size),
      ),
      icon: Icon(icon),
      onPressed: onPressed,
    );
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          round(Icons.replay_10, l10n.rewind10, () => _seekBy(-_skip)),
          const SizedBox(width: 40),
          round(
            s.playing ? Icons.pause : Icons.play_arrow,
            s.playing ? l10n.pause : l10n.play,
            _player.playOrPause,
            size: 76,
          ),
          const SizedBox(width: 40),
          round(Icons.forward_10, l10n.forward10, () => _seekBy(_skip)),
        ],
      ),
    );
  }

  Widget _bottomBar(
    BuildContext context,
    AppLocalizations l10n,
    PlayerState s,
  ) {
    final total = s.duration.inMilliseconds.toDouble();
    final max = total > 0 ? total : 1.0;
    final position =
        _seeking ?? s.position.inMilliseconds.clamp(0, max).toDouble();
    final rate = NumberFormat('0.0#', l10n.localeName).format(s.rate);
    return ColoredBox(
      color: AppColors.playScrim,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                max: max,
                value: position,
                secondaryTrackValue: s.buffer.inMilliseconds
                    .clamp(0, max)
                    .toDouble(),
                onChanged: total > 0
                    ? (v) => setState(() => _seeking = v)
                    : null,
                onChangeEnd: (v) {
                  _player.seek(Duration(milliseconds: v.round()));
                  setState(() => _seeking = null);
                  _scheduleHide();
                },
              ),
              Row(
                children: [
                  const SizedBox(width: 8),
                  Text(
                    '${formatDuration(Duration(milliseconds: position.round()))}'
                    ' / ${formatDuration(s.duration)}',
                    style: AppTheme.mono(const TextStyle(fontSize: 16)),
                  ),
                  const Spacer(),
                  PopupMenuButton<double>(
                    tooltip: l10n.speed,
                    initialValue: s.rate,
                    onSelected: _player.setRate,
                    itemBuilder: (context) => [
                      for (final speed in _speeds)
                        PopupMenuItem(
                          value: speed,
                          child: Text(
                            '${NumberFormat('0.0#', l10n.localeName).format(speed)}×',
                          ),
                        ),
                    ],
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.textMuted),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        '$rate×',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.fullscreen,
                    icon: Icon(
                      _landscape ? Icons.fullscreen_exit : Icons.fullscreen,
                    ),
                    onPressed: () => setState(() => _setLandscape(!_landscape)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.at,
    required this.onResume,
    required this.onRestart,
  });

  final Duration at;
  final VoidCallback onResume;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.resumeAt(formatDuration(at))),
          const SizedBox(width: 16),
          FilledButton(onPressed: onResume, child: Text(l10n.resume)),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: onRestart, child: Text(l10n.restart)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.playScrim,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon), const SizedBox(width: 8), Text(text)],
    ),
  );
}
