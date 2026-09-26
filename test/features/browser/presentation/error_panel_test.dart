import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/core/network/syno_exception.dart';
import 'package:nuvo_explorer/features/browser/data/file_station_list_api.dart';
import 'package:nuvo_explorer/features/browser/presentation/entry_widgets.dart';
import 'package:nuvo_explorer/l10n/app_localizations.dart';

import '../../../helpers/app_harness.dart';

class _Expired extends FakeListApi {
  @override
  Future<NasPage> list(
    String folderPath, {
    NasSortBy sortBy = NasSortBy.name,
    bool descending = false,
    int offset = 0,
    int limit = 500,
  }) async => throw const SynoSessionExpired();
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('de'));

  testWidgets('„Anmelden“ im Fehlerpanel: Formular per push (E2E-013)', (
    tester,
  ) async {
    final app = await pumpApp(
      tester,
      listApi: _Expired(),
      location: folderLocation('/music'),
    );
    await tester.tap(find.widgetWithText(OutlinedButton, l10n.signIn));
    await tester.pumpAndSettle();
    expect(routerOf(app.container).state.uri.path, '/servers/1');

    await tester.tap(find.byTooltip(l10n.back));
    await tester.pumpAndSettle();
    expect(routerOf(app.container).state.uri.path, '/files/folder');
  });
}
