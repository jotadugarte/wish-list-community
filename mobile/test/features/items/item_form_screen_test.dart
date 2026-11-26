import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/items/item_form_screen.dart';
import 'package:wish_list_mobile/features/items/item_repository.dart';

void main() {
  testWidgets(
    'ItemFormScreen shows specs box and preview controls [REQ-ITEM-001] [REQ-ITEM-006]',
    (tester) async {
      final tokenStorage = InMemoryTokenStorage();
      await tokenStorage.saveToken('t');
      final client = ApiClient(
        baseUrl: 'https://api.wishlist.test',
        tokenStorage: tokenStorage,
        transport: (req) async {
          if (req.path.endsWith('/link_previews')) {
            return const ApiResponse(
              statusCode: 200,
              body: {
                'title': 'Preview Title',
                'image_url': 'https://cdn.example/i.png',
                'source_url': 'https://shop.example/p/1',
              },
            );
          }
          return const ApiResponse(
            statusCode: 201,
            body: {
              'item': {
                'id': 1,
                'wishlist_id': 1,
                'title': 'Preview Title',
                'priority': 'medium',
                'position': 0,
                'links': [],
                'images': [],
              },
            },
          );
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ItemFormScreen(
            tokens: DesignTokens.forConfiguration(),
            strings: AppStrings.forLocale('es'),
            itemRepository: ItemRepository(apiClient: client),
            wishlistId: 1,
          ),
        ),
      );

      expect(find.text('Agregar ítem'), findsOneWidget);
      expect(
        find.text('Especificaciones (color, talla, variante)'),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Pegar enlace de tienda'),
        'https://shop.example/p/1',
      );
      await tester.tap(find.text('Vista previa'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Preview Title'), findsWidgets);
      expect(find.text('Usar vista previa'), findsOneWidget);
      await tester.tap(find.text('Usar vista previa'));
      await tester.pumpAndSettle();
      expect(find.text('Preview Title'), findsWidgets);
    },
  );
}
