import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/features/auth/auth_repository.dart';

void main() {
  group('AuthRepository & ApiClient [REQ-AUTH-001] [REQ-AUTH-003] [REQ-LIFE-002]', () {
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

    setUp(() {
      tokenStorage = InMemoryTokenStorage();
      recordedRequests = [];
    });

    test('login validates EmailAddressVo, stores Bearer token, and returns UserProfile [REQ-AUTH-001]', () async {
      final client = buildMockClient((req) {
        expect(req.method, equals('POST'));
        expect(req.path, equals('/api/v1/session'));
        expect(req.body?['email_address'], equals('nata@example.com'));
        return const ApiResponse(
          statusCode: 201,
          body: {
            'token': 'raw_token_123',
            'user': {
              'id': 7,
              'username': 'ceci_nata',
              'created_at': '2026-11-25T10:00:00Z',
            },
          },
        );
      });

      final repo = AuthRepository(apiClient: client, tokenStorage: tokenStorage);
      final user = await repo.login(
        rawEmail: '  Nata@Example.com ',
        password: 'Password123!',
        deviceName: 'iPhone 16',
        fcmToken: 'fcm_abc',
      );

      expect(user.id, equals(7));
      expect(user.username.value, equals('ceci_nata'));
      expect(await tokenStorage.readToken(), equals('raw_token_123'));
    });

    test('logout calls DELETE /api/v1/session with Authorization Bearer header and clears token [REQ-AUTH-001] [REQ-NOTIF-002]', () async {
      await tokenStorage.saveToken('active_bearer_token');
      final client = buildMockClient((req) {
        expect(req.method, equals('DELETE'));
        expect(req.path, equals('/api/v1/session'));
        expect(req.headers['Authorization'], equals('Bearer active_bearer_token'));
        return const ApiResponse(statusCode: 204, body: {});
      });

      final repo = AuthRepository(apiClient: client, tokenStorage: tokenStorage);
      await repo.logout();

      expect(await tokenStorage.readToken(), isNull);
    });

    test('requestPasswordReset validates email and calls POST /api/v1/passwords [REQ-AUTH-003]', () async {
      final client = buildMockClient((req) {
        expect(req.path, equals('/api/v1/passwords'));
        return const ApiResponse(
          statusCode: 200,
          body: {'message': 'Instructions sent'},
        );
      });

      final repo = AuthRepository(apiClient: client, tokenStorage: tokenStorage);
      final msg = await repo.requestPasswordReset('Nata@example.com');
      expect(msg, equals('Instructions sent'));
    });

    test('softDeleteAccount and restoreAccount handle 30-day account lifecycle [REQ-LIFE-002]', () async {
      await tokenStorage.saveToken('token_to_delete');
      final client = buildMockClient((req) {
        if (req.path == '/api/v1/account' && req.method == 'DELETE') {
          return const ApiResponse(statusCode: 204, body: {});
        }
        if (req.path == '/api/v1/account/restore' && req.method == 'POST') {
          return const ApiResponse(
            statusCode: 200,
            body: {
              'token': 'restored_token_999',
              'user': {
                'id': 7,
                'username': 'ceci_nata',
                'created_at': '2026-11-25T10:00:00Z',
              },
            },
          );
        }
        return const ApiResponse(statusCode: 404, body: {});
      });

      final repo = AuthRepository(apiClient: client, tokenStorage: tokenStorage);
      await repo.softDeleteAccount();
      expect(await tokenStorage.readToken(), isNull);

      final restored = await repo.restoreAccount(
        rawEmail: 'nata@example.com',
        password: 'Password123!',
      );
      expect(restored.username.value, equals('ceci_nata'));
      expect(await tokenStorage.readToken(), equals('restored_token_999'));
    });
  });
}
