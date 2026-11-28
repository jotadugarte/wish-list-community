import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/features/activities/activity_repository.dart';

void main() {
  group('ActivityRepository [REQ-ACT-001] [REQ-ACT-003] [REQ-MOB-001]', () {
    late InMemoryTokenStorage tokenStorage;
    late List<RecordedApiRequest> recordedRequests;

    ApiClient buildMockClient(
      ApiResponse Function(RecordedApiRequest req) responder,
    ) {
      return ApiClient(
        baseUrl: 'https://api.wishlist.test',
        tokenStorage: tokenStorage,
        transport: (req) async {
          recordedRequests.add(req);
          return responder(req);
        },
      );
    }

    Map<String, dynamic> activityJson({
      int id = 1,
      String status = 'open',
      String mode = 'secret_santa',
      bool needsCure = false,
      String? token,
    }) {
      return {
        'id': id,
        'name': 'Navidad',
        'currency': 'CRC',
        'assignment_mode': mode,
        'visibility_mode': 'recipient_only',
        'reservation_visibility': 'hidden_from_recipient',
        'budget_mode': 'none',
        'status': status,
        'share_token': token,
        'needs_dropout_recovery': needsCure,
        'creator': {'id': 9, 'username': 'host'},
      };
    }

    setUp(() async {
      tokenStorage = InMemoryTokenStorage();
      await tokenStorage.saveToken('activity_bearer');
      recordedRequests = [];
    });

    test('create and fetch activities [REQ-ACT-001]', () async {
      final client = buildMockClient((req) {
        if (req.method == 'POST') {
          expect(req.path, equals('/api/v1/activities'));
          return ApiResponse(
            statusCode: 201,
            body: {'activity': activityJson(token: 'ActivityTokenValue123456')},
          );
        }
        return ApiResponse(
          statusCode: 200,
          body: {
            'activities': [activityJson(token: null)],
          },
        );
      });
      final repo = ActivityRepository(apiClient: client);
      final created = await repo.createActivity(
        name: 'Navidad',
        currency: 'CRC',
        assignmentMode: ActivityAssignmentMode.secretSanta,
      );
      expect(created.name, equals('Navidad'));
      expect(created.shareToken, isNotNull);

      final listed = await repo.fetchActivities();
      expect(listed, hasLength(1));
    });

    test('draw leave bridge and cancel paths [REQ-ACT-001] [REQ-ACT-003]', () async {
      final client = buildMockClient((req) {
        if (req.path.endsWith('/draw')) {
          return ApiResponse(
            statusCode: 200,
            body: {'activity': activityJson(status: 'sealed')},
          );
        }
        if (req.path.endsWith('/participants/me')) {
          return ApiResponse(
            statusCode: 200,
            body: {
              'activity': activityJson(status: 'sealed', needsCure: true),
            },
          );
        }
        if (req.path.endsWith('/blind_bridge')) {
          return ApiResponse(
            statusCode: 200,
            body: {'activity': activityJson(status: 'sealed', needsCure: false)},
          );
        }
        if (req.path.endsWith('/cancel')) {
          return ApiResponse(
            statusCode: 200,
            body: {'activity': activityJson(status: 'cancelled')},
          );
        }
        if (req.path.endsWith('/my_assignment')) {
          return ApiResponse(
            statusCode: 200,
            body: {
              'assignment': {
                'giver_id': 1,
                'recipient_id': 2,
                'recipient': {'username': 'amigo'},
              },
            },
          );
        }
        return ApiResponse(statusCode: 200, body: {'activity': activityJson()});
      });
      final repo = ActivityRepository(apiClient: client);
      expect((await repo.draw(activityId: 1)).isSealed, isTrue);
      expect((await repo.leave(activityId: 1)).needsDropoutRecovery, isTrue);
      expect((await repo.blindBridge(activityId: 1)).needsDropoutRecovery, isFalse);
      expect(
        (await repo.cancel(activityId: 1)).status,
        equals(ActivityLifecycleStatus.cancelled),
      );
      final assignment = await repo.myAssignment(activityId: 1);
      expect(assignment?.recipientUsername, equals('amigo'));
    });
  });
}
