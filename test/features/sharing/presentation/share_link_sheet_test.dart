import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/features/browser/presentation/entry_widgets.dart';
import 'package:nuvo_explorer/features/sharing/data/sharing_api.dart';
import 'package:nuvo_explorer/features/sharing/domain/share_link.dart';
import 'package:nuvo_explorer/features/sharing/presentation/sharing_providers.dart';

import '../../../helpers/app_harness.dart';

class FakeSharingApi implements SharingApi {
  final created = <({List<String> paths, String? password, DateTime? at})>[];

  @override
  Future<List<ShareLink>> create(
    List<String> paths, {
    String? password,
    DateTime? expiresAt,
  }) async {
    created.add((paths: paths, password: password, at: expiresAt));
    return [
      for (final p in paths)
        ShareLink(
          id: 'kQ7mX2pLv',
          url: 'https://192.168.1.2:5001/sharing/kQ7mX2pLv',
          name: p.split('/').last,
          path: p,
          isFolder: false,
          hasPassword: password != null,
          expiresAt: expiresAt,
        ),
    ];
  }

  @override
  Future<List<ShareLink>> list() async => const [];

  @override
  Future<void> delete(List<String> ids) async {}
}

void main() {
  const album = '/music/Alben/Nordlicht – Treibholz';

  testWidgets(
    '22: Ablauf (Default 7 Tage), Passwort, Kopieren erst nach Tipp',
    (tester) async {
      final api = FakeSharingApi();
      final clipboard = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') clipboard.add(call.arguments);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpApp(
        tester,
        location: folderLocation(album),
        overrides: [sharingApiProvider.overrideWithValue(api)],
      );

      await tester.tap(find.byTooltip('Mehr').at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Freigabelink erstellen'));
      await tester.pumpAndSettle();

      expect(find.text('Freigabelink'), findsOne);
      expect(find.textContaining('Läuft ab am'), findsOne);
      await tester.tap(find.text('Nie'));
      await tester.pumpAndSettle();
      expect(find.text('Kein Ablauf'), findsOne);
      await tester.tap(find.text('7 Tage'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generieren'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Link erstellen'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final call = api.created.single;
      expect(call.paths.single, '$album/02 Strandgut.flac');
      expect(call.password, hasLength(10));
      expect(call.at, DateTime(now.year, now.month, now.day + 7));

      expect(find.text('Link erstellt'), findsOne);
      // Ohne zweite Adresse, aber mit öffentlicher primärer Adresse
      // (nas.lan zählt nicht als privat): Link zeigt auf die primäre.
      expect(find.text('https://nas.lan:5001/sharing/kQ7mX2pLv'), findsOne);
      expect(find.textContaining('öffentlich erreichbare Adresse'), findsOne);
      expect(clipboard, isEmpty, reason: 'nie ohne Tipp kopieren');

      await tester.tap(find.text('Kopieren'));
      await tester.pumpAndSettle();
      expect(clipboard.single, {
        'text': 'https://nas.lan:5001/sharing/kQ7mX2pLv',
      });
      expect(find.text('Link kopiert.'), findsOne);
    },
  );
}
