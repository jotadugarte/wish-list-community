import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/api_config.dart';
import 'package:wish_list_mobile/core/network/secure_token_storage.dart';
import 'package:wish_list_mobile/core/theme/app_navigation_shell.dart';
import 'package:wish_list_mobile/core/theme/app_theme.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/auth/auth_repository.dart';
import 'package:wish_list_mobile/features/auth/login_screen.dart';
import 'package:wish_list_mobile/features/auth/profile_settings_screen.dart';
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
// Traceability: [REQ-ARCH-001], [REQ-AUTH-001], [REQ-SOC-001], [REQ-WISH-001], [REQ-USER-002]
void main() {
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

  runApp(
    WishListApp(
      tokens: DesignTokens.forConfiguration(),
      authRepository: authRepo,
      socialRepository: socialRepo,
      wishlistRepository: wishlistRepo,
      reservationRepository: reservationRepo,
      giftRepository: giftRepo,
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

  const WishListApp({
    super.key,
    required this.tokens,
    required this.authRepository,
    required this.socialRepository,
    required this.wishlistRepository,
    required this.reservationRepository,
    required this.giftRepository,
  });


  @override
  State<WishListApp> createState() => _WishListAppState();
}

class _WishListAppState extends State<WishListApp> {
  UserProfile? _currentUser;
  int _selectedIndex = 0;
  bool _restoring = true;

  @override
  void initState() {
    super.initState();
    widget.authRepository.apiClient.onUnauthorized = _handleSessionExpired;
    _restoreSession();
  }

  @override
  void dispose() {
    widget.authRepository.apiClient.onUnauthorized = null;
    super.dispose();
  }

  // [REQ-AUTH-001] A 401 from the server means the token expired or was revoked:
  // return the user to the login screen (the client already cleared the token).
  void _handleSessionExpired() {
    if (!mounted) return;
    setState(() {
      _currentUser = null;
      _selectedIndex = 0;
    });
  }

  // [REQ-AUTH-001] Restores the persisted session on app start via GET /api/v1/me.
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

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final s = AppStrings.forLocale(_currentUser?.locale ?? 'es');

    // ValueKey resets the navigator when auth state flips so pushed auth
    // routes (password reset / account restore) cannot outlive the session.
    return MaterialApp(
      key: ValueKey<String>(_currentUser == null ? 'signed_out' : 'signed_in'),
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
        onAuthenticated: (profile) => setState(() => _currentUser = profile),
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
          onSignedOut: () => setState(() {
            _currentUser = null;
            _selectedIndex = 0;
          }),
        );
    }
  }
}
