import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Karte mit Zeilen und Trennlinien (Screens 25 und 26).
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children, this.highlight});

  final List<Widget> children;

  /// Farbe für Rahmen und Tönung der Karte (Hauptschalter in Screen 25).
  final Color? highlight;

  @override
  Widget build(BuildContext context) => Material(
    // Material statt DecoratedBox: ListTiles zeichnen Ripple darauf.
    clipBehavior: Clip.antiAlias,
    color: highlight == null
        ? AppColors.surface
        : Color.alphaBlend(
            highlight!.withValues(alpha: 0.12),
            AppColors.surface,
          ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: highlight?.withValues(alpha: 0.6) ?? AppColors.border,
      ),
    ),
    child: Column(
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0) Divider(height: 1, color: AppColors.border),
          child,
        ],
      ],
    ),
  );
}

/// Wert rechts in einer Zeile (grau, bei Zahlen/Größen in Mono). Bricht bis
/// zu dreimal um, damit auf 360 dp nichts gekürzt wird.
class SettingsValue extends StatelessWidget {
  const SettingsValue(this.text, {super.key, this.mono = false, this.color});

  final String text;
  final bool mono;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: color ?? AppColors.textMuted, fontSize: 14);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            text,
            style: mono ? AppTheme.mono(style) : style,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right, color: AppColors.textMuted),
      ],
    );
  }
}
