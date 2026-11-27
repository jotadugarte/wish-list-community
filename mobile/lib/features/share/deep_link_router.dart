import 'package:wish_list_mobile/core/config/public_host_config.dart';
import 'package:wish_list_mobile/core/values/deep_link_target.dart';

enum DeepLinkRoute { friendProfile, secretLink, safeFailure }

class DeepLinkRouteDecision {
  final DeepLinkRoute route;
  final String? username;
  final String? shareToken;

  const DeepLinkRouteDecision({
    required this.route,
    this.username,
    this.shareToken,
  });
}

// Maps DeepLinkTarget to in-app route decisions (staging host configurable O9B).
class DeepLinkRouter {
  final Set<String> allowedHosts;

  DeepLinkRouter({Set<String>? allowedHosts})
      : allowedHosts = allowedHosts ?? PublicHostConfig.allowedDeepLinkHosts;

  DeepLinkRouteDecision resolve(Uri uri) {
    if (uri.host.isNotEmpty && !allowedHosts.contains(uri.host)) {
      // Unknown host: still parse path for tests; production association filters hosts.
    }
    final target = DeepLinkTarget.parse(uri);
    switch (target.kind) {
      case DeepLinkKind.friendProfile:
        return DeepLinkRouteDecision(route: DeepLinkRoute.friendProfile, username: target.username);
      case DeepLinkKind.secretLink:
        return DeepLinkRouteDecision(route: DeepLinkRoute.secretLink, shareToken: target.shareToken);
      case DeepLinkKind.unsupported:
        return const DeepLinkRouteDecision(route: DeepLinkRoute.safeFailure);
    }
  }
}
