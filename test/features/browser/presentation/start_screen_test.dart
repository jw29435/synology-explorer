import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/l10n/app_localizations.dart';
import 'package:synology_explorer/features/browser/data/local_library_repository.dart';
import 'package:synology_explorer/features/browser/domain/nas_entry.dart';

import '../../../helpers/app_harness.dart';

void main() {
  testWidgets('05: Shares, Favoriten und Zuletzt geöffnet', (tester) async {
    final api = FakeListApi();
    final app = await pumpApp(tester, listApi: api, location: '/files');

    expect(find.text('Heim-NAS'), findsOne);
    expect(find.text('FREIGEGEBENE ORDNER'), findsOne);
    for (final share in ['music', 'photo', 'video', 'dokumente']) {
      expect(find.text(share), findsOne);
    }
    expect(find.text('Nur Lesen'), findsOne, reason: 'video ist RO');
    expect(find.text('FAVORITEN'), findsNothing, reason: 'noch leer');

    final library = LocalLibraryRepository(app.db);
    {
      await library.setFavorite(
        1,
        const NasEntry(
          path: '/music/Hörbücher',
          name: 'Hörbücher',
          isDir: true,
          type: NasFileType.folder,
        ),
        true,
      );
      await library.addRecent(
        1,
        '/music/Alben/Nordlicht – Treibholz/02 Strandgut.flac',
      );
    }
    await tester.pumpAndSettle();
    expect(find.text('FAVORITEN'), findsOne);
    expect(find.text('Hörbücher'), findsOne);
    expect(find.text('02 Strandgut.flac'), findsOne);
    expect(
      find.textContaining('music/Alben/Nordlicht – Treibholz · heute'),
      findsOne,
    );

    await tester.tap(find.text('Hörbücher'));
    await tester.pumpAndSettle();
    expect(api.calls.last.path, '/music/Hörbücher');

    routerOf(app.container).go('/files');
    await tester.pumpAndSettle();
    await tester.tap(find.text('music'));
    await tester.pumpAndSettle();
    expect(api.calls.last.path, '/music');
  });

  testWidgets('01: ohne Session zeigt die App die Server-Liste', (
    tester,
  ) async {
    await pumpApp(tester, loggedIn: false, location: '/files');
    expect(find.text('Server'), findsOne);
    expect(find.text('Noch kein Server eingerichtet.'), findsOne);
  });

  testWidgets('05: keine Shares sichtbar → Hinweis statt Leere (E2E-038)', (
    tester,
  ) async {
    await pumpApp(tester, listApi: _NoShares(), location: '/files');
    expect(
      find.text(lookupAppLocalizations(const Locale('de')).sharesEmpty),
      findsOne,
    );
  });
}

class _NoShares extends FakeListApi {
  @override
  Future<List<NasEntry>> listShares() async => const [];
}
