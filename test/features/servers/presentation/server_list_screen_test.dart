import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nuvo_explorer/app/theme.dart';
import 'package:nuvo_explorer/features/servers/presentation/server_list_screen.dart';
import 'package:nuvo_explorer/features/servers/presentation/server_providers.dart';
import 'package:nuvo_explorer/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('de'));

  Future<void> pump(WidgetTester tester, List<Override> overrides) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ServerListScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('01: Start-Verbindung mit Text und Abbrechen (E2E-037)', (
    tester,
  ) async {
    final never = Completer<bool>();
    await pump(tester, [
      startupProvider.overrideWith((ref) => never.future),
      serversProvider.overrideWith((ref) async => const []),
    ]);
    expect(find.text(l10n.serverResuming), findsOneWidget);
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
    expect(find.text(l10n.serversEmpty), findsOneWidget);
  });

  testWidgets('01: DB-Fehler ist kein „kein Server“ (E2E-039)', (tester) async {
    await pump(tester, [
      startupProvider.overrideWith((ref) async => false),
      serversProvider.overrideWith((ref) async => throw StateError('db')),
    ]);
    await tester.pumpAndSettle();
    expect(find.text(l10n.serversEmpty), findsNothing);
    expect(find.text(l10n.errorGeneric), findsOneWidget);
  });
}
