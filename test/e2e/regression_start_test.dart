import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_harness.dart';

/// Regressionen aus dem E2E-Lauf auf Screen 05 (Dateien – Start).
void main() {
  testWidgets('E2E-019: „Zuletzt geöffnet“ öffnet die Datei', (tester) async {
    final app = await E2E.start(tester);
    await app.addServerAndLogin();
    await app.tapThen(find.text('music'), find.text('booklet.pdf'));
    await app.tapThen(find.text('booklet.pdf'), find.byType(BackButton));
    expect(app.location, startsWith('/view'));
    await app.backButton();
    await app.backButton();
    expect(app.location, '/files');

    await app.tapThen(find.text('booklet.pdf'), find.byType(BackButton));
    expect(app.location, startsWith('/view'));
    await app.backButton();
    expect(app.location, '/files');
    await app.dispose();
  });
}
