import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/features/autoupload/domain/auto_upload_config.dart';

void main() {
  final t0 = DateTime(2026, 9, 26, 17, 40);
  CameraAsset asset(String id, int seconds, {bool video = false}) =>
      CameraAsset(id, t0.add(Duration(seconds: seconds)), isVideo: video);

  test('Delta: nur Neues nach dem Cursor, gleiche Sekunde über IDs', () {
    final cursor = UploadCursor(t0, {'a'});
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

  test('Cursor rückt vor und merkt IDs derselben Sekunde', () {
    var c = UploadCursor(t0, const {});
    c = c.advance(asset('a', 0)).advance(asset('b', 0));
    expect(c.ids, {'a', 'b'});
    c = c.advance(asset('c', 3));
    expect(c.created, t0.add(const Duration(seconds: 3)));
    expect(c.ids, {'c'});
    // Ältere Aufnahme ändert nichts.
    expect(c.advance(asset('x', -1)), same(c));
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
      cursor: UploadCursor(t0, {'a', 'b'}),
    );
    final back = AutoUploadConfig.decode(config.encode());
    expect(back.encode(), config.encode());
    expect(back.ready, isTrue);

    final empty = AutoUploadConfig.decode(null);
    expect((empty.enabled, empty.wifiOnly, empty.ready), (false, true, false));
  });
}
