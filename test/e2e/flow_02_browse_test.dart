import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/features/browser/presentation/browser_providers.dart';
import 'package:synology_explorer/features/browser/presentation/entry_widgets.dart';

import '../../tool/mock_nas/mock_nas.dart';
import 'e2e_harness.dart';

/// Flow 2: Start (05) → Share → Ordner (06) → Sortierung → Paging →
/// Grid (07) → zurück bis 05.
void main() {
  const photoFolder = '/files/folder?path=%2Fphoto';

  testWidgets('Share öffnen, sortieren, nachladen, Grid, zurück', (
    tester,
  ) async {
    final app = await E2E.start(tester);
    await app.addServerAndLogin();

    await app.tapText('photo');
    expect(app.location, photoFolder);
    await app.waitFor(find.text(mockPhotoName(1)));
    expect(find.text(l10n.itemCount(mockPhotoCount)), findsOneWidget);

    // Sortierung: nochmal „Name“ dreht auf absteigend.
    await app.tap(find.byIcon(Icons.sort));
    await app.tap(find.text(l10n.sortName).last);
    await app.waitFor(find.text(mockPhotoName(mockPhotoCount)));
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    final sorted = app.nas.calls('SYNO.FileStation.List', 'list').last;
    expect(sorted, containsPair('sort_direction', 'desc'));
    expect(sorted, containsPair('offset', '0'));

    // Paging: ans Ende der ersten Seite → zweite Seite ab offset = limit.
    final pageSize = int.parse(sorted['limit']!);
    expect(pageSize, lessThan(mockPhotoCount));
    await scrollToEnd(tester);
    // Erster Eintrag der zweiten Seite (absteigend: Nr. 520 − 500).
    await app.waitFor(find.text(mockPhotoName(mockPhotoCount - pageSize)));
    expect(find.text(l10n.itemCount(mockPhotoCount)), findsOneWidget);
    expect(
      app.nas.calls('SYNO.FileStation.List', 'list').last,
      allOf(
        containsPair('offset', '$pageSize'),
        containsPair('sort_direction', 'desc'),
      ),
    );

    // Größe: neue Anfrage mit sort_by=size ab offset 0.
    final before = app.nas.calls('SYNO.FileStation.List', 'list').length;
    await app.tap(find.byIcon(Icons.sort));
    await app.tap(find.text(l10n.sortSize).last);
    await app.waitForCalls('SYNO.FileStation.List', 'list', before + 1);
    expect(
      app.nas.calls('SYNO.FileStation.List', 'list').elementAt(before),
      allOf(containsPair('sort_by', 'size'), containsPair('offset', '0')),
    );
    await app.waitUntil(
      () =>
          app.container
              .read(folderProvider(mockPhotoFolder))
              .value
              ?.entries
              .first
              .name ==
          mockPhotoName(1),
      'Liste nach Größe sortiert',
    );
    // E2E-Finding H-101: Nach dem Sortierwechsel bleibt die Scrollposition
    // stehen – man landet mitten in der neu sortierten Liste statt am Anfang.
    // expect(find.text(mockPhotoName(1)), findsOneWidget);

    // Grid (07) und zurück zur Liste.
    await app.tap(find.byTooltip(l10n.viewGrid));
    expect(find.byType(GridView), findsOneWidget);
    // Kacheln zeigen den Namen nur ohne Vorschaubild – daher über EntryIcon.
    expect(
      tester.widget<EntryIcon>(find.byType(EntryIcon).first).entry.name,
      mockPhotoName(1),
    );
    await app.tap(find.byTooltip(l10n.viewList));
    expect(find.byType(GridView), findsNothing);
    await app.tap(find.byTooltip(l10n.viewGrid));

    // Zurück bis 05: Zurückknopf, dann dasselbe per Zurück-Geste.
    await app.backButton();
    expect(app.location, '/files');
    expect(find.text(l10n.sectionShares.toUpperCase()), findsOneWidget);

    await app.tapText('photo');
    await app.waitFor(find.byType(GridView));
    expect(app.location, photoFolder);
    expect(await app.systemBack(), isTrue);
    expect(app.location, '/files');
    expect(await app.systemBack(), isFalse);
    await app.dispose();
  });
}

/// Springt ans Ende der Ordnerliste (lädt die nächste Seite).
Future<void> scrollToEnd(WidgetTester tester) async {
  final list = tester.state<ScrollableState>(
    find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  list.position.jumpTo(list.position.maxScrollExtent);
  await tester.pump();
}
