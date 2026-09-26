import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/core/storage/app_database.dart';

import '../../../helpers/app_harness.dart';

void main() {
  testWidgets('21: gruppiert nach Ordner, Exportieren über Share-Sheet', (
    tester,
  ) async {
    final shares = <MethodCall>[];
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      shares.add(call);
      return 'dev.fluttercommunity.plus/share/unavailable';
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final (container: _, :db) = await pumpApp(tester, location: '/offline');
    await tester.runAsync(
      () => db.batch(
        (b) => b.insertAll(db.offlineFiles, [
          for (final name in ['01 Ebbe.flac', '02 Strandgut.flac', '03 x.flac'])
            OfflineFilesCompanion.insert(
              serverId: 1,
              remotePath: '/music/Alben/N/$name',
              localPath: '/tmp/offline/1/music/Alben/N/$name',
              size: 1024,
            ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('music / Alben / N'), findsOne);
    expect(find.text('01 Ebbe.flac'), findsOne);
    expect(find.text('03 x.flac'), findsNothing);
    await tester.tap(find.text('+ 1 weitere'));
    await tester.pumpAndSettle();
    expect(find.text('03 x.flac'), findsOne);

    await tester.tap(find.byTooltip('Exportieren').first);
    await tester.pumpAndSettle();
    expect(shares, hasLength(1));
    expect(
      shares.single.arguments.toString(),
      contains('/tmp/offline/1/music/Alben/N/01 Ebbe.flac'),
    );
  });
}
