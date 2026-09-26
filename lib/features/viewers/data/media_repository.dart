import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/media_proxy.dart';
import '../../../core/network/syno_api_client.dart';
import '../../../core/storage/media_cache.dart';
import '../../browser/domain/nas_entry.dart';

/// Originaldateien für die Viewer: komplett in den [MediaCache] laden (Bild,
/// PDF, Text, DOCX, „Öffnen mit“) oder über einen [MediaProxy] streamen
/// (Video).
class MediaRepository {
  MediaRepository(this._client, this._cache);

  final SynoApiClient _client;
  final MediaCache _cache;

  /// Laufende Downloads je Schlüssel; mehrere Viewer teilen sich einen.
  final _jobs = <String, _Job>{};

  /// Lokale Kopie von [entry]; Schlüssel ist Server, Pfad und Änderungszeit.
  /// [cancel] bricht den Download nur ab, wenn niemand sonst mehr wartet.
  Future<File> file(
    NasEntry entry, {
    ProgressCallback? onProgress,
    CancelToken? cancel,
  }) {
    final key =
        '${_client.profile.id}|${entry.path}|'
        '${entry.mtime?.millisecondsSinceEpoch}';
    final dot = entry.name.lastIndexOf('.');
    final job = _jobs[key] ??= _Job();
    job.waiters++;
    if (onProgress != null) job.listeners.add(onProgress);
    if (cancel == null) {
      job.keep = true;
    } else {
      cancel.whenCancel.then((_) {
        job.listeners.remove(onProgress);
        if (--job.waiters == 0 && !job.keep) job.token.cancel();
      });
    }
    return job.future ??= _cache
        .file(
          key,
          (target) => _download(entry, target, job),
          extension: dot < 1 ? '' : entry.name.substring(dot + 1).toLowerCase(),
        )
        .whenComplete(() {
          if (identical(_jobs[key], job)) _jobs.remove(key);
        });
  }

  Future<void> _download(NasEntry entry, File target, _Job job) =>
      _client.download(
        'SYNO.FileStation.Download',
        'download',
        {'path': entry.path, 'mode': 'open'},
        target,
        cancelToken: job.token,
        onProgress: (done, total) {
          for (final listener in [...job.listeners]) {
            listener(done, total ?? -1);
          }
        },
      );

  /// Proxy auf 127.0.0.1 für den Video-Player; der Aufrufer schließt ihn.
  Future<MediaProxy> stream(NasEntry entry) =>
      MediaProxy.start(_client, entry.path);
}

class _Job {
  final token = CancelToken();
  final listeners = <ProgressCallback>[];
  Future<File>? future;
  int waiters = 0;

  /// Ein Aufrufer ohne Abbruch-Token wartet bis zum Ende.
  bool keep = false;
}
