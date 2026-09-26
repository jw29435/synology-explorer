import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/media_cache.dart';
import '../../browser/domain/nas_entry.dart';
import '../../servers/presentation/server_providers.dart';
import '../../settings/presentation/settings_providers.dart';
import '../data/media_repository.dart';

/// Limit des Medien-Caches: 4/5 des Cache-Limits aus den Einstellungen
/// (den Rest bekommen die Vorschaubilder).
final mediaCacheLimitProvider = Provider<int>(
  (ref) => ref.watch(cacheLimitProvider) * 4 ~/ 5,
);

final mediaCacheProvider = Provider<MediaCache>(
  (ref) => MediaCache(
    getApplicationCacheDirectory().then((d) => Directory('${d.path}/media')),
    maxBytes: ref.watch(mediaCacheLimitProvider),
  ),
);

final mediaRepositoryProvider = Provider<MediaRepository>(
  (ref) => MediaRepository(
    (ref.watch(sessionProvider) ?? (throw StateError('Keine Session'))).client,
    ref.watch(mediaCacheProvider),
  ),
);

/// Ladezustand einer Datei: [progress] 0…1 (null = Größe unbekannt), am Ende
/// mit [file].
typedef CachedFile = ({double? progress, File? file});

/// Lädt [NasEntry] in den Cache und meldet den Fortschritt; beim Verlassen
/// des Viewers wird ein laufender Download abgebrochen.
final cachedFileProvider = StreamProvider.autoDispose
    .family<CachedFile, NasEntry>((ref, entry) {
      final cancel = CancelToken();
      final out = StreamController<CachedFile>();
      ref.onDispose(() {
        cancel.cancel();
        out.close();
      });
      out.add((progress: 0, file: null));
      ref
          .watch(mediaRepositoryProvider)
          .file(
            entry,
            cancel: cancel,
            onProgress: (received, total) {
              if (out.isClosed) return;
              final size = total > 0 ? total : entry.size ?? 0;
              out.add((
                progress: size > 0 ? received / size : null,
                file: null,
              ));
            },
          )
          .then(
            (file) {
              if (!out.isClosed) out.add((progress: 1, file: file));
            },
            onError: (Object e, StackTrace st) {
              if (!out.isClosed) out.addError(e, st);
            },
          );
      return out.stream;
    });
