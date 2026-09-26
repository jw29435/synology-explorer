import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/features/browser/domain/nas_entry.dart';
import 'package:synology_explorer/features/viewers/presentation/viewer_screen.dart';

import '../../helpers/app_harness.dart';

/// `getinfo` antwortet nie (langsames NAS).
class _SlowInfo extends FakeListApi {
  @override
  Future<NasEntry> getInfo(String path) => Completer<NasEntry>().future;
}

void main() {
  testWidgets('E2E-042: Ladezustand mit Zurückknopf', (tester) async {
    final app = await pumpApp(tester, location: '/files', listApi: _SlowInfo());
    // Aus „Zuletzt geöffnet“: ohne Änderungszeit, also erst `getinfo`.
    routerOf(app.container).push(viewerLocation('/dokumente/Notizen.txt'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CircularProgressIndicator), findsOne);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      routerOf(app.container).routerDelegate.state.uri.toString(),
      '/files',
    );
  });
}
