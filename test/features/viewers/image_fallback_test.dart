import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/features/browser/domain/nas_entry.dart';
import 'package:nuvo_explorer/features/viewers/presentation/nas_image.dart';

import '../../helpers/app_harness.dart';
import 'fake_media.dart';

/// HEIC-Fallback-Kette: Original (Plattform-Decoder) → Vorschaubild vom NAS
/// → Platzhalter. Flutter kann im Test kein HEIC; „kaputte“ Bytes stehen für
/// ein Original, das die Plattform nicht dekodiert.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final jpeg = File('test/fixtures/SYNO.FileStation.Thumb/get.jpg')
      .readAsBytesSync();
  final heic = Uint8List.fromList([0, 0, 0, 24, ...'ftypheic'.codeUnits]);

  late List<String> calls;
  Future<Uint8List> Function() source(String name, Object result) => () async {
    calls.add(name);
    if (result is Uint8List) return result;
    throw result;
  };
  Future<ui.Codec> decode(Uint8List bytes) async =>
      ui.instantiateImageCodec(bytes);

  setUp(() => calls = []);

  test('Original lässt sich dekodieren → kein Vorschaubild nötig', () async {
    final codec = await firstDecodable([
      source('original', jpeg),
      source('thumb', jpeg),
    ], decode);
    expect(codec.frameCount, 1);
    expect(calls, ['original']);
  });

  test('Original nicht dekodierbar → Vorschaubild vom NAS', () async {
    final codec = await firstDecodable([
      source('original', heic),
      source('thumb', jpeg),
    ], decode);
    expect((await codec.getNextFrame()).image.width, greaterThan(0));
    expect(calls, ['original', 'thumb']);
  });

  test('beides scheitert → ImageUnavailable mit letzter Ursache', () async {
    const notFound = HttpException('404');
    await expectLater(
      firstDecodable([
        source('original', heic),
        source('thumb', notFound),
      ], decode),
      throwsA(
        isA<ImageUnavailable>().having((e) => e.cause, 'cause', notFound),
      ),
    );
    expect(calls, ['original', 'thumb']);
  });

  test('Zielgröße: längere Seite höchstens max, kleine Bilder unverändert', () {
    (int?, int?) fit(int w, int h) {
      final t = fitWithin(w, h, 2340);
      return (t.width, t.height);
    }

    expect(fit(4032, 3024), (2340, null));
    expect(fit(3024, 4032), (null, 2340));
    expect(fit(1080, 720), (null, null));
  });

  testWidgets('NasImage dekodiert verkleinert und meldet die Originalmaße', (
    tester,
  ) async {
    const entry = NasEntry(
      path: '/photo/a.jpg',
      name: 'a.jpg',
      isDir: false,
      type: NasFileType.image,
    );
    final reported = <(int, int)>[];
    final image = NasImage(
      entry,
      FakeMediaRepository({
        'a.jpg': 'test/fixtures/SYNO.FileStation.Thumb/get.jpg',
      }),
      NoThumbnails(),
      maxDimension: 8,
      onSize: (_, w, h) => reported.add((w, h)),
    );
    final info = await tester.runAsync(() {
      final done = Completer<ImageInfo>();
      image
          .resolve(ImageConfiguration.empty)
          .addListener(ImageStreamListener((i, _) => done.complete(i)));
      return done.future;
    });
    final (width, height) = reported.single;
    expect(width, greaterThan(8));
    expect(
      [info!.image.width, info.image.height].reduce((a, b) => a > b ? a : b),
      8,
    );
    expect(info.image.width / info.image.height, closeTo(width / height, 0.05));
  });
}
