import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/auth/auth_repository.dart';
import 'package:wish_list_mobile/features/social/social_repository.dart';
import 'package:wish_list_mobile/main.dart';

typedef _Responder = ApiResponse Function(RecordedApiRequest req);

const _friendJson = {
  'id': 2,
  'username': 'ceci_nata',
  'created_at': '2026-11-25T10:00:00Z',
};

ApiResponse _defaultResponder(RecordedApiRequest req) {
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
  if (req.path == '/api/v1/me') {
    return const ApiResponse(
      statusCode: 200,
      body: {
        'id': 1,
        'username': 'jader_dev',
        'email_address': 'jader@example.com',
        'locale': 'en',
        'time_zone': 'UTC',
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
            'friend': _friendJson,
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
}

void main() {
  group('Sprint 1 & Sprint 2 Mobile Screens [REQ-AUTH-001] [REQ-SOC-001] [REQ-WISH-001] [REQ-BLOCK-001]', () {
    late InMemoryTokenStorage tokenStorage;
    late List<RecordedApiRequest> log;

    setUp(() {
      tokenStorage = InMemoryTokenStorage();
      log = [];
    });

    Widget buildApp(_Responder responder) {
      final client = ApiClient(
        baseUrl: 'https://api.wishlist.test',
        tokenStorage: tokenStorage,
        transport: (req) async {
          log.add(req);
          return responder(req);
        },
      );
      return WishListApp(
        tokens: DesignTokens.forConfiguration(),
        authRepository: AuthRepository(
          apiClient: client,
          tokenStorage: tokenStorage,
        ),
        socialRepository: SocialRepository(apiClient: client),
      );
    }

    Future<void> login(WidgetTester tester) async {
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
    }

    Future<void> openSearchAndFind(WidgetTester tester) async {
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('search_username_field')),
        '@stranger',
      );
      await tester.tap(find.byKey(const Key('search_submit_button')));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'authenticates via LoginScreen and navigates between Friends, Search, and Profile [REQ-AUTH-001] [REQ-SOC-001] [REQ-WISH-001]',
      (tester) async {
        await tester.pumpWidget(buildApp(_defaultResponder));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('login_email_field')), findsOneWidget);
        await login(tester);

        expect(find.text('@ceci_nata'), findsOneWidget);
        expect(find.text('@carlos_friend'), findsOneWidget);

        await openSearchAndFind(tester);
        expect(find.text('@stranger_handle'), findsOneWidget);
        expect(find.byKey(const Key('send_friend_request_8')), findsOneWidget);
        expect(find.byKey(const Key('block_user_8')), findsOneWidget);
        expect(find.byKey(const Key('report_user_8')), findsOneWidget);
      },
    );

    testWidgets(
      'block and report buttons call /api/v1/user_blocks and /api/v1/reports [REQ-BLOCK-001] [REQ-DISC-001]',
      (tester) async {
        await tester.pumpWidget(buildApp(_defaultResponder));
        await tester.pumpAndSettle();
        await login(tester);
        await openSearchAndFind(tester);

        await tester.tap(find.byKey(const Key('block_user_8')));
        await tester.pumpAndSettle();
        final block = log.lastWhere((r) => r.path == '/api/v1/user_blocks');
        expect(block.method, equals('POST'));
        expect(block.body?['blocked_id'], equals(8));

        await tester.tap(find.byKey(const Key('report_user_8')));
        await tester.pumpAndSettle();
        final report = log.lastWhere((r) => r.path == '/api/v1/reports');
        expect(report.body?['reportable_id'], equals(8));
        expect(report.body?['reason'], equals('harassment'));
      },
    );

    testWidgets(
      'a 409 from the server shows a friendly localized message, not raw text [REQ-SOC-001] [REQ-USER-002]',
      (tester) async {
        await tester.pumpWidget(
          buildApp((req) {
            if (req.path == '/api/v1/friendships' && req.method == 'POST') {
              return const ApiResponse(statusCode: 409, body: {'error': 'dup'});
            }
            return _defaultResponder(req);
          }),
        );
        await tester.pumpAndSettle();
        await login(tester);
        await openSearchAndFind(tester);

        await tester.tap(find.byKey(const Key('send_friend_request_8')));
        await tester.pumpAndSettle();

        expect(
          find.text(AppStrings.forLocale('es').conflictError),
          findsOneWidget,
        );
        expect(find.textContaining('ApiException'), findsNothing);
      },
    );

    testWidgets(
      'a 401 after login returns the user to LoginScreen and clears the token [REQ-AUTH-001]',
      (tester) async {
        await tester.pumpWidget(
          buildApp((req) {
            if (req.path == '/api/v1/friendships' && req.method == 'GET') {
              return const ApiResponse(
                statusCode: 401,
                body: {'error': 'Unauthorized'},
              );
            }
            return _defaultResponder(req);
          }),
        );
        await tester.pumpAndSettle();
        await login(tester);

        expect(find.byKey(const Key('login_email_field')), findsOneWidget);
        expect(await tokenStorage.readToken(), isNull);
      },
    );

    testWidgets(
      'restores a persisted session on start and uses the profile locale (en) [REQ-AUTH-001] [REQ-USER-002]',
      (tester) async {
        await tokenStorage.saveToken('persisted_token');

        await tester.pumpWidget(buildApp(_defaultResponder));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('login_email_field')), findsNothing);
        expect(find.text('Friends'), findsOneWidget);
        final me = log.firstWhere((r) => r.path == '/api/v1/me');
        expect(me.headers['Authorization'], equals('Bearer persisted_token'));
      },
    );

    testWidgets(
      'LoginScreen navigates to PasswordResetScreen and submits POST /api/v1/passwords [REQ-AUTH-003] [REQ-USER-002]',
      (tester) async {
        const resetMessage = 'If the account exists, instructions were sent.';
        await tester.pumpWidget(
          buildApp((req) {
            if (req.path == '/api/v1/passwords' && req.method == 'POST') {
              return const ApiResponse(
                statusCode: 200,
                body: {'message': resetMessage},
              );
            }
            return _defaultResponder(req);
          }),
        );
        await tester.pumpAndSettle();

        final s = AppStrings.forLocale('es');
        expect(find.text(s.forgotPasswordLink), findsOneWidget);
        await tester.tap(find.byKey(const Key('forgot_password_link')));
        await tester.pumpAndSettle();

        expect(find.text(s.passwordResetTitle), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('password_reset_email_field')),
          'jader@example.com',
        );
        await tester.tap(find.byKey(const Key('password_reset_submit_button')));
        await tester.pumpAndSettle();

        expect(find.text(resetMessage), findsOneWidget);
        final reset = log.lastWhere((r) => r.path == '/api/v1/passwords');
        expect(reset.method, equals('POST'));
        expect(reset.body?['email_address'], equals('jader@example.com'));
        expect(reset.headers.containsKey('Authorization'), isFalse);
      },
    );

    testWidgets(
      'LoginScreen navigates to AccountRestoreScreen and restores within 30-day window [REQ-LIFE-002] [REQ-USER-002]',
      (tester) async {
        await tester.pumpWidget(
          buildApp((req) {
            if (req.path == '/api/v1/account/restore' && req.method == 'POST') {
              return const ApiResponse(
                statusCode: 200,
                body: {
                  'token': 'restored_session_token',
                  'user': {
                    'id': 1,
                    'username': 'jader_dev',
                    'created_at': '2026-11-25T10:00:00Z',
                  },
                },
              );
            }
            return _defaultResponder(req);
          }),
        );
        await tester.pumpAndSettle();

        final s = AppStrings.forLocale('es');
        expect(find.text(s.restoreAccountLink), findsOneWidget);
        await tester.tap(find.byKey(const Key('restore_account_link')));
        await tester.pumpAndSettle();

        expect(find.text(s.accountRestoreTitle), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('restore_email_field')),
          'jader@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('restore_password_field')),
          'Password123!',
        );
        await tester.tap(find.byKey(const Key('restore_submit_button')));
        await tester.pumpAndSettle();

        expect(find.text('@ceci_nata'), findsOneWidget);
        expect(await tokenStorage.readToken(), equals('restored_session_token'));
        final restore = log.firstWhere(
          (r) => r.path == '/api/v1/account/restore',
        );
        expect(restore.method, equals('POST'));
        expect(restore.body?['email_address'], equals('jader@example.com'));
        expect(restore.headers.containsKey('Authorization'), isFalse);
      },
    );

    testWidgets(
      'PasswordResetScreen shows friendly error for invalid email input [REQ-AUTH-003] [REQ-USER-002]',
      (tester) async {
        await tester.pumpWidget(buildApp(_defaultResponder));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('forgot_password_link')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('password_reset_email_field')),
          'not-an-email',
        );
        await tester.tap(find.byKey(const Key('password_reset_submit_button')));
        await tester.pumpAndSettle();

        expect(
          find.text(AppStrings.forLocale('es').invalidInputError),
          findsOneWidget,
        );
        expect(log.where((r) => r.path == '/api/v1/passwords'), isEmpty);
      },
    );
  });
}
