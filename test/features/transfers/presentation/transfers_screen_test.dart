import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/core/storage/app_database.dart';
import 'package:synology_explorer/features/transfers/domain/transfer.dart';

import '../../../helpers/app_harness.dart';

void main() {
  TransfersCompanion row(
    String path,
    TransferState state, {
    TransferKind kind = TransferKind.download,
    int done = 0,
    int? total = 1000,
    String? error,
  }) => TransfersCompanion.insert(
    serverId: 1,
    kind: kind,
    remotePath: path,
    localPath: '/tmp/x$path',
    state: state,
    bytesDone: Value(done),
    bytesTotal: Value(total),
    error: Value(error),
    createdAt: DateTime(2026, 9, 26),
  );

  testWidgets('20: Tabs Aktiv/Fertig, Wiederholen, Alle pausieren', (
    tester,
  ) async {
    final (container: _, :db) = await pumpApp(tester, location: '/transfers');
    await tester.runAsync(
      () => db.batch(
        (b) => b.insertAll(db.transfers, [
          row('/music/a.flac', TransferState.running, done: 690),
          row(
            '/photo/Handy/IMG_4830.HEIC',
            TransferState.queued,
            kind: TransferKind.upload,
          ),
          row(
            '/video/Drohne.mp4',
            TransferState.failed,
            done: 310,
            error: 'SynoNetworkError',
          ),
          row('/music/b.flac', TransferState.done, done: 1000),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aktiv (3)'), findsOne);
    expect(find.text('Fertig (1)'), findsOne);
    expect(find.text('a.flac'), findsOne);
    expect(find.text('IMG_4830.HEIC'), findsOne);
    expect(find.textContaining('Upload → photo/Handy'), findsOne);
    expect(find.textContaining('Fehlgeschlagen: '), findsOne);
    expect(find.text('wird fortgesetzt (Range)'), findsOne);
    expect(find.textContaining('69 %'), findsOne);
    expect(find.text('b.flac'), findsNothing);

    Future<List<TransferState>> states() async => [
      for (final t in (await tester.runAsync(
        () => db.select(db.transfers).get(),
      ))!)
        t.state,
    ];

    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();
    expect((await states())[2], TransferState.queued);

    await tester.tap(find.text('Alle pausieren'));
    await tester.pumpAndSettle();
    expect(await states(), [
      TransferState.paused,
      TransferState.paused,
      TransferState.paused,
      TransferState.done,
    ]);

    await tester.tap(find.text('Fertig (1)'));
    await tester.pumpAndSettle();
    expect(find.text('b.flac'), findsOne);
    expect(find.text('a.flac'), findsNothing);
    await tester.tap(find.text('Liste leeren'));
    await tester.pumpAndSettle();
    expect(find.text('Fertig (0)'), findsOne);
  });
}
