import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/app/theme.dart';
import 'package:nuvo_explorer/features/browser/data/file_station_list_api.dart';
import 'package:nuvo_explorer/features/browser/data/file_station_ops_api.dart';
import 'package:nuvo_explorer/features/browser/domain/nas_entry.dart';
import 'package:nuvo_explorer/features/browser/presentation/browser_providers.dart';
import 'package:nuvo_explorer/features/browser/presentation/entry_widgets.dart';
import 'package:nuvo_explorer/features/settings/presentation/settings_providers.dart';
import 'package:nuvo_explorer/features/viewers/presentation/image_viewer_screen.dart';
import 'package:nuvo_explorer/features/viewers/presentation/viewer_providers.dart';
import 'package:nuvo_explorer/features/viewers/presentation/viewer_screen.dart';

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
      for (final e in [
        _file('IMG_1.jpg', NasFileType.image),
        _file('clip.mp4', NasFileType.video),
        _file('IMG_2.HEIC', NasFileType.image),
      ])
        if (!deleted.contains(e.path)) e,
    ];
    return (entries: entries, total: entries.length);
  }

  final deleted = <String>{};
}

/// Löschen-Task, der sofort fertig ist und die Datei aus [folder] nimmt.
class _Ops implements FileStationOpsApi {
  _Ops(this.folder);

  final _PhotoFolder folder;

  @override
  Future<String> deleteStart(List<String> paths) async {
    folder.deleted.addAll(paths);
    return 'task';
  }

  @override
  Future<TaskProgress> deleteStatus(String taskId) async =>
      (finished: true, progress: 1.0);

  @override
  Future<void> deleteStop(String taskId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _confirmDelete(WidgetTester tester) async {
  await tester.tap(find.text('Löschen'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Löschen'),
    ),
  );
  await pumpWithIo(tester);
  await tester.pumpAndSettle();
}

/// Der Ordner lädt nie fertig (langsames Netz).
class _SlowFolder extends FakeListApi {
  @override
  Future<NasPage> list(
    String folderPath, {
    NasSortBy sortBy = NasSortBy.name,
    bool descending = false,
    int offset = 0,
    int limit = 500,
  }) => Completer<NasPage>().future;
}

void main() {
  testWidgets('E2E-043: Zurück, während der Ordner lädt', (tester) async {
    final app = await pumpApp(
      tester,
      listApi: _SlowFolder(),
      location: '/files',
    );
    final entry = _file('IMG_1.jpg', NasFileType.image);
    routerOf(app.container).push(viewerLocation(entry.path), extra: entry);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CircularProgressIndicator), findsOne);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      routerOf(app.container).routerDelegate.state.uri.toString(),
      '/files',
    );
  });

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

  testWidgets('E2E-003: Löschen mit Bestätigung, dann nächstes Bild', (
    tester,
  ) async {
    final folder = _PhotoFolder();
    await pumpApp(
      tester,
      listApi: folder,
      location: folderLocation(_folder),
      overrides: [
        mediaRepositoryProvider.overrideWithValue(
          FakeMediaRepository({
            'IMG_1.jpg': 'test/fixtures/SYNO.FileStation.Thumb/get.jpg',
            'IMG_2.HEIC': 'test/fixtures/SYNO.FileStation.Thumb/get.jpg',
          }),
        ),
        fileOpsApiProvider.overrideWithValue(_Ops(folder)),
      ],
    );
    await tester.tap(find.text('IMG_1.jpg'));
    await pumpWithIo(tester);
    expect(find.text('1 von 2'), findsOne);

    await _confirmDelete(tester);
    expect(folder.deleted, {'$_folder/IMG_1.jpg'});
    expect(find.text('IMG_2.HEIC'), findsOne);
    expect(find.text('1 von 1'), findsOne);

    // Das letzte Bild gelöscht: zurück im Ordner.
    await _confirmDelete(tester);
    expect(find.text('1 von 1'), findsNothing);
    expect(find.text('clip.mp4'), findsOne);
    expect(find.text('IMG_2.HEIC'), findsNothing);
  });

  testWidgets('E2E-047: Design „Hell“ – Leisten hell auf dunklem Scrim', (
    tester,
  ) async {
    addTearDown(() => AppColors.neutrals = Neutrals.dark);
    await pumpApp(
      tester,
      listApi: _PhotoFolder(),
      location: folderLocation(_folder),
      overrides: [
        themeModeProvider.overrideWith((ref) => Stream.value(ThemeMode.light)),
        mediaRepositoryProvider.overrideWithValue(
          FakeMediaRepository({
            'IMG_1.jpg': 'test/fixtures/SYNO.FileStation.Thumb/get.jpg',
            'IMG_2.HEIC': 'test/fixtures/SYNO.FileStation.Thumb/get.jpg',
          }),
        ),
      ],
    );
    expect(AppColors.neutrals, same(Neutrals.light));
    await tester.tap(find.text('IMG_1.jpg'));
    await pumpWithIo(tester);

    Color text(String label) {
      final element = tester.element(find.text(label));
      final style = (element.widget as Text).style;
      return DefaultTextStyle.of(element).style.merge(style).color!;
    }

    bool light(Color c) => c.computeLuminance() > 0.3;
    for (final label in ['IMG_1.jpg', '1 von 2', 'Teilen', 'Favorit']) {
      expect(light(text(label)), isTrue, reason: label);
    }
    expect(text('Löschen'), Neutrals.dark.errorSoft);
    expect(
      light(
        IconTheme.of(tester.element(find.byIcon(Icons.info_outline))).color!,
      ),
      isTrue,
    );
    final status = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find
          .descendant(
            of: find.byType(ImageViewerScreen),
            matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
          )
          .first,
    );
    expect(status.value.statusBarIconBrightness, Brightness.light);
  });
}
