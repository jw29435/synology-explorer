import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/core/storage/storage_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'iOS: Secrets ab der ersten Entsperrung lesbar (Hintergrund-Upload)',
    () {
      expect(
        appSecureStorage.iOptions.params['accessibility'],
        KeychainAccessibility.first_unlock_this_device.name,
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(secureStorageProvider), same(appSecureStorage));
    },
  );

  test('nur ein Secure Storage im Code (überall dieselbe Zugriffsstufe)', () {
    final others = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            !f.path.endsWith('storage_providers.dart') &&
            f.readAsStringSync().contains('FlutterSecureStorage('))
          f.path,
    ];
    expect(others, isEmpty);
  });

  test('Migration zieht Einträge einmalig um und behält die Werte', () async {
    FlutterSecureStorage.setMockInitialValues({'server:1:sid': 'abc'});
    await migrateSecureStorage();
    expect(await appSecureStorage.read(key: 'server:1:sid'), 'abc');
    expect(
      await appSecureStorage.read(key: 'storage:accessibility'),
      'first_unlock_this_device',
    );
    // Zweiter Start: nichts mehr zu tun, auch neue Werte bleiben.
    await appSecureStorage.write(key: 'server:1:sid', value: 'neu');
    await migrateSecureStorage();
    expect(await appSecureStorage.read(key: 'server:1:sid'), 'neu');
  });
}
