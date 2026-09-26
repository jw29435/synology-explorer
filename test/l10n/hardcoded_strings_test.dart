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
    return [
      for (final m in uiArgument.allMatches(source))
        if ((
              literal: readLiteral(source, m.end).text,
              line: '\n'.allMatches(source.substring(0, m.end)).length + 1,
            )
            case (:final literal, :final line)
            when letters.hasMatch(literal) &&
                !lines[line - 1].contains('l10n-ignore'))
          '$line: $literal',
    ];
  }

  test('erkennt Literale und Ausnahmen', () {
    expect(literalsIn("Text('Hallo')"), ['1: Hallo']);
    expect(literalsIn("tooltip:\n    'Zurück',"), ['2: Zurück']);
    expect(literalsIn(r"Text('${a} · $b %')"), isEmpty);
    expect(literalsIn(r"Text('${f('Name')} · ${x}')"), isEmpty);
    expect(literalsIn(r"Text('Datei ${f('x')}')"), ['1: Datei ']);
    expect(literalsIn("hintText: 'https://', // l10n-ignore"), isEmpty);
    expect(literalsIn('Text(l10n.title)'), isEmpty);
  });

  test('keine hartkodierten UI-Texte in presentation/ und app/', () {
    final files =
        [
          ...Directory('lib/app').listSync(recursive: true),
          for (final feature in Directory('lib/features').listSync())
            if (Directory('${feature.path}/presentation') case final dir
                when dir.existsSync())
              ...dir.listSync(recursive: true),
        ].whereType<File>().where(
          (f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'),
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
