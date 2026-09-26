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
    ServerProfile? existing,
  }) async {
    final repo = _FakeRepo(onConnect ?? (_) async => session);
    if (existing != null) await repo.add(existing);
    await pumpApp(
      tester,
      loggedIn: false,
      location: existing == null ? '/servers/new' : '/servers/1',
      overrides: [serverRepositoryProvider.overrideWithValue(repo)],
    );
    return repo;
  }

  // Eingeklappt: Name, Adresse, Benutzer, Passwort.
  Future<void> fill(
    WidgetTester tester, {
    String name = 'Heim-NAS',
    String lan = 'nas.lan:5001',
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), name);
    await tester.enterText(fields.at(1), lan);
    await tester.enterText(fields.at(2), 'johann');
    await tester.enterText(fields.at(3), 'geheim');
  }

  Future<void> connect(WidgetTester tester) async {
    await tester.tap(find.text('Verbinden'));
    await tester.pumpAndSettle();
  }

  testWidgets('02: Pflichtfelder, Adressprüfung, HTTP-Warnung', (tester) async {
    final repo = await open(tester);
    await connect(tester);
    expect(find.text('Pflichtfeld'), findsNWidgets(3));
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

  testWidgets('02: Standardansicht ohne zweite Adresse, aufklappbar', (
    tester,
  ) async {
    final repo = await open(
      tester,
      onConnect: (_) async => throw const SynoNetworkError(),
    );
    expect(find.text('ADRESSE'), findsOne);
    expect(find.text('BENUTZER'), findsOne);
    expect(find.text('PASSWORT'), findsOne);
    expect(find.text('EXTERNE ADRESSE (OPTIONAL)'), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(4));

    await tester.tap(find.text('Zweite Adresse für unterwegs'));
    await tester.pump();
    expect(find.text('EXTERNE ADRESSE (OPTIONAL)'), findsOne);
    await tester.enterText(find.byType(TextFormField).at(2), 'nas.example.de');

    // Zuklappen leert das Feld nicht; die Adresse wird trotzdem gespeichert.
    await tester.tap(find.text('Zweite Adresse ausblenden'));
    await tester.pump();
    expect(find.text('EXTERNE ADRESSE (OPTIONAL)'), findsNothing);
    await fill(tester);
    await connect(tester);
    expect(repo.saved.single.externalUrl, 'https://nas.example.de');
  });

  testWidgets('02: ungültige zweite Adresse klappt den Bereich auf', (
    tester,
  ) async {
    final repo = await open(tester);
    await tester.tap(find.text('Zweite Adresse für unterwegs'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(2), 'kein host');
    await tester.tap(find.text('Zweite Adresse ausblenden'));
    await tester.pump();
    await fill(tester);
    await connect(tester);
    expect(find.text('EXTERNE ADRESSE (OPTIONAL)'), findsOne);
    expect(find.textContaining('Keine gültige Adresse'), findsOne);
    expect(repo.saved, isEmpty);
  });

  testWidgets('02: Bearbeiten mit zweiter Adresse ist aufgeklappt', (
    tester,
  ) async {
    await open(
      tester,
      existing: const ServerProfile(
        name: 'Heim-NAS',
        lanUrl: 'https://192.168.1.20:5001',
        externalUrl: 'https://nas.example.de',
        user: 'johann',
      ),
    );
    expect(find.text('EXTERNE ADRESSE (OPTIONAL)'), findsOne);
    expect(find.text('https://nas.example.de'), findsOne);
    expect(find.text('Zweite Adresse ausblenden'), findsOne);
  });

  testWidgets('02: leerer Name → Host der Adresse', (tester) async {
    final repo = await open(
      tester,
      onConnect: (_) async => throw const SynoNetworkError(),
    );
    await fill(tester, name: '', lan: 'https://nas.lan:5001/');
    await connect(tester);
    expect(repo.saved.single.name, 'nas.lan');
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
