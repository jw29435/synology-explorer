import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// Flow 4: Suche (11) – Start, Poll (erst `finished` ohne `total`), Treffer,
/// Typ-Filter, Verlassen stoppt den Task → zurück bis 05.
void main() {
  const search = 'SYNO.FileStation.Search';

  testWidgets(
    'Suche pollt bis total, Filter startet neu, Verlassen räumt auf',
    (tester) async {
      final app = await E2E.start(tester);
      await app.addServerAndLogin();

      Future<void> searchFor(String query) async {
        await app.tap(find.byTooltip(l10n.search));
        expect(app.location, '/files/search');
        expect(find.text(l10n.searchAllShares), findsOneWidget);
        await app.type(find.byType(TextField), query);
      }

      await searchFor('nebel');
      // Erstes list: finished ohne total → Suche läuft weiter.
      await app.waitFor(find.text(l10n.searchRunning(3)));
      await app.waitFor(find.text(l10n.searchDone(3)));
      expect(app.nas.calls(search, 'list'), hasLength(2));
      final start = app.nas.calls(search, 'start').single;
      expect(start, containsPair('pattern', 'nebel'));
      expect(start['folder_path'], contains('/music'));
      expect(find.text('03 Nebelbank.flac'), findsOneWidget);
      expect(find.text('Nebelhorn – Live 2024'), findsOneWidget);

      // Typ-Filter: neue Suche mit Endungen, alter Task aufgeräumt.
      await app.press(find.widgetWithText(ChoiceChip, l10n.filterAudio));
      await app.waitFor(find.text(l10n.searchDone(3)));
      expect(app.nas.calls(search, 'start'), hasLength(2));
      expect(
        app.nas.calls(search, 'start').last['extension']!.split(','),
        contains('flac'),
      );
      await app.waitForCalls(search, 'clean', 1);
      expect(app.nas.calls(search, 'stop'), hasLength(1));
      final selected = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, l10n.filterAudio),
      );
      expect(selected.selected, isTrue);

      // Verlassen per Zurückknopf stoppt und räumt den fertigen Task auf.
      await app.backButton();
      expect(app.location, '/files');
      await app.waitForCalls(search, 'clean', 2);
      expect(app.nas.calls(search, 'stop'), hasLength(2));

      // Verlassen per Zurück-Geste mitten im Poll.
      await searchFor('strand');
      await app.waitFor(find.text(l10n.searchRunning(0)));
      expect(await app.systemBack(), isTrue);
      expect(app.location, '/files');
      await app.waitForCalls(search, 'clean', 3);
      expect(app.nas.calls(search, 'stop'), hasLength(3));
      expect(await app.systemBack(), isFalse);
      await app.dispose();
    },
  );
}
