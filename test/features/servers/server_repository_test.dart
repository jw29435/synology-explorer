import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/core/network/certificate_pinning.dart';
import 'package:synology_explorer/core/storage/app_database.dart';
import 'package:synology_explorer/features/servers/data/server_repository.dart';
import 'package:synology_explorer/features/servers/domain/server_profile.dart';

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

  test('verbinden übernimmt die gespeicherte SID', () async {
    final nas = await MockNasServer.start();
    addTearDown(nas.close);
    final saved = await repo.add(profile.copyWith(lanUrl: nas.url));
    secure['server:${saved.id}:sid'] = 'gespeichert';

    final session = await repo.connect(saved);
    expect(session.client.activeUrl, Uri.parse(nas.url));
    expect(session.client.sid, 'gespeichert');
    expect(session.deviceName, startsWith('Synology Explorer'));
  });
}
