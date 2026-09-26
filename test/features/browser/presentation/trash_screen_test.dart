import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/core/network/syno_exception.dart';
import 'package:synology_explorer/features/browser/data/file_station_list_api.dart';
import 'package:synology_explorer/features/browser/domain/nas_entry.dart';
import 'package:synology_explorer/l10n/app_localizations.dart';

import '../../../helpers/app_harness.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('de'));

  testWidgets('24: Shares-Fehler zeigt Meldung mit Neuversuch (E2E-002)', (
    tester,
  ) async {
    final api = _SharesFailOnce();
    await pumpApp(tester, listApi: api, location: '/files/trash');

    expect(find.textContaining(l10n.trashChecking), findsNothing);
    expect(find.text(l10n.errorNetwork), findsOne);

    await tester.tap(find.text(l10n.retry));
    await tester.pumpAndSettle();
    expect(find.text(l10n.errorNetwork), findsNothing);
    expect(find.textContaining(l10n.trashInfo), findsOne);
  });

  testWidgets('24: Netzfehler beim Papierkorb heißt nicht „nur Admins“ '
      '(E2E-029)', (tester) async {
    await pumpApp(
      tester,
      listApi: _RecycleFails(const SynoNetworkError()),
      location: '/files/trash',
    );
    expect(find.text(l10n.errorNetwork), findsOne);
    expect(find.textContaining('Admins'), findsNothing);
  });

  testWidgets('24: 407 beim Papierkorb bleibt „nur Admins“', (tester) async {
    await pumpApp(
      tester,
      listApi: _RecycleFails(const SynoPermissionDenied(407)),
      location: '/files/trash',
    );
    expect(find.text(l10n.errorNetwork), findsNothing);
    expect(find.textContaining('Admins'), findsOne);
  });

  testWidgets('24: Papierkorb lädt beim Scrollen die nächste Seite '
      '(E2E-040)', (tester) async {
    final api = _BigRecycle();
    await pumpApp(tester, listApi: api, location: '/files/trash');
    expect(find.text('f0'), findsOne);
    await tester.scrollUntilVisible(
      find.text('f519'),
      2000,
      scrollable: find.byType(Scrollable).first,
    );
    expect(api.calls.map((c) => c.offset), contains(500));
  });
}

/// `/music/#recycle` mit 520 Einträgen in Seiten zu 500, sonst leer.
class _BigRecycle extends FakeListApi {
  @override
  Future<NasPage> list(
    String folderPath, {
    NasSortBy sortBy = NasSortBy.name,
    bool descending = false,
    int offset = 0,
    int limit = 500,
  }) async {
    calls.add((
      path: folderPath,
      by: sortBy,
      descending: descending,
      offset: offset,
    ));
    if (folderPath != '/music/#recycle') {
      return (entries: const <NasEntry>[], total: 0);
    }
    return (
      entries: [
        for (var i = offset; i < 520 && i < offset + limit; i++)
          NasEntry(
            path: '$folderPath/f$i',
            name: 'f$i',
            isDir: false,
            type: NasFileType.other,
          ),
      ],
      total: 520,
    );
  }
}

/// `list` scheitert mit [error], jeder `#recycle` also auch.
class _RecycleFails extends FakeListApi {
  _RecycleFails(this.error);

  final Object error;

  @override
  Future<NasPage> list(
    String folderPath, {
    NasSortBy sortBy = NasSortBy.name,
    bool descending = false,
    int offset = 0,
    int limit = 500,
  }) async => throw error;
}

/// `list_share` scheitert beim ersten Mal (Netz weg), danach Fixtures;
/// jeder `#recycle` ist leer.
class _SharesFailOnce extends FakeListApi {
  var _failed = false;

  @override
  Future<NasPage> list(
    String folderPath, {
    NasSortBy sortBy = NasSortBy.name,
    bool descending = false,
    int offset = 0,
    int limit = 500,
  }) async => (entries: const <NasEntry>[], total: 0);

  @override
  Future<List<NasEntry>> listShares() async {
    if (_failed) return super.listShares();
    _failed = true;
    throw const SynoNetworkError();
  }
}
