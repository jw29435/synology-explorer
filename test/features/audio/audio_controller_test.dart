import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nuvo_explorer/core/auth/session_manager.dart';
import 'package:nuvo_explorer/core/network/certificate_pinning.dart';
import 'package:nuvo_explorer/core/network/media_proxy.dart';
import 'package:nuvo_explorer/core/network/syno_api_client.dart';
import 'package:nuvo_explorer/core/network/syno_exception.dart';
import 'package:nuvo_explorer/core/storage/app_database.dart';
import 'package:nuvo_explorer/core/storage/media_cache.dart';
import 'package:nuvo_explorer/core/storage/storage_providers.dart';
import 'package:nuvo_explorer/features/audio/data/audio_handler.dart';
import 'package:nuvo_explorer/features/audio/data/playback_repository.dart';
import 'package:nuvo_explorer/features/audio/data/track_info_loader.dart';
import 'package:nuvo_explorer/features/audio/domain/playback_queue.dart';
import 'package:nuvo_explorer/features/audio/presentation/playback_providers.dart';
import 'package:nuvo_explorer/features/browser/data/file_station_list_api.dart';
import 'package:nuvo_explorer/features/browser/domain/nas_entry.dart';
import 'package:nuvo_explorer/features/browser/presentation/browser_providers.dart';
import 'package:nuvo_explorer/features/viewers/data/playback_position_repository.dart';
import 'package:nuvo_explorer/features/servers/presentation/server_providers.dart';

import '../../helpers/app_harness.dart';

/// just_audio ohne Plattform: merkt sich Quellen und Aufrufe; Position und
/// Ende steuert der Test.
class FakePlayer implements AudioPlayer {
  final _playing = StreamController<bool>.broadcast();
  final _processing = StreamController<ProcessingState>.broadcast();
  final _duration = StreamController<Duration?>.broadcast();
  final _events = StreamController<PlaybackEvent>.broadcast();

  final sources = <String>[];
  final calls = <String>[];
  bool _isPlaying = false;
  ProcessingState _state = ProcessingState.idle;

  @override
  Duration position = Duration.zero;

  /// Nächster setAudioSource-Aufruf wirft das.
  Object? failNext;

  @override
  bool get playing => _isPlaying;
  @override
  ProcessingState get processingState => _state;
  @override
  Duration get bufferedPosition => Duration.zero;
  @override
  double get speed => 1;
  @override
  Stream<bool> get playingStream => _playing.stream;
  @override
  Stream<ProcessingState> get processingStateStream => _processing.stream;
  @override
  Stream<Duration?> get durationStream => _duration.stream;
  @override
  Stream<PlaybackEvent> get playbackEventStream => _events.stream;
  @override
  Stream<double> get speedStream => const Stream.empty();
  @override
  Stream<Duration> get positionStream => const Stream.empty();

  void _setState(ProcessingState s) {
    _state = s;
    _processing.add(s);
  }

  void _setPlaying(bool p) {
    if (_isPlaying == p) return;
    _isPlaying = p;
    _playing.add(p);
  }

  @override
  Future<Duration?> setAudioSource(
    AudioSource audioSource, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    if (failNext case final e?) {
      failNext = null;
      throw e;
    }
    sources.add((audioSource as UriAudioSource).uri.pathSegments.last);
    position = initialPosition ?? Duration.zero;
    _setState(ProcessingState.ready);
    const d = Duration(minutes: 4);
    _duration.add(d);
    return d;
  }

  /// Wie just_audio: play() im completed-Zustand startet nichts neu.
  @override
  Future<void> play() async {
    calls.add('play');
    _setPlaying(true);
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    _setPlaying(false);
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    _setPlaying(false);
    _setState(ProcessingState.idle);
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    calls.add('seek $position');
    this.position = position ?? Duration.zero;
    if (_state == ProcessingState.completed) _setState(ProcessingState.ready);
  }

  @override
  Future<void> setSpeed(double speed) async {}

