import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/features/audio/domain/playback_queue.dart';
import 'package:nuvo_explorer/features/browser/data/file_station_list_api.dart';
import 'package:nuvo_explorer/features/browser/domain/nas_entry.dart';

NasEntry file(String path) => NasEntry(
  path: path,
  name: path.substring(path.lastIndexOf('/') + 1),
  isDir: false,
  type: NasFileType.fromName(path),
);

NasEntry dir(String path) => NasEntry(
  path: path,
  name: path.substring(path.lastIndexOf('/') + 1),
  isDir: true,
  type: NasFileType.folder,
);

/// Liefert je Ordner feste Einträge in Seiten zu [pageSize]; sortiert nach
/// Namen, absteigend wenn verlangt – wie das NAS.
class _PagedListApi implements FileStationListApi {
  _PagedListApi(this.folders);

  final Map<String, List<NasEntry>> folders;
  static const pageSize = 2;
  final calls = <({String path, NasSortBy by, bool desc, int offset})>[];

  @override
  Future<NasPage> list(
    String folderPath, {
    NasSortBy sortBy = NasSortBy.name,
    bool descending = false,
    int offset = 0,
    int limit = 500,
  }) async {
    calls.add((path: folderPath, by: sortBy, desc: descending, offset: offset));
    final all = [...folders[folderPath]!]
      ..sort((a, b) => a.name.compareTo(b.name));
    final sorted = descending ? all.reversed.toList() : all;
    return (
      entries: sorted.skip(offset).take(pageSize).toList(),
      total: sorted.length,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final album = [
    file('/m/A/01 Ebbe.flac'),
    file('/m/A/cover.jpg'),
    file('/m/A/02 Strandgut.mp3'),
    dir('/m/A/Bonus'),
    file('/m/A/03 Nebelbank.m4a'),
  ];

  group('Queue-Aufbau', () {
    test('nur Audiodateien, Reihenfolge bleibt, Start am getippten Titel', () {
      final q = PlaybackQueue.fromEntries(
        album,
        startPath: '/m/A/02 Strandgut.mp3',
      );
      expect(q.tracks.map((t) => t.name), [
        '01 Ebbe.flac',
        '02 Strandgut.mp3',
        '03 Nebelbank.m4a',
      ]);
      expect(q.index, 1);
      expect(q.current!.name, '02 Strandgut.mp3');
    });

    test('ohne oder mit unbekanntem Startpfad: erster Titel', () {
      expect(PlaybackQueue.fromEntries(album).index, 0);
      expect(PlaybackQueue.fromEntries(album, startPath: '/x').index, 0);
      expect(PlaybackQueue.fromEntries([file('/m/a.pdf')]).isEmpty, isTrue);
    });

    test('lädt alle Seiten in der verlangten Sortierung', () async {
      final api = _PagedListApi({'/m/A': album});
      final files = await listFilesDeep(
        api,
        '/m/A',
        sortBy: NasSortBy.mtime,
        descending: true,
      );
      expect(api.calls.map((c) => c.offset), [0, 2, 4]);
      expect(api.calls.every((c) => c.by == NasSortBy.mtime && c.desc), true);
      final q = PlaybackQueue.fromEntries(files);
      expect(q.tracks.map((t) => t.name), [
        '03 Nebelbank.m4a',
        '02 Strandgut.mp3',
        '01 Ebbe.flac',
      ]);
    });

    test('rekursiv: Unterordner nach den Dateien, höchstens depth', () async {
      final api = _PagedListApi({
        '/m': [file('/m/intro.mp3'), dir('/m/A')],
        '/m/A': [file('/m/A/a.mp3'), dir('/m/A/B')],
        '/m/A/B': [file('/m/A/B/b.mp3'), dir('/m/A/B/C')],
        '/m/A/B/C': [file('/m/A/B/C/c.mp3')],
      });
      final names = [
        for (final e in await listFilesDeep(api, '/m', depth: 2)) e.name,
      ];
      expect(names, ['intro.mp3', 'a.mp3', 'b.mp3']);
      expect((await listFilesDeep(api, '/m')).map((e) => e.name), [
        'intro.mp3',
      ]);
    });
  });

  group('Shuffle', () {
    final tracks = [for (var i = 0; i < 20; i++) file('/m/$i.mp3')];
    final q = PlaybackQueue(tracks, 7);

    test('gleicher Seed = gleiche Reihenfolge, aktueller Titel vorn', () {
      final a = q.shuffle(42);
      final b = q.shuffle(42);
      expect(a.tracks, b.tracks);
      expect(a.index, 0);
      expect(a.current, tracks[7]);
      expect(a.tracks.toSet(), tracks.toSet());
      expect(q.shuffle(43).tracks, isNot(a.tracks));
    });

    test('unshuffle stellt die Ordnerreihenfolge wieder her', () {
      final shuffled = q.shuffle(1).jump(3);
      final current = shuffled.current;
      final back = shuffled.unshuffle();
      expect(back.tracks, tracks);
      expect(back.current, current);
      expect(back.shuffled, isFalse);
    });
  });

  group('Navigation und Bearbeiten', () {
    final q = PlaybackQueue([
      for (final n in ['a', 'b', 'c']) file('/m/$n.mp3'),
    ], 2);

    test('next/previous je Repeat-Modus', () {
      expect(q.next(QueueRepeat.off), isNull);
      expect(q.next(QueueRepeat.all), 0);
      expect(q.next(QueueRepeat.one), 0);
      expect(q.next(QueueRepeat.one, auto: true), 2);
      expect(q.jump(0).previous(QueueRepeat.off), isNull);
      expect(q.jump(0).previous(QueueRepeat.all), 2);
      expect(q.previous(QueueRepeat.off), 1);
    });

    test('move hält den aktuellen Titel', () {
      final moved = q.jump(1).move(0, 2);
      expect(moved.tracks.map((t) => t.name), ['b.mp3', 'c.mp3', 'a.mp3']);
      expect(moved.current!.name, 'b.mp3');
      final self = q.jump(1).move(1, 0);
      expect(self.current!.name, 'b.mp3');
      expect(self.index, 0);
    });

    test('removeAt vor/auf dem aktuellen Titel', () {
      expect(q.removeAt(0).current!.name, 'c.mp3');
      expect(q.jump(1).removeAt(1).current!.name, 'c.mp3');
      expect(q.removeAt(2).current!.name, 'b.mp3');
    });
  });
}
