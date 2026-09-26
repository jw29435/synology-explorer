import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shelf/shelf.dart' show Response;

import 'e2e_harness.dart';

const _folder = '/dokumente';

/// Dateien im Testordner und ihr Download-Inhalt (Fixture).
const _files = {
  'foto.jpg': 'SYNO.FileStation.Thumb/get.jpg',
  'booklet.pdf': 'pdf/booklet.pdf',
  'README.md': 'text/README.md',
  'Protokoll.docx': 'docx/protokoll.docx',
};

/// Flow 6: Viewer 15–19 aus dem Ordner öffnen und zurück; Download
/// verweigert → Fehlermeldung statt Endlos-Spinner, Zurück geht.
void main() {
  /// Anmelden und `/dokumente` mit je einer Datei pro Viewer öffnen.
  /// Mit [noThumbs] liefert Thumb wie DSM bei fehlender Datei 404 (HTML).
  Future<E2E> openFolder(WidgetTester tester, {bool noThumbs = false}) async {
    final app = await E2E.start(tester);
    app.serveFolder(_folder, {
      for (final name in _files.keys) name: 20000,
      'clip.mp4': 900000,
    });
    if (noThumbs) {
      final listing = app.nas.intercept!;
      app.nas.intercept = (p) => p['api'] == 'SYNO.FileStation.Thumb'
          ? Response(404, body: '<html>404</html>')
          : listing(p);
    }
    for (final MapEntry(key: name, value: fixture) in _files.entries) {
      app.nas.control.files['$_folder/$name'] = File('test/fixtures/$fixture')
          .readAsBytesSync();
    }
    await app.addServerAndLogin();
    await app.tapThen(find.text('dokumente'), find.text('foto.jpg'));
    expect(app.location, startsWith('/files/folder'));
    return app;
  }

  /// Öffnet jeden Viewer (15, 17, 18, 19) und kehrt mit [back] zurück.
  Future<void> openEachViewer(E2E app, Future<void> Function() back) async {
    for (final (name, shown) in [
      ('README.md', find.text('NAS-Setup Heim')), // 18
      ('Protokoll.docx', find.text('Protokoll der Vereinssitzung')), // 19
      ('booklet.pdf', find.byType(PdfViewer)), // 17
      ('foto.jpg', find.text('1 von 1')), // 15
    ]) {
      await app.tapThen(find.text(name), shown);
      expect(app.location, startsWith('/view'), reason: name);
      await back();
      expect(app.location, startsWith('/files/folder'), reason: name);
      expect(find.text(name), findsOneWidget);
    }
  }

  testWidgets('Viewer 15/17/18/19 öffnen, per Zurückknopf zurück', (
    tester,
  ) async {
    final app = await openFolder(tester);
    await openEachViewer(app, app.backButton);

    // Ordner → Start (05).
    await app.backButton();
    expect(app.location, '/files');
    expect(await app.systemBack(), isFalse);
    await app.dispose();
  });

  testWidgets('Viewer 15/17/18/19 öffnen, per Zurück-Geste zurück', (
    tester,
  ) async {
    final app = await openFolder(tester);
    await openEachViewer(app, () async {
      expect(await app.systemBack(), isTrue);
    });

    expect(await app.systemBack(), isTrue);
    expect(app.location, '/files');
    expect(await app.systemBack(), isFalse);
    await app.dispose();
  });

  testWidgets(
    'Video (16) öffnen und zurück',
    (tester) async {
      final app = await openFolder(tester);
      await app.tapThen(find.text('clip.mp4'), app.backButtonFinder);
      await app.backButton();
      expect(app.location, startsWith('/files/folder'));
      await app.dispose();
    },
    // media_kit braucht libmpv (FFI); `VideoPlayerScreen` erzeugt den
    // `Player` selbst, einen Override-Punkt gibt es nicht. Test-Artefakt,
    // kein App-Fehler – auf dem Gerät prüfen.
    skip: true,
  );

  testWidgets('Download verweigert: Fehlermeldung, kein Spinner, Zurück', (
    tester,
  ) async {
    // Ohne Vorschaubilder: sonst zeigt der Bild-Viewer (gewollt) das
    // Vorschaubild, wenn das Original fehlt.
    final app = await openFolder(tester, noThumbs: true);
    final errors = app.nas.control.downloadErrors;
    // 407: kein Leserecht (DSM-Code in der JSON-Antwort).
    errors['$_folder/README.md'] = 407;
    errors['$_folder/Protokoll.docx'] = 407;
    // HTTP 502 mit HTML-Seite: so meldet DSM eine fehlende Datei.
    errors['$_folder/booklet.pdf'] = 502;
    errors['$_folder/foto.jpg'] = 502;

    for (final name in ['README.md', 'Protokoll.docx']) {
      await app.tapThen(find.text(name), find.text(l10n.errorPermission));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await app.backButton();
      expect(app.location, startsWith('/files/folder'), reason: name);
    }

    await app.tapThen(find.text('booklet.pdf'), find.text(l10n.retry));
    // E2E-026: DSM meldet eine fehlende Datei mit HTTP 502 (HTML).
    expect(find.text(l10n.errorNotFound), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(await app.systemBack(), isTrue);
    expect(app.location, startsWith('/files/folder'));

    await app.tapThen(find.text('foto.jpg'), find.text(l10n.imageUnavailable));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await app.backButton();

    // 105 (keine Berechtigung) mit nicht gemerktem Passwort.
    errors['$_folder/README.md'] = 105;
    await app.tapThen(find.text('README.md'), find.byType(OutlinedButton));
    // E2E-024: Rechtefehler bleibt Rechtefehler, die Session bleibt.
    expect(find.text(l10n.errorPermission), findsOneWidget);
    await app.backButton();
    expect(app.location, startsWith('/files/folder'));

    await app.backButton();
    expect(app.location, '/files');
    await app.dispose();
  });
}
