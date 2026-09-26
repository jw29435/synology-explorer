import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';
import 'package:synology_explorer/core/auth/session_manager.dart';
import 'package:synology_explorer/core/network/certificate_pinning.dart';
import 'package:synology_explorer/core/network/syno_api_client.dart';
import 'package:synology_explorer/core/network/syno_exception.dart';
import 'package:synology_explorer/core/storage/app_database.dart';
import 'package:synology_explorer/features/browser/data/favorite_api.dart';
import 'package:synology_explorer/features/browser/data/local_library_repository.dart';
import 'package:synology_explorer/features/browser/domain/nas_entry.dart';
import 'package:synology_explorer/features/servers/domain/server_profile.dart';

import '../../../tool/mock_nas/mock_nas.dart';
import '../../helpers/mock_nas_server.dart';

/// NAS-Favoriten (Phase 6): Spiegeln in den Cache und die Regel „erst list,
/// dann nur add bzw. delete“ (docs/SPIKE.md: delete trifft sonst auch
/// fremde Favoriten, add auf Vorhandenes liefert 800).
void main() {
  late MockNasServer nas;
  late AppDatabase db;
  late LocalLibraryRepository repo;
  late FileStationFavoriteApi api;

  const fav = 'SYNO.FileStation.Favorite';
  const bonus = NasEntry(
    path: '/music/Bonus',
    name: 'Bonus',
    isDir: true,
    type: NasFileType.folder,
  );

  setUp(() async {
    nas = await MockNasServer.start();
    db = AppDatabase(NativeDatabase.memory());
    repo = LocalLibraryRepository(db);
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    final client = SynoApiClient(
      ServerProfile(id: 1, name: 'NAS', lanUrl: nas.url, user: mockUser),
      CertificatePinStore(storage),
    );
    await client.connect();
    await SessionManager(
      client,
      storage,
      deviceName: 'Test',
    ).login(mockUser, mockPassword, otp: mockOtp);
    api = FileStationFavoriteApi(client);
  });
  tearDown(() async {
    await db.close();
    await nas.close();
  });

  Future<List<FavoriteItem>> cached() => repo.favorites(1).first;

  test('sync spiegelt die NAS-Liste, broken inklusive', () async {
    await repo.syncFavorites(1, api);
    expect(await cached(), [
      (
        entry: const NasEntry(
          path: '/music/Hörbücher',
          name: 'Hörbücher',
          isDir: true,
          type: NasFileType.folder,
        ),
        name: 'Hörbücher',
        broken: false,
      ),
      (
        entry: const NasEntry(
          path: '/photo/Urlaub 2019',
          name: 'Urlaub 2019',
          isDir: true,
          type: NasFileType.folder,
        ),
        name: 'Alt-Urlaub',
        broken: true,
      ),
    ]);
  });

  test('sync ersetzt lokale Ordner-Favoriten, lässt Datei-Favoriten', () async {
    const file = NasEntry(
      path: '/music/Bonus/intro.mp3',
      name: 'intro.mp3',
      isDir: false,
      type: NasFileType.audio,
    );
    await repo.setFavorite(1, bonus, true); // alter, lokaler Ordner-Favorit
    await repo.setFavorite(1, file, true);
    await repo.syncFavorites(1, api);
    final paths = [for (final f in await cached()) f.entry.path];
    expect(paths, containsAll(['/music/Hörbücher', file.path]));
    expect(paths, isNot(contains(bonus.path)));
  });

  test('setzen: list, dann add; nochmal setzen: kein zweites add', () async {
    await repo.setFolderFavorite(1, api, bonus, true);
    await repo.setFolderFavorite(1, api, bonus, true);
    expect(nas.calls(fav, 'add'), hasLength(1));
    expect(nas.calls(fav, 'add').single['path'], bonus.path);
    expect(await repo.isFavorite(1, bonus.path).first, isTrue);
  });

  test('entfernen ohne Favorit auf dem NAS: kein delete', () async {
    await repo.setFolderFavorite(1, api, bonus, false);
    expect(nas.calls(fav, 'delete'), isEmpty);

    await repo.setFolderFavorite(1, api, bonus, true);
    await repo.setFolderFavorite(1, api, bonus, false);
    expect(nas.calls(fav, 'delete'), hasLength(1));
    expect(await repo.isFavorite(1, bonus.path).first, isFalse);
    // Fremde Favoriten (DS File) bleiben.
    expect(await repo.isFavorite(1, '/music/Hörbücher').first, isTrue);
  });

  test('800 („schon vorhanden“) gilt als Erfolg', () async {
    // Zwischen list und add legt DS File denselben Favoriten an.
    await api.add(bonus.path, bonus.name);
    var hide = true;
    nas.intercept = (p) {
      if (p['api'] != fav || p['method'] != 'list' || !hide) return null;
      hide = false;
      return Response.ok(
        '{"success": true, "data": {"favorites": [], "total": 0}}',
        headers: {'content-type': 'application/json'},
      );
    };
    await repo.setFolderFavorite(1, api, bonus, true);
    expect(await repo.isFavorite(1, bonus.path).first, isTrue);
  });

  test('verweigert (105): Fehler, Cache unverändert', () async {
    await repo.syncFavorites(1, api);
    final before = await cached();
    nas.control.denyFavorites = 105;
    await expectLater(
      repo.setFolderFavorite(1, api, bonus, true),
      throwsA(isA<SynoPermissionDenied>()),
    );
    expect(await cached(), before);
  });
}
