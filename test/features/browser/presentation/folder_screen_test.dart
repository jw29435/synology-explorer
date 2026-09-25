import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/features/browser/data/file_station_list_api.dart';
import 'package:synology_explorer/features/browser/presentation/entry_widgets.dart';

import '../../../helpers/app_harness.dart';

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

  testWidgets('06: Long-Press setzt die Auswahl, Grid-Umschalter', (
    tester,
  ) async {
    await pumpApp(tester, location: folderLocation(album));

    await tester.longPress(find.text('02 Strandgut.flac'));
    await tester.pumpAndSettle();
    expect(find.text('1 ausgewählt'), findsOne);

    await tester.tap(find.byTooltip('Rasteransicht'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOne);
    // Ohne Vorschaubild: Typ-Icon mit Namen.
    expect(find.text('cover.jpg'), findsOne);
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
    expect(download.enabled, isFalse);
    expect(find.byTooltip('ab M4'), findsWidgets);

    await tester.tap(find.text('Info'));
    await tester.pumpAndSettle();
    expect(find.text('johann · users'), findsOne);
    expect(find.text('rwxrwxr-x · ACL: Lesen/Schreiben'), findsOne);
  });
}
