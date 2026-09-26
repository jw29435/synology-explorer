import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/storage_providers.dart';
import '../../audio/presentation/playback_providers.dart';
import '../../browser/presentation/browser_providers.dart';
import '../../servers/presentation/server_providers.dart';
import '../../transfers/presentation/transfer_providers.dart';
import '../../viewers/presentation/viewer_providers.dart';
import '../data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

/// Design; Standard wie in den Mockups dunkel.
final themeModeProvider = StreamProvider<ThemeMode>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch(SettingsRepository.themeMode)
      .map((v) => ThemeMode.values.asNameMap()[v] ?? ThemeMode.dark),
);

/// Sprache; `null` = Systemsprache.
final localeProvider = StreamProvider<Locale?>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch(SettingsRepository.locale)
      .map((v) => v == null ? null : Locale(v)),
);

/// Cache-Limit (Slider 200 MB – 5 GB), Standard 500 MB (CONCEPT.md 6).
const cacheLimitSteps = [200, 500, 1024, 2048, 3072, 4096, 5120];

/// Gesamtlimit in Byte: 4/5 für Medien, 1/5 für Vorschaubilder.
final cacheLimitProvider = Provider<int>(
  (ref) => (ref.watch(cacheLimitMbProvider).value ?? 500) << 20,
);

final cacheLimitMbProvider = StreamProvider<int>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch(SettingsRepository.cacheLimitMb)
      .map((v) => int.tryParse(v ?? '') ?? 500),
);

final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

/// Cache-Unterordner mit Medien, Vorschaubildern und Covern. `uploads/`
/// bleibt: Dort liegen Kopien für noch wartende Uploads.
const _cacheDirs = ['media', 'thumbs', 'covers'];

Future<void> _deleteDir(Directory dir) async {
  try {
    await dir.delete(recursive: true);
  } on FileSystemException {
    // Gibt es nicht (mehr).
  }
}

/// Leert den Medien-Cache; die Caches starten danach neu.
Future<void> clearCache(WidgetRef ref) async {
  final root = await getApplicationCacheDirectory();
  for (final name in _cacheDirs) {
    await _deleteDir(Directory('${root.path}/$name'));
  }
  ref
    ..invalidate(mediaCacheProvider)
    ..invalidate(thumbnailCacheProvider)
    ..invalidate(storageUsageProvider);
}

/// „Alle lokalen Daten löschen“: Cache, Offline-Dateien samt Transfers und
/// alle Secrets (SID, Geräte-Token, gemerkte Passwörter, Zertifikat-Pins).
/// Server-Profile und Einstellungen bleiben; danach ist niemand angemeldet.
Future<void> clearAllLocalData(WidgetRef ref) async {
  try {
    await ref.read(audioControllerProvider.notifier).clear(save: false);
  } catch (_) {
    // Kein Player aktiv.
  }
  await ref.read(sessionProvider.notifier).close();
  final db = ref.read(appDatabaseProvider);
  await db.transaction(() async {
    await db.delete(db.transfers).go();
    await db.delete(db.offlineFiles).go();
  });
  await _deleteDir(
    Directory('${(await getApplicationDocumentsDirectory()).path}/offline'),
  );
  for (final e
      in await (await getApplicationCacheDirectory()).list().toList()) {
    if (e is Directory) await _deleteDir(e);
  }
  await ref.read(secureStorageProvider).deleteAll();
  ref
    ..invalidate(mediaCacheProvider)
    ..invalidate(thumbnailCacheProvider)
    ..invalidate(storageUsageProvider);
}
