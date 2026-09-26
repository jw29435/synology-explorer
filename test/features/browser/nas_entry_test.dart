import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/features/browser/domain/nas_entry.dart';

void main() {
  test('Typ aus Endung', () {
    expect(NasFileType.fromName('01 Ebbe.FLAC'), NasFileType.audio);
    expect(NasFileType.fromName('IMG_4821.HEIC'), NasFileType.image);
    expect(NasFileType.fromName('film.mkv'), NasFileType.video);
    expect(NasFileType.fromName('booklet.pdf'), NasFileType.pdf);
    expect(NasFileType.fromName('README.md'), NasFileType.text);
    expect(NasFileType.fromName('Brief.docx'), NasFileType.docx);
    expect(NasFileType.fromName('archiv.tar.gz'), NasFileType.other);
    expect(NasFileType.fromName('.flac'), NasFileType.other);
    expect(NasFileType.fromName('Makefile'), NasFileType.other);
  });

  test('Share mit share_right RO, ohne time/size', () {
    final e = NasEntry.fromSyno({
      'isdir': true,
      'name': 'video',
      'path': '/video',
      'additional': {
        'perm': {
          'share_right': 'RO',
          'acl': {'write': false},
        },
      },
    });
    expect(
      e,
      const NasEntry(
        path: '/video',
        name: 'video',
        isDir: true,
        type: NasFileType.folder,
        perm: NasPerm.readOnly,
      ),
    );
  });

  test('Schreibrecht: ACL entscheidet, share_right RO sperrt', () {
    NasPerm? perm(Map<String, Object?> p) => NasEntry.fromSyno({
      'isdir': true,
      'name': 'x',
      'path': '/x',
      'additional': {'perm': p},
    }).perm;
    // DSM 7.2.1: share_right RW, ACL write:false → CreateFolder/Upload 407.
    expect(
      perm({
        'share_right': 'RW',
        'acl': {'write': false, 'del': true},
      }),
      NasPerm.readOnly,
    );
    expect(
      perm({
        'share_right': 'RW',
        'acl': {'write': true},
      }),
      NasPerm.readWrite,
    );
    expect(perm({'share_right': 'RW'}), NasPerm.readWrite);
    expect(
      perm({
        'acl': {'write': true},
      }),
      NasPerm.readWrite,
    );
    expect(
      perm({
        'share_right': 'RO',
        'acl': {'write': true},
      }),
      NasPerm.readOnly,
    );
  });

  test('Datei ohne additional', () {
    final e = NasEntry.fromSyno({
      'isdir': false,
      'name': 'a.mp3',
      'path': '/music/a.mp3',
    });
    expect(e.type, NasFileType.audio);
    expect([e.size, e.mtime, e.perm], [null, null, null]);
  });
}
