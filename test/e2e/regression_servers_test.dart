import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
