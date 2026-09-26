import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:synology_explorer/features/servers/presentation/server_providers.dart';

import 'e2e_harness.dart';

/// Regressionen aus dem E2E-Lauf rund um Screen 01 (Server-Liste).
void main() {
  testWidgets('E2E-009: Einstellungen → Server verwalten → zurück', (
    tester,
  ) async {
    final app = await E2E.start(tester);
    await app.addServerAndLogin();
    await app.tap(find.text(l10n.tabSettings));
    expect(app.location, '/settings');

    await app.tap(find.text(l10n.settingsServers));
    expect(app.location, '/servers');
    await app.backButton();
    expect(app.location, '/settings');

    await app.tap(find.text(l10n.settingsServers));
    expect(await app.systemBack(), isTrue);
    expect(app.location, '/settings');
    await app.dispose();
  });

  testWidgets('E2E-010: Server wechseln → zurück bzw. aktiven Server wählen', (
    tester,
  ) async {
    final app = await E2E.start(tester);
    await app.addServerAndLogin();
    await app.tapThen(find.text('music'), find.text('Bonus'));
    final folder = app.location;

    // Zurück auf Start, dort „Server wechseln“.
    await app.tap(find.byTooltip(l10n.back));
    expect(app.location, '/files');
    await app.tap(find.byTooltip(l10n.switchServer));
    expect(app.location, '/servers');
    await app.backButton();
    expect(app.location, '/files');

    // Aktiven Server antippen: zurück an die alte Stelle, Tabs erhalten.
    await app.tapThen(find.text('music'), find.text('Bonus'));
    await app.tap(find.text(l10n.tabSettings));
    await app.tap(find.text(l10n.settingsServers));
    await app.tap(find.text('Heim-NAS'));
    expect(app.location, '/settings');
    await app.tap(find.text(l10n.tabFiles));
    expect(app.location, folder);
    await app.dispose();
  });

  testWidgets('E2E-001: ohne Session zu Offline und Einstellungen', (
    tester,
  ) async {
    final app = await E2E.start(tester);
    await app.tap(find.byTooltip(l10n.tabOffline));
    expect(app.location, '/offline');
    expect(find.text(l10n.offlineEmpty), findsOneWidget);

    await app.tap(find.text(l10n.tabSettings));
    expect(app.location, '/settings');
    // Dateien braucht eine Session: zurück zu 01.
    await app.tap(find.text(l10n.tabFiles));
    expect(app.location, '/servers');

    await app.tap(find.byTooltip(l10n.tabSettings));
    expect(app.location, '/settings');
    await app.dispose();
  });

  testWidgets('E2E-022: Verwalten per Long-Press ist angekündigt', (
    tester,
  ) async {
    final app = await E2E.start(tester);
    await app.addServerAndLogin();
    await app.tap(find.byTooltip(l10n.switchServer));
    expect(find.textContaining(l10n.serverManageHint), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.hintOverrides?.onLongPressHint ==
                l10n.serverManageAction,
      ),
      findsOneWidget,
    );
    await tester.longPress(find.text('Heim-NAS'));
    await app.settle();
    expect(find.text(l10n.serverLogout), findsOneWidget);
    await app.dispose();
  });

  testWidgets('E2E-058: Verbinden bleibt über der Tastatur erreichbar', (
    tester,
  ) async {
    final app = await E2E.start(tester);
    await app.tapText(l10n.serverAdd);
    // Tastatur mit 300 dp Höhe (Handy 390 × 844 dp, dpr 3).
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await app.settle();

    final button = find.widgetWithText(FilledButton, l10n.connect);
    expect(tester.getRect(button).bottom, lessThanOrEqualTo(844 - 300));
    await tester.tap(button);
    await app.settle();
    expect(find.text(l10n.validationRequired), findsWidgets);
    await app.dispose();
  });

  testWidgets('E2E-023: Bearbeiten mit falschem Passwort behält die Session', (
    tester,
  ) async {
    final app = await E2E.start(tester);
    await app.addServerAndLogin();
    final active = app.container.read(sessionProvider);
    await app.tap(find.byTooltip(l10n.switchServer));
    await tester.longPress(find.text('Heim-NAS'));
    await app.settle();
    await app.tap(find.text(l10n.serverEdit));
    await app.type(find.byType(TextFormField).at(0), 'Heim-NAS 2');
    await app.type(find.byType(TextFormField).at(4), 'falsch');
    await app.tap(find.widgetWithText(FilledButton, l10n.connect));
    await app.waitFor(find.text(l10n.errorUnauthorized));

    expect(app.container.read(sessionProvider), same(active));
    expect(active!.isLoggedIn, isTrue);
    await app.backButton();
    await app.backButton();
    expect(app.location, '/files');
    expect(find.text('music'), findsOneWidget);
    await app.dispose();
  });

  testWidgets('E2E-034: Bearbeiten übernimmt „Passwort merken“', (
    tester,
  ) async {
    final app = await E2E.start(tester);
    await app.addServerAndLogin(rememberPassword: true);
    await app.tap(find.byTooltip(l10n.switchServer));
    await tester.longPress(find.text('Heim-NAS'));
    await app.settle();
    await app.tap(find.text(l10n.serverEdit));
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    await app.dispose();
  });

  testWidgets('E2E-060: Formularfelder tragen ihre Beschriftung', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final app = await E2E.start(tester);
    await app.tapText(l10n.serverAdd);
    final fields = find.byType(TextFormField);
    for (final (i, label) in [
      (0, l10n.fieldName),
      (1, l10n.fieldLanUrl),
      (3, l10n.fieldUser),
      (4, l10n.fieldPassword),
    ]) {
      expect(
        tester.getSemantics(fields.at(i)).label.toLowerCase(),
        contains(label.toLowerCase()),
      );
    }
    await app.dispose();
    semantics.dispose();
  });
}
