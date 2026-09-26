import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/core/storage/app_database.dart';
import 'package:nuvo_explorer/features/browser/domain/nas_entry.dart';
import 'package:nuvo_explorer/features/viewers/data/playback_position_repository.dart';

void main() {
  late AppDatabase db;
  late PlaybackPositionRepository positions;
  final video = NasEntry(
    path: '/video/Drohne.mp4',
    name: 'Drohne.mp4',
    isDir: false,
    type: NasFileType.video,
    mtime: DateTime.utc(2026, 8, 1),
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    positions = PlaybackPositionRepository(db, 1);
  });

  test('speichert je Server und Datei; geänderte Datei verwirft', () async {
    expect(await positions.load(video), isNull);
    await positions.save(video, const Duration(seconds: 102));
    expect(await positions.load(video), const Duration(seconds: 102));
    expect(await PlaybackPositionRepository(db, 2).load(video), isNull);

    final changed = video.copyWith(mtime: DateTime.utc(2026, 9, 1));
    expect(await positions.load(changed), isNull);

    await positions.clear(video);
    expect(await positions.load(video), isNull);
  });

  test('Resume-Regeln: nicht am Anfang, nicht ab 95 %', () {
    const total = Duration(minutes: 10);
    bool keep(Duration d) => PlaybackPositionRepository.worthKeeping(d, total);
    expect(keep(const Duration(seconds: 9)), isFalse);
    expect(keep(const Duration(seconds: 10)), isTrue);
    expect(keep(const Duration(minutes: 9, seconds: 29)), isTrue);
    expect(keep(const Duration(minutes: 9, seconds: 30)), isFalse);
  });
}
