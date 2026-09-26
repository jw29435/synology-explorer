import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synology_explorer/app/theme.dart';
import 'package:synology_explorer/features/audio/presentation/playback_providers.dart';
import 'package:synology_explorer/features/viewers/presentation/video_player_screen.dart';
import 'package:synology_explorer/l10n/app_localizations.dart';

import '../../helpers/audio_fakes.dart';

// Den Player selbst (media_kit/libmpv) gibt es headless nicht; getestet
// werden die Teile ohne Player.

Future<void> _pump(WidgetTester tester, Widget child, {Size? size}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  tester.view
    ..physicalSize = (size ?? const Size(360, 740)) * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

class _Audio extends FakeAudioController {
  _Audio(super.initial);

  @override
  Future<void> pause() async => calls.add('pause');
}

/// Führt beim ersten Bauen aus, was der Player in `initState` tut.
Future<_Audio> _startVideo(WidgetTester tester, {required bool playing}) async {
  final audio = _Audio(playingAlbum(playing: playing));
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [audioControllerProvider.overrideWith(() => audio)],
      child: Consumer(
        builder: (context, ref, _) {
          pauseMusicForVideo(ref);
          return const SizedBox();
        },
      ),
    ),
  );
  return audio;
}

void main() {
  testWidgets('E2E-045: Videostart pausiert laufende Musik', (tester) async {
    expect((await _startVideo(tester, playing: true)).calls, ['pause']);
    expect((await _startVideo(tester, playing: false)).calls, isEmpty);
  });

  testWidgets('E2E-052: Resume-Karte passt ins Hochformat (360 dp)', (
    tester,
  ) async {
    var resumed = false;
    await _pump(
      tester,
      Center(
        child: ResumeCard(
          at: const Duration(minutes: 1, seconds: 42),
          onResume: () => resumed = true,
          onRestart: () {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Bei 1:42 fortsetzen?'), findsOne);
    await tester.tap(find.text('Fortsetzen'));
    expect(resumed, isTrue);
    for (final label in ['Fortsetzen', 'Von vorn']) {
      expect(
        tester
            .getSize(
              find.ancestor(
                of: find.text(label),
                matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
              ),
            )
            .height,
        greaterThanOrEqualTo(44),
        reason: label,
      );
    }
  });
}
