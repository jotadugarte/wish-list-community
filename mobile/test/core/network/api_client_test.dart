import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';

void main() {
  group('ApiClient resilience [REQ-AUTH-001] [REQ-ARCH-003]', () {
    late InMemoryTokenStorage storage;

    setUp(() async {
      storage = InMemoryTokenStorage();
      await storage.saveToken('active_token');
    });

    ApiClient clientWith(ApiTransport transport) => ApiClient(
      baseUrl: 'https://api.test',
      tokenStorage: storage,
      requestTimeout: const Duration(milliseconds: 50),
      transport: transport,
    );

    test('401 on an authenticated request clears the token and notifies onUnauthorized [REQ-AUTH-001]', () async {
      var notified = 0;
      final client = clientWith(
        (_) async =>
            const ApiResponse(statusCode: 401, body: {'error': 'Unauthorized'}),
      )..onUnauthorized = () => notified++;

      await expectLater(
        client.request(method: 'GET', path: '/api/v1/me'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isUnauthorized,
            'isUnauthorized',
            true,
          ),
        ),
      );
      expect(await storage.readToken(), isNull);
      expect(notified, equals(1));
    });

    test('401 on an unauthenticated request (login) does not clear the token [REQ-AUTH-001]', () async {
      var notified = 0;
      final client = clientWith(
        (_) async => const ApiResponse(
          statusCode: 401,
          body: {'error': 'Invalid credentials'},
        ),
      )..onUnauthorized = () => notified++;

      await expectLater(
        client.request(
          method: 'POST',
          path: '/api/v1/session',
          authenticated: false,
          body: const {'email_address': 'a@b.co', 'password': 'x'},
        ),
        throwsA(isA<ApiException>()),
      );
      expect(await storage.readToken(), equals('active_token'));
      expect(notified, equals(0));
    });

    test('a request that never completes fails with a network ApiException after requestTimeout [REQ-ARCH-001]', () async {
      final client = clientWith((_) => Completer<ApiResponse>().future);

      await expectLater(
        client.request(method: 'GET', path: '/api/v1/me'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isNetworkError,
            'isNetworkError',
            true,
          ),
        ),
      );
    });

    test(
      'SocketException is mapped to a network ApiException [REQ-ARCH-001]',
      () async {
        final client = clientWith(
          (_) async => throw const SocketException('Network is unreachable'),
        );

        await expectLater(
          client.request(method: 'GET', path: '/api/v1/me'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.isNetworkError,
              'isNetworkError',
              true,
            ),
          ),
        );
      },
    );

    test('rejects paths outside /api/v1/ [REQ-ARCH-001]', () async {
      final client = clientWith(
        (_) async => const ApiResponse(statusCode: 200, body: {}),
      );
      expect(
        () => client.request(method: 'GET', path: '/admin/secret'),
        throwsArgumentError,
      );
    });
  });
}
