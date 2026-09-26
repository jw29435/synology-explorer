import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keine hartkodierten UI-Texte: Jeder String-Literal an einer Stelle, die
/// Text anzeigt, muss aus den ARB-Dateien kommen. Ausnahmen (z. B. ein
/// URL-Schema als Platzhalter) tragen `// l10n-ignore` in der Zeile.
void main() {
  // Argumente, die angezeigten Text tragen; danach beginnt ein Literal.
  final uiArgument = RegExp(
    r'''(?:\bText(?:\.rich)?\(|\bTextSpan\(\s*text:|\b(?:tooltip|label|labelText|hintText|helperText|errorText|title|subtitle|semanticLabel|semanticsLabel|message|content|applicationName|applicationLegalese|text)\s*:)\s*(?:const\s+)?(?:Text\(\s*)?(?=['"])''',
  );
  final letters = RegExp('[A-Za-zÄÖÜäöüß]{2,}');

  // Positionale Literale an Widgets und Helfern (`showSnack(context, '…')`,
  // `SectionLabel('…')`): nur Satzartiges (zwei Wörter) zählt, sonst wären
  // Schlüssel, Pfade und Endungen lauter Fehlalarme.
  final positional = RegExp(r'''(?:\b(\w+)\(|,)\s*(?=['"])''');
  final sentence = RegExp('[A-Za-zÄÖÜäöüß]{2,}[ ]+[A-Za-zÄÖÜäöüß]{2,}');
  // Aufrufe, deren Text nie angezeigt wird (Fehler, Logs, Schlüssel, Pfade).
  const notUi = {
    'Key',
    'ValueKey',
    'StateError',
    'UnimplementedError',
    'ArgumentError',
    'FormatException',
    'Exception',
    'debugPrint',
    'print',
    'Directory',
    'File',
    'Uri',
    'RegExp',
    'go',
    'push',
    'startsWith',
    'endsWith',
    'contains',
    'getAttribute',
    'Locale',
    'AndroidNotificationDetails',
    'AndroidInitializationSettings',
  };

  /// Literal ab [start] (Anführungszeichen) ohne Interpolationen `${…}`/`$x`.
  ({String text, int end}) readLiteral(String s, int start) {
    final quote = s[start];
    final out = StringBuffer();
    var i = start + 1;
    while (i < s.length && s[i] != quote) {
      if (s[i] == r'\') {
        out.write(s[i + 1]);
        i += 2;
      } else if (s.startsWith(r'${', i)) {
        // Bis zur passenden Klammer; Strings darin überspringen.
        var depth = 1;
        i += 2;
        while (depth > 0) {
          if (s[i] == "'" || s[i] == '"') {
            i = readLiteral(s, i).end;
            continue;
          }
          if (s[i] == '{') depth++;
          if (s[i] == '}') depth--;
          i++;
        }
      } else if (s[i] == r'$') {
        i++;
        while (RegExp(r'\w').hasMatch(s[i])) {
          i++;
        }
      } else {
        out.write(s[i++]);
      }
    }
    return (text: out.toString(), end: i + 1);
  }

  List<String> literalsIn(String source) {
    final lines = source.split('\n');
    String? hit(int at, bool Function(String) isUi) {
      final literal = readLiteral(source, at).text;
      final line = '\n'.allMatches(source.substring(0, at)).length + 1;
      return isUi(literal) && !lines[line - 1].contains('l10n-ignore')
          ? '$line: $literal'
          : null;
    }

    return {
      for (final m in uiArgument.allMatches(source))
        ?hit(m.end, letters.hasMatch),
      for (final m in positional.allMatches(source))
        if (!notUi.contains(m.group(1))) ?hit(m.end, sentence.hasMatch),
    }.toList();
  }

  test('erkennt Literale und Ausnahmen', () {
    expect(literalsIn("Text('Hallo')"), ['1: Hallo']);
    expect(literalsIn("tooltip:\n    'Zurück',"), ['2: Zurück']);
    expect(literalsIn(r"Text('${a} · $b %')"), isEmpty);
    expect(literalsIn(r"Text('${f('Name')} · ${x}')"), isEmpty);
    expect(literalsIn(r"Text('Datei ${f('x')}')"), ['1: Datei ']);
    expect(literalsIn("hintText: 'https://', // l10n-ignore"), isEmpty);
    expect(literalsIn('Text(l10n.title)'), isEmpty);
    expect(literalsIn("showSnack(context, 'Datei gelöscht')"), [
      '1: Datei gelöscht',
    ]);
    expect(literalsIn("SectionLabel('Zuletzt geöffnet')"), [
      '1: Zuletzt geöffnet',
    ]);
    expect(literalsIn("StateError('Keine Session')"), isEmpty);
    expect(literalsIn("Key('play-pause'), go('/files')"), isEmpty);
    expect(literalsIn("_xml(archive, 'word/document.xml')"), isEmpty);
  });

  test('keine hartkodierten UI-Texte in presentation/, app/, viewers/', () {
    final files =
        [
          ...Directory('lib/app').listSync(recursive: true),
          ...Directory('lib/features/viewers').listSync(recursive: true),
          for (final feature in Directory('lib/features').listSync())
            if (Directory('${feature.path}/presentation') case final dir
                when dir.existsSync())
              ...dir.listSync(recursive: true),
        ].whereType<File>().where(
          (f) =>
              f.path.endsWith('.dart') &&
              !f.path.endsWith('.g.dart') &&
              !f.path.endsWith('.freezed.dart'),
        );
    final found = {
      for (final f in files)
        if (literalsIn(f.readAsStringSync()) case final hits
            when hits.isNotEmpty)
          f.path: hits,
    };
    expect(found, isEmpty, reason: 'Texte gehören in lib/l10n/app_*.arb');
  });

  test('app_de.arb und app_en.arb haben dieselben Schlüssel', () {
    Set<String> keys(String file) =>
        RegExp(r'^  "([^@"][^"]*)":', multiLine: true)
            .allMatches(File('lib/l10n/$file').readAsStringSync())
            .map((m) => m.group(1)!)
            .toSet();
    expect(keys('app_en.arb'), keys('app_de.arb'));
  });
}
