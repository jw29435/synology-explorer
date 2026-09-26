import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:synology_explorer/features/browser/presentation/entry_widgets.dart';
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
}
