import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/media_proxy.dart';
import '../../../core/network/syno_exception.dart';
import '../../../core/storage/storage_providers.dart';
import '../../browser/domain/nas_entry.dart';
import '../../browser/presentation/browser_providers.dart';
import '../../browser/presentation/entry_widgets.dart';
import '../../servers/presentation/server_providers.dart';
import '../../viewers/data/playback_position_repository.dart';
import '../data/audio_handler.dart';
import '../data/playback_repository.dart';
import '../data/track_info_loader.dart';
import '../domain/playback_queue.dart';
import '../domain/sleep_timer.dart';

part 'playback_providers.freezed.dart';

/// Vom App-Start (`main`) mit [AppAudioHandler.init] überschrieben.
final audioHandlerProvider = Provider<AppAudioHandler>(
  (ref) => throw UnimplementedError('AppAudioHandler.init() fehlt'),
);

final playbackRepositoryProvider = Provider<PlaybackRepository>(
  (ref) => PlaybackRepository(ref.watch(appDatabaseProvider)),
);

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

/// WLAN oder Ethernet (kein Mobilfunk).
bool isUnmetered(List<ConnectivityResult> types) =>
    types.contains(ConnectivityResult.wifi) ||
    types.contains(ConnectivityResult.ethernet);

/// Darf gerade gestreamt werden? („Streaming nur im WLAN“)
Future<bool> streamingAllowed(Ref ref) async =>
    !await ref.read(playbackRepositoryProvider).wifiOnly() ||
    isUnmetered(await ref.read(connectivityProvider).checkConnectivity());

/// Startet den Loopback-Proxy (core/network) für eine Datei der aktiven
/// Session. Jeder Request prüft „Streaming nur im WLAN“ – auch Play vom
/// Sperrbildschirm oder Kopfhörer lädt so nie über Mobilfunk.
final audioProxyStarterProvider =
    Provider<Future<MediaProxy> Function(String path)>((ref) {
      final client = ref.watch(sessionProvider)!.client;
      return (path) =>
          MediaProxy.start(client, path, allow: () => streamingAllowed(ref));
    });

/// Positionen je Datei (gemeinsam mit Video, siehe viewers/data).
PlaybackPositionRepository _positionsFor(Ref ref, int serverId) =>
    PlaybackPositionRepository(ref.read(appDatabaseProvider), serverId);

final trackInfoLoaderProvider = Provider<TrackInfoLoader>((ref) {
  final client = ref.watch(sessionProvider)!.client;
  final thumbs = ref.watch(thumbnailCacheProvider);
  return TrackInfoLoader(
    download: (path, {maxBytes}) async {
      final body = await client.requestStream(
        'SYNO.FileStation.Download',
        'download',
        {'path': path, 'mode': 'open'},
        end: maxBytes,
      );
      final bytes = BytesBuilder(copy: false);
      await body.stream.forEach(bytes.add);
      return bytes.takeBytes();
    },
    thumbnail: thumbs.load,
    dir: getApplicationCacheDirectory().then(
      (d) => Directory('${d.path}/covers/${client.profile.id}'),
    ),
  );
});

/// „Streaming nur im WLAN“.
final wifiOnlyProvider = StreamProvider<bool>(
  (ref) => ref.watch(playbackRepositoryProvider).watchWifiOnly(),
);

final isAudiobookProvider = StreamProvider.autoDispose.family<bool, String>(
  (ref, folder) => ref
      .watch(playbackRepositoryProvider)
      .watchAudiobook(ref.watch(serverIdProvider), folder),
);

/// Aktuelle Position des Players (Fortschritt und Zeiten).
final positionProvider = StreamProvider.autoDispose<Duration>(
  (ref) => ref.watch(audioHandlerProvider).player.positionStream,
);

/// Ob gerade etwas abgespielt wird; dann zeigt die Shell den Mini-Player.
final hasActivePlaybackProvider = Provider<bool>(
  (ref) => ref.watch(audioControllerProvider.select((s) => s.active)),
);

/// Fehler, die der Player selbst meldet (Text über l10n).
sealed class PlaybackError implements Exception {
  const PlaybackError();
}

/// Einstellung „Streaming nur im WLAN“ und gerade kein WLAN.
class WifiRequired extends PlaybackError {
  const WifiRequired();
}

/// Format wird auf dem Gerät nicht dekodiert.
class NotPlayable extends PlaybackError {
  const NotPlayable();
}

/// Datei ließ sich nicht laden (Netz, NAS, Proxy).
class StreamFailed extends PlaybackError {
  const StreamFailed();
}

