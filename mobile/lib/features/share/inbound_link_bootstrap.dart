import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:wish_list_mobile/features/share/deep_link_router.dart';
import 'package:wish_list_mobile/features/share/share_intent_coordinator.dart';
import 'package:wish_list_mobile/features/share/share_intent_source.dart';

// Wires OS share intents + App Links into ShareIntentCoordinator / DeepLinkRouter.
// Traceability: [REQ-MOB-001], [REQ-MOB-002], [REQ-ITEM-006]
class InboundLinkBootstrap {
  final ShareIntentSource shareSource;
  final ShareIntentCoordinator shareCoordinator;
  final DeepLinkRouter deepLinkRouter;
  final Future<void> Function(ShareIntentDecision decision) onShareDecision;
  final Future<void> Function(DeepLinkRouteDecision decision) onDeepLink;
  final AppLinks? appLinks;

  StreamSubscription<String>? _shareSub;
  StreamSubscription<Uri>? _linkSub;

  InboundLinkBootstrap({
    required this.shareSource,
    required this.shareCoordinator,
    required this.deepLinkRouter,
    required this.onShareDecision,
    required this.onDeepLink,
    this.appLinks,
  });

  Future<void> start() async {
    await _handleInitialShare();
    _shareSub = shareSource.sharedTextStream.listen(_onSharedText);

    final links = appLinks;
    if (links != null) {
      final initial = await links.getInitialLink();
      if (initial != null) await _onUri(initial);
      _linkSub = links.uriLinkStream.listen(_onUri);
    }
  }

  Future<void> dispose() async {
    await _shareSub?.cancel();
    await _linkSub?.cancel();
  }

  Future<void> _handleInitialShare() async {
    final initial = await shareSource.getInitialSharedText();
    if (initial != null && initial.trim().isNotEmpty) {
      await _onSharedText(initial);
    }
  }

  Future<void> _onSharedText(String raw) async {
    final decision = await shareCoordinator.handleSharedText(raw);
    await onShareDecision(decision);
  }

  Future<void> _onUri(Uri uri) async {
    await onDeepLink(deepLinkRouter.resolve(uri));
  }
}
