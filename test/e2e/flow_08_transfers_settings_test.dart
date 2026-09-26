import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/core/storage/app_database.dart';
import 'package:synology_explorer/features/servers/presentation/server_providers.dart';

import 'e2e_harness.dart';

const _album = 'Nordlicht – Treibholz';

/// Flow 8: Transfers (20), Offline (21), Freigabelinks (22/23),
/// Papierkorb (24), Auto-Upload (25, nur Formular), Einstellungen (26).
void main() {
  Future<E2E> login(WidgetTester tester) async {
    final app = await E2E.start(tester);
    await app.addServerAndLogin();
    return app;
  }

  Future<void> openMusic(E2E app) =>
      app.tapThen(find.text('music'), find.text('cover.jpg'));

  /// Kebab einer Zeile → Sheet 09 → [action].
  Future<void> entryAction(E2E app, String name, String action) async {
    await app.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, name),
        matching: find.byTooltip(l10n.more),
      ),
    );
    await app.tapText(action);
  }

  Finder tab(IconData icon) => find.byIcon(icon).last;

  Future<List<Transfer>> transfers(E2E app) =>
      app.db.select(app.db.transfers).get();

  testWidgets('Transfers (20): fertig, fehlgeschlagen, Wiederholen', (
    tester,
  ) async {
    final app = await login(tester);
    await openMusic(app);
    app.nas.control
      ..downloadErrors['/music/Alben/$_album/booklet.pdf'] = 407
      ..files['/music/Alben/$_album/cover.jpg'] = File(
        'test/fixtures/SYNO.FileStation.Thumb/get.jpg',
      ).readAsBytesSync();

    await entryAction(app, 'cover.jpg', l10n.actionDownload);
    await entryAction(app, 'booklet.pdf', l10n.actionDownload);
    await app.waitUntil(
      () async =>
          (await transfers(app)).length == 2 &&
          (await transfers(app)).every((t) => t.state.name != 'queued'),
    );
    // Snackbar mit Aktion verschwindet von selbst (E2E-015).
    await app.waitFor(find.byType(SnackBar), gone: true);

    await app.tap(tab(Icons.swap_vert));
    expect(app.location, '/transfers');
    await app.waitFor(find.text(l10n.transferFailed(l10n.errorPermission)));
    expect(find.text(l10n.transfersActive(1)), findsOneWidget);

    // Wiederholen, nachdem das Recht wieder da ist.
    app.nas.control.downloadErrors.clear();
    await app.tapThen(find.text(l10n.retry), find.text(l10n.transfersNone));
    expect(find.text(l10n.transfersDone(2)), findsOneWidget);

    // Fertig: Tippen öffnet die lokale Kopie im Viewer (15).
    await app.tapText(l10n.transfersDone(2));
    await app.tapThen(
      find.text('cover.jpg'),
      find.text(l10n.imageOf('1', '1')),
    );
    expect(app.location, startsWith('/view'));
    await app.backButton();
    expect(app.location, '/transfers');
    // Der fehlgeschlagene PDF-Transfer öffnet den Viewer online (PDFium).
    if (pdfiumAvailable) {
      await app.tapThen(find.text('booklet.pdf'), find.byType(BackButton));
      expect(await app.systemBack(), isTrue);
      expect(app.location, '/transfers');
    }

    await app.tapText(l10n.clearList);
    expect(find.text(l10n.transfersNoneDone), findsOneWidget);

    // Tab-Root: Zurück führt zum Dateien-Tab, der den Ordner behält
    // (E2E-059).
    expect(await app.systemBack(), isTrue);
    expect(app.location, startsWith('/files/folder'));
    await app.backButton();
    expect(app.location, '/files');
    await app.dispose();
  });

  testWidgets('Offline (21): Fake-Datei öffnen und entfernen', (tester) async {
    final app = await login(tester);
    final serverId = app.container.read(sessionProvider)!.client.profile.id!;
    final dir = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('offline'),
    ))!;
    addTearDown(() => dir.delete(recursive: true));
    final local = File('${dir.path}/README.md');
    await tester.runAsync(() async {
      await File('test/fixtures/text/README.md').copy(local.path);
      await app.db
          .into(app.db.offlineFiles)
          .insert(
            OfflineFilesCompanion.insert(
              serverId: serverId,
              remotePath: '/dokumente/Projekte/README.md',
              localPath: local.path,
              size: await local.length(),
              mtime: Value(DateTime.utc(2026, 9)),
            ),
          );
    });

    await app.tap(tab(Icons.cloud_download_outlined));
    expect(app.location, '/offline');
    await app.waitFor(find.text('README.md'));
    expect(find.text('dokumente / Projekte'), findsOneWidget);

    // Öffnen ohne Netz-Download: Text-Viewer (18) aus der lokalen Datei.
    await app.tapThen(find.text('README.md'), find.text('NAS-Setup Heim'));
    expect(app.nas.calls('SYNO.FileStation.Download', 'download'), isEmpty);
    await app.backButton();
    expect(app.location, '/offline');
    await app.tapThen(find.text('README.md'), find.text('NAS-Setup Heim'));
    expect(await app.systemBack(), isTrue);
    expect(app.location, '/offline');

    // Bearbeiten → Entfernen löscht Eintrag und Datei.
    await app.tapText(l10n.edit);
    await app.tap(find.byTooltip(l10n.offlineRemove).last);
    await app.waitFor(find.text(l10n.offlineEmpty));
    expect((await tester.runAsync(local.exists))!, isFalse);

    // Tab-Root: Zurück führt zum Dateien-Tab (E2E-059).
    expect(await app.systemBack(), isTrue);
    expect(app.location, '/files');
    await app.dispose();
  });

  testWidgets('Freigabelinks: erstellen aus Sheet 09 (22), verwalten (23)', (
    tester,
  ) async {
    final app = await login(tester);
    await openMusic(app);

    await entryAction(app, 'booklet.pdf', l10n.actionShareLink);
    expect(find.text(l10n.shareLinkTitle), findsOneWidget);
    await app.tapThen(
      find.text(l10n.shareCreate),
      find.text(l10n.shareCreated),
    );
    final create = app.nas.calls('SYNO.FileStation.Sharing', 'create').single;
    expect(create['path'], '["/music/Alben/$_album/booklet.pdf"]');
    expect(find.textContaining('/sharing/mockLink1'), findsOneWidget);
    await app.tap(find.byTooltip(l10n.close));
    expect(find.text(l10n.shareLinkTitle), findsNothing);

    // Einstellungen → Freigabelinks (23).
    await app.tap(tab(Icons.settings_outlined));
    await app.waitFor(find.text(l10n.settingsLinksActive(1)));
    await app.tapThen(
      find.byKey(const Key('settings-share-links')),
      find.text('booklet.pdf'),
    );
    expect(app.location, '/settings/shares');
    expect(find.text(l10n.shareLinksCount(1, 0)), findsOneWidget);

    // Löschen erst nach Bestätigung (E2E-035).
    await app.tapThen(
      find.byTooltip(l10n.actionDeleteShort),
      find.text(l10n.shareLinkDeleteConfirm('booklet.pdf')),
    );
    expect(app.nas.calls('SYNO.FileStation.Sharing', 'delete'), isEmpty);
    await app.tapThen(
      find.widgetWithText(FilledButton, l10n.actionDeleteShort),
      find.text(l10n.shareLinksEmpty),
    );
    expect(app.nas.calls('SYNO.FileStation.Sharing', 'delete'), hasLength(1));

    await app.backButton();
    expect(app.location, '/settings');
    await app.tap(find.byKey(const Key('settings-share-links')));
    expect(app.location, '/settings/shares');
    expect(await app.systemBack(), isTrue);
    expect(app.location, '/settings');
    // Tab-Root: Zurück führt zum Dateien-Tab (E2E-059).
    expect(await app.systemBack(), isTrue);
    expect(app.location, startsWith('/files/folder'));
    await app.backButton();
    expect(app.location, '/files');
    await app.dispose();
  });

  testWidgets('Papierkorb (24): listen, Unterordner, wiederherstellen, '
      'endgültig löschen', (tester) async {
    final app = await login(tester);
    await app.tapThen(
      find.byTooltip(l10n.trashTitle),
      find.text('Demo Sturmflut.mp3'),
    );
    expect(app.location, '/files/trash');
    // Nur `music` hat einen listbaren Papierkorb, `photo` meldet 407.
    expect(find.widgetWithText(ChoiceChip, 'music'), findsOneWidget);
    expect(find.textContaining(l10n.trashHidden('photo')), findsOneWidget);

    // Unterordner öffnen, Zurück-Geste geht eine Ebene hoch.
    await app.tapThen(find.text('Alben'), find.text('altes-cover.jpg'));
    expect(await app.systemBack(), isTrue);
    expect(app.location, '/files/trash');
    await app.waitFor(find.text('Demo Sturmflut.mp3'));

    // Wiederherstellen = Verschieben an den Ursprungsort.
    await app.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Demo Sturmflut.mp3'),
        matching: find.byTooltip(l10n.restore),
      ),
    );
    await app.waitFor(find.text(l10n.restored('music')));
    final restore = app.nas.calls('SYNO.FileStation.CopyMove', 'start').single;
    expect(restore['path'], '["/music/#recycle/Demo Sturmflut.mp3"]');
    expect(restore['dest_folder_path'], '"/music"');
    expect(restore['remove_src'], 'true');
    await app.waitFor(find.text('Demo Sturmflut.mp3'), gone: true);

    // Endgültig löschen mit roter Bestätigung.
    await app.tapThen(find.text('Alben'), find.text('altes-cover.jpg'));
    await app.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'altes-cover.jpg'),
        matching: find.byTooltip(l10n.deleteForever),
      ),
    );
    expect(find.text(l10n.deleteForeverTitle), findsOneWidget);
    await app.tapThen(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10n.deleteForever),
      ),
      find.text(l10n.trashIsEmpty),
    );
    final delete = app.nas.calls('SYNO.FileStation.Delete', 'start').single;
    expect(delete['path'], '["/music/#recycle/Alben/altes-cover.jpg"]');

    // Oben: Pfeil nach oben, dann per Zurückknopf zum Start (05).
    await app.tap(find.byIcon(Icons.arrow_upward));
    await app.waitFor(find.text('Alben'));
    await app.backButton();
    expect(app.location, '/files');
    await app.tapThen(find.byTooltip(l10n.trashTitle), find.text('Alben'));
    expect(await app.systemBack(), isTrue);
    expect(app.location, '/files');
    await app.dispose();
  });

  testWidgets('Auto-Upload (25): nur Formular ansehen, nichts speichern', (
    tester,
  ) async {
    final app = await login(tester);
    await app.tap(tab(Icons.settings_outlined));
    await app.tapThen(
      find.byKey(const Key('settings-auto-upload')),
      find.text(l10n.autoUploadHeroTitle),
    );
    expect(app.location, '/settings/autoupload');
    for (final key in [
      'auto-upload-enabled',
      'auto-upload-target',
      'auto-upload-scheme',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    expect(find.text(l10n.autoUploadTargetNone), findsOneWidget);
    final enabled = tester.widget<SwitchListTile>(
      find.byKey(const Key('auto-upload-enabled')),
    );
    expect(enabled.value, isFalse);

    // Zielordner-Picker öffnen und ohne Auswahl schließen.
    await app.tap(find.byKey(const Key('auto-upload-target')));
    await app.waitFor(find.text(l10n.autoUploadPickConfirm));
    await app.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byTooltip(l10n.close),
      ),
    );
    expect(find.text(l10n.autoUploadPickConfirm), findsNothing);
    expect(find.text(l10n.autoUploadTargetNone), findsOneWidget);

    await app.backButton();
    expect(app.location, '/settings');
    expect(find.text(l10n.settingsOff), findsOneWidget);
    await app.tap(find.byKey(const Key('settings-auto-upload')));
    expect(await app.systemBack(), isTrue);
    expect(app.location, '/settings');
    expect(find.text(l10n.settingsOff), findsOneWidget);
    // Tab-Root: Zurück führt zum Dateien-Tab (E2E-059), dort ans System.
    expect(await app.systemBack(), isTrue);
    expect(app.location, '/files');
    expect(await app.systemBack(), isFalse);
    await app.dispose();
  });

  testWidgets('Einstellungen (26): alle lokalen Daten löschen', (tester) async {
    final app = await login(tester);
    await openMusic(app);
    await entryAction(app, 'cover.jpg', l10n.actionDownload);
    await app.waitUntil(
      () async => (await transfers(app)).singleOrNull?.state.name == 'done',
    );

    // Snackbar mit Aktion verschwindet von selbst (E2E-015).
    await app.waitFor(find.byType(SnackBar), gone: true);
    await app.tap(tab(Icons.settings_outlined));
    expect(app.location, '/settings');
    await app.tap(find.byKey(const Key('settings-clear-all')));
    expect(find.text(l10n.settingsClearAllConfirm), findsOneWidget);

    // Abbrechen lässt alles stehen.
    await app.tapText(l10n.cancel);
    expect(app.location, '/settings');
    expect((await tester.runAsync(() => transfers(app)))!, hasLength(1));

    await app.tap(find.byKey(const Key('settings-clear-all')));
    await app.tapThen(
      find.byKey(const Key('clear-all-confirm')),
      find.text(l10n.settingsCleared),
    );
    expect(app.location, '/servers');
    expect((await tester.runAsync(() => transfers(app)))!, isEmpty);
    expect(
      (await tester.runAsync(() => app.db.select(app.db.offlineFiles).get()))!,
      isEmpty,
    );
    expect(app.nas.calls('SYNO.API.Auth', 'logout'), hasLength(1));
    // Server-Profil bleibt, Anmeldung ist weg.
    expect(find.text('Heim-NAS'), findsOneWidget);
    expect(app.container.read(sessionProvider), isNull);
    // 01 ist jetzt Ausgangspunkt: Zurück-Geste geht an das System.
    expect(await app.systemBack(), isFalse);
    await app.dispose();
  });
}
