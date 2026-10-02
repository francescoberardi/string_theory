import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Court Midnight Theme Foundation', () {
    test(
      '[P0] AC-1 should configure ThemeData with Court Midnight visual tokens and typography',
      () {
        final theme = CourtMidnightTheme.themeData;

        // Criterion-defining primary assertion: scaffold background must be Court Midnight graphite (#121516)
        expect(
          theme.scaffoldBackgroundColor,
          equals(const Color(0xFF121516)),
          reason: 'Scaffold background must match Court Midnight #121516',
        );

        // Secondary assertions: surfaces, outlines, primary volt, typography
        expect(
          theme.colorScheme.surface,
          equals(const Color(0xFF1A1E20)),
          reason: 'Surface color must match slate card surface #1A1E20',
        );
        expect(
          theme.colorScheme.primary,
          equals(const Color(0xFFC6F10E)),
          reason: 'Primary accent must match Electric Tennis Volt #C6F10E',
        );
        expect(
          theme.colorScheme.outline,
          equals(const Color(0xFF2A3034)),
          reason: 'Border outline must match #2A3034',
        );
        expect(
          theme.brightness,
          equals(Brightness.dark),
          reason: 'Theme brightness must be dark',
        );
        expect(
          theme.textTheme.headlineMedium?.fontFamily,
          anyOf(contains('Barlow Condensed'), contains('BarlowCondensed')),
          reason: 'Headings must use Barlow Condensed font family',
        );
        expect(
          theme.textTheme.bodyMedium?.fontFamily,
          contains('Inter'),
          reason: 'Body text must use Inter font family',
        );
      },
    );
  });
}
