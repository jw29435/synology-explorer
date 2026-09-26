import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shelf/shelf.dart' show Response;
import 'package:synology_explorer/app/app.dart';
import 'package:synology_explorer/app/router.dart';
import 'package:synology_explorer/core/storage/app_database.dart';
import 'package:synology_explorer/core/storage/storage_providers.dart';
import 'package:synology_explorer/features/audio/presentation/playback_providers.dart';
import 'package:synology_explorer/features/transfers/presentation/transfer_providers.dart';
import 'package:synology_explorer/l10n/app_localizations.dart';

import '../../tool/mock_nas/mock_nas.dart';
import '../helpers/app_harness.dart' show NoNotifications;
import '../helpers/audio_fakes.dart';
import '../helpers/mock_nas_server.dart';
import '../helpers/settings_fakes.dart';

/// PDFium (pdfrx) liegt nur vor, wenn der Build-Hook von pdfium_dart lokal
/// gelaufen ist; auf dem CI-Runner fehlt es. Flows, die ein PDF wirklich
/// rendern, nehmen diesen Schritt nur dann mit – Screen 17 ist zusätzlich
/// über test/features/viewers/pdf_viewer_screen_test.dart abgedeckt.
final pdfiumAvailable = File('.dart_tool/lib/libpdfium.so').existsSync();

/// Deutsche Texte der App – Tests suchen Widgets über dieselben Strings.
final l10n = lookupAppLocalizations(const Locale('de'));

/// Headless E2E: die ganze App mit echtem HTTP gegen den Mock-NAS.
///
/// Ersetzt werden nur Plattform-Teile: drift in-memory, Secure Storage und
/// path_provider gefaked, Player, Benachrichtigungen, WorkManager und
/// Fotozugriff durch Fakes. Alles andere – Router, Provider, Repositories,
/// `SynoApiClient` mit Re-Login – läuft wie auf dem Gerät.
class E2E {
  E2E._(this.tester, this.nas, this.container, this.db, this.audio);

  final WidgetTester tester;
  final MockNasServer nas;
  final ProviderContainer container;
  final AppDatabase db;
  final FakeAudioController audio;

  /// Startet Mock-NAS und App (auf `/servers`, ohne Server).
  static Future<E2E> start(
    WidgetTester tester, {
    List<Override> overrides = const [],
    Map<String, String> secureStorage = const {},
  }) async {
    // flutter_test beantwortet jedes HTTP mit 400 – hier soll echtes HTTP
    // an den Loopback-Mock gehen.
    final httpOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = httpOverrides);
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    FlutterSecureStorage.setMockInitialValues({...secureStorage});

