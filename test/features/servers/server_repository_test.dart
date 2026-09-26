import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/core/network/certificate_pinning.dart';
import 'package:nuvo_explorer/core/storage/app_database.dart';
import 'package:nuvo_explorer/features/autoupload/data/auto_upload_repository.dart';
import 'package:nuvo_explorer/features/servers/data/server_repository.dart';
import 'package:nuvo_explorer/features/servers/domain/server_profile.dart';

import 'package:nuvo_explorer/features/transfers/data/offline_store.dart';
import 'package:nuvo_explorer/features/transfers/domain/transfer.dart';

import '../../helpers/mock_nas_server.dart';

void main() {
  late AppDatabase db;
  late Map<String, String> secure;
  late ServerRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    secure = {'pin:nas.lan:5001': 'AB:CD'};
    FlutterSecureStorage.setMockInitialValues(secure);
    const storage = FlutterSecureStorage();
    repo = ServerRepository(db, storage, CertificatePinStore(storage));
  });
  tearDown(() => db.close());

  const profile = ServerProfile(
    name: 'Heim-NAS',
    lanUrl: 'https://nas.lan:5001',
    externalUrl: 'https://nas.example.de',
    user: 'johann',
  );

  test('CRUD', () async {
    final saved = await repo.add(profile);
    expect(saved.id, isNotNull);
    expect(await repo.all(), [saved]);

    final edited = saved.copyWith(name: 'Büro', externalUrl: null);
    await repo.update(edited);
    expect(await repo.all(), [edited]);

    secure['server:${saved.id}:sid'] = 'sid';
    secure['server:${saved.id}:password'] = 'pw';
    await repo.remove(saved.id!);
    expect(await repo.all(), isEmpty);
    expect(secure.keys, ['pin:nas.lan:5001'], reason: 'Pins bleiben');
  });

  test('löschen räumt alle Daten des Servers auf (E2E-007)', () async {
    final root = await Directory.systemTemp.createTemp('offline');
    addTearDown(() => root.delete(recursive: true));
    final store = OfflineStore(db, Future.value(root));
    final gone = (await repo.add(profile)).id!;
    final kept = (await repo.add(profile.copyWith(name: 'Büro'))).id!;
    final now = DateTime.now();

    for (final id in [gone, kept]) {
      final local = await store.localPathFor(id, '/music/a.mp3');
      await File(local).create(recursive: true);
      await File('$local.part').create();
      await db
          .into(db.offlineFiles)
          .insert(
            OfflineFilesCompanion.insert(
              serverId: id,
              remotePath: '/music/a.mp3',
              localPath: local,
              size: 0,
            ),
          );
      await db
          .into(db.transfers)
          .insert(
            TransfersCompanion.insert(
              serverId: id,
              kind: TransferKind.download,
              remotePath: '/music/a.mp3',
              localPath: local,
              state: TransferState.queued,
              createdAt: now,
            ),
          );
      await db
          .into(db.playbackPositions)
          .insert(
            PlaybackPositionsCompanion.insert(
              serverId: id,
              path: '/music/a.mp3',
              positionMs: 1000,
              updatedAt: now,
            ),
          );
      await db
          .into(db.audiobookFolders)
          .insert(
            AudiobookFoldersCompanion.insert(serverId: id, path: '/music'),
          );
    }
    final autoUpload = AutoUploadRepository(db);
    await autoUpload.update(
      (c) => c.copyWith(enabled: true, serverId: gone, targetPath: '/photo'),
    );

    await repo.remove(gone);

    expect(
      [
        for (final r in await db.select(db.offlineFiles).get()) r.serverId,
        for (final r in await db.select(db.transfers).get()) r.serverId,
        for (final r in await db.select(db.playbackPositions).get()) r.serverId,
        for (final r in await db.select(db.audiobookFolders).get()) r.serverId,
      ],
      [kept, kept, kept, kept],
    );
    expect(Directory('${root.path}/$gone').existsSync(), isFalse);
    expect(File('${root.path}/$kept/music/a.mp3').existsSync(), isTrue);
    expect((await autoUpload.read()).serverId, isNull);

    // Konfiguration eines anderen Servers bleibt.
    await autoUpload.update(
      (c) => c.copyWith(enabled: true, serverId: kept, targetPath: '/photo'),
    );
    await repo.remove(gone);
    expect((await autoUpload.read()).ready, isTrue);
  });

  test('verbinden übernimmt die gespeicherte SID', () async {
    final nas = await MockNasServer.start();
    addTearDown(nas.close);
    final saved = await repo.add(profile.copyWith(lanUrl: nas.url));
    secure['server:${saved.id}:sid'] = 'gespeichert';

    final session = await repo.connect(saved);
    expect(session.client.activeUrl, Uri.parse(nas.url));
    expect(session.client.sid, 'gespeichert');
    expect(session.deviceName, startsWith('Nuvo Explorer'));
  });
}
