import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/features/browser/domain/nas_entry.dart';
import 'package:synology_explorer/features/viewers/presentation/video_player_screen.dart';
import 'package:synology_explorer/features/viewers/presentation/viewer_common.dart';
import 'package:synology_explorer/features/viewers/presentation/viewer_providers.dart';
import 'package:synology_explorer/features/viewers/presentation/viewer_screen.dart';

import '../../helpers/app_harness.dart';
import 'fake_media.dart';

NasEntry _text(String name, int size) => NasEntry(
  path: '/dokumente/Projekte/$name',
  name: name,
  isDir: false,
  type: NasFileType.text,
  size: size,
  mtime: DateTime.utc(2026, 9, 1),
);

Future<FakeMediaRepository> _open(WidgetTester tester, NasEntry entry) async {
  final media = FakeMediaRepository({
    'README.md': 'test/fixtures/text/README.md',
    'tool.py': 'test/fixtures/text/tool.py',
  });
  final app = await pumpApp(
    tester,
    location: '/files',
    overrides: [mediaRepositoryProvider.overrideWithValue(media)],
  );
  routerOf(app.container).push(viewerLocation(entry.path), extra: entry);
  await pumpWithIo(tester);
  await tester.pumpAndSettle();
  return media;
}

void main() {
  testWidgets('18: Markdown gerendert, Umschalter auf Rohtext', (tester) async {
    await _open(tester, _text('README.md', 3174));
    expect(find.text('dokumente/Projekte · 3,1 KB'), findsOne);
    expect(find.text('NAS-Setup Heim'), findsOne);
    expect(find.textContaining('# NAS-Setup Heim'), findsNothing);

    await tester.tap(find.text('Rohtext'));
    await tester.pumpAndSettle();
    expect(find.textContaining('# NAS-Setup Heim'), findsOne);
  });

  testWidgets('18: Code mit Highlighting nach Endung', (tester) async {
    await _open(tester, _text('tool.py', 60));
    final text = tester.widget<SelectableText>(find.byType(SelectableText));
    final spans = <TextSpan>[];
    text.textSpan!.visitChildren((s) {
      if (s is TextSpan && s.text != null) spans.add(s);
      return true;
    });
    // Schlüsselwörter bekommen eine eigene Farbe.
    final keyword = spans.firstWhere((s) => s.text == 'import');
    final plain = spans.firstWhere((s) => s.text!.contains('os'));
    expect(keyword.style?.color, isNot(plain.style?.color));
  });

  testWidgets('18: über 5 MB nur Hinweis und „Öffnen mit“', (tester) async {
    final media = await _open(tester, _text('server.log', 6 << 20));
    expect(find.textContaining('größer als 5 MB'), findsOne);
    expect(find.text('Öffnen mit …'), findsOne);
    expect(media.requested, isEmpty, reason: 'erst auf Knopfdruck laden');
  });

  testWidgets('21 → 18: Offline-Datei öffnet ohne Session im Viewer', (
    tester,
  ) async {
    final app = await pumpApp(tester, location: '/offline', loggedIn: false);
    final entry = _text('README.md', 3174);
    routerOf(app.container).push(
      viewerLocation(entry.path),
      extra: LocalView(
        entry,
        LocalFile(File('test/fixtures/text/README.md'), 1),
      ),
    );
    await pumpWithIo(tester);
    await tester.pumpAndSettle();
    expect(find.text('NAS-Setup Heim'), findsOne);
    expect(find.byTooltip('Teilen'), findsOne);
  });

  test('16: Zeitformat des Players', () {
    expect(formatPlaybackTime(const Duration(seconds: 102)), '1:42');
    expect(formatPlaybackTime(const Duration(hours: 1, seconds: 5)), '1:00:05');
  });
}
