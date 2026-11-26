import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/network/api_config.dart';
import 'package:wish_list_mobile/core/network/secure_token_storage.dart';

class _FakeKeyValueStore implements KeyValueStore {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);
}

void main() {
  group('SecureTokenStorage [REQ-AUTH-001]', () {
    test('persists, reads, and clears the bearer token through the secure store [REQ-AUTH-001]', () async {
      final fake = _FakeKeyValueStore();
      final storage = SecureTokenStorage(store: fake);

      expect(await storage.readToken(), isNull);
      await storage.saveToken('  secret_token  ');
      expect(await storage.readToken(), equals('secret_token'));
      expect(fake.data[SecureTokenStorage.tokenKey], equals('secret_token'));

      await storage.clearToken();
      expect(await storage.readToken(), isNull);
    });

    test('rejects empty tokens [REQ-AUTH-001]', () async {
      final storage = SecureTokenStorage(store: _FakeKeyValueStore());
      expect(() => storage.saveToken('   '), throwsArgumentError);
    });
  });

  group('resolveApiBaseUrl [REQ-ARCH-001]', () {
    test('uses per-platform development defaults when no override is given [REQ-ARCH-001]', () {
      expect(
        resolveApiBaseUrl(override: '', platform: TargetPlatform.android),
        equals('http://10.0.2.2:3000'),
      );
      expect(
        resolveApiBaseUrl(override: '', platform: TargetPlatform.iOS),
        equals('http://localhost:3000'),
      );
    });

    test('honours the override and strips a trailing slash [REQ-ARCH-001]', () {
      expect(
        resolveApiBaseUrl(
          override: 'https://api.example.com/',
          platform: TargetPlatform.android,
        ),
        equals('https://api.example.com'),
      );
    });

    test(
      'rejects invalid URLs and plain http in release builds [REQ-ARCH-001]',
      () {
        expect(
          () => resolveApiBaseUrl(
            override: 'not a url',
            platform: TargetPlatform.iOS,
          ),
          throwsArgumentError,
        );
        expect(
          () => resolveApiBaseUrl(
            override: 'http://api.example.com',
            platform: TargetPlatform.iOS,
            isRelease: true,
          ),
          throwsStateError,
        );
        expect(
          resolveApiBaseUrl(
            override: 'https://api.example.com',
            platform: TargetPlatform.iOS,
            isRelease: true,
          ),
          equals('https://api.example.com'),
        );
      },
    );
  });
}
