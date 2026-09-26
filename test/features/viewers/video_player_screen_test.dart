import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:synology_explorer/app/theme.dart';
import 'package:synology_explorer/features/viewers/presentation/video_player_screen.dart';
import 'package:synology_explorer/l10n/app_localizations.dart';

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

void main() {
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
