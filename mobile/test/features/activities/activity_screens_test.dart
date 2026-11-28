import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/activities/activities_list_screen.dart';
import 'package:wish_list_mobile/features/activities/activity_board_screen.dart';
import 'package:wish_list_mobile/features/activities/activity_repository.dart';

void main() {
  group('Activity screens [REQ-ACT-001] [REQ-MOB-001]', () {
    late InMemoryTokenStorage tokenStorage;

    ApiClient buildClient(ApiResponse Function(RecordedApiRequest req) responder) {
      return ApiClient(
        baseUrl: 'https://api.wishlist.test',
        tokenStorage: tokenStorage,
        transport: (req) async => responder(req),
      );
    }

    Map<String, dynamic> activityJson({
      String status = 'open',
      bool needsCure = false,
      String mode = 'secret_santa',
    }) {
      return {
        'id': 7,
        'name': 'Grupo',
        'currency': 'CRC',
        'assignment_mode': mode,
        'visibility_mode': 'recipient_only',
        'reservation_visibility': 'hidden_from_recipient',
        'budget_mode': 'none',
        'status': status,
        'needs_dropout_recovery': needsCure,
        'viewer_status': 'accepted',
        'viewer_can_manage': true,
        'creator': {'id': 1, 'username': 'host'},
      };
    }

    setUp(() async {
      tokenStorage = InMemoryTokenStorage();
      await tokenStorage.saveToken('tok');
    });

    testWidgets('lists activities and opens board [REQ-ACT-001]', (tester) async {
      final client = buildClient((req) {
        if (req.path == '/api/v1/activities' && req.method == 'GET') {
          return ApiResponse(
            statusCode: 200,
            body: {
              'activities': [activityJson()],
            },
          );
        }
        if (req.path.endsWith('/my_assignment')) {
          return const ApiResponse(statusCode: 200, body: {'assignment': null});
        }
        return ApiResponse(statusCode: 200, body: {'activity': activityJson()});
      });
      final repo = ActivityRepository(apiClient: client);

      await tester.pumpWidget(
        MaterialApp(
          home: ActivitiesListScreen(
            activityRepository: repo,
            strings: AppStrings.forLocale('es'),
            tokens: DesignTokens.forConfiguration(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Grupo'), findsOneWidget);

      await tester.tap(find.text('Grupo'));
      await tester.pumpAndSettle();
      expect(find.textContaining('secret_santa'), findsOneWidget);
      expect(find.text(AppStrings.forLocale('es').activityDrawAction), findsOneWidget);
    });

    testWidgets('shows cure actions when dropout recovery needed [REQ-ACT-003]', (
      tester,
    ) async {
      final client = buildClient((req) {
        if (req.path.endsWith('/my_assignment')) {
          return const ApiResponse(statusCode: 200, body: {'assignment': null});
        }
        return ApiResponse(
          statusCode: 200,
          body: {'activity': activityJson(status: 'sealed', needsCure: true)},
        );
      });
      await tester.pumpWidget(
        MaterialApp(
          home: ActivityBoardScreen(
            activityRepository: ActivityRepository(apiClient: client),
            strings: AppStrings.forLocale('es'),
            tokens: DesignTokens.forConfiguration(),
            activityId: 7,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.forLocale('es').activityNeedsCureLabel), findsOneWidget);
      expect(find.text(AppStrings.forLocale('es').activityBlindBridgeAction), findsOneWidget);
      expect(find.text(AppStrings.forLocale('es').activityFullRedrawAction), findsOneWidget);
    });
  });
}
