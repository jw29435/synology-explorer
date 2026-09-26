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
