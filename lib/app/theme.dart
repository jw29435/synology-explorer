import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design-Tokens aus den Mockups (siehe CLAUDE.md).
abstract final class AppColors {
  static const background = Color(0xFF15171C);
  static const surface = Color(0xFF1F2229);
  static const surfaceRaised = Color(0xFF23272F);
  static const border = Color(0xFF2B303A);
  static const text = Color(0xFFEDEFF3);
  static const textSecondary = Color(0xFFA3A9B5);
  static const textMuted = Color(0xFF7C8494);
  static const accent = Color(0xFFF2A93B);
  static const success = Color(0xFF4CC38A);
  static const info = Color(0xFF5AB0FF);
  static const errorSoft = Color(0xFFF0A8A8);
  static const error = Color(0xFFD64545);
}

abstract final class AppTheme {
  /// Schrift für Pfade und Zeiten.
  static TextStyle mono([TextStyle? style]) =>
      GoogleFonts.jetBrainsMono(textStyle: style);

  static final ThemeData dark = _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.accent,
      onPrimary: AppColors.background,
      secondary: AppColors.info,
      onSecondary: AppColors.background,
      error: AppColors.error,
      onError: AppColors.text,
      errorContainer: AppColors.errorSoft,
      onErrorContainer: AppColors.background,
      surface: AppColors.background,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceRaised,
      surfaceContainerHighest: AppColors.surfaceRaised,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    ),
  );

  // ponytail: Mockups definieren nur dunkle Tokens; helles Schema vorerst aus der Akzentfarbe abgeleitet.
  static final ThemeData light = _build(
    ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
    ),
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
        labelStyle: WidgetStateTextStyle.resolveWith(
          (states) => GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
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
