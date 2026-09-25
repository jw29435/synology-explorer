import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/core/auth/session_manager.dart';
import 'package:synology_explorer/core/network/certificate_pinning.dart';
import 'package:synology_explorer/core/network/syno_api_client.dart';
import 'package:synology_explorer/core/network/syno_exception.dart';
import 'package:synology_explorer/features/browser/data/file_station_list_api.dart';
import 'package:synology_explorer/features/browser/data/file_station_task_api.dart';
import 'package:synology_explorer/features/servers/domain/server_profile.dart';

import '../../../tool/mock_nas/mock_nas.dart';
import '../../helpers/mock_nas_server.dart';

/// Search, DirSize, getinfo und Thumb gegen den Mock-NAS.
void main() {
  late MockNasServer nas;
  late SynoApiClient client;

  setUp(() async {
    nas = await MockNasServer.start();
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    client = SynoApiClient(
      ServerProfile(id: 1, name: 'NAS', lanUrl: nas.url, user: mockUser),
      CertificatePinStore(storage),
    );
    await client.connect();
    final session = SessionManager(client, storage, deviceName: 'Test');
    await session.login(mockUser, mockPassword, otp: mockOtp);
  });
  tearDown(() async {
    client.close();
    await nas.close();
  });

  test('Search: start, list, stop, clean mit JSON-kodierter Task-ID', () async {
    final api = FileStationSearchApi(client);
    final task = await api.start(
      ['/music'],
      'nebel',
      extensions: ['mp3', 'flac'],
    );
    expect(task, 'mock-search-1');
    expect(
      nas.calls('SYNO.FileStation.Search', 'start').single,
      containsPair('folder_path', '["/music"]'),
    );
    expect(
      nas.calls('SYNO.FileStation.Search', 'start').single,
      containsPair('extension', 'mp3,flac'),
    );

    final page = await api.list(task);
    expect(page.finished, isTrue);
    expect(page.total, 3);
    expect(page.entries.map((e) => e.name), contains('03 Nebelbank.flac'));
    await api.stop(task);
    await api.clean(task);
    for (final method in ['list', 'stop', 'clean']) {
      expect(
        nas.calls('SYNO.FileStation.Search', method).single,
        containsPair('taskid', '"mock-search-1"'),
      );
    }
  });

  test('DirSize: start und status', () async {
    final api = FileStationDirSizeApi(client);
    final task = await api.start('/music');
    final size = await api.status(task);
    expect(size, (finished: true, files: 14, dirs: 2, bytes: 163577856));
    expect(
      nas.calls('SYNO.FileStation.DirSize', 'status').single,
      containsPair('taskid', '"mock-dirsize-1"'),
    );
  });

  test('getinfo liefert Besitzer, Erstellzeit und POSIX-Rechte', () async {
    final info = await FileStationListApi(client).getInfo('/music/x.flac');
    expect(info.owner, 'johann');
    expect(info.group, 'users');
    expect(info.posix, 775);
    expect(info.size, 32598114);
    expect(info.crtime, isNotNull);
  });

  test('Thumb liefert Bytes; API-Fehler als JSON werden gemappt', () async {
    final bytes = await client.requestBytes('SYNO.FileStation.Thumb', 'get', {
      'path': '/photo/a.jpg',
      'size': 'small',
    });
    expect(bytes.take(2), [0xFF, 0xD8], reason: 'JPEG');

    client.sid = 'abgelaufen';
    await expectLater(
      client.requestBytes('SYNO.FileStation.Thumb', 'get', {'path': '/x'}),
      throwsA(isA<SynoSessionExpired>()),
    );
  });
}
