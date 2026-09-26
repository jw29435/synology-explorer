import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/core/network/certificate_pinning.dart';
import 'package:synology_explorer/core/network/syno_api_client.dart';
import 'package:synology_explorer/core/network/syno_exception.dart';
import 'package:synology_explorer/core/storage/media_cache.dart';
import 'package:synology_explorer/features/browser/domain/nas_entry.dart';
import 'package:synology_explorer/features/servers/domain/server_profile.dart';
import 'package:synology_explorer/features/viewers/data/media_repository.dart';

import '../../helpers/app_harness.dart' show testProfile;
import '../../helpers/mock_nas_server.dart';
import '../../../tool/mock_nas/mock_nas.dart' show mockFileBytes;

class _MockClient extends Mock implements SynoApiClient {}

void main() {
  late MockNasServer nas;
  late SynoApiClient client;
  late Directory dir;
  late MediaRepository media;
  const photo = NasEntry(
    path: '/photo/a.jpg',
    name: 'a.JPG',
    isDir: false,
    type: NasFileType.image,
  );

  setUp(() async {
    nas = await MockNasServer.start();
    FlutterSecureStorage.setMockInitialValues({});
    client = SynoApiClient(
      ServerProfile(id: 1, name: 'Mock', lanUrl: nas.url, user: 'johann'),
      CertificatePinStore(const FlutterSecureStorage()),
    );
    await client.connect();
    final login = await client.request('SYNO.API.Auth', 'login', {
      'account': 'johann',
      'passwd': 'geheim',
      'otp_code': '123456',
    }) as Map;
    client.sid = login['sid'] as String;
    dir = Directory.systemTemp.createTempSync('media');
    media = MediaRepository(
      client,
      MediaCache(Future.value(dir), maxBytes: 1 << 20),
    );
    addTearDown(() async {
      client.close();
      await nas.close();
      dir.deleteSync(recursive: true);
    });
  });

  test('lädt über Download in den Cache und meldet Fortschritt', () async {
    final progress = <(int, int)>[];
    final file = await media.file(
      photo,
      onProgress: (r, t) => progress.add((r, t)),
    );
    final expected = mockFileBytes();
    expect(file.readAsBytesSync(), expected);
    expect(file.path, endsWith('.jpg'));
    expect(progress.last, (expected.length, expected.length));
    final call = nas.calls('SYNO.FileStation.Download', 'download').single;
    expect(call['path'], '/photo/a.jpg');
    expect(call['mode'], 'open');

    // Zweiter Aufruf aus dem Cache.
    await media.file(photo);
    expect(nas.calls('SYNO.FileStation.Download', 'download'), hasLength(1));
  });

  test('JSON-Fehler statt Datei: SynoException, nichts im Cache', () async {
    client.sid = 'abgelaufen';
    await expectLater(media.file(photo), throwsA(isA<SynoSessionExpired>()));
    expect(dir.listSync(), isEmpty);
  });

  group('geteilter Download', () {
    late _MockClient mock;
    late Completer<void> gate;
    late MediaRepository shared;
    late List<void Function(int, int?)> progress;

    setUpAll(() {
      registerFallbackValue(CancelToken());
      registerFallbackValue(File(''));
      registerFallbackValue(<String, Object?>{});
    });

    setUp(() {
      mock = _MockClient();
      gate = Completer();
      progress = [];
      when(() => mock.profile).thenReturn(testProfile);
      when(
        () => mock.download(
          any(),
          any(),
          any(),
          any(),
          cancelToken: any(named: 'cancelToken'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((call) async {
        progress.add(
          call.namedArguments[#onProgress] as void Function(int, int?),
        );
        await gate.future;
        await (call.positionalArguments[3] as File).writeAsBytes([1, 2, 3, 4]);
        return 4;
      });
      shared = MediaRepository(
        mock,
        MediaCache(Future.value(dir), maxBytes: 1 << 20),
      );
    });

    Future<CancelToken> upstream() async {
      await pumpEventQueue();
      return verify(
            () => mock.download(
              any(),
              any(),
              any(),
              any(),
              cancelToken: captureAny(named: 'cancelToken'),
              onProgress: any(named: 'onProgress'),
            ),
          ).captured.single
          as CancelToken;
    }

    test('Abbruch des ersten trifft den zweiten nicht', () async {
      final first = CancelToken();
      final second = CancelToken();
      final seen = <int>[];
      unawaited(shared.file(photo, cancel: first).catchError((_) => File('')));
      final other = shared.file(
        photo,
        cancel: second,
        onProgress: (r, _) => seen.add(r),
      );
      final token = await upstream();
      first.cancel();
      await pumpEventQueue();
      expect(token.isCancelled, isFalse);

      progress.single(4, 4);
      gate.complete();
      expect(await (await other).length(), 4);
      expect(seen, [4], reason: 'auch der zweite sieht Fortschritt');
    });

    test('Abbruch aller Wartenden beendet den Download', () async {
      final first = CancelToken();
      final second = CancelToken();
      unawaited(shared.file(photo, cancel: first).catchError((_) => File('')));
      unawaited(shared.file(photo, cancel: second).catchError((_) => File('')));
      final token = await upstream();
      first.cancel();
      second.cancel();
      await pumpEventQueue();
      expect(token.isCancelled, isTrue);
      gate.complete();
    });

    test('ohne Abbruch-Token (Bild) wird nie abgebrochen', () async {
      final viewer = CancelToken();
      unawaited(shared.file(photo, cancel: viewer).catchError((_) => File('')));
      unawaited(shared.file(photo).catchError((_) => File('')));
      final token = await upstream();
      viewer.cancel();
      await pumpEventQueue();
      expect(token.isCancelled, isFalse);
      gate.complete();
    });
  });
}
