import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/core/values/domain_values.dart';
import 'package:wish_list_mobile/features/auth/auth_repository.dart';
import 'package:wish_list_mobile/features/auth/profile_settings_screen.dart';
import 'package:wish_list_mobile/features/auth/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ProfileSettingsScreen shows bilingual legal links O8A/O13A', (
    tester,
  ) async {
    final storage = InMemoryTokenStorage();
    await storage.saveToken('t');
    final auth = AuthRepository(
      apiClient: ApiClient(
        baseUrl: 'https://api.wishlist.test',
        tokenStorage: storage,
        transport: (_) async => const ApiResponse(statusCode: 200, body: {}),
      ),
      tokenStorage: storage,
    );
    final opened = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileSettingsScreen(
            tokens: DesignTokens.forConfiguration(),
            strings: AppStrings.forLocale('es'),
            user: UserProfile(
              id: 1,
              email: EmailAddressVo('a@b.co'),
              username: UsernameVo('alice_user'),
              locale: 'es',
              timeZone: 'America/Costa_Rica',
            ),
            authRepository: auth,
            onSignedOut: () {},
            onOpenLegalUri: opened.add,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('legal_terms_link')), findsOneWidget);
    expect(find.byKey(const Key('legal_privacy_link')), findsOneWidget);
    expect(
      find.textContaining('staging.wishlist.local/terms'),
      findsOneWidget,
    );
    expect(
      find.textContaining('staging.wishlist.local/privacy'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('legal_terms_link')));
    await tester.pump();
    expect(opened.single.path, '/terms');
  });
}
