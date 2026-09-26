import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nuvo_explorer/core/auth/session_manager.dart';
import 'package:nuvo_explorer/core/network/syno_exception.dart';
import 'package:nuvo_explorer/features/servers/data/server_repository.dart';
import 'package:nuvo_explorer/features/servers/domain/server_profile.dart';
import 'package:nuvo_explorer/features/servers/presentation/server_form_screen.dart';
import 'package:nuvo_explorer/features/servers/presentation/server_providers.dart';

import '../../../helpers/app_harness.dart';

class _MockSession extends Mock implements SessionManager {}

class _FakeRepo implements ServerRepository {
  _FakeRepo(this.onConnect);

  final Future<SessionManager> Function(ServerProfile) onConnect;
  final saved = <ServerProfile>[];

  @override
  String get deviceName => 'Test';

  @override
  Future<List<ServerProfile>> all() async => [...saved];

  @override
  Future<ServerProfile> add(ServerProfile p) async {
    final withId = p.copyWith(id: saved.length + 1);
    saved.add(withId);
    return withId;
  }

  @override
  Future<void> update(ServerProfile p) async =>
      saved[saved.indexWhere((s) => s.id == p.id)] = p;

  @override
  Future<void> remove(int id) async => saved.removeWhere((s) => s.id == id);

  @override
  Future<SessionManager> connect(ServerProfile p) => onConnect(p);
}

void main() {
  late _MockSession session;

  setUp(() {
    session = _MockSession();
    when(() => session.client).thenReturn(testSession().client);
  });

  void stubLogin(Object? error, {String? otp}) {
    final call = when(
      () => session.login(
        any(),
        any(),
        otp: otp == null ? null : any(named: 'otp'),
        rememberPassword: any(named: 'rememberPassword'),
        trustDevice: any(named: 'trustDevice'),
      ),
    );
    error == null ? call.thenAnswer((_) async {}) : call.thenThrow(error);
  }

  Future<_FakeRepo> open(
    WidgetTester tester, {
    Future<SessionManager> Function(ServerProfile)? onConnect,
  }) async {
    final repo = _FakeRepo(onConnect ?? (_) async => session);
    await pumpApp(
      tester,
      loggedIn: false,
      location: '/servers/new',
      overrides: [serverRepositoryProvider.overrideWithValue(repo)],
    );
    return repo;
  }

  Future<void> fill(WidgetTester tester, {String lan = 'nas.lan:5001'}) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Heim-NAS');
    await tester.enterText(fields.at(1), lan);
    await tester.enterText(fields.at(3), 'johann');
    await tester.enterText(fields.at(4), 'geheim');
  }

  Future<void> connect(WidgetTester tester) async {
    await tester.tap(find.text('Verbinden'));
    await tester.pumpAndSettle();
  }

  testWidgets('02: Pflichtfelder, Adressprüfung, HTTP-Warnung', (tester) async {
    final repo = await open(tester);
    await connect(tester);
    expect(find.text('Pflichtfeld'), findsNWidgets(4));
    expect(repo.saved, isEmpty);

    await fill(tester, lan: 'kein host');
    await connect(tester);
    expect(find.textContaining('Keine gültige Adresse'), findsOne);

    await tester.enterText(find.byType(TextFormField).at(1), 'http://nas');
    await tester.pump();
    expect(find.textContaining('Unverschlüsselt (HTTP)'), findsOne);

    expect(normalizeServerUrl('nas.lan:5001'), 'https://nas.lan:5001');
    expect(normalizeServerUrl('https://nas.lan:5001/'), 'https://nas.lan:5001');
    expect(normalizeServerUrl('ftp://nas'), isNull);
  });

  testWidgets('02: nicht erreichbar → Fehler, Profil bleibt gespeichert', (
    tester,
  ) async {
    final repo = await open(
      tester,
      onConnect: (_) async => throw const SynoNetworkError(),
    );
    await fill(tester);
    await connect(tester);
    expect(find.text('Server nicht erreichbar.'), findsOne);
    expect(repo.saved.single.lanUrl, 'https://nas.lan:5001');

    // Zweiter Versuch aktualisiert dasselbe Profil statt ein neues anzulegen.
    await connect(tester);
    expect(repo.saved, hasLength(1));
  });

  testWidgets('02: falsches Passwort → genau ein Login, kein Retry', (
    tester,
  ) async {
    stubLogin(const SynoUnauthorized(400));
    await open(tester);
    await fill(tester);
    await connect(tester);
    expect(find.text('Benutzer oder Passwort falsch.'), findsOne);
    verify(() => session.login('johann', 'geheim', rememberPassword: false))
        .called(1);
  });

  testWidgets('02: gesperrtes Konto zeigt Auto-Block-Hinweis', (tester) async {
    stubLogin(const SynoAccountLocked(407));
    await open(tester);
    await fill(tester);
    await connect(tester);
    expect(find.textContaining('Auto-Block'), findsOne);
  });

  testWidgets('04: OTP nötig → Code-Screen, falscher Code zeigt Fehler', (
    tester,
  ) async {
    // Spätere Stubs haben Vorrang: ohne OTP → 403, mit OTP → 404.
    stubLogin(const SynoOtpInvalid(404), otp: '000000');
    stubLogin(const SynoOtpRequired(403));
    await open(tester);
    await fill(tester);
    await connect(tester);

    expect(find.text('Zwei-Faktor-Authentifizierung'), findsOne);
    expect(find.textContaining('johann @ Heim-NAS'), findsOne);
    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump();
    await tester.tap(find.text('Anmelden'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Code ungültig oder abgelaufen. Kein automatischer '
        'Neuversuch (Auto-Block).',
      ),
      findsOne,
    );
    verify(
      () => session.login(
        'johann',
        'geheim',
        otp: '000000',
        rememberPassword: false,
        trustDevice: true,
      ),
    ).called(1);
  });
}
