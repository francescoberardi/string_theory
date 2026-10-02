import 'package:flutter/material.dart';

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
    // Red-phase scaffold: returns standard dark theme before full token mapping
    return ThemeData.dark();
  }
}
