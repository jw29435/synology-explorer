import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/features/browser/data/file_station_task_api.dart';
import 'package:nuvo_explorer/features/browser/domain/nas_entry.dart';
import 'package:nuvo_explorer/features/browser/presentation/browser_providers.dart';
import 'package:nuvo_explorer/features/browser/presentation/entry_widgets.dart';
import 'package:nuvo_explorer/features/viewers/presentation/viewer_screen.dart';

import '../../../helpers/app_harness.dart';

/// Search-Task, der nie fertig wird – so läuft das Polling, bis der Screen
/// verlassen wird.
class _EndlessSearch implements FileStationSearchApi {
  final log = <String>[];
  var lists = 0;
  var tasks = 0;

  @override
  Future<String> start(
    List<String> folders,
    String pattern, {
    List<String> extensions = const [],
  }) async {
    log.add('start ${folders.join()} $pattern ${extensions.join(',')}');
    return 't${++tasks}';
  }

  @override
  Future<SearchPage> list(String taskId, {int limit = 500}) async {
    lists++;
    return (
      entries: fixtureEntries('SYNO.FileStation.Search/list.json', 'files'),
      total: null,
      finished: false,
    );
  }

  @override
  Future<void> stop(String taskId) async => log.add('stop $taskId');

  @override
  Future<void> clean(String taskId) async => log.add('clean $taskId');
}

void main() {
  testWidgets('11: pollt mit Backoff, Filter startet neu, Verlassen stoppt', (
    tester,
  ) async {
    final api = _EndlessSearch();
    final app = await pumpApp(
      tester,
      location: '/files/search?path=/music',
      overrides: [searchApiProvider.overrideWithValue(api)],
    );
    expect(find.text('Suche in music (rekursiv) · '), findsOne);

    await tester.enterText(find.byType(TextField), 'nebel');
    await tester.pump(SearchNotifier.debounce);
    await tester.pump();
    expect(api.log, ['start /music nebel ']);
    expect(api.lists, 1);
    expect(find.text('Suche läuft … 3 Treffer bisher'), findsOne);
    expect(find.textContaining('Nebelbank.flac', findRichText: true), findsOne);

    // Backoff: 500 ms, 750 ms, 1125 ms … höchstens 3 s.
    await tester.pump(const Duration(milliseconds: 500));
    expect(api.lists, 2);
    await tester.pump(const Duration(milliseconds: 750));
    expect(api.lists, 3);
    await tester.pump(const Duration(seconds: 20));
    expect(api.lists, lessThan(12), reason: 'Abstand wächst bis 3 s');

    await tester.tap(find.text('Audio'));
    await tester.pump();
    expect(api.log, containsAllInOrder(['stop t1', 'clean t1']));
    expect(api.log, contains(startsWith('start /music nebel mp3,')));

    routerOf(app.container).go('/files');
    await tester.pumpAndSettle();
    expect(api.log.sublist(api.log.length - 2), ['stop t2', 'clean t2']);
    final polled = api.lists;
    await tester.pump(const Duration(seconds: 30));
    expect(api.lists, polled, reason: 'kein Polling nach dem Verlassen');
  });

  testWidgets('11: „Ganzes NAS“ hat ein Touch-Ziel von 44 px (E2E-054)', (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: '/files/search?path=/music',
      overrides: [searchApiProvider.overrideWithValue(_EndlessSearch())],
    );
    final target = tester.getSize(
      find.ancestor(
        of: find.text('Ganzes NAS'),
        matching: find.byType(InkWell),
      ),
    );
    expect(target.height, greaterThanOrEqualTo(44));
  });

  testWidgets('11: Datei-Treffer öffnet die Datei, Ordner den Ordner '
      '(E2E-020)', (tester) async {
    final app = await pumpApp(
      tester,
      location: '/files/search?path=/music',
      overrides: [searchApiProvider.overrideWithValue(_EndlessSearch())],
    );
    final router = routerOf(app.container);
    await tester.enterText(find.byType(TextField), 'nebel');
    await tester.pump(SearchNotifier.debounce);
    await tester.pump();

    await tester.tap(
      find.textContaining('Live 2024', findRichText: true).first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      router.state.uri.toString(),
      folderLocation('/music/Alben/Nebelhorn – Live 2024'),
    );
    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.textContaining('Setlist', findRichText: true));
    await tester.pump();
    expect(
      router.state.uri.toString(),
      viewerLocation(
        '/music/Alben/Nebelhorn – Live 2024/Nebelhorn_Setlist.pdf',
      ),
    );
    // Suche verlassen: Polling endet.
    router.go('/files');
    await tester.pumpAndSettle();
  });

  test('Filter setzen Dateiendungen', () {
    expect(SearchFilter.all.extensions, isEmpty);
    expect(SearchFilter.audio.extensions, containsAll(['mp3', 'flac']));
    expect(SearchFilter.image.extensions, contains('heic'));
    expect(SearchFilter.document.extensions, containsAll(['pdf', 'docx']));
    expect(
      NasFileType.extensionsOf({NasFileType.video}),
      containsAll(['mp4', 'mkv']),
    );
  });
}
