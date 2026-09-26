import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/mock_nas/mock_nas.dart';
import 'e2e_harness.dart';

const _albumName = 'Nordlicht – Treibholz';

/// Flow 9: Session läuft mitten im Flow ab (119) → genau ein stiller
/// Re-Login, es geht weiter; scheitert der Re-Login → Meldung und laut
/// CONCEPT (Abschnitt 4) Rückkehr zur Anmeldung (01).
void main() {
  Future<E2E> openMusic(WidgetTester tester, {required bool remember}) async {
    final app = await E2E.start(tester);
    await app.addServerAndLogin(rememberPassword: remember);
    await app.tapThen(find.text('music'), find.text('Bonus'));
    return app;
  }

  int logins(E2E app) => app.nas.calls('SYNO.API.Auth', 'login').length;

  testWidgets('119 mit gemerktem Passwort: genau ein Re-Login, weiter', (
    tester,
  ) async {
    final app = await openMusic(tester, remember: true);
    final before = logins(app);

    app.nas.control.expireSessions();
    // Breadcrumb des Unterordners (Pfad aus der Fixture).
    await app.tapThen(find.text('Bonus'), find.text(_albumName));
    expect(app.location, contains('Bonus'));
    await app.waitFor(find.text('cover.jpg'));
    // E2E-063: list, getinfo und Thumb laufen parallel mit der alten SID –
    // trotzdem genau ein Re-Login.
    expect(logins(app), before + 1, reason: 'genau ein Re-Login');
    // Stiller Re-Login mit Geräte-Token: kein OTP.
    expect(app.nas.calls('SYNO.API.Auth', 'login').last['otp_code'], isNull);
    expect(find.text(l10n.errorSessionExpired), findsNothing);

    // Nochmal ablaufen lassen: der Viewer lädt nach einem Re-Login.
    final mid = logins(app);
    app.nas.control.expireSessions();
    await app.tapThen(
      find.text('cover.jpg'),
      find.text(l10n.imageOf('1', '1')),
    );
    expect(logins(app), mid + 1);
    await app.backButton();

    // Zurück bis zum Start (05): Zurückknopf, dann Zurück-Geste.
    await app.backButton();
    expect(app.location, startsWith('/files/folder'));
    expect(await app.systemBack(), isTrue);
    expect(app.location, '/files');
    expect(await app.systemBack(), isFalse);
    await app.dispose();
  });

  testWidgets('Re-Login scheitert: ein Versuch, Meldung, zurück zu 01', (
    tester,
  ) async {
    final app = await openMusic(tester, remember: true);
    final before = logins(app);

    // Passwort auf dem NAS geändert: stiller Login scheitert (400).
    app.nas.control
      ..expireSessions()
      ..rejectLogin = true;
    // E2E-012: Die App verwirft die Session und führt mit Meldung zu 01.
    await app.tapThen(find.text('Bonus'), find.text(l10n.errorSessionExpired));
    await app.settle();
    expect(app.location, '/servers?expired=1');
    expect(logins(app), before + 1, reason: 'kein zweiter Login-Versuch');
    expect(find.text(l10n.serverNotConnected), findsOneWidget);

    // E2E-014: Die Karte führt zur Anmeldung (02), nicht in die Fehlerseite.
    app.nas.control.rejectLogin = false;
    await app.tapThen(find.text('Heim-NAS'), find.text(l10n.connect));
    expect(app.location, startsWith('/servers/'));
    expect(logins(app), before + 1, reason: 'Verbinden allein meldet nicht an');
    await app.type(find.byType(TextFormField).at(3), mockPassword);
    await app.tapThen(
      find.text(l10n.connect),
      find.text(l10n.sectionShares.toUpperCase()),
    );
    expect(logins(app), before + 2);
    expect(app.location, '/files');
    expect(await app.systemBack(), isFalse);
    await app.dispose();
  });

  testWidgets('119 ohne gemerktes Passwort: kein Login-Versuch, Meldung', (
    tester,
  ) async {
    final app = await openMusic(tester, remember: false);
    final before = logins(app);

    app.nas.control.expireSessions();
    await app.tapThen(find.text('Bonus'), find.text(l10n.errorSessionExpired));
    await app.settle();
    expect(logins(app), before, reason: 'ohne Passwort kein stiller Login');
    // E2E-012: zurück zu 01 mit Meldung; 01 ist jetzt der Einstieg.
    expect(app.location, '/servers?expired=1');
    expect(await app.systemBack(), isFalse);
    await app.dispose();
  });
}