  /// Titel zu Ende gelaufen.
  void complete() => _setState(ProcessingState.completed);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProxy implements MediaProxy {
  _FakeProxy(this.path);

  final String path;
  bool closed = false;

  @override
  Uri get url => Uri(
    scheme: 'http',
    host: '127.0.0.1',
    pathSegments: ['t', path.substring(path.lastIndexOf('/') + 1)],
  );

  @override
  Future<void> close() async => closed = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeConnectivity implements Connectivity {
  List<ConnectivityResult> now = [ConnectivityResult.wifi];
  final changes = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => now;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => changes.stream;
}

/// Beantwortet nur `SYNO.API.Info` – reicht für `connect()` nach Netzwechsel.
class _InfoAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({
      'success': true,
      'data': {
        'SYNO.API.Info': {'maxVersion': 1, 'path': 'entry.cgi'},
      },
    }),
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}

SessionManager _connectableSession() {
  const storage = FlutterSecureStorage();
  return SessionManager(
    SynoApiClient(
      testProfile,
      CertificatePinStore(storage),
      adapter: _InfoAdapter(),
    ),
    storage,
    deviceName: 'Test',
  );
}

const album = '/music/Alben/Nordlicht – Treibholz';
const ebbe = '$album/01 Ebbe.flac';
const strandgut = '$album/02 Strandgut.flac';
const nebelbank = '$album/03 Nebelbank.flac';
const leuchtfeuer = '$album/04 Leuchtfeuer.flac';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late FakePlayer player;
  late AppAudioHandler handler;
  late _FakeConnectivity net;
  late AudioController controller;
  late PlaybackRepository repo;
  late PlaybackPositionRepository positions;
  late List<_FakeProxy> proxies;
  late _ListApi listApi;

