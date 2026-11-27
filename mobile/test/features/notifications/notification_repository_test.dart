import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/features/notifications/notification_repository.dart';

void main() {
  group('NotificationRepository O1A/O6A/O7A [REQ-NOTIF-001] [REQ-NOTIF-002]', () {
    late InMemoryTokenStorage tokenStorage;
    late List<RecordedApiRequest> recorded;

    ApiClient mockClient(ApiResponse Function(RecordedApiRequest) responder) {
      return ApiClient(
        baseUrl: 'https://api.wishlist.test',
        tokenStorage: tokenStorage,
        transport: (req) async {
          recorded.add(req);
          return responder(req);
        },
      );
    }

    setUp(() async {
      tokenStorage = InMemoryTokenStorage();
      await tokenStorage.saveToken('tok');
      recorded = [];
    });

    test('fetchInbox maps notifications', () async {
      final client = mockClient((req) {
        expect(req.path, '/api/v1/notifications');
        return const ApiResponse(
          statusCode: 200,
          body: {
            'notifications': [
              {
                'id': 1,
                'event_key': 'friend.request_received',
                'title': 'Nueva solicitud',
                'body': 'hola',
                'read_at': null,
                'created_at': '2026-11-27T12:00:00Z',
              },
            ],
          },
        );
      });
      final notes = await NotificationRepository(apiClient: client).fetchInbox();
      expect(notes, hasLength(1));
      expect(notes.first.isUnread, isTrue);
      expect(notes.first.eventKey, 'friend.request_received');
    });

    test('markRead posts mark_read', () async {
      final client = mockClient((req) {
        expect(req.method, 'POST');
        expect(req.path, '/api/v1/notifications/9/mark_read');
        return const ApiResponse(
          statusCode: 200,
          body: {
            'notification': {
              'id': 9,
              'event_key': 'gift.thank_you',
              'title': 'Gracias',
              'read_at': '2026-11-27T13:00:00Z',
            },
          },
        );
      });
      final note = await NotificationRepository(apiClient: client).markRead(9);
      expect(note.isUnread, isFalse);
    });

    test('fetchPreferences returns O7A catalog', () async {
      final client = mockClient((req) {
        expect(req.path, '/api/v1/notification_preferences');
        return const ApiResponse(
          statusCode: 200,
          body: {
            'notification_preference': {
              'channels': {
                'friend.request_received': {'email': false, 'push': true},
              },
              'defaults_events': [
                'friend.request_received',
                'friend.request_accepted',
                'gift.thank_you',
              ],
            },
          },
        );
      });
      final prefs =
          await NotificationRepository(apiClient: client).fetchPreferences();
      expect(prefs.defaultsEvents, contains('friend.request_received'));
      expect(prefs.channelEnabled('friend.request_received', 'email'), isFalse);
      expect(prefs.channelEnabled('gift.thank_you', 'push'), isTrue);
    });

    test('updateChannel patches single toggle', () async {
      final client = mockClient((req) {
        expect(req.method, 'PATCH');
        expect(req.body?['notification_preference'], isNotNull);
        return const ApiResponse(
          statusCode: 200,
          body: {
            'notification_preference': {
              'channels': {
                'reservation.grace_started': {'push': false},
              },
              'defaults_events': ['reservation.grace_started'],
            },
          },
        );
      });
      final prefs = await NotificationRepository(apiClient: client).updateChannel(
        eventKey: 'reservation.grace_started',
        channel: 'push',
        enabled: false,
      );
      expect(prefs.channelEnabled('reservation.grace_started', 'push'), isFalse);
    });
  });
}
