import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/features/notifications/notification_models.dart';

export 'package:wish_list_mobile/features/notifications/notification_models.dart';

// Inbox + prefs client for /api/v1 notifications (O1A/O6A).
// Traceability: [REQ-NOTIF-001], [REQ-NOTIF-002]
class NotificationRepository {
  static const int maxInbox = 100;

  final ApiClient apiClient;

  const NotificationRepository({required this.apiClient});

  // [REQ-NOTIF-001] Lists the current user's in-app notifications (newest first).
  Future<List<InboxNotification>> fetchInbox() async {
    final response = await apiClient.request(
      method: 'GET',
      path: '/api/v1/notifications',
    );
    final raw = (response.body['notifications'] as List<dynamic>? ?? const [])
        .take(maxInbox);
    return raw
        .map((e) => InboxNotification.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  // [REQ-NOTIF-001] Marks one notification as read.
  Future<InboxNotification> markRead(int id) async {
    if (id <= 0) {
      throw ArgumentError('Pre-condition failed: notification id must be > 0');
    }
    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/notifications/$id/mark_read',
    );
    return InboxNotification.fromJson(
      response.body['notification'] as Map<String, dynamic>,
    );
  }

  // [REQ-NOTIF-001] Loads per-event channel toggles + catalog defaults.
  Future<NotificationPreferenceSnapshot> fetchPreferences() async {
    final response = await apiClient.request(
      method: 'GET',
      path: '/api/v1/notification_preferences',
    );
    return NotificationPreferenceSnapshot.fromJson(
      response.body['notification_preference'] as Map<String, dynamic>,
    );
  }

  // [REQ-NOTIF-001] Patches one event/channel toggle (merge on server).
  Future<NotificationPreferenceSnapshot> updateChannel({
    required String eventKey,
    required String channel,
    required bool enabled,
  }) async {
    if (eventKey.isEmpty || channel.isEmpty) {
      throw ArgumentError('Pre-condition failed: eventKey and channel required');
    }
    final response = await apiClient.request(
      method: 'PATCH',
      path: '/api/v1/notification_preferences',
      body: {
        'notification_preference': {
          'channels': {
            eventKey: {channel: enabled},
          },
        },
      },
    );
    return NotificationPreferenceSnapshot.fromJson(
      response.body['notification_preference'] as Map<String, dynamic>,
    );
  }
}
