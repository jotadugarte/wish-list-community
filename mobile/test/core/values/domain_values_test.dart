import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/values/domain_values.dart';

void main() {
  group('EmailAddressVo [REQ-USER-001] [REQ-AUTH-001]', () {
    test('normalizes valid email and redacts toString() [REQ-USER-001]', () {
      final email = EmailAddressVo('  Nata.Ceci@Example.COM  ');
      expect(email.value, equals('nata.ceci@example.com'));
      expect(email.toString(), equals('[REDACTED_EMAIL]'));
      expect(email, equals(EmailAddressVo('nata.ceci@example.com')));
    });

    test('rejects malformed or empty emails [REQ-AUTH-001]', () {
      expect(() => EmailAddressVo(''), throwsArgumentError);
      expect(() => EmailAddressVo('not-an-email'), throwsArgumentError);
      expect(
        () => EmailAddressVo('${'a' * 250}@example.com'),
        throwsArgumentError,
      );
    });
  });

  group('UsernameVo [REQ-USER-001] [REQ-USER-004]', () {
    test('normalizes valid @username handle [REQ-USER-001]', () {
      final username = UsernameVo('  @Ceci_Nata24  ');
      expect(username.value, equals('ceci_nata24'));
      expect(username.toString(), equals('ceci_nata24'));
      expect(username, equals(UsernameVo('ceci_nata24')));
    });

    test(
      'rejects short, long, invalid format, or reserved words [REQ-USER-001]',
      () {
        expect(() => UsernameVo('ab'), throwsArgumentError);
        expect(() => UsernameVo('a' * 31), throwsArgumentError);
        expect(() => UsernameVo('bad-handle!'), throwsArgumentError);
        expect(() => UsernameVo('admin'), throwsArgumentError);
        expect(() => UsernameVo('api'), throwsArgumentError);
      },
    );
  });

  group('SearchQueryVo [REQ-SOC-001] [REQ-WISH-001]', () {
    test('normalizes valid search query prefix [REQ-SOC-001]', () {
      final query = SearchQueryVo('  @Nata_24  ');
      expect(query.value, equals('nata_24'));
      expect(query.toString(), equals('nata_24'));
      expect(query, equals(SearchQueryVo('nata_24')));
    });

    test('rejects queries shorter than 2 chars or with invalid symbols [REQ-SOC-001]', () {
      expect(() => SearchQueryVo('a'), throwsArgumentError);
      expect(() => SearchQueryVo('@a'), throwsArgumentError);
      expect(() => SearchQueryVo('a' * 31), throwsArgumentError);
      expect(() => SearchQueryVo('nata%drop'), throwsArgumentError);
    });
  });

  group('ReportReasonVo [REQ-SOC-001] [REQ-DISC-001]', () {
    test(
      'normalizes and accepts all 5 allowed report reasons [REQ-DISC-001]',
      () {
        for (final raw in [
          'spam',
          'harassment',
          'impersonation',
          'inappropriate_content',
          'scam',
        ]) {
          final vo = ReportReasonVo('  ${raw.toUpperCase()}  ');
          expect(vo.value, equals(raw));
          expect(vo.toString(), equals(raw));
        }
      },
    );

    test('rejects unknown report reasons [REQ-DISC-001]', () {
      expect(() => ReportReasonVo(''), throwsArgumentError);
      expect(() => ReportReasonVo('random_reason'), throwsArgumentError);
    });
  });
}
