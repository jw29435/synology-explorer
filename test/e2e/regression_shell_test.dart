import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// Regressionen aus dem E2E-Lauf rund um die Tab-Shell.
void main() {
  testWidgets('E2E-059: Zurück auf einem anderen Tab-Root', (tester) async {
    final app = await E2E.start(tester);
    await app.addServerAndLogin();
    await app.tapThen(find.text('music'), find.text('Bonus'));
    final folder = app.location;
    await app.tap(find.text(l10n.tabTransfers));
    expect(app.location, '/transfers');

    // Zurück führt zum Dateien-Tab, dessen Ordner-Stack bleibt.
    expect(await app.systemBack(), isTrue);
    expect(app.location, folder);
    expect(await app.systemBack(), isTrue);
    expect(app.location, '/files');
    expect(await app.systemBack(), isFalse, reason: 'Start: App schließt');

    // Unterseite im Einstellungen-Tab: normales Zurück dorthin.
    await app.tap(find.text(l10n.tabSettings));
    await app.tap(find.text(l10n.shareLinksTitle));
    expect(app.location, '/settings/shares');
    expect(await app.systemBack(), isTrue);
    expect(app.location, '/settings');
    expect(await app.systemBack(), isTrue);
    expect(app.location, '/files');
    await app.dispose();
  });
}
