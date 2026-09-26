import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/features/audio/data/track_info_loader.dart';
import 'package:synology_explorer/features/browser/domain/nas_entry.dart';

/// Minimaler ID3v2.3-Tag mit Titel, Interpret, Album und Frontcover –
/// so, wie er am Anfang einer MP3 steht.
Uint8List id3Tag({required List<int> cover}) {
  List<int> frame(String id, List<int> body) => [
    ...ascii.encode(id),
    ...[24, 16, 8, 0].map((s) => body.length >> s & 0xff),
    0,
    0,
    ...body,
  ];
  List<int> text(String id, String value) =>
      frame(id, [0, ...latin1.encode(value)]);
  final frames = [
    ...text('TIT2', 'Strandgut'),
    ...text('TPE1', 'Nordlicht'),
    ...text('TALB', 'Treibholz'),
    ...frame('APIC', [0, ...ascii.encode('image/jpeg'), 0, 3, 0, ...cover]),
  ];
  final size = frames.length;
  return Uint8List.fromList([
    ...ascii.encode('ID3'),
    3,
    0,
    0,
    // Größe syncsafe: 4 × 7 Bit.
    for (final s in [21, 14, 7, 0]) size >> s & 0x7f,
    ...frames,
    // Abgeschnittener Audio-Anfang wie beim Range-Prefix.
    ...List.filled(64, 0),
  ]);
}

void main() {
  late Directory tmp;
  late List<({String path, int? maxBytes})> downloads;
  late List<String> thumbs;
  late Map<String, Uint8List> files;

  TrackInfoLoader loader() => TrackInfoLoader(
    download: (path, {maxBytes}) async {
      downloads.add((path: path, maxBytes: maxBytes));
      final bytes = files[path] ?? (throw const SocketException('offline'));
      return maxBytes == null || bytes.length <= maxBytes
          ? bytes
          : bytes.sublist(0, maxBytes);
    },
    thumbnail: (entry) async {
      thumbs.add(entry.path);
      return Uint8List.fromList([9, 9, 9]);
    },
    dir: Future.value(tmp),
  );

  NasEntry entry(String path, {int? size}) => NasEntry(
    path: path,
    name: path.substring(path.lastIndexOf('/') + 1),
    isDir: false,
    type: NasFileType.fromName(path),
    size: size,
    mtime: DateTime.utc(2026, 5, 12),
  );

  final track = entry('/m/A/02 Strandgut.mp3');
  final folderCover = entry('/m/A/cover.jpg', size: 3);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('covers');
    downloads = [];
    thumbs = [];
    files = {
      folderCover.path: Uint8List.fromList([1, 2, 3]),
    };
  });
  tearDown(() => tmp.delete(recursive: true));

  test('1. eingebettetes Cover und Tags aus dem Datei-Anfang', () async {
    files[track.path] = id3Tag(cover: [0xff, 0xd8, 0xff, 0xe0]);
    final info = await loader().load(track, folderCover: folderCover);
    expect(info.title, 'Strandgut');
    expect(info.artist, 'Nordlicht');
    expect(info.album, 'Treibholz');
    expect(await info.cover!.readAsBytes(), [0xff, 0xd8, 0xff, 0xe0]);
    // Nur der Prefix per Range, kein Ordner-Cover.
    expect(downloads, [
      (path: track.path, maxBytes: TrackInfoLoader.prefixBytes),
    ]);

    // Zweiter Aufruf (auch neue Instanz) kommt aus dem Cache.
    final again = await loader().load(track, folderCover: folderCover);
    expect(again.title, 'Strandgut');
    expect(await again.cover!.readAsBytes(), [0xff, 0xd8, 0xff, 0xe0]);
    expect(downloads, hasLength(1));
  });

  test('2. ohne eingebettetes Bild: cover.jpg aus dem Ordner', () async {
    files[track.path] = Uint8List.fromList(List.filled(256, 7));
    final info = await loader().load(track, folderCover: folderCover);
    expect(info.title, isNull);
    expect(await info.cover!.readAsBytes(), [1, 2, 3]);
    expect(downloads.last, (path: folderCover.path, maxBytes: null));
  });

  test('2b. großes Ordner-Cover kommt als Vorschaubild', () async {
    files[track.path] = Uint8List(16);
    final big = entry('/m/A/folder.jpg', size: 50 << 20);
    final info = await loader().load(track, folderCover: big);
    expect(await info.cover!.readAsBytes(), [9, 9, 9]);
    expect(thumbs, [big.path]);
  });

  test('3. weder noch: Platzhalter', () async {
    files[track.path] = Uint8List(16);
    expect((await loader().load(track)).cover, isNull);
    // Ordner-Cover nicht ladbar: ebenfalls Platzhalter statt Fehler.
    final missing = entry('/m/A/folder.png', size: 10);
    expect((await loader().load(track, folderCover: missing)).cover, isNull);
  });

  test('Netzwerkfehler wird nicht als „kein Cover“ gecacht', () async {
    await expectLater(loader().load(track), throwsA(isA<SocketException>()));
    files[track.path] = id3Tag(cover: [1]);
    expect((await loader().load(track)).title, 'Strandgut');
  });

  test(
    'parallele Loads desselben Titels kommen sich nicht in die Quere',
    () async {
      files[track.path] = id3Tag(cover: [5, 6]);
      final results = await Future.wait([
        for (var i = 0; i < 4; i++) loader().load(track),
      ]);
      for (final info in results) {
        expect(info.title, 'Strandgut');
        expect(await info.cover!.readAsBytes(), [5, 6]);
      }
      // Keine liegengebliebenen Zwischendateien.
      expect(
        tmp
            .listSync()
            .map((f) => f.path)
            .where((p) => p.contains('.part') || p.endsWith('.tmp')),
        isEmpty,
      );
    },
  );
}