/// Ordnet einen Player-Fehler ein. Android: `ExoPlaybackException.type`
/// (1 = Renderer/Decoder); iOS: AVFoundation „kann nicht öffnen/nicht
/// unterstützt“ (-11828/-11829). Alles andere gilt als Ladefehler.
PlaybackError classifyPlayerError(PlayerException e) =>
    const {1, -11828, -11829}.contains(e.code)
    ? const NotPlayable()
    : const StreamFailed();

@freezed
abstract class AudioState with _$AudioState {
  const factory AudioState({
    @Default(PlaybackQueue.empty) PlaybackQueue queue,

    /// Ordner, aus dem gespielt wird (Kopf von Screen 12).
    String? folder,
    @Default(false) bool playing,
    @Default(false) bool loading,
    Duration? duration,
    @Default(QueueRepeat.off) QueueRepeat repeat,
    @Default(1.0) double speed,

    /// Ende des Sleep-Timers mit fester Dauer.
    DateTime? sleepEndsAt,
    @Default(false) bool sleepEndOfTrack,
    TrackInfo? info,
    Object? error,
  }) = _AudioState;

  const AudioState._();

  bool get active => !queue.isEmpty;
  bool get shuffle => queue.shuffled;
  NasEntry? get track => queue.current;

  /// Anzeigename: Titel-Tag, sonst Dateiname ohne Endung.
  String get title {
    if (info?.title case final title?) return title;
    return trackName(track?.name ?? '');
  }

  /// Interpret-Tag, sonst Name des Ordners.
  String? get artist =>
      info?.artist ?? (track == null ? null : folderName(track!.path));
}

/// Dateiname ohne Endung.
String trackName(String name) {
  final dot = name.lastIndexOf('.');
  return dot > 0 ? name.substring(0, dot) : name;
}

/// Name des Ordners, in dem [path] liegt.
String folderName(String path) {
  final segments = path.split('/');
  return segments.length > 2 ? segments[segments.length - 2] : '';
}

final audioControllerProvider = NotifierProvider<AudioController, AudioState>(
  AudioController.new,
);

/// Ordner-Player: baut die Queue, steuert just_audio über den
/// [AppAudioHandler], speichert Positionen und stellt vor jedem Titel eine
/// gültige Session und die richtige Adresse sicher.
class AudioController extends Notifier<AudioState> {
  static const speeds = [0.8, 1.0, 1.25, 1.5, 1.75, 2.0];
  static const saveInterval = Duration(seconds: 5);

  /// Rekursives „Ordner abspielen“: höchstens so viele Ebenen Unterordner.
  static const maxDepth = 3;

  late final SleepTimer _sleep = SleepTimer(_onSleep);
  final _subscriptions = <StreamSubscription<Object?>>[];
  Timer? _saveTimer;
  bool _attached = false;
  bool _addressStale = false;
  MediaProxy? _proxy;

  /// Stelle, an der ein Netzfehler die Wiedergabe unterbrochen hat.
  Duration? _errorPosition;

  /// Offline-Wiedergabe (Screen 21): lokale Datei je NAS-Pfad und der
  /// Server, zu dem die Positionen gehören – geht ohne Session.
  final _localFiles = <String, File>{};
  int? _localServerId;
  int _loadToken = 0;

  /// Ordner-Cover je Ordnerpfad (aus dem Listing beim Queue-Aufbau).
  final _folderCovers = <String, NasEntry>{};

  @override
  AudioState build() {
    // Server gewechselt oder abgemeldet: Wiedergabe endet. Positionen sind
    // höchstens 5 s alt; sichern ginge hier schon auf den neuen Server.
    ref.listen(sessionProvider, (previous, next) {
      if (!identical(previous, next)) unawaited(clear(save: false));
    });
    ref.onDispose(_detach);
    return const AudioState();
  }

  AppAudioHandler get _handler => ref.read(audioHandlerProvider);
  AudioPlayer get _player => _handler.player;
  PlaybackRepository get _repo => ref.read(playbackRepositoryProvider);
  int get _serverId => _localServerId ?? ref.read(serverIdProvider);
  PlaybackPositionRepository get _positions => _positionsFor(ref, _serverId);

  // -------------------------------------------------------------------------
  // Queue aufbauen

