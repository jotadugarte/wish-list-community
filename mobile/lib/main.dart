import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/api_config.dart';
import 'package:wish_list_mobile/core/network/secure_token_storage.dart';
import 'package:wish_list_mobile/core/theme/app_navigation_shell.dart';
import 'package:wish_list_mobile/core/theme/app_theme.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/core/values/share_payload.dart';
import 'package:wish_list_mobile/features/auth/auth_repository.dart';
import 'package:wish_list_mobile/features/auth/login_screen.dart';
import 'package:wish_list_mobile/features/auth/profile_settings_screen.dart';
import 'package:wish_list_mobile/features/items/item_form_screen.dart';
import 'package:wish_list_mobile/features/items/item_repository.dart';
import 'package:wish_list_mobile/features/notifications/notification_repository.dart';
import 'package:wish_list_mobile/features/notifications/push_registration.dart';
import 'package:wish_list_mobile/features/share/deep_link_router.dart';
import 'package:wish_list_mobile/features/share/inbound_link_bootstrap.dart';
import 'package:wish_list_mobile/features/share/last_wishlist_memory.dart';
import 'package:wish_list_mobile/features/share/share_intent_coordinator.dart';
import 'package:wish_list_mobile/features/share/share_intent_source.dart';
import 'package:wish_list_mobile/features/social/friends_list_screen.dart';
import 'package:wish_list_mobile/features/social/social_repository.dart';
import 'package:wish_list_mobile/features/social/user_search_screen.dart';
import 'package:wish_list_mobile/features/wishlists/friend_wishlists_screen.dart';
import 'package:wish_list_mobile/features/wishlists/my_wishlists_screen.dart';
import 'package:wish_list_mobile/features/wishlists/shared_wishlists_screen.dart';
import 'package:wish_list_mobile/features/wishlists/wishlist_repository.dart';
import 'package:wish_list_mobile/features/gifts/gift_repository.dart';
import 'package:wish_list_mobile/features/reservations/reservation_repository.dart';

// Entry point for Wish List Community mobile app (iOS & Android).
// Run with: flutter run --dart-define=API_BASE_URL=https://your-server
// Traceability: [REQ-ARCH-001], [REQ-AUTH-001], [REQ-SOC-001], [REQ-WISH-001], [REQ-USER-002], [REQ-MOB-001]
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = SecureTokenStorage(store: FlutterKeyValueStore());
  final apiClient = ApiClient(
    baseUrl: resolveApiBaseUrl(
      override: const String.fromEnvironment('API_BASE_URL'),
      platform: defaultTargetPlatform,
      isRelease: kReleaseMode,
    ),
    tokenStorage: tokenStorage,
  );
  final authRepo = AuthRepository(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );
  final socialRepo = SocialRepository(apiClient: apiClient);
  final wishlistRepo = WishlistRepository(apiClient: apiClient);
  final reservationRepo = ReservationRepository(apiClient: apiClient);
  final giftRepo = GiftRepository(apiClient: apiClient);
  final notificationRepo = NotificationRepository(apiClient: apiClient);
  final pushRegistration = PushRegistration(
    tokenSource: FirebasePushTokenSource(),
    bindSession: (token) => authRepo.bindDeviceToken(fcmToken: token),
    // Server unbind happens on DELETE /session; local token cleared in unregisterOnLogout.
    clearSession: () async {},
  );
  final prefs = await SharedPreferences.getInstance();
  final lastWishlistMemory = LastWishlistMemory(prefs);
  final shareCoordinator = ShareIntentCoordinator(
    memory: lastWishlistMemory,
    isLoggedIn: () => false, // replaced once WishListApp mounts
    loadOwnedWishlistIds: () async => {},
  );

  runApp(
    WishListApp(
      tokens: DesignTokens.forConfiguration(),
      authRepository: authRepo,
      socialRepository: socialRepo,
      wishlistRepository: wishlistRepo,
      reservationRepository: reservationRepo,
      giftRepository: giftRepo,
      notificationRepository: notificationRepo,
      pushRegistration: pushRegistration,
      shareCoordinator: shareCoordinator,
      shareIntentSource: ReceiveSharingIntentSource(),
      deepLinkRouter: DeepLinkRouter(),
      appLinks: AppLinks(),
    ),
  );
}

