import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/features/activities/activity_enums.dart';
import 'package:wish_list_mobile/features/activities/activity_models.dart';

export 'package:wish_list_mobile/features/activities/activity_enums.dart';
export 'package:wish_list_mobile/features/activities/activity_models.dart';

// Repository for Sprint A Activities API parity with Hotwire.
// Traceability: [REQ-ACT-001], [REQ-ACT-002], [REQ-ACT-003], [REQ-ACT-004], [REQ-ACT-005], [REQ-MOB-001]
class ActivityRepository {
  static const int maxList = 100;

  final ApiClient apiClient;

  const ActivityRepository({required this.apiClient});

  Future<List<ActivityShell>> fetchActivities() async {
    final response = await apiClient.request(
      method: 'GET',
      path: '/api/v1/activities',
    );
    final raw = response.body['activities'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .take(maxList)
        .map(ActivityShell.fromJson)
        .toList(growable: false);
  }

  Future<ActivityShell> createActivity({
    required String name,
    required String currency,
    required ActivityAssignmentMode assignmentMode,
    String visibilityMode = 'recipient_only',
    String reservationVisibility = 'hidden_from_recipient',
    ActivityBudgetMode budgetMode = ActivityBudgetMode.none,
    int? budgetAmountCents,
  }) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty) {
      throw ArgumentError('Pre-condition failed: name cannot be blank');
    }
    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/activities',
      body: {
        'activity': {
          'name': cleaned,
          'currency': currency,
          'assignment_mode': assignmentMode.apiValue,
          'visibility_mode': visibilityMode,
          'reservation_visibility': reservationVisibility,
          'budget_mode': budgetMode.apiValue,
          'budget_amount_cents': ?budgetAmountCents,
        },
      },
    );
    return ActivityShell.fromJson(
      response.body['activity'] as Map<String, dynamic>,
    );
  }

  Future<ActivityShell> fetchActivity(int activityId) async {
    _assertId(activityId);
    final response = await apiClient.request(
      method: 'GET',
      path: '/api/v1/activities/$activityId',
    );
    return ActivityShell.fromJson(
      response.body['activity'] as Map<String, dynamic>,
    );
  }

  Future<void> invite({required int activityId, required int userId}) async {
    _assertId(activityId);
    if (userId <= 0) {
      throw ArgumentError('Pre-condition failed: userId must be > 0');
    }
    await apiClient.request(
      method: 'POST',
      path: '/api/v1/activities/$activityId/participants',
      body: {'user_id': userId},
    );
  }

  Future<void> acceptInvite({required int activityId}) async {
    _assertId(activityId);
    await apiClient.request(
      method: 'POST',
      path: '/api/v1/activities/$activityId/participants/accept',
    );
  }

  Future<void> declineInvite({required int activityId}) async {
    _assertId(activityId);
    await apiClient.request(
      method: 'POST',
      path: '/api/v1/activities/$activityId/participants/decline',
    );
  }

  Future<ActivityShell> draw({required int activityId, int? seed}) async {
    _assertId(activityId);
    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/activities/$activityId/draw',
      body: {'seed': ?seed},
    );
    return ActivityShell.fromJson(
      response.body['activity'] as Map<String, dynamic>,
    );
  }

  Future<ActivityShell> arrancar({required int activityId}) async {
    _assertId(activityId);
    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/activities/$activityId/arrancar',
    );
    return ActivityShell.fromJson(
      response.body['activity'] as Map<String, dynamic>,
    );
  }

  Future<ActivityShell> leave({required int activityId}) async {
    _assertId(activityId);
    final response = await apiClient.request(
      method: 'DELETE',
      path: '/api/v1/activities/$activityId/participants/me',
    );
    return ActivityShell.fromJson(
      response.body['activity'] as Map<String, dynamic>,
    );
  }

  Future<ActivityShell> blindBridge({required int activityId}) async {
    _assertId(activityId);
    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/activities/$activityId/blind_bridge',
    );
    return ActivityShell.fromJson(
      response.body['activity'] as Map<String, dynamic>,
    );
  }

  Future<ActivityShell> fullRedraw({required int activityId, int? seed}) async {
    _assertId(activityId);
    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/activities/$activityId/full_redraw',
      body: {'seed': ?seed},
    );
    return ActivityShell.fromJson(
      response.body['activity'] as Map<String, dynamic>,
    );
  }

  Future<ActivityShell> cancel({required int activityId}) async {
    _assertId(activityId);
    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/activities/$activityId/cancel',
    );
    return ActivityShell.fromJson(
      response.body['activity'] as Map<String, dynamic>,
    );
  }

  Future<ActivityShell> transfer({
    required int activityId,
    required int newCreatorId,
  }) async {
    _assertId(activityId);
    if (newCreatorId <= 0) {
      throw ArgumentError('Pre-condition failed: newCreatorId must be > 0');
    }
    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/activities/$activityId/transfer',
      body: {'new_creator_id': newCreatorId},
    );
    return ActivityShell.fromJson(
      response.body['activity'] as Map<String, dynamic>,
    );
  }

  Future<ActivityAssignmentView?> myAssignment({required int activityId}) async {
    _assertId(activityId);
    final response = await apiClient.request(
      method: 'GET',
      path: '/api/v1/activities/$activityId/my_assignment',
    );
    final raw = response.body['assignment'];
    if (raw == null) return null;
    return ActivityAssignmentView.fromJson(raw as Map<String, dynamic>);
  }

  void _assertId(int activityId) {
    if (activityId <= 0) {
      throw ArgumentError('Pre-condition failed: activityId must be > 0');
    }
  }
}
