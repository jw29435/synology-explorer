import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/features/browser/domain/nas_entry.dart';

/// Parser gegen anonymisierte echte Antworten von DSM 7.2.1 (Spike, docs/SPIKE.md).
void main() {
  Map<String, dynamic> fixture(String path) =>
      jsonDecode(File('test/fixtures/dsm-7.2.1/$path').readAsStringSync())
          as Map<String, dynamic>;

  List<NasEntry> entries(String path, String key) => [
    for (final e in fixture(path)['data'][key] as List)
      NasEntry.fromSyno(e as Map<String, dynamic>),
  ];

  test('API.Info meldet die Versionen, die der Client nutzt', () {
    final data = fixture('SYNO.API.Info/query.json')['data'];
    expect(data['SYNO.API.Auth']['maxVersion'], 7);
    expect(data['SYNO.FileStation.List']['maxVersion'], 2);
    expect(data['SYNO.FileStation.Download']['maxVersion'], 2);
    expect(data['SYNO.FileStation.Thumb']['maxVersion'], 3);
  });

  test('list_share', () {
    final share = entries('SYNO.FileStation.List/list_share.json', 'shares');
    expect(
      share.single,
      const NasEntry(
        path: '/music',
        name: 'music',
        isDir: true,
        type: NasFileType.folder,
        // share_right RW, aber ACL write:false – Schreiben scheitert mit 407.
        perm: NasPerm.readOnly,
        owner: 'admin',
        group: 'administrators',
        posix: 555,
      ),
    );
  });

  test('list', () {
    final files = entries('SYNO.FileStation.List/list.json', 'files');
    expect(files, hasLength(4));
    expect(files.map((e) => e.type), everyElement(NasFileType.audio));
    expect(files.first.size, 15029063);
    expect(files.first.mtime, DateTime.utc(2022, 3, 5, 17, 46, 53));
  });

  test('getinfo: Datei und Ordner', () {
    final [file, dir] = entries('SYNO.FileStation.List/getinfo.json', 'files');
    expect(file.isDir, isFalse);
    expect(dir.isDir, isTrue);
    expect(dir.size, isNull);
  });
}
