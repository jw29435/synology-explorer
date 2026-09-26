import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/auth/session_manager.dart';
import '../../../core/network/certificate_pinning.dart';
import '../../../core/network/syno_exception.dart';
import '../../../core/storage/storage_providers.dart';
import '../../browser/data/file_station_list_api.dart';
import '../../servers/data/server_repository.dart';
import '../../transfers/data/transfer_api.dart';
import '../../transfers/data/transfer_queue.dart';
import '../domain/auto_upload_config.dart';
import 'auto_upload_repository.dart';
import 'auto_uploader.dart';
import 'camera_roll.dart';

/// Name des periodischen Tasks; auf iOS zugleich die BGTaskScheduler-ID
/// (Info.plist `BGTaskSchedulerPermittedIdentifiers`).
const autoUploadTask = 'de.jw29435.synologyExplorer.autoUpload';

/// WLAN oder Ethernet; ein VPN über Mobilfunk zählt nicht.
Future<bool> unmeteredNow() async {
  final types = await Connectivity().checkConnectivity();
  return types.contains(ConnectivityResult.wifi) ||
      types.contains(ConnectivityResult.ethernet);
}

Future<bool> chargingNow() async => switch (await Battery().batteryState) {
  BatteryState.charging ||
  BatteryState.full ||
  BatteryState.connectedNotCharging => true,
  _ => false,
};

/// Plant den Hintergrund-Task passend zu [config] ein oder entfernt ihn.
/// Android: WorkManager alle 15 min mit Netz-/Lade-Bedingung. iOS:
/// BGAppRefreshTask – das System entscheidet, ob und wann er läuft.
class AutoUploadScheduler {
  const AutoUploadScheduler();

  Future<void> apply(AutoUploadConfig config) async {
    if (!config.ready) {
      await Workmanager().cancelByUniqueName(autoUploadTask);
      return;
    }
    await Workmanager().registerPeriodicTask(
      autoUploadTask,
      autoUploadTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: config.wifiOnly
            ? NetworkType.unmetered
            : NetworkType.connected,
        requiresCharging: config.chargingOnly,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }
}

/// Einstieg des Hintergrund-Tasks (eigene Engine, ohne Riverpod).
@pragma('vm:entry-point')
void autoUploadDispatcher() {
  Workmanager().executeTask((task, input) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await runAutoUploadInBackground();
    } catch (_) {
      // Protokolliert der Lauf selbst; der Task gilt trotzdem als erledigt,
      // sonst plant WorkManager Wiederholungen mit Backoff.
    }
    return true;
  });
}

/// Ein Lauf außerhalb der App: meldet sich mit der gespeicherten SID an (ein
/// stiller Re-Login nur mit „Passwort merken“, siehe SessionManager) und lädt
/// über eine eigene TransferQueue hoch. Nach der Wartezeit bleiben offene
/// Uploads eingereiht und laufen im nächsten Lauf oder in der App weiter.
Future<void> runAutoUploadInBackground() async {
  final db = openAppDatabase();
  const storage = FlutterSecureStorage();
  SessionManager? session;
  TransferQueue? queue;
  try {
    await AutoUploader(
      AutoUploadRepository(db),
      const CameraRoll(),
      isUnmetered: unmeteredNow,
      isCharging: chargingNow,
    ).run(
      (serverId) async {
        final servers = ServerRepository(
          db,
          storage,
          CertificatePinStore(storage),
        );
        final profile = (await servers.all())
            .where((p) => p.id == serverId)
            .firstOrNull;
        if (profile == null) throw const SynoNotFound();
        final s = session = await servers.connect(profile);
        if (!s.isLoggedIn) throw const SynoSessionExpired();
        final q = queue = TransferQueue(
          db,
          api: TransferApi(s.client),
          serverId: serverId,
        );
        return (queue: q, listApi: FileStationListApi(s.client));
      },
      // iOS gibt einem App-Refresh rund 30 s, Android einem Worker 10 min.
      wait: Platform.isIOS
          ? const Duration(seconds: 20)
          : const Duration(minutes: 8),
    );
  } finally {
    await queue?.dispose(requeue: true);
    session?.client.close();
    await db.close();
  }
}
