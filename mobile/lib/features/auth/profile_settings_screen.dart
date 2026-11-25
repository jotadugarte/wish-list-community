import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/app_icon_badge.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/auth/auth_repository.dart';

// Profile screen displaying public @username, logout action, and 30-day soft-delete account action.
// Traceability: [REQ-USER-001], [REQ-USER-002], [REQ-AUTH-001], [REQ-LIFE-002]
class ProfileSettingsScreen extends StatelessWidget {
  final DesignTokens tokens;
  final AppStrings strings;
  final UserProfile user;
  final AuthRepository authRepository;
  final VoidCallback onSignedOut;

  const ProfileSettingsScreen({
    super.key,
    required this.tokens,
    required this.strings,
    required this.user,
    required this.authRepository,
    required this.onSignedOut,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: AppIconBadge(icon: Icons.person, tokens: tokens),
            title: Text('@${user.username.value}'),
            subtitle: Text('Idioma: ${user.locale} • Zona: ${user.timeZone}'),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          key: const Key('logout_button'),
          onPressed: () async {
            await authRepository.logout();
            onSignedOut();
          },
          child: Text(strings.signOutButton),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const Key('soft_delete_account_button'),
          onPressed: () async {
            await authRepository.softDeleteAccount();
            onSignedOut();
          },
          child: Text(strings.softDeleteAccountButton),
        ),
      ],
    );
  }
}
