import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/mock_nas/mock_nas.dart';
import 'e2e_harness.dart';

/// Flow 1: Erststart → Server anlegen → Validierung → Fehlerzustände →
/// 2FA → Start (05).
void main() {
  testWidgets('Erststart bis Dateien-Start mit Fehlerzuständen', (
    tester,
  ) async {
    final app = await E2E.start(tester);
    expect(find.text(l10n.serverAdd), findsWidgets);

    await app.tapText(l10n.serverAdd);
    expect(app.location, '/servers/new');

    // Validierung: leeres Formular.
    await app.tap(find.text(l10n.connect));
    expect(find.text(l10n.validationRequired), findsWidgets);

    final fields = find.byType(TextFormField);
    await app.type(fields.at(0), 'Heim-NAS');
    await app.type(fields.at(1), app.nas.url);
    await app.type(fields.at(3), mockUser);

    // 400: falsches Passwort – eigener Zustand, kein Retry.
    await app.type(fields.at(4), 'falsch');
    await app.tap(find.text(l10n.connect));
    await app.waitFor(find.text(l10n.errorUnauthorized));
    expect(app.nas.calls('SYNO.API.Auth', 'login'), hasLength(1));

    // 403: OTP nötig → Screen 04; 404: OTP falsch.
    await app.type(fields.at(4), mockPassword);
    await app.tap(find.text(l10n.connect));
    await app.waitFor(find.text(l10n.otpTitle));
    await app.type(find.byType(TextField).first, '000000');
    await app.tap(find.text(l10n.signIn));
    await app.waitFor(find.text(l10n.errorOtpInvalid));

    // 04 → Zurück bricht ab, Formular bleibt.
    await app.backButton();
    expect(find.text(l10n.otpTitle), findsNothing);
    expect(app.location, '/servers/new');

    await app.tap(find.text(l10n.connect));
    await app.waitFor(find.text(l10n.otpTitle));
    await app.type(find.byType(TextField).first, mockOtp);
    await app.tap(find.text(l10n.signIn));
    await app.waitFor(find.text(l10n.sectionShares.toUpperCase()));
    expect(app.location, '/files');
    expect(find.text('music'), findsOneWidget);

    // Tab-Root: Zurück-Geste gibt an das System ab (App in den Hintergrund).
    expect(await app.systemBack(), isFalse);
    await app.dispose();
  });

  testWidgets('Zurück vom Formular ohne Session führt zur Server-Liste', (
    tester,
  ) async {
    final app = await E2E.start(tester);
    await app.tapText(l10n.serverAdd);
    await app.backButton();
    expect(app.location, '/servers');
    await app.tapText(l10n.serverAdd);
    expect(await app.systemBack(), isTrue);
    expect(app.location, '/servers');
    await app.dispose();
  });
}
