import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/storage_providers.dart';
import '../../browser/data/file_station_list_api.dart';
import '../../browser/domain/nas_entry.dart';
import '../../browser/presentation/browser_providers.dart';
import '../../servers/presentation/server_providers.dart';
import '../data/offline_store.dart';
import '../data/transfer_api.dart';
import '../data/transfer_queue.dart';
import 'transfer_notifications.dart';

final offlineStoreProvider = Provider<OfflineStore>(
  (ref) => OfflineStore(
    ref.watch(appDatabaseProvider),
    getApplicationDocumentsDirectory().then(
      (d) => Directory('${d.path}/offline'),
    ),
  ),
);

final transferNotificationsProvider = Provider<TransferNotifications>(
  (ref) => TransferNotifications(),
);

/// Die Queue der aktiven Session; ohne Session nur Liste und Verwaltung,
/// kein Worker. Startet nach einem Neustart unterbrochene Transfers neu.
final transferQueueProvider = Provider<TransferQueue>((ref) {
  final session = ref.watch(sessionProvider);
  final queue = TransferQueue(
    ref.watch(appDatabaseProvider),
    api: session == null ? null : TransferApi(session.client),
    serverId: session?.client.profile.id,
  );
  final notifications = ref.watch(transferNotificationsProvider);
  final sub = queue.watch().listen(notifications.update);
  unawaited(queue.start());
  ref.onDispose(() {
    unawaited(sub.cancel());
    unawaited(queue.dispose());
  });
  return queue;
});

final transfersProvider = StreamProvider<List<Transfer>>(
  (ref) => ref.watch(transferQueueProvider).watch(),
);

/// Reiht Downloads in den Offline-Bereich ein; Ordner werden rekursiv
/// aufgelöst. Liefert die Zahl der eingereihten Dateien.
Future<int> enqueueDownloads(WidgetRef ref, Iterable<NasEntry> entries) async {
  final queue = ref.read(transferQueueProvider);
  final store = ref.read(offlineStoreProvider);
  final listApi = ref.read(fileStationListApiProvider);
  final serverId = ref.read(serverIdProvider);
  var count = 0;
  final seen = <String>{};
  Future<void> add(NasEntry e) async {
    if (!seen.add(e.path)) return;
    if (e.isDir) {
      for (var offset = 0; ; offset += 1000) {
        final page = await listApi.list(e.path, offset: offset, limit: 1000);
        for (final child in page.entries) {
          await add(child);
        }
        if (offset + page.entries.length >= page.total ||
            page.entries.isEmpty) {
          break;
        }
      }
      return;
    }
    await queue.enqueueDownload(
      remotePath: e.path,
      localPath: await store.localPathFor(serverId, e.path),
      size: e.size,
      mtime: e.mtime,
    );
    count++;
  }

  for (final e in entries) {
    await add(e);
  }
  return count;
}

final offlineFilesProvider = StreamProvider<List<OfflineFile>>(
  (ref) => ref.watch(offlineStoreProvider).watchAll(),
);

final isOfflineProvider = StreamProvider.autoDispose.family<bool, String>(
  (ref, path) => ref
      .watch(offlineStoreProvider)
      .isOffline(ref.watch(serverIdProvider), path),
);

/// Offline-Dateien des aktiven Servers, die sich auf dem NAS geändert haben
/// (mtime), mit der neuen Änderungszeit. Ohne Session oder Netz: keine.
final offlineChangedProvider =
    FutureProvider.autoDispose<Map<String, DateTime>>((ref) async {
      final session = ref.watch(sessionProvider);
      if (session == null) return const {};
      final files = [
        for (final f in await ref.watch(offlineFilesProvider.future))
          if (f.serverId == session.client.profile.id) f,
      ];
      if (files.isEmpty) return const {};
      final FileStationListApi api = ref.watch(fileStationListApiProvider);
      try {
        final remote = await api.mtimes([for (final f in files) f.remotePath]);
        return {
          for (final f in files)
            if (remote[f.remotePath] case final mtime?
                when !mtime.isAtSameMomentAs(f.mtime ?? mtime))
              f.remotePath: mtime,
        };
      } catch (_) {
        return const {};
      }
    });

/// Belegter Speicher: Offline-Dateien und App-Cache (Thumbnails, Medien).
final storageUsageProvider =
    FutureProvider.autoDispose<({int offline, int cache})>((ref) async {
      final files = await ref.watch(offlineFilesProvider.future);
      var cache = 0;
      try {
        final dir = await getApplicationCacheDirectory();
        await for (final e in dir.list(recursive: true, followLinks: false)) {
          if (e is File) cache += await e.length();
        }
      } catch (_) {
        // Cache nicht lesbar: nur Offline-Dateien zeigen.
      }
      return (offline: files.fold(0, (s, f) => s + f.size), cache: cache);
    });
