import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/features/audio/data/playback_repository.dart';

import '../helpers/app_harness.dart';
import '../helpers/audio_fakes.dart';

void main() {
  testWidgets('ohne Server startet die App auf der Server-Liste', (
    tester,
  ) async {
    await pumpApp(tester, loggedIn: false);
    expect(find.text('Server'), findsOne);
    expect(find.text('Noch kein Server eingerichtet.'), findsOne);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('mit Session: vier Tabs, Tab-Wechsel', (tester) async {
    await pumpApp(tester, location: '/files');
    final tabs = find.byType(NavigationBar);
    for (final label in ['Dateien', 'Offline', 'Transfers', 'Einstellungen']) {
      expect(find.descendant(of: tabs, matching: find.text(label)), findsOne);
    }
    expect(find.byKey(const Key('mini-player-slot')), findsNothing);

    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Einstellungen'),
      ),
      findsOne,
    );
  });

  testWidgets('Einstellung „Streaming nur im WLAN“ landet in drift', (
    tester,
  ) async {
    final app = await pumpApp(tester, location: '/settings');
    await tester.tap(find.byKey(const Key('wifi-only')));
    await tester.pumpAndSettle();
    expect(
      await tester.runAsync(() => PlaybackRepository(app.db).wifiOnly()),
      isTrue,
    );
    final tile = tester.widget<SwitchListTile>(
      find.byKey(const Key('wifi-only')),
    );
    expect(tile.value, isTrue);
  });

  testWidgets('Shell zeigt den Mini-Player (64 px), sobald etwas läuft', (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: '/files',
      overrides: audioOverrides(FakeAudioController(playingAlbum())),
    );
    final slot = find.byKey(const Key('mini-player-slot'));
    expect(tester.getSize(slot).height, 64);
  });
}
