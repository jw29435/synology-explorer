import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nuvo_explorer/app/app.dart';
import 'package:nuvo_explorer/app/router.dart';
import 'package:nuvo_explorer/core/auth/session_manager.dart';
import 'package:nuvo_explorer/core/network/certificate_pinning.dart';
import 'package:nuvo_explorer/core/network/syno_api_client.dart';
import 'package:nuvo_explorer/core/storage/app_database.dart';
import 'package:nuvo_explorer/core/storage/storage_providers.dart';
import 'package:nuvo_explorer/features/browser/data/file_station_list_api.dart';
import 'package:nuvo_explorer/features/browser/data/thumbnail_cache.dart';
import 'package:nuvo_explorer/features/browser/domain/nas_entry.dart';
import 'package:nuvo_explorer/features/browser/presentation/browser_providers.dart';
import 'package:nuvo_explorer/features/servers/domain/server_profile.dart';
import 'package:nuvo_explorer/features/servers/presentation/server_providers.dart';
import 'package:nuvo_explorer/features/transfers/data/offline_store.dart';
import 'package:nuvo_explorer/features/transfers/data/transfer_queue.dart';
import 'package:nuvo_explorer/features/transfers/presentation/transfer_notifications.dart';
import 'package:nuvo_explorer/features/transfers/presentation/transfer_providers.dart';

const testProfile = ServerProfile(
  id: 1,
  name: 'Heim-NAS',
  lanUrl: 'https://nas.lan:5001',
  user: 'johann',
);

List<NasEntry> fixtureEntries(String file, String key) => [
  for (final e
      in (jsonDecode(File('test/fixtures/$file').readAsStringSync())
              as Map)['data'][key]
          as List)
    NasEntry.fromSyno(e as Map<String, dynamic>),
];

/// `list`/`list_share` aus den Fixtures; merkt sich jeden `list`-Aufruf.
class FakeListApi implements FileStationListApi {
  final calls = <({String path, NasSortBy by, bool descending, int offset})>[];

  @override
  Future<List<NasEntry>> listShares() async =>
      fixtureEntries('SYNO.FileStation.List/list_share.json', 'shares');

  @override
  Future<NasPage> list(
    String folderPath, {
    NasSortBy sortBy = NasSortBy.name,
    bool descending = false,
    int offset = 0,
    int limit = 500,
  }) async {
    calls.add((
      path: folderPath,
      by: sortBy,
      descending: descending,
      offset: offset,
    ));
    final entries = fixtureEntries('SYNO.FileStation.List/list.json', 'files');
    return (entries: entries, total: entries.length);
  }

  @override
  Future<NasEntry> getInfo(String path) async =>
      fixtureEntries('SYNO.FileStation.List/getinfo.json', 'files').single;

  @override
  Future<Map<String, DateTime?>> mtimes(List<String> paths) async => {};
}

/// Liefert nie ein Vorschaubild – das Grid zeigt Typ-Icons.
class NoThumbnails implements ThumbnailCache {
  @override
  Future<Uint8List> load(NasEntry entry) async => throw StateError('kein Bild');

  @override
  int get maxBytes => 0;
}

/// Keine Plattform-Benachrichtigungen in Widget-Tests.
class NoNotifications implements TransferNotifications {
  @override
  Future<void> update(List<Transfer> transfers) async {}
}

class FixedSession extends SessionNotifier {
  FixedSession(this._session);

  final SessionManager? _session;

  @override
  SessionManager? build() => _session;
}

/// Echte [SessionManager]-Instanz ohne Netzwerk (für Profil/Adresse).
SessionManager testSession() {
  const storage = FlutterSecureStorage();
  return SessionManager(
    SynoApiClient(testProfile, CertificatePinStore(storage)),
    storage,
    deviceName: 'Test',
  );
}

/// Startet die App auf [location] mit In-Memory-DB und den [overrides].
/// Mit [loggedIn] ist eine Session aktiv (Dateien-Tab erreichbar).
Future<({ProviderContainer container, AppDatabase db})> pumpApp(
  WidgetTester tester, {
  String? location,
  bool loggedIn = true,
  FileStationListApi? listApi,
  List<Override> overrides = const [],
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  tester.platformDispatcher.localesTestValue = const [Locale('de')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  // Handygröße (Mockups: 390 × 844 dp).
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  FlutterSecureStorage.setMockInitialValues({});
  final db = AppDatabase(NativeDatabase.memory());
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      if (loggedIn)
        sessionProvider.overrideWith(() => FixedSession(testSession())),
      startupProvider.overrideWith((ref) async => false),
      fileStationListApiProvider.overrideWithValue(listApi ?? FakeListApi()),
      thumbnailCacheProvider.overrideWithValue(NoThumbnails()),
      transferNotificationsProvider.overrideWithValue(NoNotifications()),
      offlineStoreProvider.overrideWith(
        (ref) => OfflineStore(
          ref.watch(appDatabaseProvider),
          Future.value(Directory('${Directory.systemTemp.path}/offline')),
        ),
      ),
      // Queue ohne Worker: Widget-Tests übertragen nichts übers Netz.
      transferQueueProvider.overrideWith(
        (ref) => TransferQueue(
          ref.watch(appDatabaseProvider),
          serverId: ref.watch(sessionProvider)?.client.profile.id,
        ),
      ),
      ...overrides,
    ],
  );
  addTearDown(() async {
    // Erst den Baum abbauen (Streams abmelden), dann Container und DB.
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await db.close();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const NuvoExplorerApp(),
    ),
  );
  await tester.pump();
  if (location != null) {
    container.read(routerProvider).go(location);
  }
  await tester.pumpAndSettle();
  return (container: container, db: db);
}

GoRouter routerOf(ProviderContainer c) => c.read(routerProvider);
