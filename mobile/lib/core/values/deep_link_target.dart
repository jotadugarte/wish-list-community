import 'package:wish_list_mobile/core/values/domain_values.dart';

// DeepLinkTarget VO: friend profile + secret link + activity link.
// Traceability: [REQ-WISH-005], [REQ-SOC-001], [REQ-MOB-001], [REQ-ACT-001]
enum DeepLinkKind { friendProfile, secretLink, activityLink, unsupported }

class DeepLinkTarget {
  final DeepLinkKind kind;
  final UsernameVo? username;
  final ShareTokenVo? shareToken;
  final ShareTokenVo? activityToken;

  const DeepLinkTarget._({
    required this.kind,
    this.username,
    this.shareToken,
    this.activityToken,
  });

  factory DeepLinkTarget.parse(Uri uri) {
    final path = uri.path;

    final activity = RegExp(r'^/a/([A-Za-z0-9\-_]+)/?$').firstMatch(path);
    if (activity != null) {
      try {
        return DeepLinkTarget._(
          kind: DeepLinkKind.activityLink,
          activityToken: ShareTokenVo(activity.group(1)!),
        );
      } on ArgumentError {
        return const DeepLinkTarget._(kind: DeepLinkKind.unsupported);
      }
    }

    final secret = RegExp(r'^/s/([A-Za-z0-9\-_]+)/?$').firstMatch(path);
    if (secret != null) {
      try {
        return DeepLinkTarget._(
          kind: DeepLinkKind.secretLink,
          shareToken: ShareTokenVo(secret.group(1)!),
        );
      } on ArgumentError {
        return const DeepLinkTarget._(kind: DeepLinkKind.unsupported);
      }
    }

    // Friend profile: only /u/:username or /@:username (never bare paths).
    final profile = RegExp(r'^/(?:u/|@)([a-z0-9_]{3,30})/?$', caseSensitive: false)
        .firstMatch(path);
    if (profile != null) {
      try {
        return DeepLinkTarget._(
          kind: DeepLinkKind.friendProfile,
          username: UsernameVo(profile.group(1)!),
        );
      } on ArgumentError {
        return const DeepLinkTarget._(kind: DeepLinkKind.unsupported);
      }
    }

    return const DeepLinkTarget._(kind: DeepLinkKind.unsupported);
  }

  bool get isSupported => kind != DeepLinkKind.unsupported;
}
