import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/features/browser/domain/recycle.dart';
import 'package:nuvo_explorer/features/browser/presentation/file_actions.dart';

void main() {
  test('Ursprungspfad aus dem #recycle-Pfad', () {
    expect(
      restorePathOf('/dokumente/#recycle/Verträge/Angebot_alt.pdf'),
      '/dokumente/Verträge/Angebot_alt.pdf',
    );
    expect(
      restorePathOf('/dokumente/#recycle/Scans 2023'),
      '/dokumente/Scans 2023',
    );
    // Nur #recycle direkt unter dem Share zählt.
    expect(restorePathOf('/dokumente/a/#recycle/b.pdf'), isNull);
    expect(restorePathOf('/dokumente/#recycle'), isNull);
    expect(restorePathOf('/dokumente/Verträge/a.pdf'), isNull);
  });

  test('Papierkorb und Share eines Pfads', () {
    expect(shareOf('/music/Alben/x.flac'), '/music');
    expect(shareOf('/music'), '/music');
    expect(recycleFolder('/music/Alben'), '/music/#recycle');
  });

  test('Ziel für Verschieben/Kopieren', () {
    const sources = ['/music/Alben/A', '/music/Alben/b.flac'];
    expect(isValidDestination('/music', sources), isTrue);
    expect(isValidDestination('/photo/x', sources), isTrue);
    // Bisheriger Ordner, die Quelle selbst und Ordner darin nicht.
    expect(isValidDestination('/music/Alben', sources), isFalse);
    expect(isValidDestination('/music/Alben/A', sources), isFalse);
    expect(isValidDestination('/music/Alben/A/CD1', sources), isFalse);
    expect(isValidDestination('/music/Alben/AB', sources), isTrue);
  });
}
