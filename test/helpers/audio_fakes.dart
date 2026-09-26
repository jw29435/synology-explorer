import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:synology_explorer/features/audio/data/track_info_loader.dart';
import 'package:synology_explorer/features/audio/domain/playback_queue.dart';
import 'package:synology_explorer/features/audio/presentation/playback_providers.dart';
import 'package:synology_explorer/features/browser/domain/nas_entry.dart';

NasEntry audioFile(String name, {int size = 30 << 20}) => NasEntry(
  path: '/music/Alben/Nordlicht – Treibholz/$name',
  name: name,
  isDir: false,
  type: NasFileType.audio,
  size: size,
);

/// Album mit vier Titeln, „02 Strandgut“ läuft (3:12 von 4:48).
AudioState playingAlbum({bool playing = true}) => AudioState(
  queue: PlaybackQueue([
    audioFile('01 Ebbe.flac'),
    audioFile('02 Strandgut.flac'),
    audioFile('03 Nebelbank.flac'),
    audioFile('04 Leuchtfeuer.flac'),
  ], 1),
  folder: '/music/Alben/Nordlicht – Treibholz',
  playing: playing,
  duration: const Duration(minutes: 4, seconds: 48),
  info: const TrackInfo(artist: 'Nordlicht', album: 'Treibholz'),
);

/// AudioController ohne Player: merkt sich Aufrufe, ändert nur den State.
class FakeAudioController extends AudioController {
  FakeAudioController(
    this._initial, {
    this.resume,
    this.delay,
    this.emptyFolder = false,
  });

  /// [playFolder] meldet „keine Audiodateien“.
  final bool emptyFolder;

  final AudioState _initial;
  final calls = <String>[];

  /// Rückgabe von [playFolder] („Bei … fortsetzen?“) und künstliche Dauer.
  final Duration? resume;
  final Duration? delay;

  @override
  AudioState build() => _initial;

  @override
  Future<Duration?> playFolder(
    String folder, {
    String? startPath,
    bool recursive = false,
  }) async {
    calls.add('playFolder $folder ${startPath ?? '-'} $recursive');
    if (delay case final d?) await Future<void>.delayed(d);
    if (emptyFolder) throw const NoAudioInFolder();
    if (!state.active) state = playingAlbum();
    return resume;
  }

  @override
  Future<void> togglePlay() async {
    calls.add('toggle');
    state = state.copyWith(playing: !state.playing);
  }

  @override
  Future<void> next() async => calls.add('next');

  @override
  Future<void> previous() async => calls.add('previous');

  @override
  Future<void> seek(Duration position) async => calls.add('seek $position');

  @override
  Future<void> jumpTo(int index) async => calls.add('jump $index');

  @override
  Future<void> removeAt(int index) async {
    calls.add('remove $index');
    state = state.copyWith(queue: state.queue.removeAt(index));
  }

  @override
  void move(int from, int to) {
    calls.add('move $from $to');
    super.move(from, to);
  }

  @override
  Future<void> clear({bool save = true}) async {
    calls.add('clear');
    state = const AudioState();
  }

  @override
  void setSleep(Duration? duration) {
    calls.add('sleep $duration');
    state = state.copyWith(
      sleepEndsAt: duration == null ? null : DateTime.now().add(duration),
    );
  }
}

/// Overrides für Widget-Tests mit [controller] und fester Position 3:12.
List<Override> audioOverrides(FakeAudioController controller) => [
  audioControllerProvider.overrideWith(() => controller),
  positionProvider.overrideWith(
    (ref) => Stream.value(const Duration(minutes: 3, seconds: 12)),
  ),
];
