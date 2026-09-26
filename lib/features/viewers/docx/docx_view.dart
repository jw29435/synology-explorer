import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import 'docx_parser.dart';

/// Zeigt ein [DocxDocument] als Fließtext (Reflow) – Absätze, Überschriften,
/// Listen, Tabellen und Bilder als Flutter-Widgets.
class DocxView extends StatelessWidget {
  const DocxView(this.document, {super.key, this.header});

  final DocxDocument document;

  /// Über dem Dokument, z. B. der Lesemodus-Hinweis.
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final blocks = document.blocks;
    final offset = header == null ? 0 : 1;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      itemCount: blocks.length + offset,
      itemBuilder: (context, i) => i < offset
          ? header!
          : Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _block(context, blocks[i - offset]),
            ),
    );
  }

  Widget _block(BuildContext context, DocxBlock block) => switch (block) {
    DocxParagraph p => _paragraph(context, p),
    DocxTable t => _table(context, t),
    DocxImage(:final bytes) => Image.memory(
      bytes,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    ),
  };

  Widget _paragraph(BuildContext context, DocxParagraph p) {
    final text = Theme.of(context).textTheme;
    final style = switch (p.heading) {
      null => text.bodyLarge,
      0 => text.headlineMedium,
      1 => text.headlineSmall,
      2 => text.titleLarge,
      _ => text.titleMedium,
    }?.copyWith(fontWeight: p.heading == null ? null : FontWeight.w700);
    final content = Text.rich(_spans(p), style: style);
    final list = p.list;
    if (list == null) return content;
    return Padding(
      padding: EdgeInsets.only(left: 8 + 20.0 * list.level),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              list.ordered
                  ? '${list.number}.'
                  : (list.level.isEven ? '•' : '◦'),
              style: style,
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  static TextSpan _spans(DocxParagraph p) => TextSpan(
    children: [
      for (final r in p.runs)
        TextSpan(
          text: r.text,
          style: TextStyle(
            fontWeight: r.bold ? FontWeight.w700 : null,
            fontStyle: r.italic ? FontStyle.italic : null,
            decoration: r.underline ? TextDecoration.underline : null,
          ),
        ),
    ],
  );

  Widget _table(BuildContext context, DocxTable t) {
    const line = BorderSide(color: AppColors.border);
    final style = Theme.of(context).textTheme.bodyMedium;
    return Table(
      border: const TableBorder(horizontalInside: line, bottom: line),
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        for (final row in t.rows)
          TableRow(
            children: [
              for (final cell in row)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        for (final (i, p) in cell.indexed) ...[
                          if (i > 0) const TextSpan(text: '\n'),
                          _spans(p),
                        ],
                      ],
                    ),
                    style: style,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
