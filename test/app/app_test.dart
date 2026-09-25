import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synology_explorer/app/app.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('App startet mit vier Tabs und wechselt den Tab', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const ProviderScope(child: SynologyExplorerApp()));
    await tester.pumpAndSettle();

    final tabs = find.byType(NavigationBar);
    for (final label in ['Dateien', 'Offline', 'Transfers', 'Einstellungen']) {
      expect(find.descendant(of: tabs, matching: find.text(label)), findsOne);
    }
    final body = find.byType(Center);
    expect(find.descendant(of: body, matching: find.text('Dateien')), findsOne);

    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: body, matching: find.text('Einstellungen')),
      findsOne,
    );
  });
}
