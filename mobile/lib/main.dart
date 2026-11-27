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
    bindSession: (_) async {},
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
    if (!mounted) return;
    setState(() {
      _currentUser = restored;
      _restoring = false;
    });
  }

  Future<void> _openLegalUri(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      _snack('Could not open ${uri.toString()}');
    }
  }

  Future<void> _onShareDecision(ShareIntentDecision decision) async {
    switch (decision.outcome) {
      case ShareIntentOutcome.requireLogin:
        _pendingShare = decision.payload;
        _snack('Sign in to add the shared link');
      case ShareIntentOutcome.cannotParse:
        _snack('No link found in shared text');
      case ShareIntentOutcome.skipPicker:
      case ShareIntentOutcome.showPicker:
        if (_currentUser == null) {
          _pendingShare = decision.payload;
          return;
        }
        if (decision.wishlistId != null) {
          await widget.shareCoordinator.rememberChosenWishlist(decision.wishlistId!);
        }
        setState(() => _selectedIndex = 0);
        _snack(
          decision.outcome == ShareIntentOutcome.skipPicker
              ? 'Shared link ready for your last list'
              : 'Shared link ready — pick a wishlist',
        );
    }
  }

  Future<void> _onDeepLink(DeepLinkRouteDecision decision) async {
    switch (decision.route) {
      case DeepLinkRoute.friendProfile:
        setState(() => _selectedIndex = 3);
        _snack('Open friend @${decision.username}');
      case DeepLinkRoute.secretLink:
        final host = widget.deepLinkRouter.allowedHosts.first;
        final uri = Uri.https(host, '/s/${decision.shareToken}');
        await _openLegalUri(uri);
      case DeepLinkRoute.safeFailure:
        _snack('This link is not supported in the app');
    }
  }

  void _snack(String message) {
    final ctx = _navKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onAuthenticated(UserProfile profile) {
    setState(() => _currentUser = profile);
    _navKey.currentState?.popUntil((route) => route.isFirst);
    final pending = _pendingShare;
    if (pending == null || !pending.canOpenAddItem) return;
    _pendingShare = null;
    final raw = '${pending.url} ${pending.titleHint}'.trim();
    widget.shareCoordinator.handleSharedText(raw).then(_onShareDecision);
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
