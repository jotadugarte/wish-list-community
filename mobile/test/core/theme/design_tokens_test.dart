import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/theme/app_icon_badge.dart';
import 'package:wish_list_mobile/core/theme/app_navigation_shell.dart';
import 'package:wish_list_mobile/core/theme/app_theme.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';

void main() {
  group(
    'DesignTokens & AppTheme Parameterized Design System [REQ-ARCH-001]',
    () {
      test('resolves light and dark palettes and switches dynamically by paletteId [REQ-ARCH-001]', () {
        final defaultLight = DesignTokens.forConfiguration(
          paletteId: '01',
          typographyId: '01',
          iconStyleId: '02',
          navStructureId: 'A',
          isDark: false,
        );
        final vividPop = DesignTokens.forConfiguration(
          paletteId: '11',
          typographyId: '03',
          iconStyleId: '04',
          navStructureId: 'C',
          isDark: false,
        );
        final darkTokens = DesignTokens.forConfiguration(
          paletteId: '01',
          isDark: true,
        );

        expect(defaultLight.primary, isNot(equals(vividPop.primary)));
        expect(defaultLight.bg, isNot(equals(darkTokens.bg)));
        expect(defaultLight.navStructureId, equals('A'));
        expect(vividPop.navStructureId, equals('C'));

        for (int i = 1; i <= 20; i++) {
          final pid = i.toString().padLeft(2, '0');
          final pTokens = DesignTokens.forConfiguration(paletteId: pid);
          expect(pTokens.paletteId, equals(pid));
        }
      });

      test('falls back safely to default preset 01 / A when unknown IDs are passed [REQ-ARCH-001]', () {
        final fallback = DesignTokens.forConfiguration(
          paletteId: 'unknown',
          typographyId: 'unknown',
          iconStyleId: 'unknown',
          navStructureId: 'unknown',
        );
        expect(fallback.paletteId, equals('01'));
        expect(fallback.navStructureId, equals('A'));
      });

      testWidgets(
        'AppIconBadge renders all 8 icon badge styles without error [REQ-ARCH-001]',
        (tester) async {
          for (final styleId in [
            '01',
            '02',
            '03',
            '04',
            '05',
            '06',
            '07',
            '08',
          ]) {
            final tokens = DesignTokens.forConfiguration(iconStyleId: styleId);
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.build(tokens),
                home: Scaffold(
                  body: AppIconBadge(icon: Icons.card_giftcard, tokens: tokens),
                ),
              ),
            );
            expect(find.byIcon(Icons.card_giftcard), findsOneWidget);
          }
        },
      );

      testWidgets(
        'AppNavigationShell supports all 4 navigation structures (A, B, C, D) [REQ-ARCH-001]',
        (tester) async {
          for (final navId in ['A', 'B', 'C', 'D']) {
            final tokens = DesignTokens.forConfiguration(navStructureId: navId);
            int selectedIndex = 0;

            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.build(tokens),
                home: StatefulBuilder(
                  builder: (context, setState) {
                    return AppNavigationShell(
                      tokens: tokens,
                      currentIndex: selectedIndex,
                      onDestinationSelected: (idx) =>
                          setState(() => selectedIndex = idx),
                      items: const [
                        AppNavDestination(
                          icon: Icons.list_alt,
                          label: 'Mis Listas',
                        ),
                        AppNavDestination(
                          icon: Icons.people_outline,
                          label: 'Amigos',
                        ),
                        AppNavDestination(icon: Icons.search, label: 'Buscar'),
                        AppNavDestination(
                          icon: Icons.person_outline,
                          label: 'Perfil',
                        ),
                      ],
                      body: Text('Tab:$selectedIndex'),
                    );
                  },
                ),
              ),
            );

            expect(find.text('Tab:0'), findsOneWidget);
            await tester.tap(find.text('Amigos'));
            await tester.pumpAndSettle();
            expect(find.text('Tab:1'), findsOneWidget);
          }
        },
      );
    },
  );
}
