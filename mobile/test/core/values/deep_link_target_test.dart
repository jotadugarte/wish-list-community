import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/values/deep_link_target.dart';
import 'package:wish_list_mobile/core/values/domain_values.dart';

void main() {
  group('DeepLinkTarget [REQ-MOB-001] [REQ-WISH-005] O3A', () {
    const longToken = 'AbCdefghijklmnopqrstuv-1';

    test('parses friend profile path', () {
      final target = DeepLinkTarget.parse(Uri.parse('https://staging.example/u/alice_01'));
      expect(target.kind, DeepLinkKind.friendProfile);
      expect(target.username, UsernameVo('alice_01'));
    });

    test('parses secret link token', () {
      final target = DeepLinkTarget.parse(Uri.parse('https://staging.example/s/$longToken'));
      expect(target.kind, DeepLinkKind.secretLink);
      expect(target.shareToken, ShareTokenVo(longToken));
    });

    test('rejects short secret tokens as unsupported', () {
      expect(
        DeepLinkTarget.parse(Uri.parse('https://staging.example/s/short')).isSupported,
        isFalse,
      );
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
