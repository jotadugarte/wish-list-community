import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';

// Renders an icon inside any of the 8 distinct badge styles from Ceci's Design Studio:
// 01: Minimal, 02: Solid Pill, 03: Pastel Circle, 04: Brutalist Sticker,
// 05: Gradient Badge, 06: Bold Filled, 07: Dashed Tag, 08: Duotone Ring.
// Traceability: [REQ-ARCH-001]
class AppIconBadge extends StatelessWidget {
  final IconData icon;
  final DesignTokens tokens;
  final double size;

  const AppIconBadge({
    super.key,
    required this.icon,
    required this.tokens,
    this.size = 36,
  });

  // [REQ-ARCH-001] Builds the icon badge container according to tokens.iconStyleId.
  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle(tokens);
    return Container(
      width: size,
      height: size,
      decoration: style.decoration,
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.52, color: style.iconColor),
    );
  }

  _BadgeStyle _resolveStyle(DesignTokens t) {
    if (const {'01', '02', '03', '04'}.contains(t.iconStyleId)) {
      return _resolvePrimaryStyles(t);
    }
    return _resolveSecondaryStyles(t);
  }

  _BadgeStyle _resolvePrimaryStyles(DesignTokens t) {
    switch (t.iconStyleId) {
      case '01':
        return _BadgeStyle(
          iconColor: t.text,
          decoration: const BoxDecoration(color: Colors.transparent),
        );
      case '02':
        return _BadgeStyle(
          iconColor: t.primaryFg,
          decoration: BoxDecoration(
            color: t.primary,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      case '03':
        return _BadgeStyle(
          iconColor: t.accent,
          decoration: BoxDecoration(color: t.accentBg, shape: BoxShape.circle),
        );
      case '04':
      default:
        return _BadgeStyle(
          iconColor: t.text,
          decoration: BoxDecoration(
            color: t.specBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.text, width: 2),
            boxShadow: [BoxShadow(color: t.text, offset: const Offset(2, 2))],
          ),
        );
    }
  }

  _BadgeStyle _resolveSecondaryStyles(DesignTokens t) {
    switch (t.iconStyleId) {
      case '05':
        return _BadgeStyle(
          iconColor: t.primaryFg,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [t.primary, t.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      case '06':
        return _BadgeStyle(
          iconColor: t.primary,
          decoration: BoxDecoration(
            color: t.specBg,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      case '07':
        return _BadgeStyle(
          iconColor: t.accent,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.accent, width: 1.5),
          ),
        );
      case '08':
      default:
        return _BadgeStyle(
          iconColor: t.primary,
          decoration: BoxDecoration(
            color: t.accentBg,
            shape: BoxShape.circle,
            border: Border.all(color: t.primary, width: 2),
          ),
        );
    }
  }
}

class _BadgeStyle {
  final Color iconColor;
  final BoxDecoration decoration;
  const _BadgeStyle({required this.iconColor, required this.decoration});
}
