import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/config/public_host_config.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/app_icon_badge.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/auth/auth_repository.dart';
import 'package:wish_list_mobile/features/notifications/inbox_screen.dart';
import 'package:wish_list_mobile/features/notifications/notification_prefs_screen.dart';
import 'package:wish_list_mobile/features/notifications/notification_repository.dart';

// Profile screen displaying public @username, logout action, and 30-day soft-delete account action.
// Traceability: [REQ-USER-001], [REQ-USER-002], [REQ-AUTH-001], [REQ-LIFE-002], [REQ-AUTH-002]
class ProfileSettingsScreen extends StatelessWidget {
  final DesignTokens tokens;
  final AppStrings strings;
  final UserProfile user;
  final AuthRepository authRepository;
  final Future<void> Function() onSignedOut;
  final NotificationRepository? notificationRepository;
  final void Function(Uri uri)? onOpenLegalUri;

  const ProfileSettingsScreen({
    super.key,
    required this.tokens,
    required this.strings,
    required this.user,
    required this.authRepository,
    required this.onSignedOut,
    this.notificationRepository,
    this.onOpenLegalUri,
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
      await onSignedOut();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(strings.errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _identityCard(),
        const SizedBox(height: 16),
        ..._notificationTiles(context),
        ..._legalTiles(),
        const SizedBox(height: 16),
        ..._sessionActions(context),
      ],
    );
  }

  Widget _identityCard() {
    return Card(
      child: ListTile(
        leading: AppIconBadge(icon: Icons.person, tokens: tokens),
        title: Text('@${user.username.value}'),
        subtitle: Text(
          '${strings.languageLabel}: ${user.locale} • '
          '${strings.timeZoneLabel}: ${user.timeZone}',
        ),
      ),
    );
  }

  List<Widget> _notificationTiles(BuildContext context) {
    final repo = notificationRepository;
    if (repo == null) return const [];
    return [
      ListTile(
        key: const Key('open_inbox'),
        leading: const Icon(Icons.notifications_outlined),
        title: Text(strings.inboxTitle),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(title: Text(strings.inboxTitle)),
                body: InboxScreen(
                  tokens: tokens,
                  strings: strings,
                  notificationRepository: repo,
                ),
              ),
            ),
          );
        },
      ),
      ListTile(
        key: const Key('open_notification_prefs'),
        leading: const Icon(Icons.tune),
        title: Text(strings.notificationPrefsTitle),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => NotificationPrefsScreen(
                tokens: tokens,
                strings: strings,
                notificationRepository: repo,
              ),
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _legalTiles() {
    return [
      ListTile(
        key: const Key('legal_terms_link'),
        leading: const Icon(Icons.description_outlined),
        title: Text(strings.termsLinkLabel),
        subtitle: Text(PublicHostConfig.termsUri(locale: strings.locale).toString()),
        onTap: () => onOpenLegalUri?.call(
          PublicHostConfig.termsUri(locale: strings.locale),
        ),
      ),
      ListTile(
        key: const Key('legal_privacy_link'),
        leading: const Icon(Icons.privacy_tip_outlined),
        title: Text(strings.privacyLinkLabel),
        subtitle: Text(
          PublicHostConfig.privacyUri(locale: strings.locale).toString(),
        ),
        onTap: () => onOpenLegalUri?.call(
          PublicHostConfig.privacyUri(locale: strings.locale),
        ),
      ),
    ];
  }

  List<Widget> _sessionActions(BuildContext context) {
    return [
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
    ];
  }
}
