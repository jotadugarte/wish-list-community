import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/features/notifications/push_registration.dart';

void main() {
  group('PushRegistration O6A/O10B [REQ-NOTIF-002]', () {
    test('registerAfterLogin passes fcm token to session binder', () async {
      String? bound;
      final push = PushRegistration(
        tokenSource: FakePushTokenSource('fcm-abc'),
        bindSession: (t) async => bound = t,
        clearSession: () async {},
      );
      final token = await push.registerAfterLogin();
      expect(token, 'fcm-abc');
      expect(bound, 'fcm-abc');
    });

    test('registerAfterLogin is graceful when token missing', () async {
      String? bound = 'unset';
      final push = PushRegistration(
        tokenSource: FakePushTokenSource(null),
        bindSession: (t) async => bound = t,
        clearSession: () async {},
      );
      final token = await push.registerAfterLogin();
      expect(token, isNull);
      expect(bound, isNull);
    });

    test('unregisterOnLogout clears token and session', () async {
      var cleared = false;
      final source = FakePushTokenSource('fcm-xyz');
      final push = PushRegistration(
        tokenSource: source,
        bindSession: (_) async {},
        clearSession: () async => cleared = true,
      );
      await push.unregisterOnLogout();
      expect(source.token, isNull);
      expect(cleared, isTrue);
    });
  });
}
