import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/core/theme/app_navigation_shell.dart';
import 'package:wish_list_mobile/core/theme/app_theme.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/auth/auth_repository.dart';
import 'package:wish_list_mobile/features/auth/login_screen.dart';
import 'package:wish_list_mobile/features/auth/profile_settings_screen.dart';
import 'package:wish_list_mobile/features/social/friends_list_screen.dart';
import 'package:wish_list_mobile/features/social/social_repository.dart';
import 'package:wish_list_mobile/features/social/user_search_screen.dart';

// Entry point for Wish List Community mobile app (iOS & Android).
// Traceability: [REQ-ARCH-001], [REQ-AUTH-001], [REQ-SOC-001]
void main() {
  final tokenStorage = InMemoryTokenStorage();
  final apiClient = ApiClient(
    baseUrl: 'http://localhost:3000',
    tokenStorage: tokenStorage,
  );
  final authRepo = AuthRepository(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );
  final socialRepo = SocialRepository(apiClient: apiClient);

  runApp(
    WishListApp(
      tokens: DesignTokens.forConfiguration(),
      authRepository: authRepo,
      socialRepository: socialRepo,
    ),
  );
}

class WishListApp extends StatefulWidget {
  final DesignTokens tokens;
  final AuthRepository authRepository;
  final SocialRepository socialRepository;

  const WishListApp({
    super.key,
    required this.tokens,
    required this.authRepository,
    required this.socialRepository,
  });

  @override
  State<WishListApp> createState() => _WishListAppState();
}

class _WishListAppState extends State<WishListApp> {
  UserProfile? _currentUser;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    return MaterialApp(
      title: t.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(t),
      home: _currentUser == null
          ? LoginScreen(
              tokens: t,
              authRepository: widget.authRepository,
              onAuthenticated: (profile) =>
                  setState(() => _currentUser = profile),
            )
          : AppNavigationShell(
              tokens: t,
              currentIndex: _selectedIndex,
              onDestinationSelected: (idx) =>
                  setState(() => _selectedIndex = idx),
              appBar: AppBar(title: Text(t.appName)),
              items: const [
                AppNavDestination(icon: Icons.people_outline, label: 'Amigos'),
                AppNavDestination(icon: Icons.search, label: 'Buscar'),
                AppNavDestination(icon: Icons.person_outline, label: 'Perfil'),
              ],
              body: _buildActiveScreen(),
            ),
    );
  }

  Widget _buildActiveScreen() {
    switch (_selectedIndex) {
      case 0:
        return FriendsListScreen(
          tokens: widget.tokens,
          socialRepository: widget.socialRepository,
        );
      case 1:
        return UserSearchScreen(
          tokens: widget.tokens,
          socialRepository: widget.socialRepository,
        );
      case 2:
      default:
        return ProfileSettingsScreen(
          tokens: widget.tokens,
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
