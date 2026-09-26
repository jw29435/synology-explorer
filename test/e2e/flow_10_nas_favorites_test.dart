import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/features/browser/domain/nas_entry.dart';
import 'package:synology_explorer/features/browser/presentation/browser_providers.dart';

import 'e2e_harness.dart';

/// Phase 6: Screen 05 zeigt die Favoriten des NAS-Kontos (wie DS File).
void main() {
  const fav = 'SYNO.FileStation.Favorite';

  testWidgets('05: NAS-Favoriten, broken gedämpft, Refresh, Verweigerung', (
    tester,
  ) async {
    final app = await E2E.start(tester);
    await app.addServerAndLogin();
    final valid = find.widgetWithText(ActionChip, 'Hörbücher');
    final broken = find.widgetWithText(InputChip, 'Alt-Urlaub');
    await app.waitFor(valid);
    expect(app.nas.calls(fav, 'list'), isNotEmpty);

    // broken: gedämpft, nicht zu öffnen, mit Tooltip.
    expect(tester.widget<InputChip>(broken).onPressed, isNull);
    expect(find.byTooltip(l10n.favoriteBroken), findsOneWidget);

    // Ordner-Favorit öffnet 06.
    await app.tap(valid);
    expect(app.location, contains('H%C3%B6rb%C3%BCcher'));
    await app.backButton();

    // DS File legt einen Favoriten an: Pull-to-Refresh holt ihn.
    final lists = app.nas.calls(fav, 'list').length;
    await app.nas.control.favoritesAdd('/video', 'Filme');
    await tester.fling(find.text('music'), const Offset(0, 400), 1000);
    await app.settle();
    expect(app.nas.calls(fav, 'list').length, greaterThan(lists));
    expect(find.widgetWithText(ActionChip, 'Filme'), findsOneWidget);

    // Verweigert: Meldung, Cache unverändert.
    app.nas.control.denyFavorites = 105;
    await app.tapThen(find.text('music'), find.text('Bonus'));
    await app.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Bonus'),
        matching: find.byTooltip(l10n.more),
      ),
    );
    await app.tapText(l10n.actionFavoriteAdd);
    await app.waitFor(find.text(l10n.favoritesUnavailable));
    await app.backButton();
    expect(find.widgetWithText(ActionChip, 'Bonus'), findsNothing);
    expect(valid, findsOneWidget);

    // Kaputten Favoriten entfernen (Review R-07).
    app.nas.control.denyFavorites = null;
    await app.tap(
      find.descendant(
        of: broken,
        matching: find.byTooltip(l10n.actionFavoriteRemove),
      ),
    );
    await app.waitFor(broken, gone: true);
    expect(app.nas.calls(fav, 'delete').last['path'], '/photo/Urlaub 2019');
    expect(valid, findsOneWidget);
    await app.dispose();
  });

  testWidgets('05: lokaler Datei-Favorit öffnet den Viewer', (tester) async {
    final app = await E2E.start(tester);
    await app.addServerAndLogin();
    await tester.runAsync(
      () => app.container
          .read(localLibraryProvider)
          .setFavorite(
            1,
            const NasEntry(
              path: '/music/Alben/Nordlicht – Treibholz/booklet.pdf',
              name: 'booklet.pdf',
              isDir: false,
              type: NasFileType.pdf,
            ),
            true,
          ),
    );
    final chip = find.widgetWithText(ActionChip, 'booklet.pdf');
    await app.waitFor(chip);
    await app.tapThen(chip, find.byType(BackButton));
    expect(app.location, startsWith('/view'));
    await app.backButton();
    expect(app.location, '/files');
    await app.dispose();
  });
}
