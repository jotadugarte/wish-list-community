// DeepLinkTarget VO: friend profile + secret link only in Sprint 9 (O3A).
// Traceability: [REQ-WISH-005], [REQ-SOC-001]
enum DeepLinkKind { friendProfile, secretLink, unsupported }

class DeepLinkTarget {
  final DeepLinkKind kind;
  final String? username;
  final String? shareToken;

  const DeepLinkTarget._({
    required this.kind,
    this.username,
    this.shareToken,
  });

  factory DeepLinkTarget.parse(Uri uri) {
    final path = uri.path;

    final secret = RegExp(r'^/s/([A-Za-z0-9\-_]+)/?$').firstMatch(path);
    if (secret != null) {
      return DeepLinkTarget._(kind: DeepLinkKind.secretLink, shareToken: secret.group(1));
    }

    // Friend profile: only /u/:username or /@:username (never bare paths).
    final profile = RegExp(r'^/(?:u/|@)([a-z0-9_]{3,30})/?$', caseSensitive: false)
        .firstMatch(path);
    if (profile != null) {
      final name = profile.group(1)!.toLowerCase();
      if (!_reserved.contains(name)) {
        return DeepLinkTarget._(kind: DeepLinkKind.friendProfile, username: name);
      }
    }

    // Activity and unknown paths are unsupported in S9.
    return const DeepLinkTarget._(kind: DeepLinkKind.unsupported);
  }

  static const _reserved = {
    'admin',
    'api',
    'login',
    'logout',
    'signup',
    'wishlists',
    'settings',
    'support',
    'discover',
    'activities',
    'notifications',
    'app',
    'terms',
    'privacy',
  };

  bool get isSupported => kind != DeepLinkKind.unsupported;
}
