import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Datenschutz (CONCEPT 8, PRIVACY.md): Nichts von der App geht in Android-
/// Backups oder den Geräteumzug (E2E-005).
void main() {
  test('Manifest schaltet Backup und Datenexport ab', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:fullBackupContent="false"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );

    final rules = File(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    ).readAsStringSync();
    for (final section in ['cloud-backup', 'device-transfer']) {
      final body = RegExp(
        '<$section>(.*?)</$section>',
        dotAll: true,
      ).firstMatch(rules)!.group(1)!;
      for (final domain in ['root', 'file', 'database', 'sharedpref']) {
        expect(body, contains('<exclude domain="$domain" path="." />'));
      }
    }
  });
}
