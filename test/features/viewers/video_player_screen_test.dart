import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nuvo_explorer/app/theme.dart';
import 'package:nuvo_explorer/core/network/syno_exception.dart';
import 'package:nuvo_explorer/features/audio/presentation/playback_providers.dart';
import 'package:nuvo_explorer/features/viewers/presentation/video_player_screen.dart';
import 'package:nuvo_explorer/l10n/app_localizations.dart';

import '../../helpers/audio_fakes.dart';

final l10n = lookupAppLocalizations(const Locale('de'));

// Den Player selbst (media_kit/libmpv) gibt es headless nicht; getestet
// werden die Teile ohne Player.

Future<void> _pump(WidgetTester tester, Widget child, {Size? size}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  tester.view
    ..physicalSize = (size ?? const Size(360, 740)) * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
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
  test('E2E-041: Ladeanzeige beim Öffnen und Puffern', () {
    const open = PlayerState(duration: Duration(minutes: 6));
    expect(videoLoading(const PlayerState(), failed: false), isTrue);
    expect(videoLoading(open, failed: false), isFalse);
    expect(videoLoading(open.copyWith(buffering: true), failed: false), isTrue);
    expect(videoLoading(const PlayerState(), failed: true), isFalse);
  });

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

  test('E2E-028: Fehler nach dem Start nur, wenn das NAS scheitert', () {
    const offline = SynoNetworkError();
    // Vor dem Start: jede Meldung, der Proxy-Fehler geht vor.
    expect(playerError('tcp: failed', started: false), 'tcp: failed');
    expect(
      playerError('tcp: failed', started: false, proxyError: offline),
      offline,
    );
    // Danach: harmlose Meldungen nicht, Netzabbruch schon.
    expect(playerError('vd: late frame', started: true), isNull);
    expect(
      playerError('stream: failed', started: true, proxyError: offline),
      offline,
    );
  });

  group('E2E-027: Fehlerarten', () {
    Future<List<String>> show(WidgetTester tester, Object error) async {
      final retries = <String>[];
      await _pump(
        tester,
        VideoError(error: error, onRetry: () => retries.add('retry')),
      );
      return retries;
    }

    testWidgets('Netz: Meldung und „Erneut versuchen“', (tester) async {
      final retries = await show(tester, const SynoNetworkError());
      expect(find.text(l10n.errorNetwork), findsOne);
      await tester.tap(find.text(l10n.retry));
      expect(retries, ['retry']);
    });

    testWidgets('Session abgelaufen: „Anmelden“ statt Erneut', (tester) async {
      await show(tester, const SynoSessionExpired(119));
      expect(find.text(l10n.errorSessionExpired), findsOne);
      expect(find.text(l10n.signIn), findsOne);
      expect(find.text(l10n.retry), findsNothing);
    });

    testWidgets('Player-Meldung: nicht abspielbar, „Erneut versuchen“', (
      tester,
    ) async {
      final retries = await show(tester, 'vd: could not open codec');
      expect(find.text(l10n.videoUnavailable), findsOne);
      await tester.tap(find.text(l10n.retry));
      expect(retries, ['retry']);
    });
  });
}
