import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/core/auth/session_manager.dart';
import 'package:synology_explorer/core/network/certificate_pinning.dart';
import 'package:synology_explorer/core/network/syno_api_client.dart';
import 'package:synology_explorer/core/network/syno_exception.dart';
import 'package:synology_explorer/features/browser/data/file_station_ops_api.dart';
import 'package:synology_explorer/features/servers/domain/server_profile.dart';
import 'package:synology_explorer/features/sharing/data/sharing_api.dart';
import 'package:synology_explorer/features/transfers/data/transfer_api.dart';

import '../../../tool/mock_nas/mock_nas.dart';
import '../../helpers/mock_nas_server.dart';

/// Download (Range), Upload (Multipart), CopyMove/Delete, Sharing gegen den
/// Mock-NAS.
void main() {
  late MockNasServer nas;
  late SynoApiClient client;
  late Directory dir;

  setUp(() async {
    nas = await MockNasServer.start();
    dir = await Directory.systemTemp.createTemp('transfer-api');
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    client = SynoApiClient(
      ServerProfile(id: 1, name: 'NAS', lanUrl: nas.url, user: mockUser),
      CertificatePinStore(storage),
    );
    await client.connect();
    await SessionManager(
      client,
      storage,
      deviceName: 'Test',
    ).login(mockUser, mockPassword, otp: mockOtp);
  });
  tearDown(() async {
    client.close();
    await nas.close();
    await dir.delete(recursive: true);
  });

  group('Download', () {
    test('ganze Datei mit Fortschritt', () async {
      final file = File('${dir.path}/a.part');
      final progress = <int>[];
      final total = await TransferApi(
        client,
      ).download('/music/a.flac', file, onProgress: (d, _) => progress.add(d));
      expect(total, mockFileSize);
      expect(await file.readAsBytes(), mockFileBytes());
      expect(progress.last, mockFileSize);
      final call = nas.calls('SYNO.FileStation.Download', 'download').single;
      expect(call, containsPair('path', '/music/a.flac'));
      expect(call.containsKey('range'), isFalse);
    });

    test('Resume per Range hängt an', () async {
      final file = File('${dir.path}/a.part')
        ..writeAsBytesSync(mockFileBytes().sublist(0, 1000));
      final total = await TransferApi(client)
          .download('/music/a.flac', file, offset: 1000);
      expect(total, mockFileSize);
      expect(await file.readAsBytes(), mockFileBytes());
      expect(
        nas.calls('SYNO.FileStation.Download', 'download').single,
        containsPair('range', 'bytes=1000-'),
      );
    });

    test('abgelaufene SID ohne Re-Login → SynoSessionExpired', () async {
      client.sid = 'abgelaufen';
      await expectLater(
        TransferApi(client).download('/x', File('${dir.path}/x')),
        throwsA(isA<SynoSessionExpired>()),
      );
    });
  });

  test('Upload: Multipart, danach freier Name mit „ (1)“', () async {
    final file = File('${dir.path}/IMG_1.jpg')..writeAsBytesSync([1, 2, 3]);
    final api = TransferApi(client);
    final sent = <int>[];
    expect(
      await api.upload(
        file,
        '/photo/Handy',
        'IMG_1.jpg',
        overwrite: false,
        onProgress: (s, _) => sent.add(s),
      ),
      'IMG_1.jpg',
    );
    expect(sent, isNotEmpty);
    expect(
      await api.upload(file, '/photo/Handy', 'IMG_1.jpg', overwrite: false),
      'IMG_1 (1).jpg',
    );
    // Überschreiben fragt nicht nach freien Namen.
    expect(
      await api.upload(file, '/photo/Handy', 'IMG_1.jpg', overwrite: true),
      'IMG_1.jpg',
    );
    expect(nas.calls('SYNO.FileStation.List', 'getinfo'), hasLength(2));
    expect(nas.calls('SYNO.FileStation.Upload', 'upload'), hasLength(3));
  });

  test('Upload: parallel gleicher Name → verschiedene Namen, '
      'overwrite=false wird nie gesendet', () async {
    final file = File('${dir.path}/IMG_2.jpg')..writeAsBytesSync([1, 2, 3]);
    final api = TransferApi(client);
    final names = await Future.wait([
      for (var i = 0; i < 2; i++)
        api.upload(file, '/photo/Handy', 'IMG_2.jpg', overwrite: false),
    ]);
    expect(names.toSet(), {'IMG_2.jpg', 'IMG_2 (1).jpg'});
    final uploads = nas.calls('SYNO.FileStation.Upload', 'upload');
    expect(uploads.map((u) => u['file']).toSet(), names.toSet());
    expect(uploads.map((u) => u.containsKey('overwrite')), everyElement(false));

    await api.upload(file, '/photo/Handy', 'IMG_2.jpg', overwrite: true);
    expect(
      nas.calls('SYNO.FileStation.Upload', 'upload').last,
      containsPair('overwrite', 'true'),
    );
  });

  test('Download: Range hinter dem Dateiende → 416', () async {
    await expectLater(
      TransferApi(client).download(
        '/music/a.flac',
        File('${dir.path}/a.part'),
        offset: mockFileSize + 10,
      ),
      throwsA(
        isA<SynoNetworkError>().having((e) => e.statusCode, 'status', 416),
      ),
    );
  });

  test('numberedName', () {
    expect(numberedName('a.jpg', 1), 'a (1).jpg');
    expect(numberedName('archiv.tar.gz', 2), 'archiv.tar (2).gz');
    expect(numberedName('Makefile', 3), 'Makefile (3)');
    expect(numberedName('.hidden', 1), '.hidden (1)');
  });

  test('CopyMove und Delete: start, status bis fertig, JSON-Task-ID', () async {
    final api = FileStationOpsApi(client);
    final task = await api.copyMoveStart(
      ['/music/a.flac'],
      '/music/Alben',
      move: true,
    );
    expect(await api.copyMoveStatus(task), (finished: false, progress: 0.5));
    expect(await api.copyMoveStatus(task), (finished: true, progress: 1.0));
    final start = nas.calls('SYNO.FileStation.CopyMove', 'start').single;
    expect(start, containsPair('path', '["/music/a.flac"]'));
    expect(start, containsPair('dest_folder_path', '"/music/Alben"'));
    expect(start, containsPair('remove_src', 'true'));
    expect(
      nas.calls('SYNO.FileStation.CopyMove', 'status').first,
      containsPair('taskid', '"$task"'),
    );

    final del = await api.deleteStart(['/music/a.flac']);
    await api.deleteStop(del);
    await expectLater(api.deleteStatus(del), throwsA(isA<SynoNotFound>()));
  });

  test('Rename und CreateFolder schicken JSON-Arrays', () async {
    final api = FileStationOpsApi(client);
    await api.rename('/music/a.flac', 'b.flac');
    await api.createFolder('/music', 'Neu', forceParent: true);
    expect(
      nas.calls('SYNO.FileStation.Rename', 'rename').single,
      allOf(
        containsPair('path', '["/music/a.flac"]'),
        containsPair('name', '["b.flac"]'),
      ),
    );
    expect(
      nas.calls('SYNO.FileStation.CreateFolder', 'create').single,
      containsPair('force_parent', 'true'),
    );
  });

  test('Sharing: create, list, delete', () async {
    final api = SharingApi(client);
    final [link] = await api.create(
      ['/music/a.flac'],
      password: 'geheim',
      expiresAt: DateTime(2026, 10, 3),
    );
    expect(link.hasPassword, isTrue);
    expect(link.expiresAt, DateTime(2026, 10, 3));
    expect(
      nas.calls('SYNO.FileStation.Sharing', 'create').single,
      containsPair('date_expired', '2026-10-03'),
    );
    expect((await api.list()).single.id, link.id);
    await api.delete([link.id]);
    expect(await api.list(), isEmpty);
  });
}
