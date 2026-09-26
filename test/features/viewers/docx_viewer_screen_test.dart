import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/features/browser/domain/nas_entry.dart';
import 'package:synology_explorer/features/viewers/presentation/viewer_providers.dart';
import 'package:synology_explorer/features/viewers/presentation/viewer_screen.dart';

import '../../helpers/app_harness.dart';
import 'fake_media.dart';

void main() {
  testWidgets('19: Lesemodus mit Banner, Überschrift, Liste und Tabelle', (
    tester,
  ) async {
    final entry = NasEntry(
      path: '/dokumente/Verein/Protokoll.docx',
      name: 'Protokoll.docx',
      isDir: false,
      type: NasFileType.docx,
      size: 86016,
      mtime: DateTime.utc(2026, 9, 12),
    );
    final app = await pumpApp(
      tester,
      location: '/files',
      overrides: [
        mediaRepositoryProvider.overrideWithValue(
          FakeMediaRepository({
            'Protokoll.docx': 'test/fixtures/docx/protokoll.docx',
          }),
        ),
      ],
    );
    routerOf(app.container).push(viewerLocation(entry.path), extra: entry);
    // Parsen läuft im Isolate: warten, bis das Dokument da ist.
    for (
      var i = 0;
      i < 100 && find.text('Protokoll der Vereinssitzung').evaluate().isEmpty;
      i++
    ) {
      await pumpWithIo(tester, rounds: 1);
    }
    await tester.pumpAndSettle();

    expect(find.text('Protokoll.docx'), findsOne);
    expect(find.text('dokumente/Verein · 84 KB'), findsOne);
    expect(
      find.textContaining('Lesemodus: vereinfachte Darstellung'),
      findsOne,
    );
    expect(find.text('Protokoll der Vereinssitzung'), findsOne);
    expect(find.text('1.'), findsOne);
    expect(find.text('Öffnen mit …'), findsOne);
    await tester.scrollUntilVisible(find.text('Halle reservieren'), 200);
    expect(find.text('Halle reservieren'), findsOne);

    // E2E-004: „Herunterladen“ reiht die Datei wie Sheet 09 in die Queue.
    await tester.tap(find.text('Herunterladen'));
    await pumpWithIo(tester);
    final transfers = await tester.runAsync(
      () => app.db.select(app.db.transfers).get(),
    );
    expect(transfers!.single.remotePath, entry.path);
    expect(find.text('1 Download eingereiht.'), findsOne);
    ScaffoldMessenger.of(tester.element(find.byType(SnackBar)))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();

    // „Aa“ vergrößert die Schrift.
    final before = tester.getSize(find.text('Halle reservieren')).height;
    await tester.tap(find.byTooltip('Schriftgröße'));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.text('Halle reservieren')).height,
      greaterThan(before),
    );
  });
}
