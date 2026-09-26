import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/features/audio/presentation/playback_providers.dart';
import 'package:nuvo_explorer/features/browser/presentation/entry_widgets.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/audio_fakes.dart';

const album = '/music/Alben/Nordlicht – Treibholz';

void main() {
  testWidgets('06: Tippen auf Audio spielt den Ordner ab dieser Datei', (
    tester,
  ) async {
    final controller = FakeAudioController(const AudioState());
    await pumpApp(
      tester,
      location: folderLocation(album),
      overrides: audioOverrides(controller),
    );
    await tester.tap(find.text('02 Strandgut.flac'));
    await tester.pumpAndSettle();
    expect(controller.calls, [
      'playFolder $album $album/02 Strandgut.flac false',
    ]);
  });

  testWidgets('06: „Ordner abspielen“ startet beim ersten Titel', (
    tester,
  ) async {
    final controller = FakeAudioController(const AudioState());
    await pumpApp(
      tester,
      location: folderLocation(album),
      overrides: audioOverrides(controller),
    );
    await tester.tap(find.byKey(const Key('play-folder')));
    await tester.pumpAndSettle();
    expect(controller.calls, ['playFolder $album - false']);
  });

  testWidgets('06: laufender Titel ist markiert', (tester) async {
    final controller = FakeAudioController(playingAlbum());
    await pumpApp(
      tester,
      location: folderLocation(album),
      overrides: audioOverrides(controller),
    );
    expect(find.textContaining('läuft gerade'), findsOne);
  });

  testWidgets('09: Ordner inkl. Unterordner abspielen, Hörbuch-Modus', (
    tester,
  ) async {
    final controller = FakeAudioController(const AudioState());
    await pumpApp(
      tester,
      location: folderLocation(album),
      overrides: audioOverrides(controller),
    );
    // Kebab von „Bonus“ (Ordner).
    await tester.tap(find.byTooltip('Mehr').first);
    await tester.pumpAndSettle();
    expect(find.text('Abspielen ab hier'), findsNothing);
    final audiobook = find.byKey(const Key('audiobook-mode'));
    expect(tester.widget<SwitchListTile>(audiobook).value, isFalse);
    await tester.tap(audiobook);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(audiobook).value, isTrue);

    await tester.tap(find.text('Ordner abspielen (inkl. Unterordner)'));
    await tester.pumpAndSettle();
    expect(controller.calls, ['playFolder $album/Bonus - true']);
  });

  testWidgets('09: „Abspielen ab hier“ bietet nach dem Laden Fortsetzen an – '
      'auch wenn das Sheet schon zu ist', (tester) async {
    final controller = FakeAudioController(
      const AudioState(),
      resume: const Duration(minutes: 1, seconds: 40),
      delay: const Duration(milliseconds: 500),
    );
    await pumpApp(
      tester,
      location: folderLocation(album),
      overrides: audioOverrides(controller),
    );
    await tester.tap(find.byTooltip('Mehr').at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abspielen ab hier'));
    // Sheet schließt, dann erst kommt playFolder zurück.
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('Bei 1:40 fortsetzen?'), findsOne);
    expect(find.text('Unerwarteter Fehler.'), findsNothing);
    await tester.tap(find.text('Fortsetzen'));
    expect(controller.calls.last, 'seek 0:01:40.000000');
    // Snackbar-Timer ablaufen lassen.
    await tester.pumpAndSettle(const Duration(seconds: 10));
  });

  testWidgets('Fortsetzen-Snackbar verschwindet von selbst', (tester) async {
    final controller = FakeAudioController(
      const AudioState(),
      resume: const Duration(minutes: 1, seconds: 40),
    );
    await pumpApp(
      tester,
      location: folderLocation(album),
      overrides: audioOverrides(controller),
    );
    await tester.tap(find.text('02 Strandgut.flac'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Bei 1:40 fortsetzen?'), findsOne);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text('Bei 1:40 fortsetzen?'), findsNothing);
  });

  testWidgets('06: Chip „Abspielen“ passt auf 390 dp, nichts abgeschnitten', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      location: folderLocation(album),
      overrides: audioOverrides(FakeAudioController(const AudioState())),
    );
    final chip = find.byKey(const Key('play-folder'));
    for (final owner in [chip, find.text('7 Elemente')]) {
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: owner, matching: find.byType(RichText)).last,
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      // Volle Breite = nicht per Ellipse gekürzt.
      expect(
        paragraph.size.width,
        greaterThanOrEqualTo(
          paragraph.getMaxIntrinsicWidth(double.infinity) - 0.5,
        ),
      );
    }
    expect(tester.getSemantics(chip).label, contains('Ordner abspielen'));
    semantics.dispose();
  });

  testWidgets('06: Chip „Abspielen“ passt auf 360 dp (E2E-065)', (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: folderLocation(album),
      overrides: audioOverrides(FakeAudioController(const AudioState())),
    );
    tester.view.physicalSize = const Size(1080, 2340);
    await tester.pumpAndSettle();
    final chip = find.byKey(const Key('play-folder'));
    for (final owner in [chip, find.text('7 Elemente')]) {
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: owner, matching: find.byType(RichText)).last,
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(
        paragraph.size.width,
        greaterThanOrEqualTo(
          paragraph.getMaxIntrinsicWidth(double.infinity) - 0.5,
        ),
      );
    }
    expect(tester.getSize(chip).height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '„Ordner abspielen“ ohne Audio meldet das, auch wenn etwas läuft',
    (tester) async {
      await pumpApp(
        tester,
        location: folderLocation(album),
        overrides: audioOverrides(
          FakeAudioController(playingAlbum(), emptyFolder: true),
        ),
      );
      await tester.tap(find.byKey(const Key('play-folder')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Keine Audiodateien in diesem Ordner.'), findsOne);
      await tester.pumpAndSettle(const Duration(seconds: 10));
    },
  );
}
