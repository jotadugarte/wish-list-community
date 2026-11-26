import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/app_icon_badge.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/auth/auth_repository.dart';

// Anti-enumeration password reset form powered by AuthRepository.
// Traceability: [REQ-AUTH-003], [REQ-USER-002]
class PasswordResetScreen extends StatefulWidget {
  final DesignTokens tokens;
  final AppStrings strings;
  final AuthRepository authRepository;

  const PasswordResetScreen({
    super.key,
    required this.tokens,
    required this.strings,
    required this.authRepository,
  });

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _emailController = TextEditingController();
  String? _errorMessage;
  String? _successMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // [REQ-AUTH-003] Submits email for a generic anti-enumeration reset response.
  Future<void> _submitReset() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      final message = await widget.authRepository.requestPasswordReset(
        _emailController.text,
      );
      if (mounted) {
        setState(() => _successMessage = message);
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
        AppIconBadge(icon: Icons.lock_reset, tokens: t),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            s.passwordResetTitle,
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
        key: const Key('password_reset_email_field'),
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(labelText: s.emailLabel),
      ),
      if (_errorMessage != null) ...[
        const SizedBox(height: 12),
        Text(_errorMessage!, style: const TextStyle(color: Color(0xFFD9383A))),
      ],
      if (_successMessage != null) ...[
        const SizedBox(height: 12),
        Text(_successMessage!),
      ],
      const SizedBox(height: 20),
      ElevatedButton(
        key: const Key('password_reset_submit_button'),
        onPressed: _isLoading ? null : _submitReset,
        child: Text(
          _isLoading ? s.passwordResetSubmittingButton : s.passwordResetSubmitButton,
        ),
      ),
    ];
  }
}
