import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Visual specification and theme tokens for Court Midnight design system.
class CourtMidnightTheme {
  static const Color background = Color(0xFF121516);
  static const Color surface = Color(0xFF1A1E20);
  static const Color surfaceElevated = Color(0xFF23282C);
  static const Color surfaceBorder = Color(0xFF2A3034);
  static const Color primaryVolt = Color(0xFFC6F10E);
  static const Color primaryMuted = Color(0xFF8DAA0A);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9EAAAF);
  static const Color textTertiary = Color(0xFF606B70);

  static const Color healthOptimal = Color(0xFF10B981);
  static const Color healthDegraded = Color(0xFFF59E0B);
  static const Color healthCritical = Color(0xFFEF4444);
  static const Color healthCriticalBg = Color(0xFF2A1416);

  static ThemeData get themeData {
    final base = ThemeData.dark();
    final interTextTheme = GoogleFonts.interTextTheme(base.textTheme);
    final barlowTextTheme = GoogleFonts.barlowCondensedTextTheme(
      base.textTheme,
    );

    final textTheme = interTextTheme.copyWith(
      displayLarge: barlowTextTheme.displayLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: barlowTextTheme.displayMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: barlowTextTheme.displaySmall?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: barlowTextTheme.headlineLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: barlowTextTheme.headlineMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: barlowTextTheme.headlineSmall?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: barlowTextTheme.titleLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: interTextTheme.titleMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: interTextTheme.titleSmall?.copyWith(
        color: textSecondary,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: interTextTheme.bodyLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: interTextTheme.bodyMedium?.copyWith(
        color: textSecondary,
        fontWeight: FontWeight.normal,
      ),
      bodySmall: interTextTheme.bodySmall?.copyWith(
        color: textTertiary,
        fontWeight: FontWeight.w500,
      ),
      labelLarge: interTextTheme.labelLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        surfaceContainerHighest: surfaceElevated,
        primary: primaryVolt,
        onPrimary: Colors.black,
        onSurface: textPrimary,
        outline: surfaceBorder,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: surfaceBorder),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        titleTextStyle: GoogleFonts.barlowCondensed(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
