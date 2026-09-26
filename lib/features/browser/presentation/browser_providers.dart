import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/syno_api_client.dart';
import '../../../core/network/syno_exception.dart';
import '../../../core/storage/storage_providers.dart';
import '../../servers/presentation/server_providers.dart';
import '../../settings/presentation/settings_providers.dart';
import '../data/file_station_list_api.dart';
import '../data/file_station_ops_api.dart';
import '../data/file_station_task_api.dart';
import '../data/local_library_repository.dart';
import '../data/thumbnail_cache.dart';
import '../domain/nas_entry.dart';
import '../domain/recycle.dart';

SynoApiClient _client(Ref ref) =>
    (ref.watch(sessionProvider) ?? (throw StateError('Keine Session'))).client;

final fileStationListApiProvider = Provider<FileStationListApi>(
  (ref) => FileStationListApi(_client(ref)),
);

final searchApiProvider = Provider<FileStationSearchApi>(
  (ref) => FileStationSearchApi(_client(ref)),
);

final dirSizeApiProvider = Provider<FileStationDirSizeApi>(
  (ref) => FileStationDirSizeApi(_client(ref)),
);

final fileOpsApiProvider = Provider<FileStationOpsApi>(
  (ref) => FileStationOpsApi(_client(ref)),
);

final thumbnailCacheProvider = Provider<ThumbnailCache>(
  (ref) => ThumbnailCache(
    _client(ref),
    getApplicationCacheDirectory().then((d) => Directory('${d.path}/thumbs')),
    maxBytes: ref.watch(cacheLimitProvider) ~/ 5,
  ),
);

final localLibraryProvider = Provider<LocalLibraryRepository>(
  (ref) => LocalLibraryRepository(ref.watch(appDatabaseProvider)),
);

final serverIdProvider = Provider<int>((ref) => _client(ref).profile.id!);

final sharesProvider = FutureProvider<List<NasEntry>>(
  (ref) => ref.watch(fileStationListApiProvider).listShares(),
);

final favoritesProvider = StreamProvider<List<NasEntry>>(
  (ref) =>
      ref.watch(localLibraryProvider).favorites(ref.watch(serverIdProvider)),
);

final isFavoriteProvider = StreamProvider.autoDispose.family<bool, String>(
  (ref, path) => ref
      .watch(localLibraryProvider)
      .isFavorite(ref.watch(serverIdProvider), path),
);

final recentProvider =
    StreamProvider<List<({NasEntry entry, DateTime openedAt})>>(
      (ref) =>
          ref.watch(localLibraryProvider).recent(ref.watch(serverIdProvider)),
    );

/// Einfacher, von außen setzbarer Wert.
class Setting<T> extends Notifier<T> {
  Setting(this._initial);

  final T _initial;

  @override
  T build() => _initial;

  void set(T value) => state = value;
}

typedef FolderSort = ({NasSortBy by, bool descending});

final sortProvider = NotifierProvider<Setting<FolderSort>, FolderSort>(
  () => Setting((by: NasSortBy.name, descending: false)),
);

/// `true` = Grid (Screen 07), sonst Liste (06).
final gridViewProvider = NotifierProvider<Setting<bool>, bool>(
  () => Setting(false),
);

// ---------------------------------------------------------------------------
// Ordnerinhalt mit Paging

class FolderState {
  const FolderState(this.entries, this.total, {this.loadMoreError});

  final List<NasEntry> entries;
  final int total;

  /// Fehler beim Nachladen der nächsten Seite; die Liste zeigt dann
  /// „Erneut versuchen“ statt automatisch neu zu laden.
  final Object? loadMoreError;

  bool get hasMore => entries.length < total;
}

final folderProvider = AsyncNotifierProvider.autoDispose
    .family<FolderNotifier, FolderState, String>(FolderNotifier.new);

class FolderNotifier extends AsyncNotifier<FolderState> {
  FolderNotifier(this.path);

  static const pageSize = 500;

  final String path;
  bool _loadingMore = false;

  Future<NasPage> _page(int offset) {
    final sort = ref.read(sortProvider);
    return ref
        .read(fileStationListApiProvider)
        .list(
          path,
          sortBy: sort.by,
          descending: sort.descending,
          offset: offset,
          limit: pageSize,
        );
  }

  @override
  Future<FolderState> build() async {
    ref.watch(sortProvider);
    ref.watch(fileStationListApiProvider);
    final page = await _page(0);
    return FolderState(page.entries, page.total);
  }

