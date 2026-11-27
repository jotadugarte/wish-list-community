import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/config/public_host_config.dart';

void main() {
  group('PublicHostConfig O8A/O9B/O13A', () {
    test('terms and privacy URIs use staging host with locale', () {
      final terms = PublicHostConfig.termsUri(locale: 'es');
      expect(terms.host, 'staging.wishlist.local');
      expect(terms.path, '/terms');
      expect(terms.queryParameters['locale'], 'es');

      final privacy = PublicHostConfig.privacyUri(locale: 'en');
      expect(privacy.path, '/privacy');
      expect(privacy.queryParameters['locale'], 'en');
    });

    test('allowedDeepLinkHosts includes staging host', () {
      expect(PublicHostConfig.allowedDeepLinkHosts, contains('staging.wishlist.local'));
    });
  });
}
