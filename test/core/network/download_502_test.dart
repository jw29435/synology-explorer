import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';
import 'package:nuvo_explorer/core/auth/session_manager.dart';
import 'package:nuvo_explorer/core/network/certificate_pinning.dart';
import 'package:nuvo_explorer/core/network/syno_api_client.dart';
import 'package:nuvo_explorer/core/network/syno_exception.dart';
import 'package:nuvo_explorer/features/servers/domain/server_profile.dart';

import '../../../tool/mock_nas/mock_nas.dart';
import '../../helpers/mock_nas_server.dart';

/// HTTP 502 beim Download: DSM meint „Datei fehlt“, ein Reverse-Proxy
/// „Gateway kaputt“ – nur ersteres ist „Nicht gefunden“ (E2E-026, Review R-06).
void main() {
  late MockNasServer nas;
  late SynoApiClient client;
  late Directory tmp;

  setUp(() async {
    nas = await MockNasServer.start();
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
    tmp = await Directory.systemTemp.createTemp('dl502');
  });
  tearDown(() async {
    await nas.close();
    await tmp.delete(recursive: true);
  });

  Future<void> download(String path) => client.download(
    'SYNO.FileStation.Download',
    'download',
    {'path': path, 'mode': 'open'},
    File('${tmp.path}/x'),
  );

  test('502 und getinfo meldet 408 → Nicht gefunden', () async {
    nas.control.downloadErrors['/music/weg.pdf'] = 502;
    await expectLater(download('/music/weg.pdf'), throwsA(isA<SynoNotFound>()));
  });

  test('502, Datei existiert (Proxy) → Netzwerkfehler', () async {
    nas.intercept = (p) => p['api'] == 'SYNO.FileStation.Download'
        ? Response(502, body: '<html>Bad Gateway</html>')
        : null;
    await expectLater(
      download('/music/da.pdf'),
      throwsA(
        isA<SynoNetworkError>().having((e) => e.statusCode, 'status', 502),
      ),
    );
  });
}
