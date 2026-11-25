import 'package:flutter/material.dart';

// Single source of truth for visual design tokens (20 color palettes in Light & Dark,
// 12 typography pairings, 8 icon badge styles, and 4 navigation layouts) matching
// Ceci ("Ñata")'s Interactive Visual Design Studio.
// Traceability: [REQ-ARCH-001], [REQ-USER-002]
class DesignTokens {
  static const String defaultPaletteId = '01';
  static const String defaultTypographyId = '01';
  static const String defaultIconStyleId = '02';
  static const String defaultNavStructureId = 'A';
  static const String defaultAppName = 'Wish List';

  // Active defaults — update these 5 constants when Ñata's completed HTML arrives.
  static String activePaletteId = defaultPaletteId;
  static String activeTypographyId = defaultTypographyId;
  static String activeIconStyleId = defaultIconStyleId;
  static String activeNavStructureId = defaultNavStructureId;
  static String activeAppName = defaultAppName;

  final String paletteId;
  final String typographyId;
  final String iconStyleId;
  final String navStructureId;
  final String appName;
  final bool isDark;

  final Color bg;
  final Color surface;
  final Color text;
  final Color muted;
  final Color primary;
  final Color primaryFg;
  final Color accent;
  final Color accentBg;
  final Color border;
  final Color specBg;

  final String headingFontFamily;
  final String bodyFontFamily;
  final FontWeight headingWeight;

  const DesignTokens({
    required this.paletteId,
    required this.typographyId,
    required this.iconStyleId,
    required this.navStructureId,
    required this.appName,
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.text,
    required this.muted,
    required this.primary,
    required this.primaryFg,
    required this.accent,
    required this.accentBg,
    required this.border,
    required this.specBg,
    required this.headingFontFamily,
    required this.bodyFontFamily,
    required this.headingWeight,
  });

  // [REQ-ARCH-001] Pre-condition: IDs fall back deterministically if unknown.
  // Post-condition: returns a complete, immutable DesignTokens instance.
  factory DesignTokens.forConfiguration({
    String? paletteId,
    String? typographyId,
    String? iconStyleId,
    String? navStructureId,
    String? appName,
    bool isDark = false,
  }) {
    final resolvedPaletteId = _palettes.containsKey(paletteId)
        ? paletteId!
        : defaultPaletteId;
    final resolvedTypoId = _typographies.containsKey(typographyId)
        ? typographyId!
        : defaultTypographyId;
    final resolvedIconId = _validIconIds.contains(iconStyleId)
        ? iconStyleId!
        : defaultIconStyleId;
    final resolvedNavId = _validNavIds.contains(navStructureId)
        ? navStructureId!
        : defaultNavStructureId;
    final resolvedAppName = (appName != null && appName.trim().isNotEmpty)
        ? appName.trim()
        : activeAppName;

    final paletteSpec = _palettes[resolvedPaletteId]!;
    final colors = isDark ? paletteSpec.dark : paletteSpec.light;
    final typo = _typographies[resolvedTypoId]!;

    return DesignTokens(
      paletteId: resolvedPaletteId,
      typographyId: resolvedTypoId,
      iconStyleId: resolvedIconId,
      navStructureId: resolvedNavId,
      appName: resolvedAppName,
      isDark: isDark,
      bg: colors.bg,
      surface: colors.surface,
      text: colors.text,
      muted: colors.muted,
      primary: colors.primary,
      primaryFg: colors.primaryFg,
      accent: colors.accent,
      accentBg: colors.accentBg,
      border: colors.border,
      specBg: colors.specBg,
      headingFontFamily: typo.heading,
      bodyFontFamily: typo.body,
      headingWeight: typo.weight,
    );
  }

  static const Set<String> _validIconIds = {
    '01', '02', '03', '04', '05', '06', '07', '08',
  };
  static const Set<String> _validNavIds = {'A', 'B', 'C', 'D'};

