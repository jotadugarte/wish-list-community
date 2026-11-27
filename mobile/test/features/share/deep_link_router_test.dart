import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/features/share/deep_link_router.dart';

void main() {
  group('DeepLinkRouter O3A/O9B', () {
    final router = DeepLinkRouter(allowedHosts: {'staging.example'});

    test('routes friend profile', () {
      final d = router.resolve(Uri.parse('https://staging.example/u/bob_user'));
      expect(d.route, DeepLinkRoute.friendProfile);
      expect(d.username, 'bob_user');
    });

    test('routes secret link', () {
      final d = router.resolve(Uri.parse('https://staging.example/s/tok_1'));
      expect(d.route, DeepLinkRoute.secretLink);
      expect(d.shareToken, 'tok_1');
    });

    test('safe failure for unsupported', () {
      final d = router.resolve(Uri.parse('https://staging.example/activities/1'));
      expect(d.route, DeepLinkRoute.safeFailure);
    });

    test('safe failure for unknown host', () {
      final d = router.resolve(Uri.parse('https://evil.example/u/bob_user'));
      expect(d.route, DeepLinkRoute.safeFailure);
    });
  });
}
