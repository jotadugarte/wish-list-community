import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';

// Builds a Material 3 ThemeData directly from the centralized DesignTokens.
// Traceability: [REQ-ARCH-001]
class AppTheme {
  // [REQ-ARCH-001] Converts DesignTokens into a cohesive ThemeData instance.
  static ThemeData build(DesignTokens tokens) {
    final brightness = tokens.isDark ? Brightness.dark : Brightness.light;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.primary,
      onPrimary: tokens.primaryFg,
      secondary: tokens.accent,
      onSecondary: tokens.primaryFg,
      error: const Color(0xFFD9383A),
      onError: Colors.white,
      surface: tokens.surface,
      onSurface: tokens.text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.bg,
      fontFamily: tokens.bodyFontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.surface,
        foregroundColor: tokens.text,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: tokens.headingFontFamily,
          fontWeight: tokens.headingWeight,
          fontSize: 20,
          color: tokens.text,
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.primaryFg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
