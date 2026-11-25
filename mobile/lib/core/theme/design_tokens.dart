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
      dark: _ColorSet(bg: Color(0xFF121715), surface: Color(0xFF1B221F), text: Color(0xFFF3F2EE), muted: Color(0xFF9CA39E), primary: Color(0xFF4E8C73), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFE08266), accentBg: Color(0xFF36231E), border: Color(0xFF2D3833), specBg: Color(0xFF252E2A)),
    ),
    '02': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFFAF7F5), surface: Color(0xFFFFFFFF), text: Color(0xFF232020), muted: Color(0xFF6E6563), primary: Color(0xFFD9485B), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFF232946), accentBg: Color(0xFFE8EAF2), border: Color(0xFFE8DFD9), specBg: Color(0xFFF3ECE7)),
      dark: _ColorSet(bg: Color(0xFF171416), surface: Color(0xFF221D20), text: Color(0xFFFAF5F6), muted: Color(0xFFA89CA1), primary: Color(0xFFF06275), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFE8A598), accentBg: Color(0xFF382428), border: Color(0xFF362E33), specBg: Color(0xFF2D262A)),
    ),
    '03': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFF7F6FC), surface: Color(0xFFFFFFFF), text: Color(0xFF1D1B26), muted: Color(0xFF646075), primary: Color(0xFF554388), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFF2A7F8E), accentBg: Color(0xFFE3F3F6), border: Color(0xFFDFDCF0), specBg: Color(0xFFECEAF6)),
      dark: _ColorSet(bg: Color(0xFF14131C), surface: Color(0xFF1E1C29), text: Color(0xFFF4F2FA), muted: Color(0xFF9D99B0), primary: Color(0xFF8772C4), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFF58B4C4), accentBg: Color(0xFF1D3238), border: Color(0xFF312E42), specBg: Color(0xFF282536)),
    ),
    '04': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFF8F4EE), surface: Color(0xFFFFFFFF), text: Color(0xFF241F1B), muted: Color(0xFF6E6359), primary: Color(0xFFB85635), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFF465947), accentBg: Color(0xFFE7EDE7), border: Color(0xFFE3DACB), specBg: Color(0xFFEFE8DC)),
      dark: _ColorSet(bg: Color(0xFF1A1614), surface: Color(0xFF241E1B), text: Color(0xFFF7F2EB), muted: Color(0xFFA89B8F), primary: Color(0xFFD97250), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFF83A185), accentBg: Color(0xFF232E24), border: Color(0xFF3B312C), specBg: Color(0xFF302824)),
    ),
    '05': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFF4F7F9), surface: Color(0xFFFFFFFF), text: Color(0xFF162026), muted: Color(0xFF5A6973), primary: Color(0xFF1A4D66), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFCC7722), accentBg: Color(0xFFFBF0E4), border: Color(0xFFD7E2E8), specBg: Color(0xFFE7EEF2)),
      dark: _ColorSet(bg: Color(0xFF10171C), surface: Color(0xFF182229), text: Color(0xFFF0F5F8), muted: Color(0xFF90A2AD), primary: Color(0xFF3E88AD), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFE89846), accentBg: Color(0xFF362819), border: Color(0xFF2A3A47), specBg: Color(0xFF212E38)),
    ),
    '06': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFFAF7F8), surface: Color(0xFFFFFFFF), text: Color(0xFF211D1F), muted: Color(0xFF6B6065), primary: Color(0xFF9E3E5C), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFF3A3537), accentBg: Color(0xFFEAE7E8), border: Color(0xFFE6DCE0), specBg: Color(0xFFF2EAED)),
      dark: _ColorSet(bg: Color(0xFF171416), surface: Color(0xFF221D20), text: Color(0xFFF9F3F5), muted: Color(0xFFA6989E), primary: Color(0xFFC96382), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFE0B8C4), accentBg: Color(0xFF38262C), border: Color(0xFF382F34), specBg: Color(0xFF2E272B)),
    ),
    '07': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFF5F8F6), surface: Color(0xFFFFFFFF), text: Color(0xFF17211C), muted: Color(0xFF5A6B62), primary: Color(0xFF0F624C), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFB8821E), accentBg: Color(0xFFFAF2E1), border: Color(0xFFD7E3DC), specBg: Color(0xFFE8EFEA)),
      dark: _ColorSet(bg: Color(0xFF0F1714), surface: Color(0xFF17241F), text: Color(0xFFEFF6F2), muted: Color(0xFF8FA69B), primary: Color(0xFF279678), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFE0AD4E), accentBg: Color(0xFF332B19), border: Color(0xFF293D35), specBg: Color(0xFF20302A)),
    ),
    '08': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFF8FAFC), surface: Color(0xFFFFFFFF), text: Color(0xFF0F172A), muted: Color(0xFF64748B), primary: Color(0xFF2563EB), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFE11D48), accentBg: Color(0xFFFFE4E6), border: Color(0xFFE2E8F0), specBg: Color(0xFFEEF2F6)),
      dark: _ColorSet(bg: Color(0xFF0B1120), surface: Color(0xFF151F32), text: Color(0xFFF8FAFC), muted: Color(0xFF94A3B8), primary: Color(0xFF3B82F6), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFFB7185), accentBg: Color(0xFF381824), border: Color(0xFF283548), specBg: Color(0xFF1E293B)),
    ),
    '09': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFF6F3EC), surface: Color(0xFFFFFFFF), text: Color(0xFF241D18), muted: Color(0xFF6B6158), primary: Color(0xFF4A3328), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFF4E6E5D), accentBg: Color(0xFFE6EFEA), border: Color(0xFFDFD8CA), specBg: Color(0xFFECE7DC)),
      dark: _ColorSet(bg: Color(0xFF171412), surface: Color(0xFF221D1A), text: Color(0xFFF5F0E8), muted: Color(0xFFA3988E), primary: Color(0xFF8C6754), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFF7CA38E), accentBg: Color(0xFF213028), border: Color(0xFF38302B), specBg: Color(0xFF2E2723)),
    ),
    '10': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFFAFAFA), surface: Color(0xFFFFFFFF), text: Color(0xFF141413), muted: Color(0xFF666664), primary: Color(0xFF141413), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFC92A42), accentBg: Color(0xFFFCECEF), border: Color(0xFFE5E5E3), specBg: Color(0xFFF0F0F0)),
      dark: _ColorSet(bg: Color(0xFF111110), surface: Color(0xFF1B1B1A), text: Color(0xFFF7F7F5), muted: Color(0xFF9E9E9B), primary: Color(0xFFF7F7F5), primaryFg: Color(0xFF141413), accent: Color(0xFFF0566E), accentBg: Color(0xFF381B20), border: Color(0xFF2E2E2C), specBg: Color(0xFF262624)),
    ),
    '11': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFFFF0F6), surface: Color(0xFFFFFFFF), text: Color(0xFF2B0918), muted: Color(0xFF7A3E58), primary: Color(0xFFE1007A), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFFF5E00), accentBg: Color(0xFFFFE8D6), border: Color(0xFFF7C6DC), specBg: Color(0xFFFFE0EE)),
      dark: _ColorSet(bg: Color(0xFF1C0812), surface: Color(0xFF2B0E1D), text: Color(0xFFFFF0F6), muted: Color(0xFFD48FB0), primary: Color(0xFFFF2E9D), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFFF8533), accentBg: Color(0xFF47210B), border: Color(0xFF521D38), specBg: Color(0xFF3D1429)),
    ),
    '12': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFF3EEFF), surface: Color(0xFFFFFFFF), text: Color(0xFF1A0B36), muted: Color(0xFF5C4785), primary: Color(0xFF6D28D9), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFF4D7C0F), accentBg: Color(0xFFECFCCB), border: Color(0xFFD3C2FA), specBg: Color(0xFFE5DAFF)),
      dark: _ColorSet(bg: Color(0xFF110921), surface: Color(0xFF1B1033), text: Color(0xFFF5F0FF), muted: Color(0xFFA794CC), primary: Color(0xFF8B5CF6), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFA3E635), accentBg: Color(0xFF23360B), border: Color(0xFF362261), specBg: Color(0xFF271847)),
    ),
    '13': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFE6FCFF), surface: Color(0xFFFFFFFF), text: Color(0xFF082F38), muted: Color(0xFF3B6E7A), primary: Color(0xFF008B9E), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFFF4242), accentBg: Color(0xFFFFE3E3), border: Color(0xFFAEE8F0), specBg: Color(0xFFCCF5FA)),
      dark: _ColorSet(bg: Color(0xFF061C21), surface: Color(0xFF0C2B33), text: Color(0xFFE8FCFF), muted: Color(0xFF7AB8C4), primary: Color(0xFF00B8D4), primaryFg: Color(0xFF061C21), accent: Color(0xFFFF6B6B), accentBg: Color(0xFF421818), border: Color(0xFF1B4E5C), specBg: Color(0xFF133C47)),
    ),
    '14': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFFEF9C3), surface: Color(0xFFFFFFFF), text: Color(0xFF172554), muted: Color(0xFF475985), primary: Color(0xFF1D4ED8), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFE11D48), accentBg: Color(0xFFFFE4E6), border: Color(0xFFFDE047), specBg: Color(0xFFFEF08A)),
      dark: _ColorSet(bg: Color(0xFF0F172A), surface: Color(0xFF1E293B), text: Color(0xFFFEF9C3), muted: Color(0xFF94A3B8), primary: Color(0xFFFACC15), primaryFg: Color(0xFF0F172A), accent: Color(0xFFFB7185), accentBg: Color(0xFF3F1624), border: Color(0xFF475569), specBg: Color(0xFF334155)),
    ),
    '15': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFFFF0E5), surface: Color(0xFFFFFFFF), text: Color(0xFF2E0D16), muted: Color(0xFF7D4957), primary: Color(0xFFC9184A), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFF7209B7), accentBg: Color(0xFFF3E0FF), border: Color(0xFFF5C6B0), specBg: Color(0xFFFFE0CC)),
      dark: _ColorSet(bg: Color(0xFF1F0910), surface: Color(0xFF2E0E18), text: Color(0xFFFFF0E5), muted: Color(0xFFC98F9E), primary: Color(0xFFFF4D6D), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFB5179E), accentBg: Color(0xFF3B0D36), border: Color(0xFF571B2E), specBg: Color(0xFF421423)),
    ),
    '16': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFE8FDF2), surface: Color(0xFFFFFFFF), text: Color(0xFF062E1E), muted: Color(0xFF386B56), primary: Color(0xFF059669), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFDB2777), accentBg: Color(0xFFFCE7F3), border: Color(0xFFA7F3D0), specBg: Color(0xFFD1FAE5)),
      dark: _ColorSet(bg: Color(0xFF051F15), surface: Color(0xFF0A3022), text: Color(0xFFECFDF5), muted: Color(0xFF76B59C), primary: Color(0xFF10B981), primaryFg: Color(0xFF051F15), accent: Color(0xFFF472B6), accentBg: Color(0xFF42142B), border: Color(0xFF195740), specBg: Color(0xFF114230)),
    ),
    '17': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFFFF4E6), surface: Color(0xFFFFFFFF), text: Color(0xFF2B1406), muted: Color(0xFF78523A), primary: Color(0xFFEA580C), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFF7C3AED), accentBg: Color(0xFFEDE9FE), border: Color(0xFFFCD3A1), specBg: Color(0xFFFFE5C4)),
      dark: _ColorSet(bg: Color(0xFF1C0D06), surface: Color(0xFF2B150A), text: Color(0xFFFFF7ED), muted: Color(0xFFC4957A), primary: Color(0xFFFB923C), primaryFg: Color(0xFF1C0D06), accent: Color(0xFFA78BFA), accentBg: Color(0xFF2A1B4E), border: Color(0xFF522914), specBg: Color(0xFF3D1E0E)),
    ),
    '18': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFEBF8FF), surface: Color(0xFFFFFFFF), text: Color(0xFF082840), muted: Color(0xFF3F6785), primary: Color(0xFF0284C7), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFD97706), accentBg: Color(0xFFFEF3C7), border: Color(0xFFBAE6FD), specBg: Color(0xFFD6F0FF)),
      dark: _ColorSet(bg: Color(0xFF071926), surface: Color(0xFF0D283B), text: Color(0xFFF0F9FF), muted: Color(0xFF7FA9C7), primary: Color(0xFF38BDF8), primaryFg: Color(0xFF071926), accent: Color(0xFFFBBF24), accentBg: Color(0xFF3D2B07), border: Color(0xFF1E4B6B), specBg: Color(0xFF153852)),
    ),
    '19': _PaletteDual(
      light: _ColorSet(bg: Color(0xFF13111C), surface: Color(0xFF1E1B2E), text: Color(0xFFFAF8FF), muted: Color(0xFF9E96B8), primary: Color(0xFFFF2A85), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFF00D8E8), accentBg: Color(0xFF113842), border: Color(0xFF363052), specBg: Color(0xFF2A2640)),
      dark: _ColorSet(bg: Color(0xFF09080D), surface: Color(0xFF13111C), text: Color(0xFFFFFFFF), muted: Color(0xFF9E96B8), primary: Color(0xFFFF2A85), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFF00F0FF), accentBg: Color(0xFF0E3138), border: Color(0xFF2B2640), specBg: Color(0xFF1E1B2E)),
    ),
    '20': _PaletteDual(
      light: _ColorSet(bg: Color(0xFFF5F3FF), surface: Color(0xFFFFFFFF), text: Color(0xFF1E1B4B), muted: Color(0xFF5B568A), primary: Color(0xFF4F46E5), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFD946EF), accentBg: Color(0xFFFAE8FF), border: Color(0xFFDDD6FE), specBg: Color(0xFFEDE9FE)),
      dark: _ColorSet(bg: Color(0xFF0F0E26), surface: Color(0xFF19173B), text: Color(0xFFF5F3FF), muted: Color(0xFF9893C7), primary: Color(0xFF6366F1), primaryFg: Color(0xFFFFFFFF), accent: Color(0xFFE879F9), accentBg: Color(0xFF3B1542), border: Color(0xFF322E6B), specBg: Color(0xFF252252)),
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
