import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/core/network/syno_exception.dart';
import 'package:nuvo_explorer/core/storage/app_database.dart';
import 'package:nuvo_explorer/features/autoupload/data/auto_upload_repository.dart';
import 'package:nuvo_explorer/features/autoupload/data/auto_uploader.dart';
import 'package:nuvo_explorer/features/autoupload/data/camera_roll.dart';
import 'package:nuvo_explorer/features/autoupload/domain/auto_upload_config.dart';
import 'package:nuvo_explorer/features/browser/data/file_station_list_api.dart';
import 'package:nuvo_explorer/features/browser/domain/nas_entry.dart';
import 'package:nuvo_explorer/features/transfers/data/transfer_api.dart';
import 'package:nuvo_explorer/features/transfers/data/transfer_queue.dart';
import 'package:nuvo_explorer/features/transfers/domain/transfer.dart';

/// Kamera-Rolle im Speicher; Originale sind kleine Dateien im Temp-Ordner.
class FakeCameraRoll implements CameraRoll {
  FakeCameraRoll(this.dir);

  final Directory dir;
  final assets = <CameraAsset>[];
  bool access = true;

  @override
  Future<bool> hasAccess({required bool videos}) async => access;

  @override
  Future<List<CameraAsset>> since(
    DateTime? since, {
    required bool videos,
  }) async => [
    for (final a in assets)
      if (since == null || !a.created.isBefore(since)) a,
  ];

  var cleared = 0;

  @override
  Future<void> clearCache() async => cleared++;

