import 'package:flutter/foundation.dart';

// Resolves the API base URL from the API_BASE_URL compile-time define, with safe
// per-platform development defaults (Android emulators reach the host via 10.0.2.2).
// Release builds must use HTTPS.
// Traceability: [REQ-ARCH-001], [REQ-AUTH-001]
String resolveApiBaseUrl({
  required String override,
  required TargetPlatform platform,
  bool isRelease = false,
}) {
  final trimmed = override.trim();
  final resolved = trimmed.isNotEmpty
      ? trimmed
      : (platform == TargetPlatform.android
            ? 'http://10.0.2.2:3000'
            : 'http://localhost:3000');

  final uri = Uri.tryParse(resolved);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw ArgumentError('API_BASE_URL is not a valid absolute URL: $resolved');
  }
  if (isRelease && uri.scheme != 'https') {
    throw StateError('Release builds must use an https API_BASE_URL');
  }
  return resolved.endsWith('/')
      ? resolved.substring(0, resolved.length - 1)
      : resolved;
}
