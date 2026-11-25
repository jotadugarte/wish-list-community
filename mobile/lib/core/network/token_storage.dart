// Abstraction for storing and clearing the raw /api/v1 Bearer token on device.
// Traceability: [REQ-AUTH-001], [REQ-NOTIF-002]
abstract class TokenStorage {
  Future<String?> readToken();
  Future<void> saveToken(String rawToken);
  Future<void> clearToken();
}

// Deterministic in-memory token storage for fast unit/widget tests and default session state.
// Traceability: [REQ-AUTH-001]
class InMemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<String?> readToken() async => _token;

  // [REQ-AUTH-001] Pre-condition: rawToken must be non-empty.
  @override
  Future<void> saveToken(String rawToken) async {
    final trimmed = rawToken.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Pre-condition failed: token cannot be empty');
    }
    _token = trimmed;
  }

  @override
  Future<void> clearToken() async {
    _token = null;
  }
}
