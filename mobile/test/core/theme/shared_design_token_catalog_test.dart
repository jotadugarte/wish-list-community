import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/core/theme/shared_design_token_catalog.dart';

void main() {
  test(
    'Flutter reads the shared DesignTokens file and matches palette 01 [REQ-ARCH-001]',
    () {
      final catalog = SharedDesignTokenCatalog.readDefault();
      final light = DesignTokens.forConfiguration(
        paletteId: '01',
        isDark: false,
      );
      final dark = DesignTokens.forConfiguration(paletteId: '01', isDark: true);

      expect(catalog.version, matches(RegExp(r'^\d{4}-\d{2}-\d{2}\.')));
      expect(
        catalog.color(paletteId: '01', appearance: 'light', role: 'primary'),
        light.primary,
      );
      expect(
        catalog.color(paletteId: '01', appearance: 'dark', role: 'primary'),
        dark.primary,
      );
      expect(
        catalog.color(paletteId: '01', appearance: 'light', role: 'bg'),
        light.bg,
      );
    },
  );
}
