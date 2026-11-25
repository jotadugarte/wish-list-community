import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';

// Minimal key/value abstraction so SecureTokenStorage is testable without platform channels.
abstract class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

// Production store backed by iOS Keychain / Android Keystore.
class FlutterKeyValueStore implements KeyValueStore {
  final FlutterSecureStorage _storage;

  FlutterKeyValueStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

// Persists the raw /api/v1 Bearer token in the platform secure store so the session
// survives app restarts. Only the token is stored, never the password.
// Traceability: [REQ-AUTH-001], [REQ-NOTIF-002]
class SecureTokenStorage implements TokenStorage {
  static const String tokenKey = 'wish_list_api_bearer_token';

  final KeyValueStore store;

  SecureTokenStorage({required this.store});

  @override
  Future<String?> readToken() async {
    final value = await store.read(tokenKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  // [REQ-AUTH-001] Pre-condition: rawToken must be non-empty.
  @override
  Future<void> saveToken(String rawToken) async {
    final trimmed = rawToken.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Pre-condition failed: token cannot be empty');
    }
    await store.write(tokenKey, trimmed);
  }

  @override
  Future<void> clearToken() => store.delete(tokenKey);
}
