import 'dart:io';

import 'package:archive/archive.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/features/viewers/docx/docx_parser.dart';

DocxDocument fixture(String name) =>
    parseDocx(File('test/fixtures/docx/$name').readAsBytesSync());

List<DocxParagraph> paragraphs(DocxDocument d) =>
    d.blocks.whereType<DocxParagraph>().toList();

void main() {
  test('Brief: Absätze, Umbrüche, Fett/Kursiv/Unterstrichen', () {
    final doc = fixture('brief.docx');
    final ps = paragraphs(doc);
    expect(ps.first.text, 'Johann Wiebe\nMusterweg 1\n12345 Musterstadt');
    // Leere Absätze entfallen, gelöschter Text (Änderungsverfolgung) auch.
    expect(ps.map((p) => p.text), [
      'Johann Wiebe\nMusterweg 1\n12345 Musterstadt',
      'Musterstadt, 26. September 2026',
      'Kündigung des Vertrags Nr. 4711',
      'Sehr geehrte Damen und Herren,',
      'hiermit kündige ich den Vertrag fristgerecht zum 31. Dezember 2026.',
      'Bitte bestätigen Sie mir den Eingang schriftlich.',
      'Mit freundlichen Grüßen',
      'Johann Wiebe',
    ]);
    expect(ps[2].runs.single.bold, isTrue);
    final body = ps[4].runs;
    expect(
      [for (final r in body) (r.text, r.bold, r.italic, r.underline)],
      [
        ('hiermit kündige ich den Vertrag ', false, false, false),
        ('fristgerecht', false, true, false),
        (' zum ', false, false, false),
        ('31. Dezember 2026', false, false, true),
        ('.', false, false, false),
      ],
    );
    expect(ps.every((p) => p.heading == null && p.list == null), isTrue);
  });

  test('Protokoll: Überschriften, Listen, Tabelle', () {
    final doc = fixture('protokoll.docx');
    final ps = paragraphs(doc);
    // Lokalisierte Stil-IDs („berschrift1“) über den Stilnamen erkannt.
    expect(ps[0].heading, 0);
    expect(ps[2].text, '1. Begrüßung');
    expect(ps[2].heading, 1);
    expect(ps.firstWhere((p) => p.text == 'Offene Punkte').heading, 2);

    final numbered = ps.where((p) => p.list?.ordered ?? false).toList();
    expect(numbered.map((p) => p.list!.number), [1, 2, 3]);
    expect(numbered.first.runs[1].bold, isTrue);
    expect(numbered.last.runs[1].italic, isTrue);

    // Aufzählung über den Absatzstil und direkt, mit Unterebene.
    final bullets = [
      for (final p in ps)
        if (p.list case final l? when !l.ordered) (p.text, l.level),
    ];
    expect(bullets, [('Getränke', 0), ('Wasser', 1), ('Musik', 0)]);

    final table = doc.blocks.whereType<DocxTable>().single;
    expect(
      [
        for (final row in table.rows) [for (final c in row) c.single.text],
      ],
      [
        ['Aufgabe', 'Wer', 'Bis'],
        ['Halle reservieren', 'M. Berg', '31.10.'],
        ['Backup einrichten', 'J. W.', '15.10.'],
      ],
    );
    expect(table.rows.first.first.single.runs.single.bold, isTrue);
  });

  test('Dokument mit Bild: Bild aus word/media an der richtigen Stelle', () {
    final doc = fixture('bild.docx');
    expect(doc.blocks.map((b) => b.runtimeType), [
      DocxParagraph,
      DocxParagraph,
      DocxImage,
      DocxParagraph,
    ]);
    final image = doc.blocks[2] as DocxImage;
    expect(image.bytes.sublist(1, 4), 'PNG'.codeUnits);
  });

  test('kein Word-Dokument', () {
    expect(() => parseDocx([1, 2, 3]), throwsA(anything));
    expect(
      () => parseDocx(
        File('test/fixtures/SYNO.FileStation.Thumb/get.jpg').readAsBytesSync(),
      ),
      throwsA(anything),
    );
  });

  test('outlineLvl 9 ist Textkörper, 0–8 sind Überschriften', () {
    const w =
        'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"';
    String style(String id, int level) =>
        '<w:style w:type="paragraph" w:styleId="$id"><w:name w:val="$id"/>'
        '<w:pPr><w:outlineLvl w:val="$level"/></w:pPr></w:style>';
    String p(String id, String text) =>
        '<w:p><w:pPr><w:pStyle w:val="$id"/></w:pPr><w:r><w:t>$text</w:t></w:r></w:p>';
    final archive = Archive()
      ..add(
        ArchiveFile.string(
          'word/document.xml',
          '<w:document $w><w:body>${p('Eigen', 'Kapitel')}${p('Text', 'Absatz')}</w:body></w:document>',
        ),
      )
      ..add(
        ArchiveFile.string(
          'word/styles.xml',
          '<w:styles $w>${style('Eigen', 2)}${style('Text', 9)}</w:styles>',
        ),
      );
    final doc = parseDocx(ZipEncoder().encode(archive));
    expect(paragraphs(doc).map((p) => (p.text, p.heading)), [
      ('Kapitel', 3),
      ('Absatz', null),
    ]);
  });

  test(
    'Größengrenzen: zu großes XML → FormatException, Bilder nach Budget',
    () {
      final bytes = File('test/fixtures/docx/protokoll.docx').readAsBytesSync();
      expect(
        () => parseDocx(bytes, maxPartBytes: 1000),
        throwsA(isA<FormatException>()),
      );
      final image = File('test/fixtures/docx/bild.docx').readAsBytesSync();
      expect(
        parseDocx(image, maxImageBytes: 10).blocks.whereType<DocxImage>(),
        isEmpty,
      );
    },
  );
}
