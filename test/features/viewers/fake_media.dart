import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/core/network/media_proxy.dart';
import 'package:nuvo_explorer/features/browser/domain/nas_entry.dart';
import 'package:nuvo_explorer/features/viewers/data/media_repository.dart';

/// Liefert je Dateiname eine Fixture-Datei. Mit [gate] hält der Download an,
/// bis der Test ihn freigibt; vorher meldet er halben Fortschritt.
class FakeMediaRepository implements MediaRepository {
  FakeMediaRepository(this.files, {this.gate});

  final Map<String, String> files;
  final Completer<void>? gate;
  final requested = <String>[];

  @override
  Future<File> file(
    NasEntry entry, {
    ProgressCallback? onProgress,
    CancelToken? cancel,
  }) async {
    requested.add(entry.path);
    final file = File(files[entry.name] ?? (throw StateError(entry.name)));
    if (gate case final gate?) {
      final size = entry.size ?? 100;
      onProgress?.call(size ~/ 2, size);
      await gate.future;
    }
    return file;
  }

  @override
  Future<MediaProxy> stream(NasEntry entry) => throw UnimplementedError();
}

/// Wechselt zwischen Frames und echter Zeit, bis Datei-IO (außerhalb der
/// Fake-Zeit der Widget-Tests) durch ist. Mit [until] wird gewartet, bis die
/// Bedingung erfüllt ist (höchstens 10 s) – feste Runden allein reichen
/// nicht, wenn der Rechner ausgelastet ist (CI, parallele Tests).
Future<void> pumpWithIo(
  WidgetTester tester, {
  int rounds = 5,
  bool Function()? until,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  for (var i = 0; i < rounds || !(until?.call() ?? true); i++) {
    if (DateTime.now().isAfter(deadline)) break;
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
  }
  await tester.pump();
}
