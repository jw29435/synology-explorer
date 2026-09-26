import 'dart:io';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:synology_explorer/features/autoupload/data/background.dart';
import 'package:synology_explorer/features/autoupload/data/camera_roll.dart';
import 'package:synology_explorer/features/autoupload/domain/auto_upload_config.dart';
import 'package:synology_explorer/features/autoupload/presentation/auto_upload_providers.dart';
import 'package:synology_explorer/features/settings/presentation/settings_providers.dart';
import 'package:synology_explorer/features/sharing/presentation/sharing_providers.dart';

/// Merkt sich, was eingeplant würde, statt WorkManager aufzurufen.
class FakeScheduler implements AutoUploadScheduler {
  final applied = <AutoUploadConfig>[];

  @override
  Future<void> apply(AutoUploadConfig config) async => applied.add(config);
}

/// Fotozugriff ohne Systemdialog.
class FakeAccessCameraRoll implements CameraRoll {
  bool grant = true;
  int requests = 0;

  @override
  Future<bool> requestAccess({required bool videos}) async {
    requests++;
    return grant;
  }

  @override
  Future<bool> hasAccess({required bool videos}) async => grant;

  @override
  Future<List<CameraAsset>> since(
    DateTime? since, {
    required bool videos,
  }) async => const [];

  @override
  Future<({File file, String name})?> original(String id) async => null;

  @override
  Future<void> openSettings() async {}
}

List<Override> settingsOverrides({
  FakeScheduler? scheduler,
  CameraRoll? camera,
}) => [
  autoUploadSchedulerProvider.overrideWithValue(scheduler ?? FakeScheduler()),
  cameraRollProvider.overrideWithValue(camera ?? FakeAccessCameraRoll()),
  packageInfoProvider.overrideWith(
    (ref) async => PackageInfo(
      appName: 'Synology Explorer',
      packageName: 'de.jw29435.synology_explorer',
      version: '1.0.0',
      buildNumber: '42',
    ),
  ),
  shareLinksProvider.overrideWith((ref) async => const []),
];