  static const Map<String, _TypographyPreset> _typographies = {
    '01': _TypographyPreset('Plus Jakarta Sans', 'Plus Jakarta Sans', FontWeight.w700),
    '02': _TypographyPreset('Fraunces', 'DM Sans', FontWeight.w700),
    '03': _TypographyPreset('Syne', 'Plus Jakarta Sans', FontWeight.w800),
    '04': _TypographyPreset('Abril Fatface', 'Poppins', FontWeight.w400),
    '05': _TypographyPreset('Fredoka', 'Nunito', FontWeight.w600),
    '06': _TypographyPreset('Playfair Display', 'Lato', FontWeight.w700),
    '07': _TypographyPreset('Bricolage Grotesque', 'Bricolage Grotesque', FontWeight.w800),
    '08': _TypographyPreset('Paytone One', 'DM Sans', FontWeight.w400),
    '09': _TypographyPreset('Righteous', 'Quicksand', FontWeight.w400),
    '10': _TypographyPreset('Cormorant Garamond', 'Montserrat', FontWeight.w700),
    '11': _TypographyPreset('Comfortaa', 'Nunito', FontWeight.w700),
    '12': _TypographyPreset('Space Grotesk', 'Space Grotesk', FontWeight.w700),
  };

  static const Map<String, _PaletteDual> _palettes = {
    '01': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFF6F5F0), surface: Color(0xFFFFFFFF), text: Color(0xFF1A211E), muted: Color(0xFF636B66), primary: Color(0xFF1F4037), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFC86D51), accentBg: Color(0xFFFAEDE8), border: Color(0xFFE4E2DA), specBg: Color(0xFFF3EFE6)),
      dark: _ColorSet(bg: Color(0xFF121816), surface: Color(0xFF1B2421), text: Color(0xFFF2F4F3), muted: Color(0xFF9BA5A0), primary: Color(0xFF438A76), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFE08266), accentBg: Color(0xFF2D211E), border: Color(0xFF2A3531), specBg: Color(0xFF222D29)),
    ),
    '02': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFFDF8F5), surface: Color(0xFFFFFFFF), text: Color(0xFF2D1E2F), muted: Color(0xFF7B6B7D), primary: Color(0xFFD9534F), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFF3E2742), accentBg: Color(0xFFF6EBF8), border: Color(0xFFF0E4DF), specBg: Color(0xFFFAF0EC)),
      dark: _ColorSet(bg: Color(0xFF1A121B), surface: Color(0xFF261C28), text: Color(0xFFFBF5F8), muted: Color(0xFFB3A2B6), primary: Color(0xFFE86A66), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFD8B4E2), accentBg: Color(0xFF342537), border: Color(0xFF382B3A), specBg: Color(0xFF2E2230)),
    ),
    '11': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFFFF5F8), surface: Color(0xFFFFFFFF), text: Color(0xFF1F1124), muted: Color(0xFF755C7D), primary: Color(0xFFFF006E), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFF8338EC), accentBg: Color(0xFFF3E8FF), border: Color(0xFFFBCFE8), specBg: Color(0xFFFDF2F8)),
      dark: _ColorSet(bg: Color(0xFF140A1A), surface: Color(0xFF21122B), text: Color(0xFFFFF0F7), muted: Color(0xFFC4A8D1), primary: Color(0xFFFF2A85), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFB57BFF), accentBg: Color(0xFF311B45), border: Color(0xFF3B214D), specBg: Color(0xFF291638)),
    ),
  };
}

class _TypographyPreset {
  final String heading;
  final String body;
  final FontWeight weight;
  const _TypographyPreset(this.heading, this.body, this.weight);
}

class _PaletteDual {
  final _ColorSet light;
  final _ColorSet dark;
  const _PaletteDual({required this.light, required this.dark});
}

class _ColorSet {
  final Color bg;
  final Color surface;
  final Color text;
  final Color muted;
  final Color primary;
  final Color primaryFg;
  final Color accent;
  final Color accentBg;
  final Color border;
  final Color specBg;

  const _ColorSet({
    required this.bg,
    required this.surface,
    required this.text,
    required this.muted,
    required this.primary,
    required this.primaryFg,
    required this.accent,
    required this.accentBg,
    required this.border,
    required this.specBg,
  });
}
