import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/core/network/syno_exception.dart';
import 'package:synology_explorer/features/browser/data/file_station_list_api.dart';
import 'package:synology_explorer/features/browser/data/file_station_task_api.dart';
import 'package:synology_explorer/features/browser/domain/nas_entry.dart';
import 'package:synology_explorer/features/browser/presentation/browser_providers.dart';

import '../../../helpers/app_harness.dart';

/// 600 Einträge; die erste Seite kommt sofort, Folgeseiten über [next].
class _PagedApi extends FakeListApi {
  Completer<NasPage> next = Completer();

  NasEntry _e(String name) => NasEntry(
    path: '/p/$name',
    name: name,
    isDir: false,
    type: NasFileType.other,
  );

  @override
  Future<NasPage> list(
    String folderPath, {
    NasSortBy sortBy = NasSortBy.name,
    bool descending = false,
    int offset = 0,
    int limit = 500,
  }) {
    calls.add((
      path: folderPath,
      by: sortBy,
      descending: descending,
      offset: offset,
    ));
    if (offset > 0) return next.future;
    return Future.value((
      entries: [for (var i = 0; i < 500; i++) _e('${sortBy.name}$i')],
      total: 600,
    ));
  }
}

class _DirSizeApi implements FileStationDirSizeApi {
  final started = Completer<String>();
  final stopped = <String>[];

  @override
  Future<String> start(String path) => started.future;

  @override
  Future<DirSize> status(String taskId) async =>
      (finished: false, files: 0, dirs: 0, bytes: 0);

  @override
  Future<void> stop(String taskId) async => stopped.add(taskId);
}

void main() {
  late _PagedApi api;
  late ProviderContainer container;
  final folder = folderProvider('/p');

  setUp(() {
    api = _PagedApi();
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [fileStationListApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    container.listen(folder, (_, _) {});
  });

  test('Folgeseite nach Sortierwechsel wird verworfen', () async {
    await container.read(folder.future);
    final loading = container.read(folder.notifier).loadMore();

    container.read(sortProvider.notifier).set((
      by: NasSortBy.size,
      descending: false,
    ));
    final resorted = await container.read(folder.future);
    expect(resorted.entries.first.name, 'size0');

    // Die alte Folgeseite (Name-Sortierung) kommt erst jetzt an.
    api.next.complete((entries: [api._e('alt')], total: 600));
    await loading;
    final state = container.read(folder).value!;
    expect(state.entries, hasLength(500));
    expect(state.entries.first.name, 'size0');
  });

  test(
    'Fehler beim Nachladen: im State, kein Auto-Reload, Retry lädt',
    () async {
      await container.read(folder.future);
      final notifier = container.read(folder.notifier);
      api.next.completeError(const SynoNetworkError());
      await notifier.loadMore();

      final failed = container.read(folder).value!;
      expect(failed.loadMoreError, isA<SynoNetworkError>());
      expect(failed.entries, hasLength(500));

      final calls = api.calls.length;
      await notifier.loadMore();
      expect(
        api.calls,
        hasLength(calls),
        reason: 'kein automatisches Nachladen',
      );

      api.next = Completer()..complete((entries: [api._e('x')], total: 501));
      await notifier.retryLoadMore();
      final ok = container.read(folder).value!;
      expect(ok.loadMoreError, isNull);
      expect(ok.entries, hasLength(501));
      expect(ok.hasMore, isFalse);
    },
  );

  test('DirSize: Verlassen während start stoppt den Task danach', () async {
    final dirApi = _DirSizeApi();
    final c = ProviderContainer(
      overrides: [dirSizeApiProvider.overrideWithValue(dirApi)],
    );
    addTearDown(c.dispose);
    final sub = c.listen(dirSizeProvider('/p'), (_, _) {});
    final running = c.read(dirSizeProvider('/p').notifier).start();

    sub.close();
    await Future<void>.delayed(Duration.zero); // autoDispose
    dirApi.started.complete('t1');
    await running;
    await Future<void>.delayed(Duration.zero);
    expect(dirApi.stopped, ['t1']);
  });
}