class WishListApp extends StatefulWidget {
  final DesignTokens tokens;
  final AuthRepository authRepository;
  final SocialRepository socialRepository;
  final WishlistRepository wishlistRepository;
  final ReservationRepository reservationRepository;
  final GiftRepository giftRepository;
  final NotificationRepository notificationRepository;
  final PushRegistration pushRegistration;
  final ShareIntentCoordinator shareCoordinator;
  final ShareIntentSource shareIntentSource;
  final DeepLinkRouter deepLinkRouter;
  final AppLinks? appLinks;

  const WishListApp({
    super.key,
    required this.tokens,
    required this.authRepository,
    required this.socialRepository,
    required this.wishlistRepository,
    required this.reservationRepository,
    required this.giftRepository,
    required this.notificationRepository,
    required this.pushRegistration,
    required this.shareCoordinator,
    required this.shareIntentSource,
    required this.deepLinkRouter,
    this.appLinks,
  });

  @override
  State<WishListApp> createState() => _WishListAppState();
}

class _WishListAppState extends State<WishListApp> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  UserProfile? _currentUser;
  int _selectedIndex = 0;
  bool _restoring = true;
  SharePayload? _pendingShare;
  String? _pendingFriendUsername;
  InboundLinkBootstrap? _inbound;

  @override
  void initState() {
    super.initState();
    widget.authRepository.apiClient.onUnauthorized = _handleSessionExpired;
    widget.shareCoordinator.isLoggedIn = () => _currentUser != null;
    widget.shareCoordinator.loadOwnedWishlistIds = _loadOwnedWishlistIds;
    _restoreSession();
    _startInbound();
  }

  @override
  void dispose() {
    widget.authRepository.apiClient.onUnauthorized = null;
    _inbound?.dispose();
    super.dispose();
  }

  Future<Set<int>> _loadOwnedWishlistIds() async {
    final lists = await widget.wishlistRepository.fetchMyWishlists();
    return {for (final w in lists) w.id};
  }

  Future<void> _startInbound() async {
    try {
      final bootstrap = InboundLinkBootstrap(
        shareSource: widget.shareIntentSource,
        shareCoordinator: widget.shareCoordinator,
        deepLinkRouter: widget.deepLinkRouter,
        appLinks: widget.appLinks,
        onShareDecision: _onShareDecision,
        onDeepLink: _onDeepLink,
      );
      _inbound = bootstrap;
      await bootstrap.start();
    } catch (_) {
      // Platform channels may be unavailable in tests / without plugins.
    }
  }

  void _handleSessionExpired() {
    if (!mounted) return;
    setState(() {
      _currentUser = null;
      _selectedIndex = 0;
    });
  }

  Future<void> _restoreSession() async {
    UserProfile? restored;
    try {
      final token = await widget.authRepository.tokenStorage.readToken();
      if (token != null) {
        restored = await widget.authRepository.fetchCurrentProfile();
      }
    } catch (_) {
      restored = null;
    }
    if (restored != null) {
      try {
        await widget.pushRegistration.registerAfterLogin();
      } catch (_) {
        // Push bind is best-effort; inbox/email still work (O10B).
      }
    }
    if (!mounted) return;
    setState(() {
      _currentUser = restored;
      _restoring = false;
    });
    if (restored != null) {
      _drainPendingInbound();
    } else {
      if (_pendingFriendUsername != null) {
        _snack(_strings.deepLinkRequireLoginSnack);
      }
      if (_pendingShare != null) {
        _snack(_strings.shareRequireLoginSnack);
      }
    }
  }

  AppStrings get _strings =>
      AppStrings.forLocale(_currentUser?.locale ?? 'es');

  Future<void> _openLegalUri(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      _snack(_strings.legalOpenFailedSnack);
    }
  }

  Future<void> _onShareDecision(ShareIntentDecision decision) async {
    final s = _strings;
    switch (decision.outcome) {
      case ShareIntentOutcome.requireLogin:
        _pendingShare = decision.payload;
        if (!_restoring) {
          _snack(s.shareRequireLoginSnack);
        }
      case ShareIntentOutcome.cannotParse:
        _snack(s.shareCannotParseSnack);
      case ShareIntentOutcome.skipPicker:
        if (_restoring || _currentUser == null) {
          _pendingShare = decision.payload;
          return;
        }
        final wishlistId = decision.wishlistId;
        if (wishlistId == null) {
          await _pickWishlistAndOpenForm(decision.payload);
          return;
        }
        await widget.shareCoordinator.rememberChosenWishlist(wishlistId);
        setState(() => _selectedIndex = 0);
        _snack(s.shareSkipPickerSnack);
        await _openShareItemForm(wishlistId: wishlistId, payload: decision.payload);
      case ShareIntentOutcome.showPicker:
        if (_restoring || _currentUser == null) {
          _pendingShare = decision.payload;
          return;
        }
        setState(() => _selectedIndex = 0);
        _snack(s.shareShowPickerSnack);
        await _pickWishlistAndOpenForm(decision.payload);
    }
  }

  Future<void> _pickWishlistAndOpenForm(SharePayload payload) async {
    if (!payload.canOpenAddItem) return;
    final lists = await widget.wishlistRepository.fetchMyWishlists();
    if (!mounted) return;
    if (lists.isEmpty) {
      _snack(_strings.shareNoWishlistsSnack);
      setState(() => _selectedIndex = 0);
      return;
    }
    final nav = _navKey.currentState;
    if (nav == null) return;
    final chosen = await showDialog<WishlistShell>(
      context: nav.context,
      builder: (dialogCtx) {
        final s = _strings;
        return SimpleDialog(
          title: Text(s.sharePickWishlistTitle),
          children: [
            for (final list in lists)
              SimpleDialogOption(
                onPressed: () => Navigator.of(dialogCtx).pop(list),
                child: Text(list.title),
              ),
          ],
        );
      },
    );
    if (chosen == null || !mounted) return;
    await widget.shareCoordinator.rememberChosenWishlist(chosen.id);
    await _openShareItemForm(wishlistId: chosen.id, payload: payload);
  }

  Future<void> _openShareItemForm({
    required int wishlistId,
    required SharePayload payload,
  }) async {
    final nav = _navKey.currentState;
    if (nav == null || !payload.canOpenAddItem) return;
    final s = _strings;
    await nav.push<bool>(
      MaterialPageRoute(
        builder: (_) => ItemFormScreen(
          tokens: widget.tokens,
          strings: s,
          itemRepository: ItemRepository(apiClient: widget.authRepository.apiClient),
          wishlistId: wishlistId,
          initialStoreUrl: payload.url?.toString(),
          initialTitle: payload.titleHint.isEmpty ? null : payload.titleHint,
        ),
      ),
    );
  }

  Future<void> _onDeepLink(DeepLinkRouteDecision decision) async {
    switch (decision.route) {
      case DeepLinkRoute.friendProfile:
        final username = decision.username;
        if (username == null || username.isEmpty) return;
        if (_restoring || _currentUser == null) {
          _pendingFriendUsername = username;
          if (!_restoring) {
            _snack(_strings.deepLinkRequireLoginSnack);
          }
          return;
        }
        await _openFriendWishlists(username);
      case DeepLinkRoute.secretLink:
        final host = widget.deepLinkRouter.allowedHosts.first;
        final uri = Uri.https(host, '/s/${decision.shareToken}');
        await _openLegalUri(uri);
      case DeepLinkRoute.safeFailure:
        _snack(_strings.deepLinkUnsupportedSnack);
    }
  }

  Future<void> _openFriendWishlists(String username) async {
    setState(() => _selectedIndex = 2);
    final nav = _navKey.currentState;
    if (nav == null) return;
    await nav.push<void>(
      MaterialPageRoute(
        builder: (_) => FriendWishlistsScreen(
          tokens: widget.tokens,
          strings: _strings,
          wishlistRepository: widget.wishlistRepository,
          reservationRepository: widget.reservationRepository,
          giftRepository: widget.giftRepository,
          username: username,
        ),
      ),
    );
  }

  void _snack(String message) {
    final ctx = _navKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message)));
  }

  void _drainPendingInbound() {
    final pendingFriend = _pendingFriendUsername;
    if (pendingFriend != null && pendingFriend.isNotEmpty) {
      _pendingFriendUsername = null;
      unawaited(_openFriendWishlists(pendingFriend));
    }
    final pending = _pendingShare;
    if (pending == null || !pending.canOpenAddItem) return;
    _pendingShare = null;
    final raw = '${pending.url} ${pending.titleHint}'.trim();
    unawaited(
      widget.shareCoordinator.handleSharedText(raw).then(_onShareDecision).catchError((_) {
        _pendingShare = pending;
        if (mounted) {
          _snack(_strings.genericError);
        }
      }),
    );
  }

  void _onAuthenticated(UserProfile profile) {
    setState(() => _currentUser = profile);
    _navKey.currentState?.popUntil((route) => route.isFirst);
    unawaited(widget.pushRegistration.registerAfterLogin().catchError((_) => null));
    _drainPendingInbound();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final s = AppStrings.forLocale(_currentUser?.locale ?? 'es');

    // Keep a stable MaterialApp + navigatorKey (needed for share/legal snackbars).
    // Do not also put a changing ValueKey on MaterialApp — that fights GlobalKey.
    return MaterialApp(
      navigatorKey: _navKey,
      title: t.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(t),
      home: _buildHome(t, s),
    );
  }

  Widget _buildHome(DesignTokens t, AppStrings s) {
    if (_restoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_currentUser == null) {
      return LoginScreen(
        tokens: t,
        strings: s,
        authRepository: widget.authRepository,
        resolveFcmToken: () => widget.pushRegistration.tokenSource.getToken(),
        onAuthenticated: _onAuthenticated,
      );
    }
    return AppNavigationShell(
      tokens: t,
      currentIndex: _selectedIndex,
      onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
      appBar: AppBar(title: Text(t.appName)),
      items: [
        AppNavDestination(icon: Icons.card_giftcard_outlined, label: s.navWishlists),
        AppNavDestination(icon: Icons.share_outlined, label: s.navShared),
        AppNavDestination(icon: Icons.people_outline, label: s.navFriends),
        AppNavDestination(icon: Icons.search, label: s.navSearch),
        AppNavDestination(icon: Icons.person_outline, label: s.navProfile),
      ],
      body: _buildActiveScreen(s),
    );
  }

  Widget _buildActiveScreen(AppStrings s) {
    switch (_selectedIndex) {
      case 0:
        return MyWishlistsScreen(
          tokens: widget.tokens,
          strings: s,
          wishlistRepository: widget.wishlistRepository,
          reservationRepository: widget.reservationRepository,
          giftRepository: widget.giftRepository,
        );
      case 1:
        return SharedWishlistsScreen(
          tokens: widget.tokens,
          strings: s,
          wishlistRepository: widget.wishlistRepository,
          reservationRepository: widget.reservationRepository,
          giftRepository: widget.giftRepository,
        );
      case 2:
        return FriendsListScreen(
          tokens: widget.tokens,
          strings: s,
          socialRepository: widget.socialRepository,
          wishlistRepository: widget.wishlistRepository,
          reservationRepository: widget.reservationRepository,
          giftRepository: widget.giftRepository,
        );
      case 3:
        return UserSearchScreen(
          tokens: widget.tokens,
          strings: s,
          socialRepository: widget.socialRepository,
        );
      case 4:
      default:
        return ProfileSettingsScreen(
          tokens: widget.tokens,
          strings: s,
          user: _currentUser!,
          authRepository: widget.authRepository,
          notificationRepository: widget.notificationRepository,
          onOpenLegalUri: _openLegalUri,
          onSignedOut: () async {
            await widget.pushRegistration.unregisterOnLogout();
            if (!mounted) return;
            setState(() {
              _currentUser = null;
              _selectedIndex = 0;
            });
            _navKey.currentState?.popUntil((route) => route.isFirst);
          },
        );
    }
  }
}
