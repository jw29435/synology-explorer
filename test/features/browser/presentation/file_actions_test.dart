import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/features/browser/presentation/file_actions.dart';
import 'package:synology_explorer/l10n/app_localizations.dart';

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
}
