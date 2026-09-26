import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/ini.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../browser/domain/nas_entry.dart';
import 'viewer_common.dart';
import 'viewer_screen.dart';

/// Größer wird nicht angezeigt, sondern nur „Öffnen mit“ angeboten.
const maxTextBytes = 5 << 20;

/// Darüber ohne Highlighting und zeilenweise (sonst ruckelt das Layout).
const _maxHighlightChars = 256 << 10;

final _languages = {
  'sh': ('bash', langBash),
  'css': ('css', langCss),
  'dart': ('dart', langDart),
  'ini': ('ini', langIni),
  'js': ('javascript', langJavascript),
  'json': ('json', langJson),
  'md': ('markdown', langMarkdown),
  'markdown': ('markdown', langMarkdown),
  'py': ('python', langPython),
  'sql': ('sql', langSql),
  'ts': ('typescript', langTypescript),
  'html': ('xml', langXml),
  'xml': ('xml', langXml),
  'yaml': ('yaml', langYaml),
  'yml': ('yaml', langYaml),
};

final _highlight = Highlight()
  ..registerLanguages({
    for (final (name, mode) in _languages.values) name: mode,
  });

/// Text nach Byte-Order-Mark (UTF-8, UTF-16 LE/BE), sonst UTF-8; ist das
/// kein gültiges UTF-8, Latin-1 (alte Windows-/Linux-Dateien).
String decodeText(Uint8List bytes) {
  bool starts(List<int> bom) =>
      bytes.length >= bom.length &&
      [for (var i = 0; i < bom.length; i++) bytes[i]].join() == bom.join();
  if (starts([0xEF, 0xBB, 0xBF])) {
    return utf8.decode(bytes.sublist(3), allowMalformed: true);
  }
  if (starts([0xFF, 0xFE]) || starts([0xFE, 0xFF])) {
    final little = bytes[0] == 0xFF;
    return String.fromCharCodes([
      for (var i = 2; i + 1 < bytes.length; i += 2)
        little ? bytes[i] | bytes[i + 1] << 8 : bytes[i] << 8 | bytes[i + 1],
    ]);
  }
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return latin1.decode(bytes);
  }
}

String _extension(String name) => name.contains('.')
    ? name.substring(name.lastIndexOf('.') + 1).toLowerCase()
    : '';

/// Screen 18: Text, Markdown (gerendert/Rohtext) und Code mit Highlighting
/// nach Endung; Dateien über 5 MB nur per „Öffnen mit“.
class TextViewerScreen extends ConsumerStatefulWidget {
  const TextViewerScreen({super.key, required this.entry, this.local});

  final NasEntry entry;
  final LocalFile? local;

  @override
  ConsumerState<TextViewerScreen> createState() => _TextViewerScreenState();
}

class _TextViewerScreenState extends ConsumerState<TextViewerScreen> {
  double _scale = 1;
  bool _raw = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entry = widget.entry;
    if ((entry.size ?? 0) > maxTextBytes) {
      return OpenWithScreen(
        entry: entry,
        hint: l10n.textTooLarge,
        local: widget.local,
      );
    }
    final ext = _extension(entry.name);
    final markdown = ext == 'md' || ext == 'markdown';
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: ViewerTitle(entry.name, entrySubtitle(entry, l10n)),
        actions: [
          FontScaleButton(
            scale: _scale,
            onChanged: (s) => setState(() => _scale = s),
          ),
          ShareButton(entry, local: widget.local),
          const SizedBox(width: 8),
        ],
        bottom: markdown
            ? PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      for (final (raw, label) in [
                        (false, l10n.viewRendered),
                        (true, l10n.viewRaw),
                      ]) ...[
                        ChoiceChip(
                          label: Text(label),
                          selected: _raw == raw,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _raw = raw),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: CachedFileView(
        entry: entry,
        local: widget.local,
        builder: (context, file) => FontScale(
          scale: _scale,
          child: _TextBody(
            file: file,
            extension: ext,
            rendered: markdown && !_raw,
          ),
        ),
      ),
    );
  }
}

class _TextBody extends StatefulWidget {
  const _TextBody({
    required this.file,
    required this.extension,
    required this.rendered,
  });

  final File file;
  final String extension;
  final bool rendered;

  @override
  State<_TextBody> createState() => _TextBodyState();
}

class _TextBodyState extends State<_TextBody> {
  late final Future<String> _text = widget.file.readAsBytes().then(decodeText);

  /// Einmal berechnet; „Aa“ und der Markdown-Umschalter bauen neu.
  TextSpan? _span;

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _text,
    builder: (context, snapshot) {
      final text = snapshot.data;
      if (text == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (widget.rendered) {
        return Markdown(
          data: text,
          selectable: true,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          styleSheet: _markdownStyle(context),
        );
      }
      final mono = AppTheme.mono(
        Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
      );
      if (text.length > _maxHighlightChars) {
        final lines = const LineSplitter().convert(text);
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lines.length,
          itemBuilder: (context, i) => Text(lines[i], style: mono),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText.rich(
          _span ??= _highlighted(text, mono),
          style: mono,
        ),
      );
    },
  );

  TextSpan _highlighted(String text, TextStyle style) {
    final language = _languages[widget.extension]?.$1;
    if (language == null) return TextSpan(text: text);
    final renderer = TextSpanRenderer(style, atomOneDarkTheme);
    _highlight.highlight(code: text, language: language).render(renderer);
    return renderer.span ?? TextSpan(text: text);
  }

  static MarkdownStyleSheet _markdownStyle(BuildContext context) {
    final theme = Theme.of(context);
    final code = AppTheme.mono(
      theme.textTheme.bodyMedium?.copyWith(color: AppColors.accent),
    );
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      code: code.copyWith(backgroundColor: AppColors.surfaceRaised),
      codeblockDecoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      codeblockPadding: const EdgeInsets.all(16),
      blockquoteDecoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.accent, width: 4)),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
    );
  }
}
