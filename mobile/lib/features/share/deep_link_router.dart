import 'package:wish_list_mobile/core/config/public_host_config.dart';
import 'package:wish_list_mobile/core/values/deep_link_target.dart';
import 'package:wish_list_mobile/core/values/domain_values.dart';

enum DeepLinkRoute { friendProfile, secretLink, safeFailure }

class DeepLinkRouteDecision {
  final DeepLinkRoute route;
  final UsernameVo? username;
  final ShareTokenVo? shareToken;

  const DeepLinkRouteDecision({
    required this.route,
    this.username,
    this.shareToken,
  });
}

// Maps DeepLinkTarget to in-app route decisions (staging host configurable O9B).
// Traceability: [REQ-MOB-001], [REQ-WISH-005], [REQ-SOC-001]
class DeepLinkRouter {
  final Set<String> allowedHosts;

  DeepLinkRouter({Set<String>? allowedHosts})
      : allowedHosts = allowedHosts ?? PublicHostConfig.allowedDeepLinkHosts;

  DeepLinkRouteDecision resolve(Uri uri) {
    final normalized = normalizeCustomScheme(uri);
    // O9B: only configured public/staging hosts may open in-app routes.
    // Custom-scheme links are hostless after normalize (wishlist://u/… → /u/…).
    if (normalized.host.isNotEmpty &&
        !allowedHosts.contains(normalized.host.toLowerCase())) {
      return const DeepLinkRouteDecision(route: DeepLinkRoute.safeFailure);
    }
    final target = DeepLinkTarget.parse(normalized);
    switch (target.kind) {
      case DeepLinkKind.friendProfile:
        return DeepLinkRouteDecision(
          route: DeepLinkRoute.friendProfile,
          username: target.username,
        );
      case DeepLinkKind.secretLink:
        return DeepLinkRouteDecision(
          route: DeepLinkRoute.secretLink,
          shareToken: target.shareToken,
        );
      case DeepLinkKind.unsupported:
        return const DeepLinkRouteDecision(route: DeepLinkRoute.safeFailure);
    }
  }

  /// Maps `wishlist://u/alice` / `wishlist://s/tok` into path-style URIs
  /// (`/u/alice`, `/s/tok`) so host allowlisting does not treat `u`/`s` as hosts.
  static Uri normalizeCustomScheme(Uri uri) {
    if (uri.scheme.toLowerCase() != 'wishlist') return uri;
    final host = uri.host.toLowerCase();
    if (host != 'u' && host != 's') return uri;
    final tail = uri.pathSegments.where((s) => s.isNotEmpty).join('/');
    final path = tail.isEmpty ? '/$host' : '/$host/$tail';
    return Uri(scheme: 'wishlist', path: path);
  }
}
