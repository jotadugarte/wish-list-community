import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/values/deep_link_target.dart';

void main() {
  group('DeepLinkTarget O3A', () {
    test('parses friend profile path', () {
      final target = DeepLinkTarget.parse(Uri.parse('https://staging.example/u/alice_01'));
      expect(target.kind, DeepLinkKind.friendProfile);
      expect(target.username, 'alice_01');
    });

    test('parses secret link token', () {
      final target = DeepLinkTarget.parse(Uri.parse('https://staging.example/s/AbC-123_xy'));
      expect(target.kind, DeepLinkKind.secretLink);
      expect(target.shareToken, 'AbC-123_xy');
    });

    test('activity and unknown paths are unsupported', () {
      expect(
        DeepLinkTarget.parse(Uri.parse('https://staging.example/activities/9')).isSupported,
        isFalse,
      );
      expect(
        DeepLinkTarget.parse(Uri.parse('https://staging.example/unknown')).isSupported,
        isFalse,
      );
    });
  });
}
