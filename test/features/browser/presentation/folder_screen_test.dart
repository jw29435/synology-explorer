import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nuvo_explorer/app/theme.dart';
import 'package:nuvo_explorer/features/settings/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/core/network/syno_exception.dart';
import 'package:nuvo_explorer/features/browser/domain/nas_entry.dart';
import 'package:nuvo_explorer/features/browser/data/file_station_list_api.dart';
import 'package:nuvo_explorer/features/browser/presentation/entry_widgets.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/settings_fakes.dart';

void main() {
  const album = '/music/Alben/Nordlicht – Treibholz';

  testWidgets('06: listet den Ordner, sortiert und dreht die Richtung', (
    tester,
  ) async {
    final api = FakeListApi();
    await pumpApp(tester, listApi: api, location: folderLocation(album));

    expect(find.text('Nordlicht – Treibholz'), findsWidgets);
    expect(find.text('01 Ebbe.flac'), findsOne);
    expect(find.text('7 Elemente'), findsOne);
    expect(api.calls.last, (
      path: album,
      by: NasSortBy.name,
      descending: false,
      offset: 0,
    ));

    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Größe'));
    await tester.pumpAndSettle();
    expect(api.calls.last.by, NasSortBy.size);
    expect(api.calls.last.descending, isFalse);
    expect(find.text('Größe'), findsOne, reason: 'Chip zeigt den Schlüssel');

    // Derselbe Schlüssel noch einmal → absteigend.
    await tester.tap(find.text('Größe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Größe').last);
    await tester.pumpAndSettle();
    expect(api.calls.last.by, NasSortBy.size);
    expect(api.calls.last.descending, isTrue);
    expect(find.byIcon(Icons.arrow_downward), findsOne);
  });

  testWidgets('06: Tippen auf einen Ordner navigiert, Breadcrumb zurück', (
    tester,
  ) async {
    final api = FakeListApi();
    await pumpApp(tester, listApi: api, location: folderLocation(album));

    await tester.tap(find.text('Bonus'));
    await tester.pumpAndSettle();
    expect(api.calls.last.path, '$album/Bonus');
    expect(find.text('Alben'), findsOne, reason: 'Breadcrumb');

    await tester.ensureVisible(find.text('Alben'));
    await tester.tap(find.text('Alben'));
    await tester.pumpAndSettle();
    expect(api.calls.last.path, '/music/Alben');
  });

  testWidgets('06: Breadcrumb poppt zum Ordner im Stack, sonst push '
      '(E2E-017)', (tester) async {
    const search = '/files/search?path=%2Fmusic';
    final app = await pumpApp(tester, location: search);
    final router = routerOf(app.container);
    unawaited(router.push(folderLocation(album)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bonus'));
    await tester.pumpAndSettle();

    // Nicht im Stack: obendrauf, Zurück führt zu Bonus.
    await tester.ensureVisible(find.text('Alben'));
    await tester.tap(find.text('Alben'));
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), folderLocation('/music/Alben'));
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), folderLocation('$album/Bonus'));

    // Im Stack: dorthin zurück, die Suche bleibt darunter.
    await tester.ensureVisible(find.text('Nordlicht – Treibholz'));
    await tester.tap(find.text('Nordlicht – Treibholz'));
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), folderLocation(album));
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), search);
  });

  testWidgets('06: Breadcrumb-Touch-Ziel mindestens 44 px (E2E-053)', (
    tester,
  ) async {
    await pumpApp(tester, location: folderLocation(album));
    final target = tester.getSize(
      find.ancestor(of: find.text('Alben'), matching: find.byType(InkWell)),
    );
    expect(target.height, greaterThanOrEqualTo(44));
    expect(target.width, greaterThanOrEqualTo(44));
  });

  testWidgets('06: Long-Press setzt die Auswahl, Grid-Umschalter', (
    tester,
  ) async {
    await pumpApp(tester, location: folderLocation(album));

    await tester.longPress(find.text('02 Strandgut.flac'));
    await tester.pumpAndSettle();
    expect(find.text('1 ausgewählt'), findsOne);
    await tester.tap(find.byTooltip('Schließen'));
    await tester.pumpAndSettle();
    expect(find.text('1 ausgewählt'), findsNothing);

    await tester.tap(find.byTooltip('Rasteransicht'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOne);
    // Ohne Vorschaubild: Typ-Icon mit Namen.
    expect(find.text('cover.jpg'), findsOne);
  });

  testWidgets('07: Sheet 09 im Grid über Auswahl → Mehr (E2E-021)', (
    tester,
  ) async {
    await pumpApp(tester, location: folderLocation(album));
    await tester.tap(find.byTooltip('Rasteransicht'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Mehr'), findsNothing);

    await tester.longPress(find.text('cover.jpg'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mehr'));
    await tester.pumpAndSettle();
    expect(find.text('Umbenennen'), findsOne);
    expect(find.text('Info'), findsOne);
    expect(find.text('1 ausgewählt'), findsNothing);
  });

  testWidgets('07 Hell: Play-Icon und Badge hell auf dem Scrim (E2E-048)', (
    tester,
  ) async {
    addTearDown(() => AppColors.neutrals = Neutrals.dark);
    final app = await pumpApp(
      tester,
      listApi: _MediaApi(),
      location: folderLocation('/photo'),
      overrides: settingsOverrides(),
    );
    await tester.runAsync(
      () =>
          SettingsRepository(app.db)
              .write(SettingsRepository.themeMode, 'light'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Rasteransicht'));
    await tester.pumpAndSettle();
    expect(AppColors.neutrals, same(Neutrals.light));
    final play = tester.widget<Icon>(find.byIcon(Icons.play_arrow));
    expect(play.color, Neutrals.dark.text);
    expect(
      tester.widget<Text>(find.text('HEIC')).style?.color,
      Neutrals.dark.text,
    );
  });

  testWidgets('07: Typ-Badge außer bei JPEG und Video (E2E-049)', (
    tester,
  ) async {
    await pumpApp(
      tester,
      listApi: _MediaApi(),
      location: folderLocation('/photo'),
    );
    await tester.tap(find.byTooltip('Rasteransicht'));
    await tester.pumpAndSettle();
    expect(find.text('HEIC'), findsOne);
    expect(find.text('PNG'), findsOne);
    expect(find.text('JPG'), findsNothing);
    expect(find.text('MP4'), findsNothing);
  });

  testWidgets('07: Kacheln tragen den Dateinamen als Semantik (E2E-061)', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      listApi: _MediaApi(),
      location: folderLocation('/photo'),
    );
    await tester.tap(find.byTooltip('Rasteransicht'));
    await tester.pumpAndSettle();
    final tile = find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == 'bild.jpg',
    );
    expect(
      tester.getSemantics(tile),
      isSemantics(label: 'bild.jpg', hasTapAction: true),
    );
    semantics.dispose();
  });

  testWidgets('09/10: Kebab öffnet Aktionen, Info zeigt getinfo', (
    tester,
  ) async {
    await pumpApp(tester, location: folderLocation(album));

    await tester.tap(find.byTooltip('Mehr').at(2));
    await tester.pumpAndSettle();
    expect(find.text('Abspielen ab hier'), findsOne);
    final download = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Herunterladen'),
        matching: find.byType(ListTile),
      ),
    );
    expect(download.enabled, isTrue);
    expect(find.byTooltip('ab M4'), findsNothing);

    await tester.ensureVisible(find.text('Info'));
    await tester.tap(find.text('Info'));
    await tester.pumpAndSettle();
    expect(find.text('johann · users'), findsOne);
    expect(find.text('rwxrwxr-x · ACL: Lesen/Schreiben'), findsOne);
    // Zeile „Typ“ (Katalog 10, E2E-050).
    expect(find.text('Typ'), findsOne);
    expect(find.text('FLAC-Audio'), findsOne);
  });

  testWidgets('06: Anmeldefehler → „Anmelden“ statt „Erneut versuchen“', (
    tester,
  ) async {
    final app = await pumpApp(
      tester,
      listApi: _FailingApi(const SynoUnauthorized(400)),
      location: folderLocation(album),
    );
    expect(find.text('Benutzer oder Passwort falsch.'), findsOne);
    expect(find.text('Erneut versuchen'), findsNothing);
    await tester.tap(find.text('Anmelden'));
    await tester.pumpAndSettle();
    expect(routerOf(app.container).state.matchedLocation, '/servers/1');
  });

  testWidgets('06: Refresh-/Sortierfehler als Meldung, Liste bleibt '
      '(E2E-025)', (tester) async {
    final api = _FailingApi(const SynoNetworkError(), firstCall: true);
    await pumpApp(tester, listApi: api, location: folderLocation(album));
    expect(find.text('01 Ebbe.flac'), findsOne);

    await tester.fling(find.text('01 Ebbe.flac'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Server nicht erreichbar.'), findsOne);
    expect(find.text('01 Ebbe.flac'), findsOne);

    ScaffoldMessenger.of(tester.element(find.byType(SnackBar)))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Größe'));
    await tester.pumpAndSettle();
    expect(find.text('Server nicht erreichbar.'), findsOne);
    expect(find.text('01 Ebbe.flac'), findsOne);
  });

  testWidgets('06: Fehler beim Nachladen zeigt Retry am Listenende', (
    tester,
  ) async {
    final api = _FailingApi(const SynoNetworkError(), firstPage: true);
    await pumpApp(tester, listApi: api, location: folderLocation(album));
    await tester.scrollUntilVisible(
      find.text('Erneut versuchen'),
      500,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final calls = api.calls.length;
    await tester.pump(const Duration(seconds: 1));
    expect(api.calls, hasLength(calls), reason: 'kein Auto-Reload');
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    expect(api.calls, hasLength(calls + 1));
  });
}

/// Scheitert immer bzw. mit [firstPage] erst ab der zweiten Seite, mit
/// [firstCall] erst ab dem zweiten Aufruf (Fixtures davor).
class _FailingApi extends FakeListApi {
  _FailingApi(this.error, {this.firstPage = false, this.firstCall = false});

  final Object error;
  final bool firstPage;
  final bool firstCall;

  @override
  Future<NasPage> list(
    String folderPath, {
    NasSortBy sortBy = NasSortBy.name,
    bool descending = false,
    int offset = 0,
    int limit = 500,
  }) async {
    calls.add((
      path: folderPath,
      by: sortBy,
      descending: descending,
      offset: offset,
    ));
    if (firstCall) {
      if (calls.length > 1) throw error;
      final entries = fixtureEntries(
        'SYNO.FileStation.List/list.json',
        'files',
      );
      return (entries: entries, total: entries.length);
    }
    if (!firstPage || offset > 0) throw error;
    return (
      entries: [
        for (var i = 0; i < 30; i++)
          NasEntry(
            path: '/p/$i',
            name: 'Datei $i',
            isDir: false,
            type: NasFileType.other,
          ),
      ],
      total: 60,
    );
  }
}

/// Ein Video, je ein HEIC-, JPEG- und PNG-Bild.
class _MediaApi extends FakeListApi {
  @override
  Future<NasPage> list(
    String folderPath, {
    NasSortBy sortBy = NasSortBy.name,
    bool descending = false,
    int offset = 0,
    int limit = 500,
  }) async => (
    entries: [
      for (final (name, type) in [
        ('clip.mp4', NasFileType.video),
        ('foto.heic', NasFileType.image),
        ('bild.jpg', NasFileType.image),
        ('grafik.png', NasFileType.image),
      ])
        NasEntry(
          path: '$folderPath/$name',
          name: name,
          isDir: false,
          type: type,
        ),
    ],
    total: 4,
  );
}
