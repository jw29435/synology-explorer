import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synology_explorer/core/network/syno_api_client.dart';
import 'package:synology_explorer/core/network/syno_exception.dart';
import 'package:synology_explorer/features/browser/data/thumbnail_cache.dart';
import 'package:synology_explorer/features/browser/domain/nas_entry.dart';

import '../../helpers/app_harness.dart';

class _MockClient extends Mock implements SynoApiClient {}

void main() {
  late _MockClient client;
  late Directory dir;
  late ThumbnailCache cache;
  const photo = NasEntry(
    path: '/photo/a.jpg',
    name: 'a.jpg',
    isDir: false,
    type: NasFileType.image,
  );

  setUp(() {
    client = _MockClient();
    when(() => client.profile).thenReturn(testProfile);
    dir = Directory.systemTemp.createTempSync('thumbs');
    addTearDown(() => dir.deleteSync(recursive: true));
    cache = ThumbnailCache(client, Future.value(dir));
  });

  void answer(Object result) {
    final call = when(() => client.requestBytes(any(), any(), any()));
    result is Exception
        ? call.thenThrow(result)
        : call.thenAnswer((_) async => result as Uint8List);
  }

  test('vorübergehende Fehler werden erneut versucht', () async {
    for (final error in [
      const SynoNetworkError(),
      const SynoSessionExpired(119),
    ]) {
      answer(error);
      await expectLater(cache.load(photo), throwsA(error));
    }
    answer(Uint8List.fromList([1, 2, 3]));
    expect(await cache.load(photo), [1, 2, 3]);
    verify(() => client.requestBytes(any(), any(), any())).called(3);

    // Danach aus dem Disk-Cache, atomar geschrieben (keine .tmp-Reste).
    expect(await cache.load(photo), [1, 2, 3]);
    verifyNever(() => client.requestBytes(any(), any(), any()));
    expect(
      dir.listSync().map((f) => f.path),
      isNot(contains(endsWith('.tmp'))),
    );
  });

  test('404 vom NAS wird für die Session gemerkt', () async {
    answer(const SynoNetworkError(statusCode: 404));
    await expectLater(cache.load(photo), throwsA(isA<SynoNetworkError>()));
    await expectLater(cache.load(photo), throwsA(isA<StateError>()));
    verify(() => client.requestBytes(any(), any(), any())).called(1);
  });
}