  final entries = {
    for (final e in fixtureEntries('SYNO.FileStation.List/list.json', 'files'))
      e.path: e,
  };
  NasEntry entry(String path) => entries[path]!;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    player = FakePlayer();
    handler = AppAudioHandler(player: player);
    net = _FakeConnectivity();
    proxies = [];
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sessionProvider.overrideWith(() => FixedSession(_connectableSession())),
        fileStationListApiProvider.overrideWithValue(listApi = _ListApi()),
        audioHandlerProvider.overrideWithValue(handler),
        audioProxyStarterProvider.overrideWithValue((path) async {
          final proxy = _FakeProxy(path);
          proxies.add(proxy);
          return proxy;
        }),
        connectivityProvider.overrideWithValue(net),
        trackInfoLoaderProvider.overrideWithValue(
          TrackInfoLoader(
            download: (_, {maxBytes}) async => throw StateError('offline'),
            thumbnail: (_) async => throw StateError('offline'),
            cache: MediaCache(
              Directory.systemTemp.createTemp('covers'),
              maxBytes: 1 << 20,
            ),
          ),
        ),
      ],
    );
    controller = container.read(audioControllerProvider.notifier);
    repo = container.read(playbackRepositoryProvider);
    positions = PlaybackPositionRepository(db, 1);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  AudioState state() => container.read(audioControllerProvider);

  Future<void> settle() => pumpEventQueue();

  test(
    'Tippen: Queue aus dem Ordner, Start am Titel, Quelle über Proxy',
    () async {
      expect(await controller.playFolder(album, startPath: strandgut), isNull);
      await settle();
      expect(state().queue.tracks.map((t) => t.name), [
        '01 Ebbe.flac',
        '02 Strandgut.flac',
        '03 Nebelbank.flac',
        '04 Leuchtfeuer.flac',
      ]);
      expect(state().track!.path, strandgut);
      expect(player.sources, ['02 Strandgut.flac']);
      expect(state().playing, isTrue);
      expect(handler.mediaItem.value!.title, '02 Strandgut');
    },
  );

  test(
    'Ordnerwechsel sichert die Position unter dem alten Titel (S1)',
    () async {
      await controller.playFolder(album, startPath: ebbe);
      await settle();
      player.position = const Duration(seconds: 100);
      await controller.playFolder(album, startPath: nebelbank);
      await settle();
      expect(await positions.load(entry(ebbe)), const Duration(seconds: 100));
      expect(await positions.load(entry(nebelbank)), isNull);
    },
  );

  test('Resume-Angebot für eine gespeicherte Position', () async {
    await positions.save(entry(strandgut), const Duration(seconds: 90));
    expect(
      await controller.playFolder(album, startPath: strandgut),
      const Duration(seconds: 90),
    );
  });

  test('Position bei Pause und beim Titelwechsel', () async {
    await controller.playFolder(album, startPath: ebbe);
    await settle();
    player.position = const Duration(seconds: 42);
    await controller.pause();
    await settle();
    expect(await positions.load(entry(ebbe)), const Duration(seconds: 42));

    await controller.play();
    player.position = const Duration(seconds: 50);
    await controller.next();
    await settle();
    expect(await positions.load(entry(ebbe)), const Duration(seconds: 50));
    expect(state().track!.path, strandgut);
    // Je Titel ein eigener Proxy; der alte wird nach dem Wechsel geschlossen.
    expect(proxies.map((p) => p.closed), [true, false]);
  });

  test(
    'Titelende: Position gelöscht, nächster Titel; Queue-Ende stoppt',
    () async {
      await positions.save(entry(nebelbank), const Duration(seconds: 30));
      await controller.playFolder(album, startPath: nebelbank);
      await settle();
      player.position = const Duration(minutes: 4);
      player.complete();
      await settle();
      expect(await positions.load(entry(nebelbank)), isNull);
      expect(state().track!.path, leuchtfeuer);
      expect(player.sources.last, '04 Leuchtfeuer.flac');

      player.complete();
      await settle();
      expect(player.sources, hasLength(2), reason: 'Ende der Queue');
      expect(player.calls.sublist(player.calls.length - 2), [
        'pause',
        'seek 0:00:00.000000',
      ]);
    },
  );

  test(
    'Repeat Titel spielt denselben Titel neu, Repeat Ordner von vorn',
    () async {
      await controller.playFolder(album, startPath: leuchtfeuer);
      await settle();
      controller.cycleRepeat(); // Titel
      player.complete();
      await settle();
      expect(player.sources, ['04 Leuchtfeuer.flac']);
      expect(player.calls.last, 'seek 0:00:00.000000');

      controller.cycleRepeat(); // Ordner
      expect(state().repeat, QueueRepeat.all);
      player.complete();
      await settle();
      expect(player.sources.last, '01 Ebbe.flac');
    },
  );

  test('Sleep-Timer „Titelende“ pausiert statt weiterzuspielen', () async {
    await controller.playFolder(album, startPath: ebbe);
    await settle();
    controller.setSleepEndOfTrack();
    player.complete();
    await settle();
    expect(player.calls, contains('pause'));
    expect(player.calls.where((c) => c == 'play'), hasLength(1));
    expect(state().playing, isFalse);
    expect(state().sleepEndOfTrack, isFalse);
  });

  test(
    '„Nur WLAN“ ohne WLAN: kein Laden, auch nicht per Sperrbildschirm',
    () async {
      await repo.setWifiOnly(true);
      net.now = [ConnectivityResult.mobile];
      await controller.playFolder(album, startPath: ebbe);
      await settle();
      expect(state().error, isA<WifiRequired>());
      expect(player.sources, isEmpty);

      // Play vom Sperrbildschirm/Kopfhörer geht über den Controller (S2).
      await handler.play();
      await settle();
      expect(player.sources, isEmpty);
      expect(player.calls, isNot(contains('play')));

      net.now = [ConnectivityResult.wifi];
      await handler.play();
      await settle();
      expect(player.sources, ['01 Ebbe.flac']);
      expect(state().error, isNull);
    },
  );

  test(
    '„Nur WLAN“: Play ohne WLAN, WLAN kommt zurück → weiter an der Stelle',
    () async {
      await repo.setWifiOnly(true);
      await controller.playFolder(album, startPath: ebbe);
      await settle();
      player.position = const Duration(seconds: 80);
      await controller.pause();
      net.now = [ConnectivityResult.none];
      await handler.play(); // Kopfhörertaste ohne WLAN
      await settle();
      expect(state().error, isA<WifiRequired>());
      expect(player.calls.where((c) => c == 'play'), hasLength(1));

      net.now = [ConnectivityResult.wifi];
      net.changes.add(net.now);
      for (var i = 0; i < 50 && player.sources.length < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(player.sources, ['01 Ebbe.flac', '01 Ebbe.flac']);
      expect(player.position, const Duration(seconds: 80));
      expect(state().playing, isTrue);
    },
  );

  test('WLAN fällt weg während der Wiedergabe: Pause mit Hinweis', () async {
    await repo.setWifiOnly(true);
    await controller.playFolder(album, startPath: ebbe);
    await settle();
    net.now = [ConnectivityResult.mobile];
    net.changes.add(net.now);
    await settle();
    expect(state().playing, isFalse);
    expect(state().error, isA<WifiRequired>());
  });

  test('Player-Fehler: Decoder → nicht abspielbar, sonst Ladefehler', () async {
    player.failNext = PlayerException(1, 'Decoder', null);
    await controller.playFolder(album, startPath: ebbe);
    await settle();
    expect(state().error, isA<NotPlayable>());

    player.failNext = PlayerException(0, 'Source error', null);
    await controller.next();
    await settle();
    expect(state().error, isA<StreamFailed>());
  });

  test(
    'Offline-Kopie: lokale Datei, kein Proxy, kein getinfo; Position je Server',
    () async {
      final local = File('${Directory.systemTemp.path}/01 Ebbe.flac');
      expect(await controller.playLocal(entry(ebbe), local, 7), isNull);
      await settle();
      expect(player.sources, ['01 Ebbe.flac']);
      expect(proxies, isEmpty);
      expect(state().track!.path, ebbe);
      player.position = const Duration(seconds: 60);
      await controller.pause();
      await settle();
      expect(
        await PlaybackPositionRepository(db, 7).load(entry(ebbe)),
        const Duration(seconds: 60),
      );
    },
  );

  test(
    'Netz wieder da nach Netzfehler: Titel lädt neu und spielt weiter',
    () async {
      await controller.playFolder(album, startPath: ebbe);
      await settle();
      // Titelwechsel ohne Netz (wie WLAN weg am Titelende).
      player.failNext = const SynoNetworkError(cause: 'offline');
      await controller.next();
      await settle();
      expect(state().error, isA<SynoNetworkError>());
      expect(player.sources, ['01 Ebbe.flac']);

      net.changes.add([ConnectivityResult.none]);
      await settle();
      expect(player.sources, hasLength(1), reason: 'ohne Netz kein Versuch');

      net.changes.add([ConnectivityResult.wifi]);
      // Läuft im Listener, unabhängig vom Test – kurz warten.
      for (var i = 0; i < 50 && player.sources.length < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(player.sources, ['01 Ebbe.flac', '02 Strandgut.flac']);
      expect(state().error, isNull);
      expect(state().playing, isTrue);
    },
  );

  test(
    'Player-Fehler beim Titelwechsel: alter Proxy wird geschlossen',
    () async {
      await controller.playFolder(album, startPath: ebbe);
      await settle();
      player.failNext = PlayerException(0, 'Source error', null);
      await controller.next();
      await settle();
      expect(proxies, hasLength(2));
      expect(proxies[0].closed, isTrue, reason: 'kein Leck samt Token');
    },
  );

  test(
    '„Nur WLAN“: WLAN weg mitten im Titel, zurück → weiter an der Stelle',
    () async {
      await repo.setWifiOnly(true);
      await controller.playFolder(album, startPath: ebbe);
      await settle();
      player.position = const Duration(seconds: 70);
      net.now = [ConnectivityResult.mobile];
      net.changes.add(net.now);
      await settle();
      expect(state().error, isA<WifiRequired>());

      net.now = [ConnectivityResult.wifi];
      net.changes.add(net.now);
      for (var i = 0; i < 50 && player.sources.length < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(player.sources, hasLength(2));
      expect(player.position, const Duration(seconds: 70));
    },
  );

  test(
    'Anmelden/Abmelden beendet nur Streaming, nicht Offline-Audio (E2E-046)',
    () async {
      final session = container.read(sessionProvider.notifier);
      final local = File('${Directory.systemTemp.path}/01 Ebbe.flac');
      await controller.playLocal(entry(ebbe), local, 1);
      await settle();

      await session.close();
      await session.activate(_connectableSession());
      await settle();
      expect(state().track!.path, ebbe);
      expect(state().playing, isTrue);

      await controller.playFolder(album, startPath: strandgut);
      await settle();
      await session.activate(_connectableSession());
      await settle();
      expect(state().active, isFalse, reason: 'Streaming vom alten Server');
    },
  );

  test('„Nur WLAN“ bremst Offline-Audio nicht (Zug ohne WLAN)', () async {
    await repo.setWifiOnly(true);
    net.now = [ConnectivityResult.none];
    final local = File('${Directory.systemTemp.path}/01 Ebbe.flac');
    await controller.playLocal(entry(ebbe), local, 1);
    await settle();
    expect(state().playing, isTrue);
    expect(state().error, isNull);

    net.now = [ConnectivityResult.mobile];
    net.changes.add(net.now);
    await settle();
    expect(state().playing, isTrue, reason: 'kein Pausieren bei Netzwechsel');

    await controller.pause();
    await controller.play();
    await settle();
    expect(state().playing, isTrue);
    expect(state().error, isNull);
  });

  test('Ordner ohne Audio meldet das, auch während etwas läuft', () async {
    await controller.playFolder(album, startPath: ebbe);
    await settle();
    listApi.empty = true;
    await expectLater(
      controller.playFolder('/leer'),
      throwsA(isA<NoAudioInFolder>()),
    );
    expect(state().track!.path, ebbe, reason: 'Wiedergabe läuft weiter');
  });

  test(
    'Sleep „Titelende“: nächster Titel liegt pausiert bereit, Play geht',
    () async {
      await controller.playFolder(album, startPath: ebbe);
      await settle();
      controller.setSleepEndOfTrack();
      player.complete();
      await settle();
      expect(state().playing, isFalse);
      expect(player.sources, ['01 Ebbe.flac', '02 Strandgut.flac']);
      expect(player.processingState, ProcessingState.ready);

      await controller.play();
      await settle();
      expect(state().playing, isTrue);
      expect(state().track!.path, strandgut);
    },
  );
}

/// Wie [FakeListApi]; mit [empty] ist jeder Ordner leer.
class _ListApi extends FakeListApi {
  bool empty = false;

  @override
  Future<NasPage> list(
    String folderPath, {
    NasSortBy sortBy = NasSortBy.name,
    bool descending = false,
    int offset = 0,
    int limit = 500,
  }) async => empty
      ? (entries: <NasEntry>[], total: 0)
      : super.list(
          folderPath,
          sortBy: sortBy,
          descending: descending,
          offset: offset,
          limit: limit,
        );
}
