// Erzeugt THIRD_PARTY.md aus den Lizenzen aller Pakete, die in die App
// eingehen (ohne dev_dependencies).
//
//   flutter pub get && dart run tool/third_party.dart
//
// Die Lizenzart wird am Text erkannt; unklare Fälle stehen als „siehe
// Lizenztext“ in der Tabelle und sollten von Hand geprüft werden.
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final deps = await Process.run('flutter', ['pub', 'deps', '--json']);
  if (deps.exitCode != 0) {
    stderr.write(deps.stderr);
    exit(1);
  }
  final json = jsonDecode(deps.stdout as String) as Map<String, dynamic>;
  final packages = {
    for (final p in (json['packages'] as List).cast<Map<String, dynamic>>())
      p['name'] as String: p,
  };
  final root = packages[json['root']]!;

  // Alles, was von den normalen Abhängigkeiten aus erreichbar ist.
  final used = <String>{};
  final todo = [...(root['directDependencies'] as List).cast<String>()];
  while (todo.isNotEmpty) {
    final name = todo.removeLast();
    final p = packages[name];
    if (p == null || p['source'] == 'sdk' || !used.add(name)) continue;
    todo.addAll((p['dependencies'] as List).cast<String>());
  }

  final config =
      jsonDecode(File('.dart_tool/package_config.json').readAsStringSync())
          as Map<String, dynamic>;
  final roots = {
    for (final p in (config['packages'] as List).cast<Map<String, dynamic>>())
      p['name'] as String: Uri.parse(p['rootUri'] as String),
  };

  final rows = <String>[];
  for (final name in used.toList()..sort()) {
    final dir = Directory.fromUri(roots[name]!);
    final file = ['LICENSE', 'LICENSE.md', 'LICENSE.txt', 'COPYING']
        .map((f) => File('${dir.path}/$f'))
        .where((f) => f.existsSync())
        .firstOrNull;
    final license = file == null
        ? 'keine LICENSE-Datei'
        : detectLicense(file.readAsStringSync());
    rows.add(
      '| [$name](https://pub.dev/packages/$name) | '
      '${packages[name]!['version']} | $license |',
    );
  }

  File('THIRD_PARTY.md').writeAsStringSync('''
# Drittanbieter-Lizenzen

Synology Explorer selbst steht unter CC0 (siehe `LICENSE`). Die App enthält die
folgenden Pakete und Bibliotheken mit eigenen Lizenzen. Die vollständigen
Lizenztexte zeigt die App unter Einstellungen › Über & Lizenzen.

Erzeugt mit `dart run tool/third_party.dart` – nicht von Hand bearbeiten.

## Native Bibliotheken

| Bibliothek | Über | Lizenz |
| --- | --- | --- |
| libmpv, FFmpeg | media_kit_libs_video | LGPL-2.1-or-later, dynamisch gelinkt; Quelltext: [libmpv-android-video-build](https://github.com/media-kit/libmpv-android-video-build), [libmpv-darwin-build](https://github.com/media-kit/libmpv-darwin-build) |
| PDFium | pdfrx | BSD-3-Clause / Apache-2.0 |
| Manrope, JetBrains Mono | assets/fonts | SIL Open Font License 1.1 |

## Dart- und Flutter-Pakete (${rows.length})

| Paket | Version | Lizenz |
| --- | --- | --- |
${rows.join('\n')}
''');
  stdout.writeln('THIRD_PARTY.md: ${rows.length} Pakete');
}

/// Lizenzart am Text erkennen (grob, aber ausreichend für die Übersicht).
String detectLicense(String text) {
  final t = text.replaceAll(RegExp(r'\s+'), ' ');
  bool has(String s) => t.contains(s);
  if (has('Apache License') && has('Version 2.0')) return 'Apache-2.0';
  if (has('GNU LESSER GENERAL PUBLIC LICENSE') ||
      has('GNU Lesser General Public License')) {
    return 'LGPL';
  }
  if (has('GNU GENERAL PUBLIC LICENSE')) return 'GPL';
  if (has('Mozilla Public License')) return 'MPL-2.0';
  if (has('Permission is hereby granted, free of charge')) return 'MIT';
  if (has('Redistribution and use in source and binary forms')) {
    return has('Neither the name') || has('names of its contributors')
        ? 'BSD-3-Clause'
        : 'BSD-2-Clause';
  }
  if (has('This software is provided \'as-is\'')) return 'Zlib';
  if (has('Permission to use, copy, modify, and/or distribute')) return 'ISC';
  if (has('This is free and unencumbered software')) return 'Unlicense';
  if (has('CC0')) return 'CC0-1.0';
  return 'siehe Lizenztext';
}
