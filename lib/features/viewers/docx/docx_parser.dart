import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Lesemodus-Modell eines DOCX: bewusst nur Absätze, Überschriften, Listen,
/// Fett/Kursiv/Unterstrichen, einfache Tabellen und Bilder (CONCEPT.md
/// Abschnitt 6). Kein HTML-Zwischenschritt.
class DocxDocument {
  const DocxDocument(this.blocks);

  final List<DocxBlock> blocks;
}

sealed class DocxBlock {
  const DocxBlock();
}

class DocxRun {
  const DocxRun(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.underline = false,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
}

/// Listenpunkt: [level] ab 0, [number] ist die laufende Nummer bei
/// nummerierten Listen.
typedef DocxListItem = ({int level, bool ordered, int number});

class DocxParagraph extends DocxBlock {
  const DocxParagraph(this.runs, {this.heading, this.list});

  final List<DocxRun> runs;

  /// 0 = Titel, 1–9 = Überschrift n, `null` = Fließtext.
  final int? heading;
  final DocxListItem? list;

  String get text => runs.map((r) => r.text).join();
}

/// Zeilen → Zellen → Absätze; alle Zeilen haben gleich viele Zellen.
class DocxTable extends DocxBlock {
  const DocxTable(this.rows);

  final List<List<List<DocxParagraph>>> rows;
}

class DocxImage extends DocxBlock {
  const DocxImage(this.bytes);

  final Uint8List bytes;
}

/// Liest [bytes] (DOCX = Zip mit `word/document.xml`); wirft, wenn es kein
/// Word-Dokument ist.
///
/// Grenzen gegen Zip-Bomben: Ein XML-Teil über [maxPartBytes] (entpackt) ergibt
/// eine [FormatException]; Bilder über das Budget [maxImageBytes] entfallen.
DocxDocument parseDocx(
  List<int> bytes, {
  int maxPartBytes = 20 << 20,
  int maxImageBytes = 50 << 20,
}) => _DocxParser(bytes, maxPartBytes, maxImageBytes).parse();

typedef _Style = ({int? heading, String? numId, int? level});

class _DocxParser {
  _DocxParser(List<int> bytes, this._maxPartBytes, this._imageBudget)
    : _zip = ZipDecoder().decodeBytes(bytes);

  final Archive _zip;
  final int _maxPartBytes;
  int _imageBudget;
  final _styles = <String, _Style>{};

  /// numId → Ebene → nummeriert (nicht Aufzählungszeichen) und Startwert.
  final _formats = <String, Map<int, ({bool ordered, int start})>>{};
  final _rels = <String, String>{};

  /// Zähler je Liste und Ebene.
  final _counters = <String, List<int>>{};

  DocxDocument parse() {
    final body = _xml('word/document.xml')?.rootElement.childElements
        .where((e) => e.name.local == 'body')
        .firstOrNull;
    if (body == null) throw const FormatException('word/document.xml fehlt');
    _readStyles();
    _readNumbering();
    for (final rel
        in _xml('word/_rels/document.xml.rels')?.rootElement.childElements ??
            const <XmlElement>[]) {
      if ((rel.getAttribute('Id'), rel.getAttribute('Target')) case (
        final id?,
        final target?,
      )) {
        // Relativ zu word/ oder absolut im Paket.
        _rels[id] = target.startsWith('/')
            ? target.substring(1)
            : 'word/$target';
      }
    }
    final blocks = <DocxBlock>[];
    _blocks(body, blocks);
    return DocxDocument(blocks);
  }

  XmlDocument? _xml(String name) {
    final file = _zip.findFile(name);
    if (file == null) return null;
    if (file.size > _maxPartBytes) {
      throw FormatException('$name zu groß (${file.size} Byte)');
    }
    return XmlDocument.parse(utf8.decode(file.content, allowMalformed: true));
  }

  void _blocks(XmlElement parent, List<DocxBlock> out) {
    for (final e in parent.childElements) {
      switch (e.name.local) {
        case 'p':
          _paragraph(e, out);
        case 'tbl':
          out.add(_table(e));
        case 'sdt' || 'sdtContent' || 'customXml':
          _blocks(e, out);
      }
    }
  }

  void _paragraph(XmlElement p, List<DocxBlock> out) {
    final props = _child(p, 'pPr');
    final style = _styles[_val(_child(props, 'pStyle'))];
    final numPr = _child(props, 'numPr');
    final numId = _val(_child(numPr, 'numId')) ?? style?.numId;
    final level =
        int.tryParse(_val(_child(numPr, 'ilvl')) ?? '') ?? style?.level ?? 0;

    final runs = <DocxRun>[];
    final images = <DocxImage>[];
    _inline(p, runs, images);
    final paragraph = DocxParagraph(
      runs,
      heading: style?.heading,
      list: numId == null || numId == '0' ? null : _listItem(numId, level),
    );
    if (paragraph.text.trim().isNotEmpty) out.add(paragraph);
    out.addAll(images);
  }

  DocxListItem _listItem(String numId, int level) {
    final format = _formats[numId]?[level];
    final counters = _counters.putIfAbsent(numId, () => []);
    while (counters.length <= level) {
      counters.add((_formats[numId]?[counters.length]?.start ?? 1) - 1);
    }
    counters.length = level + 1; // tiefere Ebenen beginnen neu
    counters[level]++;
    return (
      level: level,
      ordered: format?.ordered ?? false,
      number: counters[level],
    );
  }