  /// Spielt die Audiodateien von [folder] in aktueller Sortierung ab,
  /// beginnend bei [startPath]. Ohne [startPath] startet ein Hörbuch-Ordner
  /// beim zuletzt gespielten Titel. Liefert die gespeicherte Position des
  /// Starttitels (für „Fortsetzen bei mm:ss“), sonst `null`.
  Future<Duration?> playFolder(
    String folder, {
    String? startPath,
    bool recursive = false,
  }) async {
    final sort = ref.read(sortProvider);
    final entries = await listFilesDeep(
      ref.read(fileStationListApiProvider),
      folder,
      sortBy: sort.by,
      descending: sort.descending,
      depth: recursive ? maxDepth : 0,
    );
    for (final e in entries) {
      if (folderCoverNames.contains(e.name.toLowerCase())) {
        _folderCovers.putIfAbsent(parentPath(e.path), () => e);
      }
    }
    startPath ??= await _repo.lastTrack(_serverId, folder);
    final queue = PlaybackQueue.fromEntries(entries, startPath: startPath);
    if (queue.isEmpty) return null;
    // Erst die Position des bisherigen Titels sichern, dann lesen – so
    // stimmt sie auch, wenn derselbe Titel erneut geöffnet wird.
    await _savePosition();
    _localFiles.clear();
    _localServerId = null;
    final resume = await _positions.load(queue.current!);
    await _playIndex(queue.index, queue: queue, folder: folder);
    return resume;
  }

  /// „Zur Queue hinzufügen“; startet die Wiedergabe, wenn nichts läuft.
  Future<void> enqueue(NasEntry track) async {
    if (!state.active) {
      await playFolder(parentPath(track.path), startPath: track.path);
      return;
    }
    state = state.copyWith(queue: state.queue.add([track]));
  }

  /// Spielt eine Offline-Kopie (Screen 21) ohne Netz und ohne Session; die
  /// Position gehört zu [serverId] und [entry.path] wie beim Streaming.
  Future<Duration?> playLocal(NasEntry entry, File file, int serverId) async {
    await _savePosition();
    _localFiles
      ..clear()
      ..[entry.path] = file;
    _localServerId = serverId;
    final resume = await _positions.load(entry);
    await _playIndex(
      0,
      queue: PlaybackQueue([entry], 0),
      folder: parentPath(entry.path),
    );
    return resume;
  }

  // -------------------------------------------------------------------------
  // Steuerung

  Future<void> togglePlay() => state.playing ? pause() : play();

  Future<void> play() async {
    if (!state.active) return;
    if (!_attached ||
        state.error != null ||
        _player.processingState == ProcessingState.idle) {
      // Nach einem Fehler oder Stopp den Titel neu laden.
      return _playIndex(
        state.queue.index,
        position: _attached ? _player.position : null,
      );
    }
    if (!await _networkAllowed(resumeAt: _player.position)) return;
    unawaited(_player.play());
  }

  Future<void> pause() async {
    if (_attached) await _player.pause();
  }

  Future<void> seek(Duration position) async {
    if (_attached) await _player.seek(position);
  }

  Future<void> next() async {
    final i = state.queue.next(state.repeat);
    if (i != null) await _playIndex(i);
  }

  /// Nach mehr als 3 s zurück an den Titelanfang, sonst zum vorigen Titel.
  Future<void> previous() async {
    if (_attached && _player.position > const Duration(seconds: 3)) {
      return seek(Duration.zero);
    }
    final i = state.queue.previous(state.repeat);
    if (i != null) await _playIndex(i);
  }

  Future<void> jumpTo(int index) => _playIndex(index);

  void setShuffle(bool on) => state = state.copyWith(
    queue: on
        ? state.queue.shuffle(DateTime.now().microsecondsSinceEpoch)
        : state.queue.unshuffle(),
  );

