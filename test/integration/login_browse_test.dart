import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/core/network/certificate_pinning.dart';
import 'package:nuvo_explorer/core/network/syno_exception.dart';
import 'package:nuvo_explorer/core/storage/app_database.dart';
import 'package:nuvo_explorer/features/browser/data/file_station_list_api.dart';
import 'package:nuvo_explorer/features/browser/domain/nas_entry.dart';
import 'package:nuvo_explorer/features/servers/data/server_repository.dart';
import 'package:nuvo_explorer/features/servers/domain/server_profile.dart';

import '../../tool/mock_nas/mock_nas.dart';
import '../helpers/mock_nas_server.dart';

/// Login → list_share → list über echtes HTTP gegen den Mock-NAS.
void main() {
  test('Login mit 2FA, Shares und Musikordner listen', () async {
    final nas = await MockNasServer.start();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
      await nas.close();
    });
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    final repo = ServerRepository(db, storage, CertificatePinStore(storage));

    final profile = await repo.add(
      ServerProfile(name: 'Heim-NAS', lanUrl: nas.url, user: mockUser),
    );
    final session = await repo.connect(profile);
    await expectLater(
      session.login(mockUser, mockPassword),
      throwsA(isA<SynoOtpRequired>()),
    );
    await session.login(mockUser, mockPassword, otp: mockOtp);

    final api = FileStationListApi(session.client);
    final shares = await api.listShares();
    expect(shares.map((s) => (s.name, s.perm)), [
      ('music', NasPerm.readWrite),
      ('photo', NasPerm.readWrite),
      ('video', NasPerm.readOnly),
      ('dokumente', NasPerm.readWrite),
    ]);

    const folder = '/music/Alben/Nordlicht – Treibholz';
    final page = await api.list(
      folder,
      sortBy: NasSortBy.mtime,
      descending: true,
      offset: 0,
      limit: 100,
    );
    expect(nas.calls('SYNO.FileStation.List', 'list').single, {
      'api': 'SYNO.FileStation.List',
      'version': '2',
      'method': 'list',
      '_sid': session.client.sid,
      'folder_path': folder,
      'additional': '["size","time","type","perm"]',
      'sort_by': 'mtime',
      'sort_direction': 'desc',
      'offset': '0',
      'limit': '100',
    });
    expect(page.total, 7);
    expect(page.entries.map((e) => (e.name, e.type)), [
      ('Bonus', NasFileType.folder),
      ('01 Ebbe.flac', NasFileType.audio),
      ('02 Strandgut.flac', NasFileType.audio),
      ('03 Nebelbank.flac', NasFileType.audio),
      ('04 Leuchtfeuer.flac', NasFileType.audio),
      ('cover.jpg', NasFileType.image),
      ('booklet.pdf', NasFileType.pdf),
    ]);
    final ebbe = page.entries[1];
    expect(ebbe.path, '$folder/01 Ebbe.flac');
    expect(ebbe.size, 29779968);
    expect(ebbe.mtime, DateTime.utc(2026, 5, 12, 10, 5));
    expect(ebbe.perm, NasPerm.readWrite);
    expect(page.entries.first.size, isNull);
  });
}
