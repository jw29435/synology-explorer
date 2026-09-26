import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/features/browser/presentation/entry_widgets.dart';
import 'package:nuvo_explorer/features/browser/presentation/file_actions.dart';
import 'package:nuvo_explorer/l10n/app_localizations.dart';

import '../../../helpers/app_harness.dart';

void main() {
  testWidgets('Fortschrittsdialog: Zurück bricht den Task nicht ab (E2E-030)', (
    tester,
  ) async {
    final task = StreamController<double?>();
    bool? done;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                done = await runWithProgress(context, 'Löschen', task.stream),
            child: const Text('los'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('los'));
    await tester.pump();
    expect(find.byType(AlertDialog), findsOne);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(AlertDialog), findsOne);
    expect(task.hasListener, isTrue, reason: 'Task läuft weiter');

    await task.close();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(done, isTrue);
  });

  testWidgets('Ordner-Picker: Zurück-Geste geht eine Ebene hoch (E2E-018)', (
    tester,
  ) async {
    const album = '/music/Alben/Nordlicht – Treibholz';
    await pumpApp(tester, location: folderLocation(album));
    await tester.tap(find.byTooltip('Mehr').at(2));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Verschieben nach …'));
    await tester.tap(find.text('Verschieben nach …'));
    await tester.pumpAndSettle();
    Finder inSheet(String text) => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text(text),
    );
    await tester.tap(inSheet('Bonus'));
    await tester.pumpAndSettle();
    expect(inSheet('${album.substring(1)}/Bonus'), findsOne);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(inSheet(album.substring(1)), findsOne, reason: 'eine Ebene hoch');

    // Bis zur Liste der Shares, dann schließt Zurück den Picker.
    for (var i = 0; i < 3; i++) {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
    expect(inSheet('Freigegebene Ordner'), findsOne);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });
}
