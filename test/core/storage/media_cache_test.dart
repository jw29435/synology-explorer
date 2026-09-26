import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/core/storage/media_cache.dart';

void main() {
  late Directory dir;
  late MediaCache cache;
  late int fetches;
  var clock = DateTime(2026);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('media');
    addTearDown(() => dir.deleteSync(recursive: true));
    fetches = 0;
    cache = MediaCache(
      Future.value(dir),
      maxBytes: 300,
      now: () => clock = clock.add(const Duration(minutes: 1)),
    );
  });

  Future<File> put(String key, int size, {String extension = 'bin'}) =>
      cache.file(key, (target) async {
        fetches++;
        await target.writeAsBytes(List.filled(size, 0));
      }, extension: extension);

  List<String> names() => [
    for (final f in dir.listSync()) f.uri.pathSegments.last,
  ];

  test('Hash-Dateinamen mit Endung, Treffer ohne erneuten Download', () async {
    final file = await put(
      '1|/dokumente/Brief an Anna.pdf|0',
      10,
      extension: 'pdf',
    );
    expect(file.path, isNot(contains('Anna')));
    expect(file.path, matches(RegExp(r'/[0-9a-f]{64}\.pdf$')));
    expect(
      (await put('1|/dokumente/Brief an Anna.pdf|0', 10)).path,
      isNot(file.path),
      reason: 'andere Endung, anderer Eintrag',
    );
    await put('1|/dokumente/Brief an Anna.pdf|0', 10, extension: 'pdf');
    expect(fetches, 2);
  });

  test('LRU: verdrängt die am längsten nicht benutzte Datei', () async {
    final a = await put('a', 100);
    final b = await put('b', 100);
    await put('c', 100);
    await put('a', 100); // Treffer → a zuletzt benutzt
    await put('d', 100); // 400 > 300: bis 240 verdrängen, also b und c
    expect(await a.exists(), isTrue);
    expect(await b.exists(), isFalse);
    expect(names(), hasLength(2), reason: 'Luft bis 80 % des Limits');
    expect(fetches, 4);
  });

  test('eine zu große Datei bleibt, bis die nächste kommt', () async {
    final big = await put('big', 500);
    expect(await big.exists(), isTrue);
    await put('small', 10);
    expect(await big.exists(), isFalse);
  });

  test('Fehler beim Laden hinterlässt nichts; gleichzeitige Anfragen teilen sich einen Download', () async {
    await expectLater(
      cache.file('x', (target) async {
        await target.writeAsBytes([1]);
        throw const SocketException('weg');
      }),
      throwsA(isA<SocketException>()),
    );
    expect(names(), isEmpty);

    final both = await Future.wait([put('y', 10), put('y', 10)]);
    expect(both[0].path, both[1].path);
    expect(fetches, 1);
  });
}
