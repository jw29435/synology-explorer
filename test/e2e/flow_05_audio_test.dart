import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/features/audio/domain/playback_queue.dart';
import 'package:nuvo_explorer/features/audio/presentation/playback_providers.dart';

import 'e2e_harness.dart';

/// Flow 5: Ordner abspielen → Mini-Player → Now Playing (12) → Queue (13) →
/// Shuffle/Repeat → zurück bis 05, der Player läuft weiter.
void main() {
  const folder = '/files/folder?path=%2Fmusic';
  final miniPlayer = find.byKey(const Key('mini-player'));
  AudioState player(E2E app) => app.container.read(audioControllerProvider);

  testWidgets('Ordner abspielen, Player und Queue, zurück ohne Stopp', (
    tester,
  ) async {
    final app = await E2E.start(tester);
    await app.addServerAndLogin();
    await app.tapText('music');
    await app.waitFor(find.byKey(const Key('play-folder')));
    expect(miniPlayer, findsNothing);

    await app.tap(find.byKey(const Key('play-folder')));
    expect(app.audio.calls, ['playFolder /music - false']);
    await app.waitFor(miniPlayer);
    // Laufender Titel (Fake: „02 Strandgut“) ist in der Liste markiert.
    expect(find.textContaining(l10n.nowPlayingRow), findsOneWidget);

    // Mini-Player → Now Playing (12).
    await app.tap(miniPlayer);
    expect(app.location, '/player');
    expect(find.textContaining(l10n.trackOf(2, 4)), findsOneWidget);

    // Shuffle an, Repeat zweimal weiter (aus → Titel → Ordner).
    await app.tap(find.byTooltip(l10n.shuffleOff));
    await app.tap(find.byTooltip(l10n.repeatOff));
    expect(player(app).repeat, QueueRepeat.one);
    await app.tap(find.byTooltip(l10n.repeatOne));
    expect(player(app).shuffle, isTrue);
    expect(player(app).repeat, QueueRepeat.all);
    expect(find.byTooltip(l10n.shuffleOn), findsOneWidget);
    expect(find.byTooltip(l10n.repeatAll), findsOneWidget);

    // Queue (13) zeigt den Stand.
    await app.tap(find.byTooltip(l10n.queueTitle));
    expect(app.location, '/player/queue');
    expect(find.byKey(const Key('queue-current')), findsOneWidget);
    expect(
      find.text('${l10n.shuffleSummary} · ${l10n.repeatSummaryAll}'),
      findsOneWidget,
    );

    // Zurück per Knopf: 13 → 12 → Ordner, Wiedergabe läuft weiter.
    await app.backButton();
    expect(app.location, '/player');
    await app.backButton();
    expect(app.location, folder);
    expect(miniPlayer, findsOneWidget);
    await app.backButton();
    expect(app.location, '/files');
    expect(miniPlayer, findsOneWidget);

    // Dasselbe per Zurück-Geste.
    await app.tap(miniPlayer);
    await app.tap(find.byTooltip(l10n.queueTitle));
    expect(app.location, '/player/queue');
    expect(await app.systemBack(), isTrue);
    expect(app.location, '/player');
    expect(await app.systemBack(), isTrue);
    expect(app.location, '/files');
    expect(miniPlayer, findsOneWidget);
    expect(await app.systemBack(), isFalse);

    expect(player(app).playing, isTrue);
    expect(player(app).active, isTrue);
    expect(app.audio.calls, ['playFolder /music - false']);
    await app.dispose();
  });
}
