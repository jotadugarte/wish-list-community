import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

/// Reads `design/design_tokens.json` without rewriting the hardcoded
/// [DesignTokens] maps. Sprint 9 owns `main.dart`; this reader stays additive.
/// Traceability: [REQ-ARCH-001]
class SharedDesignTokenCatalog {
  static const int maxPalettes = 20;
  static const int maxCandidatePaths = 3;

  final String version;
  final Map<String, dynamic> _raw;

  SharedDesignTokenCatalog._(this.version, this._raw);

  /// [REQ-ARCH-001] Pre-condition: the shared JSON file is on disk.
  /// Post-condition: version stamp is present.
  static SharedDesignTokenCatalog readDefault() {
    final catalog = parse(File(resolveDefaultPath()).readAsStringSync());
    if (catalog.version.isEmpty) {
      throw StateError('Post-condition failed: version blank');
    }
    return catalog;
  }

  /// [REQ-ARCH-001] Resolves the monorepo file from the Flutter package cwd.
  static String resolveDefaultPath() {
    const candidates = <String>[
      '../design/design_tokens.json',
      'design/design_tokens.json',
      '../../design/design_tokens.json',
    ];
    var checked = 0;
    for (final candidate in candidates) {
      checked += 1;
      if (checked > maxCandidatePaths) {
        break;
      }
      if (File(candidate).existsSync()) {
        return candidate;
      }
    }
    throw StateError('Pre-condition failed: design tokens file missing');
  }

  /// [REQ-ARCH-001] Pre-condition: source is a JSON object with a version.
  static SharedDesignTokenCatalog parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Pre-condition failed: tokens payload must be an object');
    }
    final version = decoded['version'];
    if (version is! String || version.isEmpty) {
      throw StateError('Pre-condition failed: version missing');
    }
    return SharedDesignTokenCatalog._(version, decoded);
  }

  /// [REQ-ARCH-001] Pre-condition: palette, appearance, and role exist.
  /// Post-condition: returns the same ARGB color the Dart fallback uses today.
  Color color({
    required String paletteId,
    required String appearance,
    required String role,
  }) {
    final hex = _hex(paletteId: paletteId, appearance: appearance, role: role);
    return _colorFromHex(hex);
  }

  String _hex({
    required String paletteId,
    required String appearance,
    required String role,
  }) {
    if (appearance != 'light' && appearance != 'dark') {
      throw StateError('Pre-condition failed: unknown appearance');
    }
    final palettes = _raw['palettes'];
    if (palettes is! Map<String, dynamic>) {
      throw StateError('Pre-condition failed: palettes missing');
    }
    if (palettes.length > maxPalettes) {
      throw StateError('Post-condition failed: palette bound exceeded');
    }
    final palette = palettes[paletteId];
    if (palette is! Map<String, dynamic>) {
      throw StateError('Pre-condition failed: unknown palette');
    }
    final colors = palette[appearance];
    if (colors is! Map<String, dynamic>) {
      throw StateError('Pre-condition failed: appearance missing');
    }
    final hex = colors[role];
    if (hex is! String) {
      throw StateError('Pre-condition failed: role missing');
    }
    return hex;
  }

  Color _colorFromHex(String hex) {
    final match = RegExp(r'^#([0-9A-F]{6})$').firstMatch(hex);
    if (match == null) {
      throw StateError('Post-condition failed: hex missing');
    }
    final value = int.parse(match.group(1)!, radix: 16);
    return Color(0xFF000000 | value);
  }
}
