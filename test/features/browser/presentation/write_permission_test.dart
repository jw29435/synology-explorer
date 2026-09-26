import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/features/browser/data/file_station_list_api.dart';
import 'package:synology_explorer/features/browser/domain/nas_entry.dart';
import 'package:synology_explorer/features/browser/presentation/entry_widgets.dart';

import '../../../helpers/app_harness.dart';

/// Wie auf dem Test-NAS: ACL ohne `write` für Ordner und Dateien.
class ReadOnlyListApi extends FakeListApi {
  @override
  Future<NasPage> list(
    String folderPath, {
    NasSortBy sortBy = NasSortBy.name,
    bool descending = false,
    int offset = 0,
    int limit = 500,
  }) async {
    final page = await super.list(folderPath);
    return (
      entries: [
        for (final e in page.entries) e.copyWith(perm: NasPerm.readOnly),
      ],
      total: page.total,
    );
  }

  @override
  Future<NasEntry> getInfo(String path) async =>
      (await super.getInfo(path)).copyWith(perm: NasPerm.readOnly);
}

void main() {
  const album = '/music/Alben/Nordlicht – Treibholz';

  testWidgets('ohne Schreibrecht: FAB erklärt statt Upload-Menü', (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: folderLocation(album),
      listApi: ReadOnlyListApi(),
    );
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Hinzufügen'), findsNothing);
    expect(find.textContaining('Keine Schreibrechte'), findsOne);
  });

  testWidgets('ohne Schreibrecht: Umbenennen/Verschieben aus, Löschen an', (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: folderLocation(album),
      listApi: ReadOnlyListApi(),
    );
    await tester.tap(find.byTooltip('Mehr').at(2));
    await tester.pumpAndSettle();
    ListTile tile(String text) => tester.widget<ListTile>(
      find.ancestor(of: find.text(text), matching: find.byType(ListTile)),
    );
    expect(tile('Umbenennen').enabled, isFalse);
    expect(tile('Verschieben nach …').enabled, isFalse);
    expect(tile('Kopieren nach …').enabled, isTrue);
    expect(tile('Löschen (in Papierkorb)').enabled, isTrue);
  });

  testWidgets('ohne Schreibrecht: Verschieben in der Auswahl erklärt', (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: folderLocation(album),
      listApi: ReadOnlyListApi(),
    );
    await tester.longPress(find.text('01 Ebbe.flac'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verschieben'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.textContaining('Keine Schreibrechte'), findsOne);
  });
}
