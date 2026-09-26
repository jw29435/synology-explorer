import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/syno_exception.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/storage_providers.dart';
import '../../browser/presentation/browser_providers.dart';
import '../../servers/presentation/server_providers.dart';
import '../../transfers/presentation/transfer_providers.dart';
import '../data/auto_upload_repository.dart';
import '../data/auto_uploader.dart';
import '../data/background.dart';
import '../data/camera_roll.dart';
import '../domain/auto_upload_config.dart';

final autoUploadRepositoryProvider = Provider<AutoUploadRepository>(
  (ref) => AutoUploadRepository(ref.watch(appDatabaseProvider)),
);

final cameraRollProvider = Provider<CameraRoll>((ref) => const CameraRoll());

final autoUploadSchedulerProvider = Provider<AutoUploadScheduler>(
  (ref) => const AutoUploadScheduler(),
);

final autoUploaderProvider = Provider<AutoUploader>(
  (ref) => AutoUploader(
    ref.watch(autoUploadRepositoryProvider),
    ref.watch(cameraRollProvider),
    isUnmetered: unmeteredNow,
    isCharging: chargingNow,
  ),
);

final autoUploadConfigProvider = StreamProvider<AutoUploadConfig>(
  (ref) => ref.watch(autoUploadRepositoryProvider).watch(),
);

final autoUploadRunsProvider = StreamProvider<List<AutoUploadRun>>(
  (ref) => ref.watch(autoUploadRepositoryProvider).watchRuns(),
);

final autoUploadTotalsProvider = StreamProvider<({int files, int bytes})>(
  (ref) => ref.watch(autoUploadRepositoryProvider).watchTotals(),
);

final autoUploadLastCheckProvider = StreamProvider<DateTime?>(
  (ref) => ref.watch(autoUploadRepositoryProvider).watchLastCheck(),
);

/// `true`, solange ein Lauf in der App läuft (Einreihen und Warten).
final autoUploadControllerProvider =
    NotifierProvider<AutoUploadController, bool>(AutoUploadController.new);

class AutoUploadController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Ändert die Einstellungen und plant den Hintergrund-Task neu.
  Future<AutoUploadConfig> update(
    AutoUploadConfig Function(AutoUploadConfig) change,
  ) async {
    final next = await ref.read(autoUploadRepositoryProvider).update(change);
    await ref.read(autoUploadSchedulerProvider).apply(next);
    return next;
  }

  /// Lauf über die Queue der aktiven Session (App-Start, „Jetzt ausführen“).
  Future<void> run({bool manual = false}) async {
    if (state) return;
    state = true;
    try {
      await ref.read(autoUploaderProvider).run((serverId) async {
        final session = ref.read(sessionProvider);
        if (session == null) throw const SynoSessionExpired();
        if (session.client.profile.id != serverId) {
          throw const OtherServerActive();
        }
        return (
          queue: ref.read(transferQueueProvider),
          listApi: ref.read(fileStationListApiProvider),
        );
      }, manual: manual);
    } catch (_) {
      // Fehler vor dem Einreihen protokolliert der Lauf selbst.
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

/// Nachholen beim App-Start bzw. nach jeder Anmeldung (iOS lässt den
/// Hintergrund-Task nur gelegentlich laufen). Plant dabei den Task neu ein.
final autoUploadCatchUpProvider = Provider<void>((ref) {
  if (ref.watch(sessionProvider) == null) return;
  Future.microtask(() async {
    try {
      final config = await ref.read(autoUploadRepositoryProvider).read();
      if (!config.ready) return;
      await ref.read(autoUploadSchedulerProvider).apply(config);
      await ref.read(autoUploadControllerProvider.notifier).run();
    } catch (_) {
      // Nachholen ist Zusatz; Session inzwischen weg o. Ä.
    }
  });
});