    final dir = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('e2e'),
    ))!;
    addTearDown(() => dir.delete(recursive: true));
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(pathChannel, (call) async {
      final sub = switch (call.method) {
        'getApplicationCacheDirectory' || 'getTemporaryDirectory' => 'cache',
        _ => 'docs',
      };
      final d = Directory('${dir.path}/$sub')..createSync(recursive: true);
      return d.path;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(pathChannel, null));

    final nas = (await tester.runAsync(
      () => MockNasServer.start(searchTotalLate: true),
    ))!;
    addTearDown(() => tester.runAsync(nas.close));
    final db = AppDatabase(NativeDatabase.memory());
    final audio = FakeAudioController(const AudioState());
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        transferNotificationsProvider.overrideWithValue(NoNotifications()),
        audioControllerProvider.overrideWith(() => audio),
        positionProvider.overrideWith((ref) => Stream.value(Duration.zero)),
        // Freigabelinks echt vom Mock-NAS (Flow 8).
        ...settingsOverrides(fakeShareLinks: false),
        ...overrides,
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SynologyExplorerApp(),
      ),
    );
    final e2e = E2E._(tester, nas, container, db, audio);
    addTearDown(() async {
      if (!e2e._disposed) await e2e.dispose();
    });
    await e2e.settle();
    return e2e;
  }

  bool _disposed = false;

  /// Baut die App ab (Tree, Provider, DB) und lässt Einmal-Timer auslaufen.
  /// Am Ende jedes Tests aufrufen: flutter_test prüft danach, dass kein
  /// Timer mehr aussteht (Polling, das beim Verlassen nicht stoppt, u. ä.).
  Future<void> dispose() async {
    _disposed = true;
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    // Keep-alive-Verbindungen des HttpClient schließen nach 15 s Leerlauf.
    await tester.pump(const Duration(seconds: 20));
    await db.close();
  }

  String get location =>
      container.read(routerProvider).routerDelegate.state.uri.toString();

  /// Frames und echte Zeit abwechselnd, bis [finder] etwas findet bzw. mit
  /// [gone] nichts mehr (höchstens [timeout] echte Zeit). HTTP an den Mock
  /// läuft außerhalb der Fake-Zeit.
  Future<void> waitFor(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
    bool gone = false,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty != gone) {
      if (DateTime.now().isAfter(deadline)) {
        fail(
          '${gone ? 'Nicht verschwunden' : 'Nicht gefunden'} nach $timeout: '
          '$finder (Route: $location)\n'
          'Sichtbar: $visibleTexts',
        );
      }
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pump();
  }

  /// Wie [waitFor], bis [condition] gilt – synchron oder asynchron (z. B.
  /// eine DB-Abfrage, läuft in echter Zeit); [what] für die Fehlermeldung.
  Future<void> waitUntil(
    FutureOr<bool> Function() condition, [
    String what = 'Bedingung',
  ]) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (!(await tester.runAsync(() async => condition()))!) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Nicht eingetreten: $what (Route: $location)');
      }
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pump();
  }

  /// Bis beim Mock mindestens [count] Anfragen [api]/[method] angekommen
  /// sind (z. B. `stop` beim Verlassen).
  Future<void> waitForCalls(String api, String method, int count) => waitUntil(
    () => nas.calls(api, method).length >= count,
    '$count× $api/$method, bisher ${nas.calls(api, method).length}',
  );

  /// Einige Runden Frames + echte Zeit, dann Animationen auslaufen lassen.
  Future<void> settle({int rounds = 10}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
    await tester.pumpAndSettle();
  }

  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    // Nach dem Scrollen erst layouten, sonst trifft der Tipp die alte Stelle.
    await tester.pump();
    await tester.tap(finder);
    await settle();
  }

  Future<void> tapText(String text) => tap(find.text(text).first);

  /// Tippen ohne [settle] – wenn danach ein Spinner läuft (Polling, Paging),
  /// der `pumpAndSettle` nie enden ließe. Weiter mit [waitFor].
  Future<void> press(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
  }

  /// Tippen und ohne `pumpAndSettle` auf [until] warten – für Ziele mit
  /// Ladeanimation (Viewer, Fortschrittsdialog), die nie „settlen“.
  Future<void> tapThen(Finder target, Finder until) async {
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    await waitFor(until);
  }

  /// Text eingeben und einen Frame bauen (Buttons hängen an `onChanged`).
  Future<void> type(Finder field, String text) async {
    await tester.enterText(field, text);
    await tester.pump();
  }

  /// Alle sichtbaren Texte – für Fehlermeldungen der Tests.
  List<String> get visibleTexts => [
    for (final e in find.byType(Text).hitTestable().evaluate())
      (e.widget as Text).data ??
          (e.widget as Text).textSpan?.toPlainText() ??
          '',
  ];

  /// Zurück-Pfeil der AppBar bzw. Schließen-Knopf (Tooltip „Zurück“/
  /// „Schließen“). `pageBack()` aus flutter_test sucht nur den englischen
  /// Tooltip.
  Finder get backButtonFinder {
    // Tooltips von MaterialLocalizations auf Deutsch.
    for (final f in [
      find.byType(BackButton),
      find.byType(CloseButton),
      find.byTooltip('Zurück'),
      find.byTooltip('Schließen'),
      // Now Playing (12) und Queue (13) klappen nach unten weg.
      find.byTooltip(l10n.collapse),
    ]) {
      if (f.hitTestable().evaluate().isNotEmpty) return f.hitTestable().first;
    }
    return find.byType(BackButton).hitTestable();
  }

  /// Zurück über den Zurück-Pfeil (schlägt fehl, wenn es keinen gibt – der
  /// typische „Screen ohne Zurückknopf“-Fehler).
  Future<void> backButton() async {
    final back = backButtonFinder;
    expect(
      back,
      findsOneWidget,
      reason: 'Kein Zurückknopf auf $location. Sichtbar: $visibleTexts',
    );
    await tester.tap(back);
    await settle();
  }

  /// Android-Zurück-Geste. Liefert, ob die App sie selbst verarbeitet hat
  /// (`false` = App würde in den Hintergrund gehen).
  Future<bool> systemBack() async {
    final handled = await tester.binding.handlePopRoute();
    await settle();
    return handled;
  }

  /// Server-Profil über Screen 02 anlegen und anmelden (Mock mit 2FA),
  /// auf Wunsch mit „Passwort merken“ (stiller Re-Login möglich).
  Future<void> addServerAndLogin({bool rememberPassword = false}) async {
    await tapText(l10n.serverAdd);
    final fields = find.byType(TextFormField);
    await type(fields.at(0), 'Heim-NAS');
    await type(fields.at(1), nas.url);
    await type(fields.at(3), mockUser);
    await type(fields.at(4), mockPassword);
    if (rememberPassword) await tapText(l10n.rememberPassword);
    await tap(find.text(l10n.connect));
    await waitFor(find.text(l10n.otpTitle));
    await type(find.byType(TextField).first, mockOtp);
    await tap(find.text(l10n.signIn));
    await waitFor(find.text(l10n.sectionShares.toUpperCase()));
  }

  /// Eigenes Listing für [folder] mit Dateien `name → Größe` (Mock liefert
  /// sonst für jeden Ordner dieselbe Fixture).
  void serveFolder(String folder, Map<String, int> files) {
    nas.intercept = (p) {
      if (p['api'] != 'SYNO.FileStation.List' ||
          p['method'] != 'list' ||
          p['folder_path'] != folder) {
        return null;
      }
      final entries = [
        for (final MapEntry(key: name, value: size) in files.entries)
          {
            'isdir': false,
            'name': name,
            'path': '$folder/$name',
            'additional': {
              'size': size,
              'time': {'mtime': 1778580000, 'crtime': 1778580000},
              'perm': {
                'acl': {'read': true, 'write': true, 'del': true},
              },
            },
          },
      ];
      return Response.ok(
        jsonEncode({
          'success': true,
          'data': {'files': entries, 'offset': 0, 'total': entries.length},
        }),
        headers: {'content-type': 'application/json'},
      );
    };
  }
}
