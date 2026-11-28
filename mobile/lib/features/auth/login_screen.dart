import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/app_icon_badge.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/auth/account_restore_screen.dart';
import 'package:wish_list_mobile/features/auth/auth_repository.dart';
import 'package:wish_list_mobile/features/auth/password_reset_screen.dart';
import 'package:wish_list_mobile/features/auth/sign_up_screen.dart';

// Login screen powered by DesignTokens, AppStrings, and AuthRepository.
// Traceability: [REQ-AUTH-001], [REQ-AUTH-003], [REQ-LIFE-002], [REQ-USER-002]
class LoginScreen extends StatefulWidget {
  final DesignTokens tokens;
  final AppStrings strings;
  final AuthRepository authRepository;
  final ValueChanged<UserProfile> onAuthenticated;
  final Future<String?> Function()? resolveFcmToken;

  const LoginScreen({
    super.key,
    required this.tokens,
    required this.strings,
    required this.authRepository,
    required this.onAuthenticated,
    this.resolveFcmToken,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // [REQ-AUTH-001] Validates credentials via EmailAddressVo and submits login.
  Future<void> _submitLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final fcmToken = await widget.resolveFcmToken?.call();
      final profile = await widget.authRepository.login(
        rawEmail: _emailController.text,
        password: _passwordController.text,
        fcmToken: fcmToken,
      );
      if (mounted) {
        widget.onAuthenticated(profile);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = widget.strings.errorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // [REQ-AUTH-002] Opens the registration screen with mandatory terms acceptance.
  void _openSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SignUpScreen(
          tokens: widget.tokens,
          strings: widget.strings,
          authRepository: widget.authRepository,
          resolveFcmToken: widget.resolveFcmToken,
          onRegistered: (profile) {
            Navigator.of(context).pop();
            widget.onAuthenticated(profile);
          },
        ),
      ),
    );
  }

  // [REQ-AUTH-003] Opens the anti-enumeration password reset screen.
  void _openPasswordReset() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PasswordResetScreen(
          tokens: widget.tokens,
          strings: widget.strings,
          authRepository: widget.authRepository,
        ),
      ),
    );
  }

  // [REQ-LIFE-002] Opens the 30-day account restore screen.
  void _openAccountRestore() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccountRestoreScreen(
          tokens: widget.tokens,
          strings: widget.strings,
          authRepository: widget.authRepository,
          onRestored: widget.onAuthenticated,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    return Scaffold(
      appBar: AppBar(title: Text(t.appName)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(t),
                  const SizedBox(height: 16),
                  ..._buildFormFields(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(DesignTokens t) {
    return Row(
      children: [
        AppIconBadge(icon: Icons.card_giftcard, tokens: t),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.strings.signInTitle,
            style: TextStyle(
              fontFamily: t.headingFontFamily,
              fontWeight: t.headingWeight,
              fontSize: 20,
              color: t.text,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFormFields() {
    final s = widget.strings;
    return [
      TextField(
        key: const Key('login_email_field'),
        controller: _emailController,
        decoration: InputDecoration(labelText: s.emailLabel),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('login_password_field'),
        controller: _passwordController,
        obscureText: true,
        decoration: InputDecoration(labelText: s.passwordLabel),
      ),
      if (_errorMessage != null) ...[
        const SizedBox(height: 12),
        Text(_errorMessage!, style: const TextStyle(color: Color(0xFFD9383A))),
      ],
      const SizedBox(height: 20),
      ElevatedButton(
        key: const Key('login_submit_button'),
        onPressed: _isLoading ? null : _submitLogin,
        child: Text(_isLoading ? s.signingInButton : s.signInButton),
      ),
      TextButton(
        key: const Key('signup_link'),
        onPressed: _openSignUp,
        child: Text(s.signUpLink),
      ),
      TextButton(
        key: const Key('forgot_password_link'),
        onPressed: _openPasswordReset,
        child: Text(s.forgotPasswordLink),
      ),
      TextButton(
        key: const Key('restore_account_link'),
        onPressed: _openAccountRestore,
        child: Text(s.restoreAccountLink),
      ),
    ];
  }
}
