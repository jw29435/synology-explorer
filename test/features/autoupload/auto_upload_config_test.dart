import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/features/autoupload/domain/auto_upload_config.dart';

void main() {
  final t0 = DateTime(2026, 9, 26, 17, 40);
  CameraAsset asset(String id, int seconds, {bool video = false}) =>
      CameraAsset(id, t0.add(Duration(seconds: seconds)), isVideo: video);

  test('Delta: nichts vor der Aktivierung, Verarbeitetes nicht nochmal', () {
    final cursor = UploadCursor(t0, done: {'a': t0});
    final pending = pendingAssets(
      [asset('c', 5), asset('a', 0), asset('b', 0), asset('old', -10)],
      cursor,
      includeVideos: true,
    );
    expect([for (final a in pending) a.id], ['b', 'c']);
  });

  test('Delta: Videos nur mit includeVideos, ohne Cursor alles', () {
    final all = [asset('v', 1, video: true), asset('p', 2)];
    expect(pendingAssets(all, null, includeVideos: false).single.id, 'p');
    expect(pendingAssets(all, null, includeVideos: true), hasLength(2));
  });

  test('spät sichtbare ältere Aufnahme gilt nicht als erledigt', () {
    // B (17:42) ist verarbeitet; A wurde 17:41 aufgenommen, aber erst
    // danach sichtbar (Nachtmodus, IS_PENDING).
    final now = t0.add(const Duration(minutes: 3));
    final cursor = UploadCursor(t0)
        .advance(asset('b', 120), now)
        .checkedAt(now);
    expect(cursor.windowStart, t0); // Fenster reicht bis zur Aktivierung.
    final pending = pendingAssets(
      [asset('a', 60), asset('b', 120)],
      cursor,
      includeVideos: true,
    );
    expect([for (final a in pending) a.id], ['a']);
  });

  test('Fenster: letzte Prüfung minus einen Tag; Altes wird aufgeräumt', () {
    final day2 = t0.add(const Duration(days: 2));
    var c = UploadCursor(t0)
        .advance(asset('a', 0), t0)
        .advance(asset('b', 0), day2.subtract(const Duration(hours: 1)));
    c = c.checkedAt(day2);
    expect(c.windowStart, day2.subtract(UploadCursor.lookback));
    expect(c.done.keys, {'b'}); // a vor dem Fenster verarbeitet: weg.
  });

  test('Zielordner nach Schema', () {
    const base = AutoUploadConfig(targetPath: '/photo/Handy');
    final date = DateTime(2026, 9, 3);
    expect(base.folderFor(date), '/photo/Handy/2026/09');
    expect(
      base.copyWith(scheme: FolderScheme.year).folderFor(date),
      '/photo/Handy/2026',
    );
    expect(
      base.copyWith(scheme: FolderScheme.flat).folderFor(date),
      '/photo/Handy',
    );
  });

  test('JSON hin und zurück; Standardwerte', () {
    final config = AutoUploadConfig(
      enabled: true,
      serverId: 2,
      targetPath: '/photo/Handy',
      scheme: FolderScheme.year,
      wifiOnly: false,
      includeVideos: true,
      chargingOnly: true,
      cursor: UploadCursor(t0, checked: t0, done: {'a': t0, 'b': t0}),
    );
    final back = AutoUploadConfig.decode(config.encode());
    expect(back.encode(), config.encode());
    expect(back.ready, isTrue);

    final empty = AutoUploadConfig.decode(null);
    expect((empty.enabled, empty.wifiOnly, empty.ready), (false, true, false));
  });
}
