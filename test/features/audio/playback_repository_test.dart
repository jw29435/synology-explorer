import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/core/storage/app_database.dart';
import 'package:synology_explorer/features/audio/data/playback_repository.dart';

void main() {
  late AppDatabase db;
  late PlaybackRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PlaybackRepository(db);
  });
  tearDown(() => db.close());

  test('Hörbuch-Modus merkt den letzten Titel nur mit Flag', () async {
    await repo.setLastTrack(1, '/books/x', '/books/x/02.mp3');
    expect(await repo.lastTrack(1, '/books/x'), isNull);

    await repo.setAudiobook(1, '/books/x', true);
    expect(await repo.watchAudiobook(1, '/books/x').first, isTrue);
    await repo.setLastTrack(1, '/books/x', '/books/x/02.mp3');
    expect(await repo.lastTrack(1, '/books/x'), '/books/x/02.mp3');
    // Erneutes Einschalten behält den Titel.
    await repo.setAudiobook(1, '/books/x', true);
    expect(await repo.lastTrack(1, '/books/x'), '/books/x/02.mp3');

    await repo.setAudiobook(1, '/books/x', false);
    expect(await repo.watchAudiobook(1, '/books/x').first, isFalse);
    expect(await repo.lastTrack(1, '/books/x'), isNull);
  });

  test('Streaming nur im WLAN: Default aus', () async {
    expect(await repo.wifiOnly(), isFalse);
    await repo.setWifiOnly(true);
    expect(await repo.wifiOnly(), isTrue);
  });
}
