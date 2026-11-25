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

  // Runs a session-ending action; on failure keeps the user signed in and shows a
  // friendly localized message instead of an unhandled async exception.
  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      onSignedOut();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(strings.errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: AppIconBadge(icon: Icons.person, tokens: tokens),
            title: Text('@${user.username.value}'),
            subtitle: Text(
              '${strings.languageLabel}: ${user.locale} • '
              '${strings.timeZoneLabel}: ${user.timeZone}',
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          key: const Key('logout_button'),
          onPressed: () => _run(context, authRepository.logout),
          child: Text(strings.signOutButton),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const Key('soft_delete_account_button'),
          onPressed: () => _run(context, authRepository.softDeleteAccount),
          child: Text(strings.softDeleteAccountButton),
        ),
      ],
    );
  }
}
