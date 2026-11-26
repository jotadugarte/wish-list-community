import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/app_icon_badge.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/auth/auth_repository.dart';

// Registration screen with mandatory UGC terms acceptance.
// Traceability: [REQ-AUTH-001], [REQ-AUTH-002], [REQ-USER-001], [REQ-USER-002]
class SignUpScreen extends StatefulWidget {
  final DesignTokens tokens;
  final AppStrings strings;
  final AuthRepository authRepository;
  final ValueChanged<UserProfile> onRegistered;

  const SignUpScreen({
    super.key,
    required this.tokens,
    required this.strings,
    required this.authRepository,
    required this.onRegistered,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _termsAccepted = false;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // [REQ-AUTH-002] Submits registration only when terms are accepted.
  Future<void> _submitSignUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await widget.authRepository.signUp(
        rawEmail: _emailController.text,
        rawUsername: _usernameController.text,
        password: _passwordController.text,
        locale: widget.strings.locale,
        timeZone: 'UTC',
        termsAccepted: _termsAccepted,
      );
      if (mounted) {
        widget.onRegistered(profile);
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

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final s = widget.strings;
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
                  _buildHeader(t, s),
                  const SizedBox(height: 16),
                  ..._buildFormFields(s),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(DesignTokens t, AppStrings s) {
    return Row(
      children: [
        AppIconBadge(icon: Icons.person_add_alt_1, tokens: t),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            s.signUpTitle,
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

  List<Widget> _buildFormFields(AppStrings s) {
    return [
      TextField(
        key: const Key('signup_email_field'),
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(labelText: s.emailLabel),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('signup_username_field'),
        controller: _usernameController,
        decoration: InputDecoration(labelText: s.usernameLabel),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('signup_password_field'),
        controller: _passwordController,
        obscureText: true,
        decoration: InputDecoration(labelText: s.passwordLabel),
      ),
      const SizedBox(height: 12),
      CheckboxListTile(
        key: const Key('signup_terms_checkbox'),
        value: _termsAccepted,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(s.termsAcceptedLabel),
        onChanged: (value) {
          setState(() => _termsAccepted = value == true);
        },
      ),
      if (_errorMessage != null) ...[
        const SizedBox(height: 12),
        Text(_errorMessage!, style: const TextStyle(color: Color(0xFFD9383A))),
      ],
      const SizedBox(height: 20),
      ElevatedButton(
        key: const Key('signup_submit_button'),
        onPressed: _isLoading ? null : _submitSignUp,
        child: Text(_isLoading ? s.signingUpButton : s.signUpButton),
      ),
    ];
  }
}
