import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/app/theme.dart';
import 'package:nuvo_explorer/features/audio/domain/playback_queue.dart';
import 'package:nuvo_explorer/features/audio/presentation/playback_providers.dart';
import 'package:nuvo_explorer/features/audio/presentation/queue_screen.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/audio_fakes.dart';

void main() {
  group('12 Now Playing', () {
    testWidgets('zeigt Titel, Position und Queue-Größe', (tester) async {
      final controller = FakeAudioController(playingAlbum());
      await pumpApp(
        tester,
        location: '/player',
        overrides: audioOverrides(controller),
      );
      expect(find.text('WIEDERGABE AUS ORDNER'), findsOne);
      expect(find.text('Alben › Nordlicht – Treibholz'), findsOne);
      expect(find.text('02 Strandgut'), findsOne);
      expect(find.text('Nordlicht · Treibholz · Titel 2 von 4'), findsOne);
      expect(find.text('3:12'), findsOne);
      expect(find.text('-1:36'), findsOne);
      expect(find.text('Queue (4)'), findsOne);
      expect(find.text('1,0×'), findsOne);
      // Platzhalter-Cover ist sichtbar (nicht 0 px breit).
      final cover = find
          .byType(ColoredBox)
          .evaluate()
          .where((e) => (e.widget as ColoredBox).color == AppColors.coverTop);
      expect(cover, isNotEmpty);
      for (final e in cover) {
        expect(e.size!.width, greaterThan(40));
      }
    });

    testWidgets('Play/Pause, Weiter, Zurück, Shuffle, Repeat', (tester) async {
      final controller = FakeAudioController(playingAlbum());
      final app = await pumpApp(
        tester,
        location: '/player',
        overrides: audioOverrides(controller),
      );
      final button = find.byKey(const Key('play-pause'));
      expect(
        find.descendant(of: button, matching: find.byIcon(Icons.pause)),
        findsOne,
      );
      await tester.tap(button);
      await tester.pump();
      expect(controller.calls, ['toggle']);
      expect(
        find.descendant(of: button, matching: find.byIcon(Icons.play_arrow)),
        findsOne,
      );

      await tester.tap(find.byTooltip('Nächster Titel'));
      await tester.tap(find.byTooltip('Vorheriger Titel'));
      expect(controller.calls, ['toggle', 'next', 'previous']);

      await tester.tap(find.byTooltip('Zufallswiedergabe aus'));
      await tester.pump();
      final state = app.container.read(audioControllerProvider);
      expect(state.shuffle, isTrue);
      // Aktueller Titel bleibt aktuell.
      expect(state.track!.name, '02 Strandgut.flac');

      await tester.tap(find.byTooltip('Wiederholen aus'));
      await tester.pump();
      expect(
        app.container.read(audioControllerProvider).repeat,
        QueueRepeat.one,
      );
      expect(find.byIcon(Icons.repeat_one), findsOne);
    });

    testWidgets('Sleep-Timer über das Sheet', (tester) async {
      final controller = FakeAudioController(playingAlbum());
      await pumpApp(
        tester,
        location: '/player',
        overrides: audioOverrides(controller),
      );
      await tester.tap(find.byKey(const Key('sleep-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('30 Minuten'));
      await tester.pumpAndSettle();
      expect(controller.calls, ['sleep 0:30:00.000000']);
      expect(find.text('Sleep 30 min'), findsOne);
    });

    testWidgets('Slider: Ziehen seekt einmal beim Loslassen', (tester) async {
      final controller = FakeAudioController(playingAlbum());
      await pumpApp(
        tester,
        location: '/player',
        overrides: audioOverrides(controller),
      );
      final slider = find.byKey(const Key('progress'));
      final box = tester.getRect(slider);
      final gesture = await tester.startGesture(
        box.centerLeft + const Offset(20, 0),
      );
      for (var i = 1; i <= 10; i++) {
        await gesture.moveBy(Offset(box.width / 20, 0));
        await tester.pump();
      }
      expect(controller.calls.where((c) => c.startsWith('seek')), isEmpty);
      await gesture.up();
      await tester.pump();
      expect(controller.calls.where((c) => c.startsWith('seek')), hasLength(1));
    });

    testWidgets('Fehler wird angezeigt', (tester) async {
      final controller = FakeAudioController(
        playingAlbum(playing: false).copyWith(error: const WifiRequired()),
      );
      await pumpApp(
        tester,
        location: '/player',
        overrides: audioOverrides(controller),
      );
      expect(
        find.text('Streaming nur im WLAN – gerade keine WLAN-Verbindung.'),
        findsOne,
      );
    });

    testWidgets('Queue-Knopf öffnet Screen 13', (tester) async {
      final controller = FakeAudioController(playingAlbum());
      await pumpApp(
        tester,
        location: '/player',
        overrides: audioOverrides(controller),
      );
      await tester.tap(find.text('Queue (4)'));
      await tester.pumpAndSettle();
      expect(find.byType(QueueScreen), findsOne);
    });
  });

  group('13 Queue', () {
    testWidgets('aktueller Titel hervorgehoben, danach die nächsten', (
      tester,
    ) async {
      final controller = FakeAudioController(playingAlbum());
      await pumpApp(
        tester,
        location: '/player/queue',
        overrides: audioOverrides(controller),
      );
      final current = find.byKey(const Key('queue-current'));
      expect(
        find.descendant(of: current, matching: find.text('02 Strandgut')),
        findsOne,
      );
      expect(find.text('ALS NÄCHSTES · 2 TITEL'), findsOne);
      expect(find.text('03 Nebelbank'), findsOne);
      expect(find.text('04 Leuchtfeuer'), findsOne);
      // Bereits gespielt: nicht in der Liste, nur im Hinweis.
      expect(find.text('01 Ebbe'), findsNothing);
      expect(find.textContaining('1 Titel wurde bereits gespielt'), findsOne);

      await tester.tap(find.text('04 Leuchtfeuer'));
      expect(controller.calls, ['jump 3']);
    });

    testWidgets('× und Wischen entfernen', (tester) async {
      final controller = FakeAudioController(playingAlbum());
      await pumpApp(
        tester,
        location: '/player/queue',
        overrides: audioOverrides(controller),
      );
      await tester.tap(find.byTooltip('Aus der Queue entfernen').first);
      await tester.pumpAndSettle();
      expect(controller.calls, ['remove 2']);
      expect(find.text('03 Nebelbank'), findsNothing);

      await tester.drag(find.text('04 Leuchtfeuer'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(controller.calls, ['remove 2', 'remove 2']);
      expect(find.text('ALS NÄCHSTES · KEINE TITEL'), findsOne);
    });

    testWidgets('Drag-Handle sortiert um', (tester) async {
      final controller = FakeAudioController(playingAlbum());
      await pumpApp(
        tester,
        location: '/player/queue',
        overrides: audioOverrides(controller),
      );
      final handle = find.byIcon(Icons.drag_handle).first;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, 150));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.calls, ['move 2 3']);
      final names = tester
          .widgetList<Text>(find.textContaining(RegExp(r'^0\d ')))
          .map((t) => t.data)
          .toList();
      expect(names, ['02 Strandgut', '04 Leuchtfeuer', '03 Nebelbank']);
    });

    testWidgets('Leeren beendet die Wiedergabe und schließt', (tester) async {
      final controller = FakeAudioController(playingAlbum());
      await pumpApp(
        tester,
        location: '/files',
        overrides: audioOverrides(controller),
      );
      await tester.tap(find.byKey(const Key('mini-player')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Queue (4)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leeren'));
      await tester.pumpAndSettle();
      expect(controller.calls, ['clear']);
      expect(find.byType(QueueScreen), findsNothing);
      // Now Playing schließt sich ebenfalls, der Mini-Player verschwindet.
      expect(find.text('WIEDERGABE AUS ORDNER'), findsNothing);
      expect(find.byKey(const Key('mini-player')), findsNothing);
      expect(find.byType(NavigationBar), findsOne);
    });
  });

  group('Mini-Player', () {
    testWidgets('zeigt Titel und Zeit, Play/Pause und Weiter', (tester) async {
      final controller = FakeAudioController(playingAlbum());
      await pumpApp(
        tester,
        location: '/files',
        overrides: audioOverrides(controller),
      );
      final mini = find.byKey(const Key('mini-player'));
      expect(tester.getSize(mini).height, 64);
      expect(
        find.descendant(of: mini, matching: find.text('02 Strandgut')),
        findsOne,
      );
      expect(
        find.descendant(
          of: mini,
          matching: find.text('Nordlicht · 3:12 / 4:48'),
        ),
        findsOne,
      );
      await tester.tap(find.byKey(const Key('play-pause')));
      await tester.tap(find.byTooltip('Nächster Titel'));
      expect(controller.calls, ['toggle', 'next']);
    });

    testWidgets('zeigt Wiedergabefehler statt der Zeit (E2E-031)', (
      tester,
    ) async {
      final controller = FakeAudioController(
        playingAlbum(playing: false).copyWith(error: const StreamFailed()),
      );
      await pumpApp(
        tester,
        location: '/files',
        overrides: audioOverrides(controller),
      );
      final mini = find.byKey(const Key('mini-player'));
      final error = find.descendant(
        of: mini,
        matching: find.byKey(const Key('mini-player-error')),
      );
      expect(error, findsOne);
      expect(
        find.descendant(of: error, matching: find.byIcon(Icons.error_outline)),
        findsOne,
      );
      expect(
        find.byTooltip(
          'Datei konnte nicht geladen werden – Verbindung zum NAS prüfen.',
        ),
        findsOne,
      );
      expect(tester.getSize(mini).height, 64);
      expect(tester.takeException(), isNull);
    });
  });
}
