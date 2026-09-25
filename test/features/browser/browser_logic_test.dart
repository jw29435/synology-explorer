import 'package:drift/native.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:synology_explorer/core/storage/app_database.dart';
import 'package:synology_explorer/core/utils/format.dart';
import 'package:synology_explorer/features/browser/data/local_library_repository.dart';
import 'package:synology_explorer/features/browser/domain/nas_entry.dart';
import 'package:synology_explorer/features/browser/presentation/browser_providers.dart';
import 'package:synology_explorer/features/browser/presentation/entry_sheets.dart';
import 'package:synology_explorer/features/browser/presentation/search_screen.dart';
import 'package:synology_explorer/l10n/app_localizations_de.dart';

void main() {
  test('Zuletzt geöffnet: neueste zuerst, höchstens 50', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = LocalLibraryRepository(db);
    for (var i = 0; i < 55; i++) {
      await repo.addRecent(1, '/music/$i.mp3');
    }
    await repo.addRecent(1, '/music/3.mp3');
    await repo.addRecent(2, '/anderer/server.mp3');

    final recent = await repo.recent(1).first;
    expect(recent, hasLength(LocalLibraryRepository.maxRecent));
    expect(recent.first.entry.name, '3.mp3', reason: 'erneut geöffnet');
    expect(recent.first.entry.type, NasFileType.audio);
    expect(recent.map((r) => r.entry.name), isNot(contains('0.mp3')));
    expect(await repo.recent(2).first, hasLength(1));
  });

  test('Favoriten setzen und entfernen', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = LocalLibraryRepository(db);
    const folder = NasEntry(
      path: '/photo/Urlaub 2026',
      name: 'Urlaub 2026',
      isDir: true,
      type: NasFileType.folder,
    );
    await repo.setFavorite(1, folder, true);
    await repo.setFavorite(1, folder, true);
    expect(await repo.favorites(1).first, [folder]);
    expect(await repo.isFavorite(1, folder.path).first, isTrue);
    await repo.setFavorite(1, folder, false);
    expect(await repo.favorites(1).first, isEmpty);
  });

  test('Formatierung', () async {
    await initializeDateFormatting('de');
    final l10n = AppLocalizationsDe();
    expect(formatSize(29779968, 'de'), '28,4 MB');
    expect(formatSize(512, 'de'), '512 B');
    expect(formatSize(225280, 'en'), '220 KB');
    expect(formatDate(DateTime(2026, 5, 12), l10n), '12.05.2026');
    final now = DateTime(2026, 9, 26, 18);
    expect(
      formatRelative(DateTime(2026, 9, 26, 17, 12), l10n, now: now),
      'heute 17:12',
    );
    expect(formatRelative(DateTime(2026, 9, 25, 9), l10n, now: now), 'gestern');
    expect(formatRelative(DateTime(2026, 1, 2), l10n, now: now), '02.01.2026');
    expect(posixString(775), 'rwxrwxr-x');
    expect(posixString(555), 'r-xr-xr-x');
    expect(posixString(0), '---------');
  });

  test('Treffer-Hervorhebung', () {
    String marked(List<TextSpan> spans) =>
        [for (final s in spans) s.style == null ? s.text : '[${s.text}]']
            .join();
    expect(
      marked(highlight('03 Nebelbank.flac', 'nebel')),
      '03 [Nebel]bank.flac',
    );
    expect(marked(highlight('Nebel im Nebel', 'NEBEL')), '[Nebel] im [Nebel]');
    expect(
      marked(highlight('a*b', '*')),
      'a*b',
      reason: 'Glob: keine Markierung',
    );
  });

  test('Backoff: 500 ms, ×1,5, höchstens 3 s', () {
    expect(Backoff.min, const Duration(milliseconds: 500));
    expect(Backoff.max, const Duration(seconds: 3));
  });
}
