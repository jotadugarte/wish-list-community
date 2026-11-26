import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/wishlists/my_wishlists_screen.dart';
import 'package:wish_list_mobile/features/wishlists/wishlist_repository.dart';

void main() {
  testWidgets(
    'MyWishlistsScreen lists and creates wishlists with DesignTokens defaults [REQ-WISH-001]',
    (tester) async {
      final tokenStorage = InMemoryTokenStorage();
      await tokenStorage.saveToken('t');
      final client = ApiClient(
        baseUrl: 'https://api.wishlist.test',
        tokenStorage: tokenStorage,
        transport: (req) async {
          if (req.method == 'POST') {
            return const ApiResponse(
              statusCode: 201,
              body: {
                'wishlist': {
                  'id': 1,
                  'title': 'Nueva',
                  'privacy_mode': 'friends',
                  'share_token': null,
                  'owner': {
                    'id': 1,
                    'username': 'me_user',
                    'created_at': '2026-11-26T10:00:00Z',
                  },
                },
              },
            );
          }
          return const ApiResponse(
            statusCode: 200,
            body: {
              'wishlists': [
                {
                  'id': 1,
                  'title': 'Nueva',
                  'privacy_mode': 'friends',
                  'share_token': null,
                  'owner': {
                    'id': 1,
                    'username': 'me_user',
                    'created_at': '2026-11-26T10:00:00Z',
                  },
                },
              ],
            },
          );
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyWishlistsScreen(
              tokens: DesignTokens.forConfiguration(),
              strings: AppStrings.forLocale('es'),
              wishlistRepository: WishlistRepository(apiClient: client),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mis listas de deseos'), findsOneWidget);
      expect(find.text('Nueva'), findsOneWidget);
      expect(find.text('Amigos'), findsWidgets);
    },
  );
}
