import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/features/browser/data/file_station_ops_api.dart';
import 'package:synology_explorer/features/browser/presentation/browser_providers.dart';
import 'package:synology_explorer/features/browser/presentation/entry_widgets.dart';

import '../../../helpers/app_harness.dart';

class FakeOpsApi implements FileStationOpsApi {
  final deleted = <List<String>>[];

  @override
  Future<String> deleteStart(List<String> paths) async {
    deleted.add(paths);
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

void main() {
  const album = '/music/Alben/Nordlicht – Treibholz';

  testWidgets('08: Long-Press, Aktionsleiste, Alle, Löschen mit Bestätigung', (
    tester,
  ) async {
    final ops = FakeOpsApi();
    await pumpApp(
      tester,
      location: folderLocation(album),
      overrides: [fileOpsApiProvider.overrideWithValue(ops)],
    );

    await tester.longPress(find.text('01 Ebbe.flac'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('02 Strandgut.flac'));
    await tester.pumpAndSettle();
    expect(find.text('2 ausgewählt'), findsOne);
    for (final label in [
      'Download',
      'Verschieben',
      'Kopieren',
      'Teilen',
      'Löschen',
    ]) {
      expect(find.text(label), findsOne);
    }
    expect(find.textContaining('Auswahl: '), findsOne);
    expect(find.byType(Checkbox), findsNWidgets(7));
    // Upload-FAB und Kebab verschwinden im Auswahlmodus.
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byTooltip('Mehr'), findsNothing);

    await tester.tap(find.text('Alle'));
    await tester.pumpAndSettle();
    expect(find.text('7 ausgewählt'), findsOne);

    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();
    expect(find.text('7 Elemente löschen?'), findsOne);
    expect(find.textContaining('hat einen Papierkorb'), findsOne);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Löschen'),
      ),
    );
    await tester.pumpAndSettle();
    expect(ops.deleted.single, hasLength(7));
    expect(ops.deleted.single, contains('$album/01 Ebbe.flac'));
    // Nach dem Löschen endet der Auswahlmodus.
    expect(find.textContaining('ausgewählt'), findsNothing);
  });

  testWidgets('08: Download reiht die Auswahl in die Transfers ein', (
    tester,
  ) async {
    final (:container, :db) = await pumpApp(
      tester,
      location: folderLocation(album),
    );
    await tester.longPress(find.text('01 Ebbe.flac'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('02 Strandgut.flac'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Download'));
    // drift arbeitet mit echten Futures/Timern.
    final rows = await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return db.select(db.transfers).get();
    });
    await tester.pumpAndSettle();
    expect(rows!.map((t) => t.remotePath), [
      '$album/01 Ebbe.flac',
      '$album/02 Strandgut.flac',
    ]);
    expect(rows.first.localPath, endsWith('/offline/1$album/01 Ebbe.flac'));
    expect(find.text('2 Downloads eingereiht.'), findsOne);
    expect(container.read(selectionProvider(album)), isEmpty);
  });

  testWidgets('Zurück beendet zuerst den Auswahlmodus', (tester) async {
    await pumpApp(tester, location: folderLocation(album));
    await tester.longPress(find.text('01 Ebbe.flac'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.textContaining('ausgewählt'), findsNothing);
    expect(find.text('01 Ebbe.flac'), findsOne);
  });
}
