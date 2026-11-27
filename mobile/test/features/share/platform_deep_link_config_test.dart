import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Platform deep-link config for app_links [REQ-WISH-005]', () {
    test('iOS disables Flutter built-in deep linking', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(
        plist,
        contains(
          '<key>FlutterDeepLinkingEnabled</key>\n\t<false/>',
        ),
      );
      expect(plist, isNot(contains(
        '<key>FlutterDeepLinkingEnabled</key>\n\t<true/>',
      )));
      expect(plist, contains('<string>wishlist</string>'));
    });

    test('Android disables Flutter built-in deep linking and registers wishlist scheme', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(
        manifest,
        contains('android:name="flutter_deeplinking_enabled"'),
      );
      expect(manifest, contains('android:value="false"'));
      expect(manifest, contains('android:scheme="wishlist"'));
      expect(manifest, contains('android:host="u"'));
      expect(manifest, contains('android:host="s"'));
    });
  });
}
