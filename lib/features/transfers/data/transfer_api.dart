import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/syno_api_client.dart';
import '../../../core/network/syno_exception.dart';
import '../../browser/domain/nas_entry.dart';

/// `SYNO.FileStation.Download` und `Upload` für die Transfer-Queue.
class TransferApi {
  TransferApi(this._client);

  final SynoApiClient _client;

  /// Lädt [remotePath] nach [file]; mit [offset] per HTTP-Range fortgesetzt.
  Future<int?> download(
    String remotePath,
    File file, {
    int offset = 0,
    CancelToken? cancelToken,
    void Function(int done, int? total)? onProgress,
  }) => _client.download(
    'SYNO.FileStation.Download',
    'download',
    {'path': remotePath, 'mode': 'download'},
    file,
    offset: offset,
    cancelToken: cancelToken,
    onProgress: onProgress,
  );

  /// Lädt [file] als [name] nach [folder] hoch (legt fehlende Ordner an).
  /// Ohne [overwrite] wird bei vorhandenem Namen „ (1)“ usw. angehängt.
  /// Liefert den tatsächlich verwendeten Namen.
  Future<String> upload(
    File file,
    String folder,
    String name, {
    required bool overwrite,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onProgress,
  }) async {
    final target = overwrite ? name : await _reserveFreeName(folder, name);
    try {
      await _client.upload(
        'SYNO.FileStation.Upload',
        'upload',
        {
          'path': folder,
          'create_parents': true,
          // `overwrite=false` hieße bei DSM „still überspringen“; ohne den
          // Parameter meldet DSM einen Namenskonflikt als Fehler.
          if (overwrite) 'overwrite': true,
        },
        file,
        target,
        cancelToken: cancelToken,
        onProgress: onProgress,
      );
    } finally {
      _reserved.remove('$folder/$target');
    }
    return target;
  }

  /// Namen, die laufende Uploads gewählt, aber noch nicht angelegt haben.
  final _reserved = <String>{};

  /// Wie [freeName], überspringt aber reservierte Namen und reserviert den
  /// gewählten – zwei parallele Uploads gleichen Namens bekommen so
  /// verschiedene Namen. Prüfen und Reservieren passieren ohne `await`
  /// dazwischen, also atomar.
  Future<String> _reserveFreeName(String folder, String name) async {
    final free = await _freeNames(folder, name);
    final chosen = free.firstWhere(
      (c) => !_reserved.contains('$folder/$c'),
      orElse: () => throw const SynoAlreadyExists(414),
    );
    _reserved.add('$folder/$chosen');
    return chosen;
  }

  /// Änderungszeit von [path] auf dem NAS (`null`, wenn unbekannt).
  Future<DateTime?> mtime(String path) async {
    final data = await _client.request('SYNO.FileStation.List', 'getinfo', {
      'path': jsonEncode([path]),
      'additional': jsonEncode(['time']),
    }) as Map;
    final file = (data['files'] as List).first as Map<String, dynamic>;
    return file['code'] == null ? NasEntry.fromSyno(file).mtime : null;
  }

  /// Erster Name aus „a.jpg“, „a (1).jpg“ … „a (9).jpg“, den es in [folder]
  /// noch nicht gibt – ein `getinfo` für alle (fehlend = Code 408).
  Future<String> freeName(String folder, String name) async =>
      (await _freeNames(folder, name)).firstOrNull ??
      (throw const SynoAlreadyExists(414));

  Future<List<String>> _freeNames(String folder, String name) async {
    final candidates = [
      name,
      for (var i = 1; i < 10; i++) numberedName(name, i),
    ];
    final data = await _client.request('SYNO.FileStation.List', 'getinfo', {
      'path': jsonEncode([for (final c in candidates) '$folder/$c']),
    }) as Map;
    return [
      for (final (i, file) in (data['files'] as List).indexed)
        if ((file as Map)['code'] == 408) candidates[i],
    ];
  }
}

/// „a.jpg“ → „a (2).jpg“, „Makefile“ → „Makefile (2)“.
String numberedName(String name, int n) {
  final dot = name.lastIndexOf('.');
  return dot < 1
      ? '$name ($n)'
      : '${name.substring(0, dot)} ($n)${name.substring(dot)}';
}