  void cycleRepeat() => state = state.copyWith(
    repeat: QueueRepeat.values[(state.repeat.index + 1) % 3],
  );

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);
    if (_attached) await _player.setSpeed(speed);
  }

  /// Sleep-Timer mit fester Dauer; `null` schaltet ihn aus.
  void setSleep(Duration? duration) {
    if (duration == null) {
      _sleep.cancel();
    } else {
      _sleep.start(duration);
    }
    state = state.copyWith(
      sleepEndsAt: duration == null ? null : DateTime.now().add(duration),
      sleepEndOfTrack: false,
    );
  }

  void setSleepEndOfTrack() {
    _sleep.startEndOfTrack();
    state = state.copyWith(sleepEndsAt: null, sleepEndOfTrack: true);
  }

  void move(int from, int to) =>
      state = state.copyWith(queue: state.queue.move(from, to));

  Future<void> removeAt(int index) async {
    final wasCurrent = index == state.queue.index;
    final queue = state.queue.removeAt(index);
    if (queue.isEmpty) return clear();
    if (wasCurrent) {
      // Position gehört noch dem entfernten Titel: _playIndex sichert sie,
      // bevor die neue Queue gilt.
      return _playIndex(queue.index, queue: queue, autoplay: state.playing);
    }
    state = state.copyWith(queue: queue);
  }

  /// Leert die Queue und beendet die Wiedergabe.
  Future<void> clear({bool save = true}) async {
    _loadToken++;
    _sleep.cancel();
    if (_attached) {
      if (save) await _savePosition();
      await _player.stop();
    }
    await _closeProxy();
    _folderCovers.clear();
    _localFiles.clear();
    _localServerId = null;
    state = AudioState(repeat: state.repeat, speed: state.speed);
  }

  Future<void> setAudiobook(String folder, bool on) async {
    await _repo.setAudiobook(_serverId, folder, on);
    if (on && state.folder == folder && state.track != null) {
      await _repo.setLastTrack(_serverId, folder, state.track!.path);
    }
  }

  Future<void> setWifiOnly(bool on) => _repo.setWifiOnly(on);

  // -------------------------------------------------------------------------
  // Intern

  void _attach() {
    if (_attached) return;
    _attached = true;
    _handler
      ..onPlay = play
      ..onSkipToNext = next
      ..onSkipToPrevious = previous
      ..onStop = clear;
    _subscriptions.addAll([
      _player.playingStream.listen((playing) {
        state = state.copyWith(playing: playing);
        if (!playing) unawaited(_savePosition());
      }),
      _player.processingStateStream.listen((s) {
        if (s == ProcessingState.completed) unawaited(_onCompleted());
      }),
      _player.durationStream.listen((d) {
        if (d != null) state = state.copyWith(duration: d);
      }),
      // Fehler mitten im Titel (Proxy verweigert, Netz weg, Decoder).
      _player.playbackEventStream.listen(
        (_) {},
        onError: (Object e) async {
          _errorPosition = _player.position;
          final error = !await streamingAllowed(ref)
              ? const WifiRequired()
              : e is PlayerException
              ? classifyPlayerError(e)
              : e;
          if (ref.mounted) state = state.copyWith(error: error, loading: false);
        },
      ),
      ref
          .read(connectivityProvider)
          .onConnectivityChanged
          .listen(_onConnectivity),
    ]);
    _saveTimer = Timer.periodic(saveInterval, (_) {
      if (_player.playing) unawaited(_savePosition());
    });
  }

  Future<void> _closeProxy() async {
    final proxy = _proxy;
    _proxy = null;
    await proxy?.close();
  }

  void _detach() {
    unawaited(_closeProxy());
    _saveTimer?.cancel();
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    _sleep.cancel();
  }

  /// Lädt Titel [index] (aus [queue], sonst der aktuellen Queue) und spielt
  /// ihn ab. Vorher: Position des bisherigen Titels sichern – noch unter der
  /// alten Queue –, WLAN-Regel prüfen, nach Netzwechsel die Adresse neu
  /// wählen und per `getinfo` eine gültige SID sicherstellen (abgelaufene
  /// Session → genau ein stiller Re-Login im SynoApiClient, sonst Fehler).
  /// Mit [folder] beginnt eine neue Ordner-Wiedergabe (Sleep-Timer aus).
  Future<void> _playIndex(
    int index, {
    PlaybackQueue? queue,
    String? folder,
    Duration? position,
    bool autoplay = true,
  }) async {
    _attach();
    final token = ++_loadToken;
    await _savePosition();
    final next = (queue ?? state.queue).jump(index);
    final entry = next.current!;
    if (folder != null) _sleep.cancel();
    state = state.copyWith(
      queue: next,
      folder: folder ?? state.folder,
      sleepEndsAt: folder != null ? null : state.sleepEndsAt,
      sleepEndOfTrack: folder == null && state.sleepEndOfTrack,
      loading: true,
      error: null,
      info: null,
      duration: null,
    );
    try {
      final AudioSource source;
      final previous = _proxy;
      if (_localFiles[entry.path] case final file?) {
        // Offline-Kopie: kein Netz, keine Session.
        _proxy = null;
        source = AudioSource.file(file.path);
      } else {
        if (!await _networkAllowed(resumeAt: position)) return;
        final client = ref.read(sessionProvider)!.client;
        if (_addressStale) {
          _addressStale = false;
          await client.connect();
        }
        await ref.read(fileStationListApiProvider).getInfo(entry.path);
        if (token != _loadToken) return;
        final proxy = await ref.read(audioProxyStarterProvider)(entry.path);
        if (token != _loadToken) {
          await proxy.close();
          return;
        }
        _proxy = proxy;
        source = AudioSource.uri(proxy.url);
      }
      await _player.setSpeed(state.speed);
      await _player.setAudioSource(source, initialPosition: position);
      // Erst jetzt: der Player liest nicht mehr vom alten Proxy.
      if (previous != null && !identical(previous, _proxy)) {
        await previous.close();
      }
      if (token != _loadToken) return;
      state = state.copyWith(loading: false);
      _publishMediaItem();
      if (autoplay) unawaited(_player.play());
      if (state.folder case final folder?) {
        unawaited(_repo.setLastTrack(_serverId, folder, entry.path));
      }
      unawaited(_loadInfo(entry, token));
    } catch (e) {
      if (token != _loadToken) return;
      // Nur den Typ loggen: Meldungen können URLs mit `_sid` enthalten.
      debugPrint('Wiedergabe fehlgeschlagen: ${e.runtimeType}');
      _errorPosition = position;
      await _player.stop();
      state = state.copyWith(
        loading: false,
        error: e is PlayerException ? classifyPlayerError(e) : e,
      );
    }
  }

  Future<void> _loadInfo(NasEntry entry, int token) async {
    final folder = parentPath(entry.path);
    try {
      final info = await ref
          .read(trackInfoLoaderProvider)
          .load(entry, folderCover: _folderCovers[folder]);
      if (token != _loadToken) return;
      state = state.copyWith(info: info);
      _publishMediaItem();
    } catch (_) {
      // Ohne Tags/Cover: Dateiname und Platzhalter.
    }
  }

  void _publishMediaItem() {
    final entry = state.track;
    if (entry == null) return;
    _handler.mediaItem.add(
      MediaItem(
        id: entry.path,
        title: state.title,
        artist: state.artist,
        album: state.info?.album,
        duration: state.duration,
        artUri: state.info?.cover?.uri,
      ),
    );
  }

  Future<void> _onCompleted() async {
    final entry = state.track;
    if (entry != null) await _positions.clear(entry);
    if (_sleep.trackEnded()) return;
    final i = state.queue.next(state.repeat, auto: true);
    if (i == state.queue.index) {
      await _player.seek(Duration.zero);
      return;
    }
    if (i == null) {
      await _player.pause();
      await _player.seek(Duration.zero);
      return;
    }
    await _playIndex(i);
  }

  void _onSleep() {
    state = state.copyWith(sleepEndsAt: null, sleepEndOfTrack: false);
    unawaited(pause());
  }

  /// Sichert die Position des aktuellen Titels; kurz nach dem Anfang und
  /// kurz vor dem Ende wird sie gelöscht (nichts zum Fortsetzen).
  Future<void> _savePosition() async {
    final entry = state.track;
    if (!_attached || entry == null || state.loading) return;
    final position = _player.position;
    final duration = state.duration;
    try {
      if (duration != null &&
          PlaybackPositionRepository.worthKeeping(position, duration)) {
        await _positions.save(entry, position);
      } else if (duration != null) {
        await _positions.clear(entry);
      }
    } catch (_) {
      // Session weg (Logout): nichts mehr zu sichern.
    }
  }

  /// [resumeAt]: dort geht es weiter, wenn das WLAN zurückkommt.
  Future<bool> _networkAllowed({Duration? resumeAt}) async {
    if (await streamingAllowed(ref)) return true;
    _errorPosition = resumeAt;
    await _player.pause();
    state = state.copyWith(loading: false, error: const WifiRequired());
    return false;
  }

  /// Netzwechsel: nächster Titel wählt die Adresse neu. Mit „nur WLAN“
  /// pausiert der Player sofort, wenn das WLAN wegfällt.
  void _onConnectivity(List<ConnectivityResult> types) {
    _addressStale = true;
    // Netz wieder da nach einem Netzfehler (auch Titelwechsel ohne Netz)
    // oder WLAN zurück nach „nur WLAN“-Pause: an der Stelle weiterspielen.
    final online = types.any((t) => t != ConnectivityResult.none);
    final error = state.error;
    if (online &&
        state.active &&
        (error is SynoNetworkError ||
            error is StreamFailed ||
            (error is WifiRequired && isUnmetered(types)))) {
      unawaited(_playIndex(state.queue.index, position: _errorPosition));
      return;
    }
    if (isUnmetered(types) || !_player.playing) return;
    unawaited(
      _repo.wifiOnly().then((wifiOnly) async {
        if (!wifiOnly) return;
        await _player.pause();
        state = state.copyWith(error: const WifiRequired());
      }),
    );
  }
}
