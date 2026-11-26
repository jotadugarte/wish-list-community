import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/app_icon_badge.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/auth/auth_repository.dart';

// 30-day soft-delete account restore form powered by AuthRepository.
// Traceability: [REQ-LIFE-002], [REQ-USER-002]
class AccountRestoreScreen extends StatefulWidget {
  final DesignTokens tokens;
  final AppStrings strings;
  final AuthRepository authRepository;
  final ValueChanged<UserProfile> onRestored;

  const AccountRestoreScreen({
    super.key,
    required this.tokens,
    required this.strings,
    required this.authRepository,
    required this.onRestored,
  });

  @override
  State<AccountRestoreScreen> createState() => _AccountRestoreScreenState();
}

class _AccountRestoreScreenState extends State<AccountRestoreScreen> {
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

  // [REQ-LIFE-002] Restores a soft-deleted account and signs the user back in.
  Future<void> _submitRestore() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await widget.authRepository.restoreAccount(
        rawEmail: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        widget.onRestored(profile);
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
                  const SizedBox(height: 8),
                  Text(s.accountRestoreSubtitle),
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
        AppIconBadge(icon: Icons.restore, tokens: t),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            s.accountRestoreTitle,
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
        key: const Key('restore_email_field'),
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(labelText: s.emailLabel),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const Key('restore_password_field'),
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
        key: const Key('restore_submit_button'),
        onPressed: _isLoading ? null : _submitRestore,
        child: Text(
          _isLoading
              ? s.accountRestoreSubmittingButton
              : s.accountRestoreSubmitButton,
        ),
      ),
    ];
  }
}