  /// Lädt die nächste Seite (offset/limit), falls vorhanden. Nach einem
  /// Fehler nur über [retryLoadMore].
  Future<void> loadMore() async {
    final current = state.value;
    if (_loadingMore ||
        current == null ||
        !current.hasMore ||
        current.loadMoreError != null) {
      return;
    }
    _loadingMore = true;
    try {
      final page = await _page(current.entries.length);
      // Inzwischen neu sortiert oder aktualisiert: Seite gehört nicht dazu.
      if (!ref.mounted || !identical(state.value, current)) return;
      state = AsyncData(
        FolderState([...current.entries, ...page.entries], page.total),
      );
    } catch (e) {
      if (!ref.mounted || !identical(state.value, current)) return;
      state = AsyncData(
        FolderState(current.entries, current.total, loadMoreError: e),
      );
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> retryLoadMore() {
    if (state.value case final current?) {
      state = AsyncData(FolderState(current.entries, current.total));
    }
    return loadMore();
  }
}

/// Auswahl je Ordner (Long-Press, Screen 08).
final selectionProvider = NotifierProvider.autoDispose
    .family<SelectionNotifier, Set<String>, String>(SelectionNotifier.new);

class SelectionNotifier extends Notifier<Set<String>> {
  SelectionNotifier(this.folder);

  final String folder;

  @override
  Set<String> build() => const {};

  void toggle(String path) => state = state.contains(path)
      ? ({...state}..remove(path))
      : {...state, path};

  void selectAll(Iterable<String> paths) => state = {...paths};

  void clear() => state = const {};
}

// ---------------------------------------------------------------------------
// Datei-Info und asynchrone Tasks

final entryInfoProvider = FutureProvider.autoDispose.family<NasEntry, String>(
  (ref, path) => ref.watch(fileStationListApiProvider).getInfo(path),
);

/// Wartezeiten zwischen Polls: 500 ms, dann ×1,5 bis höchstens 3 s.
/// [cancel] beendet das Polling; eine laufende Wartezeit endet nie.
class Backoff {
  static const min = Duration(milliseconds: 500);
  static const max = Duration(seconds: 3);

  var _delay = min;
  Timer? _timer;
  bool cancelled = false;

  Future<void> wait() {
    final done = Completer<void>();
    _timer = Timer(_delay, done.complete);
    _delay = Duration(
      milliseconds: (_delay.inMilliseconds * 1.5).round().clamp(
        min.inMilliseconds,
        max.inMilliseconds,
      ),
    );
    return done.future;
  }

  void cancel() {
    cancelled = true;
    _timer?.cancel();
  }
}

/// Ordnergröße über DirSize; `null` = noch nicht gestartet. Beim Verlassen
/// (autoDispose) wird ein laufender Task gestoppt.
final dirSizeProvider = NotifierProvider.autoDispose
    .family<DirSizeNotifier, AsyncValue<DirSize>?, String>(DirSizeNotifier.new);

class DirSizeNotifier extends Notifier<AsyncValue<DirSize>?> {
  DirSizeNotifier(this.path);

  final String path;
  late FileStationDirSizeApi _api;
  Backoff? _poll;
  String? _task;

  @override
  AsyncValue<DirSize>? build() {
    _api = ref.watch(dirSizeApiProvider);
    ref.onDispose(_cancel);
    return null;
  }

  Future<void> start() async {
    _cancel();
    final poll = _poll = Backoff();
    state = const AsyncLoading();
    try {
      final task = await _api.start(path);
      // Beim Warten auf start verlassen: Task gleich wieder stoppen.
      if (poll.cancelled) {
        unawaited(_quietly(() => _api.stop(task)));
        return;
      }
      _task = task;
      while (!poll.cancelled) {
        final size = await _api.status(task);
        if (poll.cancelled) return;
        state = AsyncData(size);
        if (size.finished) {
          _task = null;
          return;
        }
        await poll.wait();
      }
    } catch (e, st) {
      if (!poll.cancelled) state = AsyncError(e, st);
    }
  }

  void _cancel() {
    _poll?.cancel();
    if (_task case final task?) unawaited(_quietly(() => _api.stop(task)));
    _task = null;
  }
}

Future<void> _quietly(Future<void> Function() action) async {
  try {
    await action();
  } catch (_) {
    // Aufräumen ist best effort.
  }
}

/// Pollt einen CopyMove-/Delete-Task bis `finished` und liefert dabei den
/// Fortschritt (0…1, `null` = unbekannt). Wer das Abo vorher beendet, stoppt
/// den Task auf dem NAS.
Stream<double?> pollTask({
  required Future<String> Function() start,
  required Future<TaskProgress> Function(String task) status,
  required Future<void> Function(String task) stop,
}) async* {
  final task = await start();
  var finished = false;
  final poll = Backoff();
  try {
    while (true) {
      final p = await status(task);
      if (p.finished) {
        finished = true;
        yield 1;
        return;
      }
      yield p.progress;
      await poll.wait();
    }
  } finally {
    if (!finished) unawaited(_quietly(() => stop(task)));
  }
}

/// Ob Gelöschtes in [share] im Papierkorb landet.
enum RecycleBin {
  /// `#recycle` ist listbar.
  available,

  /// Kein `#recycle` (408): Löschen ist endgültig.
  missing,

  /// Nicht prüfbar, z. B. „Papierkorb nur für Administratoren“ (407).
  unknown,
}

final recycleBinProvider = FutureProvider.autoDispose
    .family<RecycleBin, String>((ref, share) async {
      try {
        await ref
            .watch(fileStationListApiProvider)
            .list(recycleFolder(share), limit: 1);
        return RecycleBin.available;
      } on SynoNotFound {
        return RecycleBin.missing;
      } on SynoNetworkError {
        // Netz/Session sagen nichts über den Papierkorb: als Fehler melden.
        rethrow;
      } on SynoSessionExpired {
        rethrow;
      } on SynoException {
        return RecycleBin.unknown;
      }
    });

// ---------------------------------------------------------------------------
// Suche (Screen 11)

enum SearchFilter {
  all({}),
  audio({NasFileType.audio}),
  image({NasFileType.image}),
  video({NasFileType.video}),
  document({NasFileType.pdf, NasFileType.docx, NasFileType.text});

  const SearchFilter(this.types);

  final Set<NasFileType> types;

  static const _office = ['doc', 'odt', 'rtf', 'xls', 'xlsx', 'ppt', 'pptx'];

  List<String> get extensions => [
    ...NasFileType.extensionsOf(types),
    if (this == document) ..._office,
  ];
}

class SearchState {
  const SearchState({
    this.query = '',
    this.filter = SearchFilter.all,
    this.entries = const [],
    this.total,
    this.running = false,
    this.error,
  });

  final String query;
  final SearchFilter filter;
  final List<NasEntry> entries;
  final int? total;
  final bool running;
  final Object? error;

  SearchState copyWith({
    String? query,
    SearchFilter? filter,
    List<NasEntry>? entries,
    int? Function()? total,
    bool? running,
    Object? Function()? error,
  }) => SearchState(
    query: query ?? this.query,
    filter: filter ?? this.filter,
    entries: entries ?? this.entries,
    total: total == null ? this.total : total(),
    running: running ?? this.running,
    error: error == null ? this.error : error(),
  );
}

/// Suche in einem Ordner (rekursiv) oder mit `null` über alle Shares.
/// start → list mit Backoff pollen; beim Verlassen (autoDispose) oder einer
/// neuen Suche stop + clean.
final searchProvider = NotifierProvider.autoDispose
    .family<SearchNotifier, SearchState, String?>(SearchNotifier.new);

class SearchNotifier extends Notifier<SearchState> {
  SearchNotifier(this.scope);

  static const debounce = Duration(milliseconds: 400);

  final String? scope;
  late FileStationSearchApi _api;
  Timer? _debounce;
  Backoff? _poll;
  String? _task;

  @override
  SearchState build() {
    _api = ref.watch(searchApiProvider);
    ref.onDispose(() {
      _debounce?.cancel();
      _cancel();
    });
    return const SearchState();
  }

  /// Neue Eingabe; die Suche startet nach [debounce].
  void setQuery(String query) {
    if (query == state.query) return;
    state = state.copyWith(query: query);
    _debounce?.cancel();
    _debounce = Timer(debounce, _start);
  }

  /// Setzt Suchbegriff und Filter und sucht sofort.
  void search(String query, SearchFilter filter) {
    state = state.copyWith(query: query, filter: filter);
    _debounce?.cancel();
    _start();
  }

  Future<void> _start() async {
    _cancel();
    final query = state.query.trim();
    if (query.isEmpty && state.filter == SearchFilter.all) {
      state = SearchState(filter: state.filter);
      return;
    }
    final poll = _poll = Backoff();
    state = SearchState(
      query: state.query,
      filter: state.filter,
      running: true,
    );
    try {
      final folders = switch (scope) {
        final path? => [path],
        null => [for (final s in await ref.read(sharesProvider.future)) s.path],
      };
      if (poll.cancelled) return;
      final task = await _api.start(
        folders,
        query,
        extensions: state.filter.extensions,
      );
      if (poll.cancelled) {
        unawaited(_cleanUp(task));
        return;
      }
      _task = task;
      while (true) {
        final page = await _api.list(task);
        if (poll.cancelled) return;
        final done = page.finished && page.total != null;
        state = state.copyWith(
          entries: page.entries,
          total: () => page.total,
          running: !done,
        );
        if (done) return;
        await poll.wait();
      }
    } catch (e) {
      if (!poll.cancelled) {
        state = state.copyWith(running: false, error: () => e);
      }
    }
  }

  void _cancel() {
    _poll?.cancel();
    if (_task case final task?) unawaited(_cleanUp(task));
    _task = null;
  }

  Future<void> _cleanUp(String task) async {
    await _quietly(() => _api.stop(task));
    await _quietly(() => _api.clean(task));
  }
}
