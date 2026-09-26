import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/features/autoupload/data/auto_upload_repository.dart';
import 'package:synology_explorer/features/autoupload/data/auto_uploader.dart';
import 'package:synology_explorer/features/autoupload/domain/auto_upload_config.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/settings_fakes.dart';

void main() {
  testWidgets('Screen 25: Einschalten fragt Ziel und Fotozugriff ab', (
    tester,
  ) async {
    final scheduler = FakeScheduler();
    final camera = FakeAccessCameraRoll();
    final app = await pumpApp(
      tester,
      location: '/settings/autoupload',
      overrides: settingsOverrides(scheduler: scheduler, camera: camera),
    );
    expect(find.text('Nicht gewählt'), findsOne);
    final run = tester.widget<FilledButton>(
      find.byKey(const Key('auto-upload-run')),
    );
    expect(run.onPressed, isNull);

    await tester.tap(find.byKey(const Key('auto-upload-enabled')));
    await tester.pumpAndSettle();

    // Share ohne Schreibrecht: verständlich abgelehnt.
    await tester.tap(find.text('video'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Keine Schreibrechte'), findsOne);
    final confirm = find.widgetWithText(FilledButton, 'Hier sichern');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byTooltip('Zurück'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('photo'));
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    final config = await tester.runAsync(
      () => AutoUploadRepository(app.db).read(),
    );
    expect(config!.ready, isTrue);
    expect(config.targetPath, '/photo');
    expect(config.cursor, isNotNull);
    expect(camera.requests, 1);
    expect(scheduler.applied.last.ready, isTrue);
    expect(find.text('photo'), findsOne);
    expect(find.textContaining('ab jetzt gesichert'), findsOne);
  });

  testWidgets(
    'abgelehnter Fotozugriff: bleibt aus, Hinweis mit Einstellungen',
    (tester) async {
      final camera = FakeAccessCameraRoll()..grant = false;
      final app = await pumpApp(
        tester,
        location: '/settings/autoupload',
        overrides: settingsOverrides(camera: camera),
      );
      await tester.runAsync(
        () =>
            AutoUploadRepository(app.db)
                .update((c) => c.copyWith(serverId: 1, targetPath: '/photo')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('auto-upload-enabled')));
      await tester.pumpAndSettle();
      expect(find.text('Einstellungen öffnen'), findsOne);
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      final config = await tester.runAsync(
        () => AutoUploadRepository(app.db).read(),
      );
      expect(config!.enabled, isFalse);
    },
  );

  testWidgets('Status zeigt letzten Lauf, Wartendes und Summe', (tester) async {
    final app = await pumpApp(
      tester,
      location: '/settings/autoupload',
      overrides: settingsOverrides(),
    );
    // Einzeln schreiben: Zwischen den Schritten laufen die Stream-Abfragen
    // der Oberfläche (drift sperrt sonst gegen die Fake-Zeit).
    final repo = AutoUploadRepository(app.db);
    Future<void> step(Future<void> Function() write) async {
      await tester.runAsync(write);
      await tester.pumpAndSettle();
    }

    await step(
      () => repo.update(
        (_) => const AutoUploadConfig(
          enabled: true,
          serverId: 1,
          targetPath: '/photo/Handy',
        ),
      ),
    );
    late int id;
    await step(() async => id = await repo.log(files: 12));
    await step(() => repo.finish(id, bytes: 3 << 20));
    await step(() => repo.log(waiting: 1, note: AutoUploadNote.noWifi));
    expect(find.textContaining('12 Dateien · 0 Fehler'), findsOne);
    expect(find.text('1 Datei wartet auf WLAN'), findsOne);
    expect(
      find.textContaining('Gesamt gesichert: 12 Dateien · 3 MB'),
      findsOne,
    );
    final run = tester.widget<FilledButton>(
      find.byKey(const Key('auto-upload-run')),
    );
    expect(run.onPressed, isNotNull);

    tester.view.physicalSize = const Size(1170, 3600);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Protokoll'));
    await tester.pumpAndSettle();
    expect(find.textContaining('12 Dateien · 0 Fehler · 3 MB'), findsOne);
  });
}
