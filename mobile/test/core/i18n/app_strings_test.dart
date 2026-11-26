import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';

void main() {
  group('AppStrings [REQ-USER-002]', () {
    test('resolves es by default and en when requested [REQ-USER-002]', () {
      expect(AppStrings.forLocale('es').navFriends, equals('Amigos'));
      expect(AppStrings.forLocale('EN').navFriends, equals('Friends'));
      expect(AppStrings.forLocale('fr').locale, equals('es'));
      expect(
        AppStrings.forLocale('es').forgotPasswordLink,
        equals('¿Olvidaste tu contraseña?'),
      );
      expect(
        AppStrings.forLocale('en').accountRestoreTitle,
        equals('Restore Account'),
      );
    });

    test('maps errors to friendly localized messages without leaking technical text [REQ-USER-002]', () {
      for (final locale in ['es', 'en']) {
        final s = AppStrings.forLocale(locale);
        expect(
          s.errorMessage(const ApiException(statusCode: 0, message: 'x')),
          equals(s.networkError),
        );
        expect(
          s.errorMessage(const ApiException(statusCode: 401, message: 'x')),
          equals(s.unauthorizedError),
        );
        expect(
          s.errorMessage(const ApiException(statusCode: 404, message: 'x')),
          equals(s.notFoundError),
        );
        expect(
          s.errorMessage(const ApiException(statusCode: 409, message: 'x')),
          equals(s.conflictError),
        );
        expect(
          s.errorMessage(const ApiException(statusCode: 422, message: 'x')),
          equals(s.invalidDataError),
        );
        expect(
          s.errorMessage(const ApiException(statusCode: 500, message: 'x')),
          equals(s.genericError),
        );
        expect(
          s.errorMessage(ArgumentError('bad')),
          equals(s.invalidInputError),
        );
        expect(s.errorMessage(StateError('boom')), equals(s.genericError));
      }
    });
  });
}
