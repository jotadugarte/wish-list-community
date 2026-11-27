import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/core/values/domain_values.dart';
import 'package:wish_list_mobile/features/items/item_repository.dart';
import 'package:wish_list_mobile/features/wishlists/wishlist_detail_screen.dart';
import 'package:wish_list_mobile/features/wishlists/wishlist_repository.dart';

void main() {
  Map<String, dynamic> shellJson({int id = 42}) {
    return {
      'id': id,
      'title': 'Lista ajena',
      'privacy_mode': 'friends',
      'share_token': null,
      'event_date': null,
      'owner': {
        'id': 9,
        'username': 'owner_handle',
        'created_at': '2026-11-26T10:00:00Z',
      },
    };
  }

  group('WishlistRepository.reportWishlist [REQ-DISC-001]', () {
    test('posts reportable_type Wishlist with ReportReasonVo [REQ-DISC-001]', () async {
      final tokenStorage = InMemoryTokenStorage();
      await tokenStorage.saveToken('t');
      RecordedApiRequest? captured;
      final client = ApiClient(
        baseUrl: 'https://api.wishlist.test',
        tokenStorage: tokenStorage,
        transport: (req) async {
          captured = req;
          return const ApiResponse(
            statusCode: 201,
            body: {
              'report': {
                'id': 1,
                'reportable_type': 'Wishlist',
                'reportable_id': 42,
                'reason': 'spam',
                'status': 'pending',
              },
            },
          );
        },
      );

      final repo = WishlistRepository(apiClient: client);
      await repo.reportWishlist(
        wishlistId: 42,
        rawReason: 'spam',
        details: 'Suspicious',
      );

      expect(captured?.method, equals('POST'));
      expect(captured?.path, equals('/api/v1/reports'));
      expect(captured?.body?['reportable_type'], equals('Wishlist'));
      expect(captured?.body?['reportable_id'], equals(42));
      expect(captured?.body?['reason'], equals(ReportReasonVo('spam').value));
      expect(captured?.body?['details'], equals('Suspicious'));
    });
  });

  group('WishlistDetailScreen report UI [REQ-DISC-001]', () {
    testWidgets(
      'non-owner sees reason picker, success, duplicate, unavailable, 429, and invalid messaging [REQ-DISC-001]',
      (tester) async {
        final tokenStorage = InMemoryTokenStorage();
        await tokenStorage.saveToken('t');
        var reportCalls = 0;
        final client = ApiClient(
          baseUrl: 'https://api.wishlist.test',
          tokenStorage: tokenStorage,
          transport: (req) async {
            if (req.path == '/api/v1/wishlists/42') {
              return ApiResponse(
                statusCode: 200,
                body: {'wishlist': shellJson()},
              );
            }
            if (req.path.startsWith('/api/v1/wishlists/42/items') ||
                req.path == '/api/v1/wishlists/42/items') {
              return const ApiResponse(statusCode: 200, body: {'items': []});
            }
            if (req.path == '/api/v1/reports') {
              reportCalls += 1;
              if (reportCalls == 1) {
                return const ApiResponse(
                  statusCode: 201,
                  body: {
                    'report': {
                      'id': 1,
                      'reportable_type': 'Wishlist',
                      'reportable_id': 42,
                      'reason': 'harassment',
                      'status': 'pending',
                    },
                  },
                );
              }
              if (reportCalls == 2) {
                return const ApiResponse(
                  statusCode: 422,
                  body: {'error': 'You already have a pending report for this target'},
                );
              }
              if (reportCalls == 3) {
                return const ApiResponse(
                  statusCode: 404,
                  body: {'error': 'Not found'},
                );
              }
              if (reportCalls == 4) {
                return const ApiResponse(
                  statusCode: 429,
                  body: {'error': 'Too many requests'},
                );
              }
              return const ApiResponse(
                statusCode: 422,
                body: {'error': 'Reason is invalid'},
              );
            }
            return const ApiResponse(statusCode: 404, body: {});
          },
        );

        final strings = AppStrings.forLocale('es');
        final wishlistRepo = WishlistRepository(apiClient: client);
        final itemRepo = ItemRepository(apiClient: client);

        await tester.pumpWidget(
          MaterialApp(
            home: WishlistDetailScreen(
              tokens: DesignTokens.forConfiguration(),
              strings: strings,
              wishlistRepository: wishlistRepo,
              itemRepository: itemRepo,
              wishlistId: 42,
              canManage: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('report_wishlist')), findsOneWidget);
        await tester.tap(find.byKey(const Key('report_wishlist')));
        await tester.pumpAndSettle();

        for (final reason in ReportReasonVo.allowedReasons) {
          expect(find.byKey(Key('report_reason_$reason')), findsOneWidget);
          expect(find.text(strings.reportReasonLabelFor(reason)), findsOneWidget);
        }

        await tester.tap(find.byKey(const Key('report_reason_harassment')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('report_wishlist_submit')));
        await tester.pumpAndSettle();
        expect(find.text(strings.reportWishlistSuccess), findsOneWidget);

        await tester.tap(find.byKey(const Key('report_wishlist')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('report_reason_spam')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('report_wishlist_submit')));
        await tester.pumpAndSettle();
        expect(find.text(strings.reportWishlistDuplicate), findsOneWidget);

        await tester.tap(find.byKey(const Key('report_wishlist')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('report_reason_scam')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('report_wishlist_submit')));
        await tester.pumpAndSettle();
        expect(find.text(strings.reportWishlistUnavailable), findsOneWidget);

        await tester.tap(find.byKey(const Key('report_wishlist')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('report_reason_impersonation')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('report_wishlist_submit')));
        await tester.pumpAndSettle();
        expect(find.text(strings.rateLimitedError), findsOneWidget);

        await tester.tap(find.byKey(const Key('report_wishlist')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('report_reason_inappropriate_content')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('report_wishlist_submit')));
        await tester.pumpAndSettle();
        expect(find.text(strings.invalidDataError), findsOneWidget);
      },
    );

    test('bilingual report strings exist for es and en [REQ-DISC-001]', () {
      final es = AppStrings.forLocale('es');
      final en = AppStrings.forLocale('en');
      expect(es.reportWishlistAction, isNot(equals(en.reportWishlistAction)));
      expect(es.reportWishlistSuccess, isNotEmpty);
      expect(en.reportWishlistSuccess, isNotEmpty);
      expect(es.reportWishlistDuplicate, isNotEmpty);
      expect(en.rateLimitedError, isNotEmpty);
      expect(es.reportWishlistUnavailable, isNotEmpty);
      expect(es.reportReasonLabelFor('harassment'), isNot(equals(en.reportReasonLabelFor('harassment'))));
      expect(es.invalidDataError, isNotEmpty);
      expect(
        en.errorMessage(const ApiException(statusCode: 429, message: 'x')),
        equals(en.rateLimitedError),
      );
    });
  });
}
