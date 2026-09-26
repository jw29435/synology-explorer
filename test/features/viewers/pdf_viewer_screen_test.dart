import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:synology_explorer/features/browser/presentation/entry_widgets.dart';
import 'package:synology_explorer/features/viewers/presentation/pdf_viewer_screen.dart';
import 'package:synology_explorer/features/viewers/presentation/viewer_providers.dart';

import '../../helpers/app_harness.dart';
import 'fake_media.dart';

void main() {
  testWidgets('17: Tippen auf PDF lädt mit Fortschritt, dann pdfrx', (
    tester,
  ) async {
    const album = '/music/Alben/Nordlicht – Treibholz';
    final gate = Completer<void>();
    final media = FakeMediaRepository({
      'booklet.pdf': 'test/fixtures/pdf/booklet.pdf',
    }, gate: gate);
    final app = await pumpApp(
      tester,
      location: folderLocation(album),
      overrides: [mediaRepositoryProvider.overrideWithValue(media)],
    );

    await tester.tap(find.text('booklet.pdf'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Wird geladen …'), findsOne);
    expect(find.text('2,4 MB von 4,8 MB'), findsOne);
    expect(media.requested, ['$album/booklet.pdf']);
    // „Zuletzt geöffnet“ merkt sich die Datei.
    final recent = await app.db.select(app.db.recentFiles).get();
    expect(recent.single.path, '$album/booklet.pdf');

    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byType(PdfViewer), findsOne);
    expect(find.text('Wird geladen …'), findsNothing);
    expect(find.byTooltip('Teilen'), findsOne);
  });

  // pdfrx rendert headless nicht (kein PDFium), die Suche geht dort nie auf;
  // daher der Zurück-Teil einzeln.
  testWidgets('E2E-016: Zurück-Geste beendet erst die Suche', (tester) async {
    var searching = true;
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const Text('Ordner')),
    );
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => StatefulBuilder(
            builder: (context, setState) => SearchPopScope(
              searching: searching,
              onEndSearch: () => setState(() => searching = false),
              child: const Text('PDF'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(searching, isFalse);
    expect(find.text('PDF'), findsOne, reason: 'Viewer bleibt offen');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('PDF'), findsNothing);
    expect(find.text('Ordner'), findsOne);
  });
}