  /// Läuft durch Hyperlinks, Einfügungen usw. bis zu den Runs; gelöschter
  /// Text (Änderungsverfolgung) bleibt draußen.
  void _inline(XmlElement e, List<DocxRun> runs, List<DocxImage> images) {
    for (final c in e.childElements) {
      switch (c.name.local) {
        case 'r':
          _run(c, runs, images);
        case 'pPr' || 'del' || 'moveFrom':
          break;
        default:
          _inline(c, runs, images);
      }
    }
  }

  void _run(XmlElement r, List<DocxRun> runs, List<DocxImage> images) {
    final props = _child(r, 'rPr');
    final text = StringBuffer();
    for (final c in r.childElements) {
      switch (c.name.local) {
        case 't':
          text.write(c.innerText);
        case 'tab':
          text.write('\t');
        case 'br' || 'cr':
          text.write('\n');
        case 'drawing' || 'pict':
          for (final ref in c.descendantElements) {
            final id = switch (ref.name.local) {
              'blip' => _attr(ref, 'embed'),
              'imagedata' => _attr(ref, 'id'),
              _ => null,
            };
            final file = _rels[id] == null ? null : _zip.findFile(_rels[id]!);
            if (file != null && file.size <= _imageBudget) {
              _imageBudget -= file.size;
              images.add(DocxImage(file.content));
            }
          }
      }
    }
    if (text.isEmpty) return;
    runs.add(
      DocxRun(
        text.toString(),
        bold: _on(props, 'b'),
        italic: _on(props, 'i'),
        underline: _on(props, 'u'),
      ),
    );
  }

  DocxTable _table(XmlElement tbl) {
    final rows = [
      for (final tr in tbl.childElements.where((e) => e.name.local == 'tr'))
        [
          for (final tc in tr.childElements.where((e) => e.name.local == 'tc'))
            [
              // Verschachtelte Tabellen werden zu Absätzen der Zelle.
              for (final p in tc.descendantElements.where(
                (e) => e.name.local == 'p',
              ))
                _cellParagraph(p),
            ],
        ],
    ];
    final columns = rows.fold(0, (m, r) => r.length > m ? r.length : m);
    return DocxTable([
      for (final row in rows)
        [...row, for (var i = row.length; i < columns; i++) const []],
    ]);
  }

  DocxParagraph _cellParagraph(XmlElement p) {
    final runs = <DocxRun>[];
    _inline(p, runs, []);
    return DocxParagraph(runs);
  }

  /// Überschriften aus `styles.xml`: Stil-IDs sind lokalisiert
  /// („berschrift1“), die Namen nicht („heading 1“).
  void _readStyles() {
    final root = _xml('word/styles.xml')?.rootElement;
    if (root == null) return;
    for (final s in root.childElements.where((e) => e.name.local == 'style')) {
      final id = _attr(s, 'styleId');
      if (id == null) continue;
      final name = _val(_child(s, 'name'))?.toLowerCase() ?? '';
      final props = _child(s, 'pPr');
      final outline = int.tryParse(_val(_child(props, 'outlineLvl')) ?? '');
      final numPr = _child(props, 'numPr');
      _styles[id] = (
        heading: name == 'title'
            ? 0
            : int.tryParse(
                    RegExp(r'^heading (\d)$').firstMatch(name)?.group(1) ?? '',
                  ) ??
                  // outlineLvl 9 = Textkörper, keine Überschrift.
                  (outline == null || outline > 8 ? null : outline + 1),
        numId: _val(_child(numPr, 'numId')),
        level: int.tryParse(_val(_child(numPr, 'ilvl')) ?? ''),
      );
    }
  }

  void _readNumbering() {
    final root = _xml('word/numbering.xml')?.rootElement;
    if (root == null) return;
    final abstract = {
      for (final a in root.childElements.where(
        (e) => e.name.local == 'abstractNum',
      ))
        _attr(a, 'abstractNumId'): {
          for (final lvl in a.childElements.where((e) => e.name.local == 'lvl'))
            int.tryParse(_attr(lvl, 'ilvl') ?? '') ?? 0: (
              ordered: !const {
                'bullet',
                'none',
              }.contains(_val(_child(lvl, 'numFmt')) ?? 'bullet'),
              start: int.tryParse(_val(_child(lvl, 'start')) ?? '') ?? 1,
            ),
        },
    };
    for (final n in root.childElements.where((e) => e.name.local == 'num')) {
      final levels = abstract[_val(_child(n, 'abstractNumId'))];
      if (_attr(n, 'numId') case final id? when levels != null) {
        _formats[id] = levels;
      }
    }
  }

  static XmlElement? _child(XmlElement? e, String local) =>
      e?.childElements.where((c) => c.name.local == local).firstOrNull;

  /// Attribut nach lokalem Namen (`w:val`, `r:embed` …).
  static String? _attr(XmlElement? e, String local) =>
      e?.attributes.where((a) => a.name.local == local).firstOrNull?.value;

  static String? _val(XmlElement? e) => _attr(e, 'val');

  /// Schalter wie `<w:b/>` oder `<w:u w:val="single"/>`; aus bei `0`,
  /// `false` oder `none`.
  static bool _on(XmlElement? props, String local) {
    final e = _child(props, local);
    return e != null && !const {'0', 'false', 'none'}.contains(_val(e));
  }
}
