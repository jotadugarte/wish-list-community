import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/auth/auth_repository.dart';
import 'package:wish_list_mobile/features/social/social_repository.dart';
import 'package:wish_list_mobile/main.dart';

void main() {
  group('Sprint 1 & Sprint 2 Mobile Screens [REQ-AUTH-001] [REQ-SOC-001] [REQ-WISH-001] [REQ-BLOCK-001]', () {
    late InMemoryTokenStorage tokenStorage;
    late ApiClient mockClient;
    late AuthRepository authRepo;
    late SocialRepository socialRepo;

    setUp(() {
      tokenStorage = InMemoryTokenStorage();
      mockClient = ApiClient(
        baseUrl: 'https://api.wishlist.test',
        tokenStorage: tokenStorage,
        transport: (req) async {
          if (req.path == '/api/v1/session' && req.method == 'POST') {
            return const ApiResponse(
              statusCode: 201,
              body: {
                'token': 'mobile_session_token',
                'user': {
                  'id': 1,
                  'username': 'jader_dev',
                  'created_at': '2026-11-25T10:00:00Z',
                },
              },
            );
          }
          if (req.path == '/api/v1/friendships' && req.method == 'GET') {
            return const ApiResponse(
              statusCode: 200,
              body: {
                'friends': [
                  {
                    'id': 10,
                    'status': 'accepted',
                    'direction': 'outgoing',
                    'friend': {
                      'id': 2,
                      'username': 'ceci_nata',
                      'created_at': '2026-11-25T10:00:00Z',
                    },
                  },
                ],
                'incoming_requests': [
                  {
                    'id': 11,
                    'status': 'pending',
                    'direction': 'incoming',
                    'friend': {
                      'id': 3,
                      'username': 'carlos_friend',
                      'created_at': '2026-11-25T10:00:00Z',
                    },
                  },
                ],
                'outgoing_requests': [],
              },
            );
          }
          if (req.path == '/api/v1/users/search' && req.method == 'GET') {
            return const ApiResponse(
              statusCode: 200,
              body: {
                'users': [
                  {
                    'id': 8,
                    'username': 'stranger_handle',
                    'friendship_status': 'none',
                    'created_at': '2026-11-25T10:00:00Z',
                  },
                ],
              },
            );
          }
          if (req.path == '/api/v1/friendships' && req.method == 'POST') {
            return const ApiResponse(
              statusCode: 201,
              body: {
                'friendship': {
                  'id': 99,
                  'status': 'pending',
                  'direction': 'outgoing',
                  'friend': {
                    'id': 8,
                    'username': 'stranger_handle',
                    'created_at': '2026-11-25T10:00:00Z',
                  },
                },
              },
            );
          }
          return const ApiResponse(statusCode: 204, body: {});
        },
      );
      authRepo = AuthRepository(apiClient: mockClient, tokenStorage: tokenStorage);
      socialRepo = SocialRepository(apiClient: mockClient);
    });

    testWidgets('authenticates via LoginScreen and navigates between Friends, Search, and Profile [REQ-AUTH-001] [REQ-SOC-001] [REQ-WISH-001]', (tester) async {
      final tokens = DesignTokens.forConfiguration();

      await tester.pumpWidget(
        WishListApp(
          tokens: tokens,
          authRepository: authRepo,
          socialRepository: socialRepo,
        ),
      );

      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'jader@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'Password123!',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      // After login, FriendsListScreen loads accepted friends and incoming requests
      expect(find.text('@ceci_nata'), findsOneWidget);
      expect(find.text('@carlos_friend'), findsOneWidget);

      // Navigate to Search tab and search for @stranger_handle (anti-stalking: only handle + request button)
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('search_username_field')),
        '@stranger',
      );
      await tester.tap(find.byKey(const Key('search_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('@stranger_handle'), findsOneWidget);
      expect(find.byKey(const Key('send_friend_request_8')), findsOneWidget);
      expect(find.byKey(const Key('block_user_8')), findsOneWidget);
      expect(find.byKey(const Key('report_user_8')), findsOneWidget);
    });
  });
}
