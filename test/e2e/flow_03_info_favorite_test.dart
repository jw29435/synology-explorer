import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/core/utils/format.dart';

import 'e2e_harness.dart';

/// Flow 3: Zeile → Kebab (09) → Info (10) mit DirSize-Polling → Favorit
/// setzen/entfernen (Chip auf 05) → zurück bis 05.
void main() {
  const dirSize = 'SYNO.FileStation.DirSize';
  // Werte aus test/fixtures/SYNO.FileStation.DirSize/status.json; der Mock
  // meldet beim ersten status die halbe Größe, beim zweiten fertig.
  String sizeText(int bytes) =>
      l10n.dirSizeResult(formatSize(bytes, 'de'), '14', '2');
  final partial = sizeText(163577856 ~/ 2);
  final done = sizeText(163577856);

  testWidgets('Info mit Ordnergröße, Favorit als Chip auf Start', (
    tester,
  ) async {
    final app = await E2E.start(tester);
    await app.addServerAndLogin();
    await app.tapText('music');
    await app.waitFor(find.text('Bonus'));

    Future<void> openInfo() async {
      await app.tap(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Bonus'),
          matching: find.byTooltip(l10n.more),
        ),
      );
      expect(find.text(l10n.actionInfo), findsOneWidget);
      await app.tapText(l10n.actionInfo);
      await app.waitFor(find.text(l10n.computeSize));
    }

    // Größe berechnen, beim Zwischenstand per Zurückknopf schließen:
    // der laufende Task wird gestoppt.
    await openInfo();
    expect(find.text(l10n.infoPath), findsOneWidget);
    await app.press(find.text(l10n.computeSize));
    await app.waitFor(find.text(partial));
    expect(app.nas.calls(dirSize, 'start').single['path'], contains('Bonus'));
    await app.backButton();
    expect(find.text(l10n.infoPath), findsNothing);
    await app.waitForCalls(dirSize, 'stop', 1);
    expect(
      app.nas.calls(dirSize, 'stop').single['taskid'],
      contains(app.nas.calls(dirSize, 'status').last['taskid']!),
    );

    // Bis zum Ende rechnen, dann per Zurück-Geste schließen: nichts mehr
    // zu stoppen.
    await openInfo();
    await app.press(find.text(l10n.computeSize));
    await app.waitFor(find.text(done));
    expect(await app.systemBack(), isTrue);
    expect(find.text(l10n.infoPath), findsNothing);
    expect(app.location, startsWith('/files/folder'));
    expect(app.nas.calls(dirSize, 'stop'), hasLength(1));

    // Favorit setzen → Chip auf 05.
    await app.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Bonus'),
        matching: find.byTooltip(l10n.more),
      ),
    );
    await app.tapText(l10n.actionFavoriteAdd);
    await app.backButton();
    expect(app.location, '/files');
    final chip = find.widgetWithText(ActionChip, 'Bonus');
    await app.waitFor(chip);

    // Chip öffnet den Ordner; zurück per Geste.
    await app.tap(chip);
    expect(app.location, contains('Bonus'));
    expect(await app.systemBack(), isTrue);
    expect(app.location, '/files');

    // Favorit wieder entfernen → Chip weg.
    await app.tapText('music');
    await app.waitFor(find.text('Bonus'));
    await app.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Bonus'),
        matching: find.byTooltip(l10n.more),
      ),
    );
    await app.tapText(l10n.actionFavoriteRemove);
    expect(await app.systemBack(), isTrue);
    expect(app.location, '/files');
    expect(chip, findsNothing);
    expect(find.text(l10n.sectionFavorites.toUpperCase()), findsNothing);
    expect(await app.systemBack(), isFalse);
    await app.dispose();
  });
}
