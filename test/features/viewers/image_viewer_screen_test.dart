import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/features/browser/data/file_station_list_api.dart';
import 'package:synology_explorer/features/browser/domain/nas_entry.dart';
import 'package:synology_explorer/features/browser/presentation/entry_widgets.dart';
import 'package:synology_explorer/features/viewers/presentation/viewer_providers.dart';

import '../../helpers/app_harness.dart';
import 'fake_media.dart';

const _folder = '/photo/Urlaub';

NasEntry _file(String name, NasFileType type) => NasEntry(
  path: '$_folder/$name',
  name: name,
  isDir: false,
  type: type,
  size: 1258291,
  mtime: DateTime.utc(2026, 8, 14),
);

/// Ordner mit zwei Bildern (eins davon HEIC) und einem Video dazwischen.
class _PhotoFolder extends FakeListApi {
  @override
  Future<NasPage> list(
    String folderPath, {
    NasSortBy sortBy = NasSortBy.name,
    bool descending = false,
    int offset = 0,
    int limit = 500,
  }) async {
    final entries = [
      _file('IMG_1.jpg', NasFileType.image),
      _file('clip.mp4', NasFileType.video),
      _file('IMG_2.HEIC', NasFileType.image),
    ];
    return (entries: entries, total: entries.length);
  }
}

void main() {
  testWidgets('15: Galerie über die Bilder des Ordners, Favorit', (
    tester,
  ) async {
    final media = FakeMediaRepository({
      'IMG_1.jpg': 'test/fixtures/SYNO.FileStation.Thumb/get.jpg',
      'IMG_2.HEIC': 'test/fixtures/SYNO.FileStation.Thumb/get.jpg',
    });
    final app = await pumpApp(
      tester,
      listApi: _PhotoFolder(),
      location: folderLocation(_folder),
      overrides: [mediaRepositoryProvider.overrideWithValue(media)],
    );

    await tester.tap(find.text('IMG_1.jpg'));
    await pumpWithIo(tester);

    expect(find.text('IMG_1.jpg'), findsOne);
    expect(find.text('1 von 2'), findsOne, reason: 'Video zählt nicht mit');
    expect(find.text('Teilen'), findsOne);
    expect(find.text('In Fotos'), findsOne);
    // Nächstes Bild wird vorgeladen.
    expect(media.requested, contains('$_folder/IMG_2.HEIC'));

    // Tippen blendet die Leisten aus und wieder ein.
    await tester.tapAt(const Offset(195, 420));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('1 von 2'), findsNothing);
    await tester.tapAt(const Offset(195, 420));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('1 von 2'), findsOne);

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await pumpWithIo(tester);
    expect(find.text('2 von 2'), findsOne);
    expect(find.text('IMG_2.HEIC'), findsOne);

    await tester.tap(find.text('Favorit'));
    await pumpWithIo(tester);
    final favorites = await app.db.select(app.db.favorites).get();
    expect(favorites.single.path, '$_folder/IMG_2.HEIC');
    expect(find.byIcon(Icons.star), findsOne);
  });
}
