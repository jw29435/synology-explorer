import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/app/theme.dart';
import 'package:synology_explorer/features/settings/data/settings_repository.dart';
import 'package:synology_explorer/features/transfers/presentation/transfer_providers.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/settings_fakes.dart';

void main() {
  tearDown(() => AppColors.neutrals = Neutrals.dark);

  /// Ganzer Screen ohne Scrollen (die Liste ist länger als ein Handy).
  Future<void> tall(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 3600);
    await tester.pumpAndSettle();
  }

  testWidgets('Screen 26: Abschnitte, Version, Werte', (tester) async {
    await pumpApp(
      tester,
      location: '/settings',
      overrides: settingsOverrides(),
    );
    for (final label in ['VERBINDUNG', 'MEDIEN & SPEICHER', 'APP']) {
      expect(find.text(label), findsOne);
    }
    expect(find.text('Server verwalten'), findsOne);
    expect(find.text('0 aktiv'), findsOne);
    expect(find.text('Aus'), findsOne); // Auto-Upload
    expect(find.text('v1.0.0 (42)'), findsOne);
    await tester.scrollUntilVisible(
      find.text('Alle lokalen Daten löschen'),
      100,
    );
    expect(find.text('Cache, Offline, Tokens'), findsOne);
  });

  testWidgets('Design „Hell“ landet in drift und schaltet die Farben um', (
    tester,
  ) async {
    final app = await pumpApp(
      tester,
      location: '/settings',
      overrides: settingsOverrides(),
    );
    await tester.tap(find.byKey(const Key('theme-light')));
    await tester.pumpAndSettle();
    expect(
      await tester.runAsync(
        () => SettingsRepository(app.db).read(SettingsRepository.themeMode),
      ),
      'light',
    );
    expect(AppColors.neutrals, same(Neutrals.light));
    // Route bleibt trotz Neuaufbau erhalten.
    expect(find.text('Server verwalten'), findsOne);
  });

  testWidgets('Designwechsel (auch vom System) verliert keinen App-State', (
    tester,
  ) async {
    final app = await pumpApp(
      tester,
      location: '/settings',
      overrides: settingsOverrides(),
    );
    final context = tester.element(find.text('Server verwalten'));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('bleibt')));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () =>
          SettingsRepository(app.db)
              .write(SettingsRepository.themeMode, 'light'),
    );
    await tester.pumpAndSettle();
    expect(AppColors.neutrals, same(Neutrals.light));
    expect(find.text('bleibt'), findsOne);
    // Widgets, die AppColors direkt lesen, sind neu gebaut.
    final label = tester.widget<Text>(find.text('VERBINDUNG'));
    expect(label.style?.color, Neutrals.light.textSecondary);
  });

  testWidgets('Sprache Englisch übersetzt die App sofort', (tester) async {
    await pumpApp(
      tester,
      location: '/settings',
      overrides: settingsOverrides(),
    );
    await tall(tester);
    expect(find.text('Deutsch (System)'), findsOne);
    await tester.tap(find.byKey(const Key('settings-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Manage servers'), findsOne);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('360 dp: Cache-Wert wird nicht gekürzt (E2E-065)', (
    tester,
  ) async {
    await pumpApp(
      tester,
      location: '/settings',
      overrides: [
        ...settingsOverrides(),
        storageUsageProvider.overrideWith(
          (ref) async => (offline: 0, cache: 364032),
        ),
      ],
    );
    tester.view.physicalSize = const Size(1080, 3600);
    await tester.pumpAndSettle();
    final value = find.text('500 MB · 355,5 KB belegt');
    expect(value, findsOne);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: value, matching: find.byType(RichText)),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
  });

  testWidgets('Cache-Limit: Slider speichert den Wert', (tester) async {
    final app = await pumpApp(
      tester,
      location: '/settings',
      overrides: settingsOverrides(),
    );
    expect(find.textContaining('500 MB · '), findsOne);
    await tester.tap(find.byKey(const Key('settings-cache')));
    await tester.pumpAndSettle();
    // Ganz nach rechts: 5 GB.
    final slider = find.byKey(const Key('cache-slider'));
    await tester.drag(slider, const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(
      await tester.runAsync(
        () => SettingsRepository(app.db).read(SettingsRepository.cacheLimitMb),
      ),
      '5120',
    );
    expect(find.textContaining('5 GB · '), findsWidgets);
  });

  testWidgets('„Alle lokalen Daten löschen“ fragt nach', (tester) async {
    await pumpApp(
      tester,
      location: '/settings',
      overrides: settingsOverrides(),
    );
    await tall(tester);
    await tester.tap(find.byKey(const Key('settings-clear-all')));
    await tester.pumpAndSettle();
    expect(find.text('Alle lokalen Daten löschen?'), findsOne);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(find.text('Alle lokalen Daten löschen?'), findsNothing);
  });

  testWidgets('Auto-Upload-Zeile öffnet Screen 25', (tester) async {
    final app = await pumpApp(
      tester,
      location: '/settings',
      overrides: settingsOverrides(),
    );
    await tester.tap(find.byKey(const Key('settings-auto-upload')));
    await tester.pumpAndSettle();
    expect(
      routerOf(app.container).state.matchedLocation,
      '/settings/autoupload',
    );
    expect(find.text('Fotos & Videos sichern'), findsOne);
  });
}
