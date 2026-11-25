import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/theme/app_icon_badge.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/auth/auth_repository.dart';

// Login screen powered by DesignTokens and AuthRepository.
// Traceability: [REQ-AUTH-001], [REQ-AUTH-003], [REQ-LIFE-002]
class LoginScreen extends StatefulWidget {
  final DesignTokens tokens;
  final AuthRepository authRepository;
  final ValueChanged<UserProfile> onAuthenticated;

  const LoginScreen({
    super.key,
    required this.tokens,
    required this.authRepository,
    required this.onAuthenticated,
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
      final profile = await widget.authRepository.login(
        rawEmail: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        widget.onAuthenticated(profile);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
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
                  Row(
                    children: [
                      AppIconBadge(icon: Icons.card_giftcard, tokens: t),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontFamily: t.headingFontFamily,
                            fontWeight: t.headingWeight,
                            fontSize: 20,
                            color: t.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('login_email_field'),
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('login_password_field'),
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFD9383A)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    key: const Key('login_submit_button'),
                    onPressed: _isLoading ? null : _submitLogin,
                    child: Text(_isLoading ? 'Ingresando...' : 'Entrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
