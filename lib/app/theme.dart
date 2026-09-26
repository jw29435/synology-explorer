import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Neutrale Töne (Flächen, Text, Rahmen) je Design. Dunkel = Mockups.
class Neutrals {
  const Neutrals({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.errorSoft,
    required this.errorSurface,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color text;
  final Color textSecondary;
  final Color textMuted;
  final Color errorSoft;
  final Color errorSurface;

  static const dark = Neutrals(
    background: Color(0xFF15171C),
    surface: Color(0xFF1F2229),
    surfaceRaised: Color(0xFF23272F),
    border: Color(0xFF2B303A),
    text: Color(0xFFEDEFF3),
    textSecondary: Color(0xFFA3A9B5),
    textMuted: Color(0xFF7C8494),
    errorSoft: Color(0xFFF0A8A8),
    errorSurface: Color(0xFF2A1A1C),
  );

  /// Helles Design: aus den dunklen Tokens abgeleitet (Mockups gibt es nur
  /// dunkel), Kontrast für Text mindestens 4,5:1.
  static const light = Neutrals(
    background: Color(0xFFF5F6F8),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFECEEF2),
    border: Color(0xFFD8DCE3),
    text: Color(0xFF15171C),
    textSecondary: Color(0xFF4F5663),
    textMuted: Color(0xFF626A7A),
    errorSoft: Color(0xFFB3261E),
    errorSurface: Color(0xFFFDECEC),
  );
}

/// Design-Tokens aus den Mockups (siehe CLAUDE.md). Die neutralen Töne
/// kommen aus [neutrals], das `NuvoExplorerApp` passend zum Design setzt;
/// Akzent- und Statusfarben sind hell wie dunkel gleich.
abstract final class AppColors {
  // ponytail: globaler Schalter statt ThemeExtension – die App baut beim
  // Designwechsel komplett neu auf (NuvoExplorerApp._rebuildAll). ThemeExtension,
  // falls Widgets je außerhalb dieses Baums gerendert werden.
  static Neutrals neutrals = Neutrals.dark;

  static Color get background => neutrals.background;
  static Color get surface => neutrals.surface;
  static Color get surfaceRaised => neutrals.surfaceRaised;
  static Color get border => neutrals.border;
  static Color get text => neutrals.text;
  static Color get textSecondary => neutrals.textSecondary;
  static Color get textMuted => neutrals.textMuted;
  static Color get errorSoft => neutrals.errorSoft;

  /// Fläche endgültiger, roter Bestätigungen (Papierkorb).
  static Color get errorSurface => neutrals.errorSurface;

  static const accent = Color(0xFFF2A93B);
  static const success = Color(0xFF4CC38A);
  static const info = Color(0xFF5AB0FF);
  static const error = Color(0xFFD64545);

  /// Akzent als Fläche hinter Icons (15 %).
  static const accentSurface = Color(0x26F2A93B);

  /// Treffer-Hervorhebung in der Suche (25 %).
  static const accentHighlight = Color(0x40F2A93B);

  /// Hintergrund für Badges auf Vorschaubildern (80 %).
  static const badgeScrim = Color(0xCC15171C);

  /// Kreis hinter dem Play-Symbol auf Video-Kacheln (60 % Schwarz).
  static const playScrim = Color(0x99000000);

  /// Cover-Platzhalter (Screen 12/13, Mini-Player): obere und untere Fläche.
  static const coverTop = Color(0xFF2F3A4B);
  static const coverBottom = Color(0xFF4A6178);

  /// Play/Pause-Knopf im Player (Akzent, abgedunkelt).
  static const accentStrong = Color(0xFFA8680A);
}

abstract final class AppTheme {
  /// Schrift für Pfade und Zeiten.
  static TextStyle mono([TextStyle? style]) =>
      GoogleFonts.jetBrainsMono(textStyle: style);

  static final ThemeData dark = _build(_scheme(Neutrals.dark, Brightness.dark));
  static final ThemeData light = _build(
    _scheme(Neutrals.light, Brightness.light),
  );

  static ColorScheme _scheme(Neutrals n, Brightness brightness) => ColorScheme(
    brightness: brightness,
    primary: AppColors.accent,
    onPrimary: Neutrals.dark.background,
    secondary: AppColors.info,
    onSecondary: Neutrals.dark.background,
    error: AppColors.error,
    onError: Neutrals.dark.text,
    errorContainer: n.errorSoft,
    onErrorContainer: n.background,
    surface: n.background,
    onSurface: n.text,
    onSurfaceVariant: n.textSecondary,
    surfaceContainerLowest: n.background,
    surfaceContainerLow: n.surface,
    surfaceContainer: n.surface,
    surfaceContainerHigh: n.surfaceRaised,
    surfaceContainerHighest: n.surfaceRaised,
    outline: n.border,
    outlineVariant: n.border,
  );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
    );
    final radius14 = BorderRadius.circular(14);
    return base.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: radius14,
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius14,
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius14,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outline),
        showCheckmark: false,
        selectedColor: scheme.primary.withValues(alpha: 0.16),
        backgroundColor: scheme.surface,
        // Chips lösen nur die Farbe nach Zustand auf (WidgetStateColor), einen
        // WidgetStateTextStyle ignorieren sie – Schrift und Farbe gingen
        // sonst verloren (im hellen Design weiße Schrift).
        labelStyle: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurface,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