  @override
  Future<({File file, String name})?> original(String id) async {
    final file = File('${dir.path}/$id.jpg')
      ..writeAsBytesSync(List.filled(10, 1));
    return (file: file, name: 'IMG_$id.jpg');
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FakeUploadApi implements TransferApi {
  final uploads = <String>[];
  Object? failWith;

  @override
  Future<String> upload(
    File file,
    String folder,
    String name, {
    required bool overwrite,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (failWith case final e?) throw e;
    uploads.add('$folder/$name');
    return name;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FakeTargetApi implements FileStationListApi {
  NasPerm perm = NasPerm.readWrite;

  @override
  Future<NasEntry> getInfo(String path) async => NasEntry(
    path: path,
    name: path.split('/').last,
    isDir: true,
    type: NasFileType.folder,
    perm: perm,
  );

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late AppDatabase db;
  late AutoUploadRepository repo;
  late FakeCameraRoll camera;
  late FakeUploadApi api;
  late FakeTargetApi target;
  late TransferQueue queue;
  late Directory tmp;
  var unmetered = true;
  var connects = 0;
  // Relativ zu jetzt: Das Abfragefenster hängt an der echten Uhr.
  final t0 = DateTime.fromMillisecondsSinceEpoch(
    DateTime.now().millisecondsSinceEpoch ~/ 1000 * 1000,
  ).subtract(const Duration(hours: 1));
  String folder(DateTime d) =>
      '/photo/Handy/${FolderScheme.yearMonth.subfolder(d)}';

  AutoUploader uploader() => AutoUploader(
    repo,
    camera,
    isUnmetered: () async => unmetered,
    isCharging: () async => false,
  );

  Future<UploadTarget> connect(int serverId) async {
    connects++;
    expect(serverId, 1);
    return (queue: queue, listApi: target);
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = AutoUploadRepository(db);
    tmp = Directory.systemTemp.createTempSync('autoupload');
    camera = FakeCameraRoll(tmp);
    api = FakeUploadApi();
    target = FakeTargetApi();
    queue = TransferQueue(db, api: api, serverId: 1);
    unmetered = true;
    connects = 0;
    await repo.update(
      (_) => AutoUploadConfig(
        enabled: true,
        serverId: 1,
        targetPath: '/photo/Handy',
        cursor: UploadCursor(t0),
      ),
    );
  });

  tearDown(() async {
    await queue.dispose();
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  test(
    'lädt neue Aufnahmen nach Schema hoch, merkt sie als erledigt',
    () async {
      final later = t0.add(const Duration(days: 40));
      camera.assets.addAll([
        CameraAsset('old', t0.subtract(const Duration(days: 1))),
        CameraAsset('a', t0.add(const Duration(minutes: 1))),
        CameraAsset('b', later),
      ]);
      await uploader().run(connect);

      expect(api.uploads, [
        '${folder(t0)}/IMG_a.jpg',
        '${folder(later)}/IMG_b.jpg',
      ]);
      final config = await repo.read();
      expect(config.cursor!.done.keys, {'a', 'b'});
      expect(config.cursor!.checked, isNotNull);
      expect(camera.cleared, 1); // Temp-Kopien weg, nichts mehr offen.
      final run = (await repo.watchRuns().first).single;
      expect((run.files, run.failed, run.bytes, run.note), (2, 0, 20, null));
      expect(await repo.watchTotals().first, (files: 2, bytes: 20));

      // Zweiter Lauf: nichts Neues, kein Login, kein weiterer Eintrag.
      await uploader().run(connect);
      expect((connects, api.uploads.length), (1, 2));
      expect(await repo.watchRuns().first, hasLength(1));
      expect(await repo.watchLastCheck().first, isNotNull);
    },
  );

  test(
    '„Nur im WLAN“ ohne WLAN: wartet, ein Protokolleintrag; manuell läuft',
    () async {
      unmetered = false;
      camera.assets.add(CameraAsset('a', t0.add(const Duration(minutes: 1))));
      await uploader().run(connect);
      await uploader().run(connect);

      final runs = await repo.watchRuns().first;
      expect(runs.single.note, AutoUploadNote.noWifi);
      expect(runs.single.waiting, 1);
      expect(connects, 0);
      expect(api.uploads, isEmpty);

      await uploader().run(connect, manual: true);
      expect(api.uploads, hasLength(1));
    },
  );

  test(
    'Ziel ohne Schreibrecht: nichts eingereiht, Hinweis im Protokoll',
    () async {
      target.perm = NasPerm.readOnly;
      camera.assets.add(CameraAsset('a', t0.add(const Duration(minutes: 1))));
      await uploader().run(connect);

      expect(await db.select(db.transfers).get(), isEmpty);
      expect(
        (await repo.watchRuns().first).single.note,
        AutoUploadNote.noWritePermission,
      );
      // Cursor unverändert: Nach dem Korrigieren wird nachgeholt.
      expect((await repo.read()).cursor!.done, isEmpty);
    },
  );

  test('407 beim Upload: Fehler gezählt, Hinweis auf Schreibrechte', () async {
    api.failWith = const SynoPermissionDenied(407);
    camera.assets.add(CameraAsset('a', t0.add(const Duration(minutes: 1))));
    await uploader().run(connect);

    final run = (await repo.watchRuns().first).single;
    expect((run.files, run.failed), (1, 1));
    expect(run.note, AutoUploadNote.noWritePermission);
    final transfer = (await db.select(db.transfers).get()).single;
    expect(transfer.state, TransferState.failed);
  });

  test(
    'Anmeldung abgelaufen und fehlender Fotozugriff werden protokolliert',
    () async {
      camera.assets.add(CameraAsset('a', t0.add(const Duration(minutes: 1))));
      await uploader().run((_) async => throw const SynoSessionExpired());
      expect(
        (await repo.watchRuns().first).first.note,
        AutoUploadNote.sessionExpired,
      );

      camera.access = false;
      await uploader().run(connect);
      expect(
        (await repo.watchRuns().first).first.note,
        AutoUploadNote.noPermission,
      );
    },
  );

  test(
    'Sperre: kein zweiter Lauf gleichzeitig, verwaiste Sperre verfällt',
    () async {
      camera.assets.add(CameraAsset('a', t0.add(const Duration(minutes: 1))));
      expect(await repo.tryLock(), isTrue);
      await uploader().run(connect);
      expect(api.uploads, isEmpty);

      await repo.unlock();
      await uploader().run(connect);
      expect(api.uploads, hasLength(1));
    },
  );

  test('ausgeschaltet oder ohne Ziel: nichts passiert', () async {
    camera.assets.add(CameraAsset('a', t0.add(const Duration(minutes: 1))));
    await repo.update((c) => c.copyWith(enabled: false));
    await uploader().run(connect, manual: true);
    expect(connects, 0);
    expect(await repo.watchRuns().first, isEmpty);
  });

  test(
    'spät sichtbare Aufnahme mit älterer Aufnahmezeit wird gesichert',
    () async {
      // A um 10:04 aufgenommen, aber erst nach B (10:05) sichtbar.
      final a = CameraAsset('a', t0.add(const Duration(minutes: 4)));
      final b = CameraAsset('b', t0.add(const Duration(minutes: 5)));
      camera.assets.add(b);
      await uploader().run(connect);
      camera.assets.add(a);
      await uploader().run(connect);

      expect(api.uploads, [
        '${folder(b.created)}/IMG_b.jpg',
        '${folder(a.created)}/IMG_a.jpg',
      ]);
    },
  );

  test('liegengebliebene Uploads laufen ohne neue Aufnahme weiter', () async {
    final file = File('${tmp.path}/rest.jpg')..writeAsBytesSync([1, 2, 3]);
    // Wie nach einem beendeten Hintergrundlauf: eingereiht, nie gestartet.
    await TransferQueue(db, serverId: 1).enqueueUpload(
      localPath: file.path,
      remotePath: '/photo/Handy/rest.jpg',
      overwrite: false,
    );
    await uploader().run(connect);

    expect(connects, 1);
    expect(api.uploads, ['/photo/Handy/rest.jpg']);
    final t = (await db.select(db.transfers).get()).single;
    expect(t.state, TransferState.done);
  });

  test('Einreihen und Fortschritt in einer Transaktion', () async {
    camera.assets.add(CameraAsset('a', t0.add(const Duration(minutes: 1))));
    api.failWith = null;
    // Fortschritt schreiben scheitert → auch kein Transfer eingereiht.
    await db.customStatement(
      "CREATE TRIGGER no_cursor BEFORE UPDATE ON settings "
      "WHEN NEW.key = 'autoUpload' AND NEW.value LIKE '%\"a\"%' "
      "BEGIN SELECT RAISE(ABORT, 'kaputt'); END",
    );
    await expectLater(uploader().run(connect), throwsA(anything));
    expect(await db.select(db.transfers).get(), isEmpty);
  });
}
