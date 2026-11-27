import 'package:firebase_messaging/firebase_messaging.dart';

// FCM register-after-login / clear-on-logout (O6A/O10B). Graceful when keys missing.
// Traceability: [REQ-NOTIF-002]
abstract class PushTokenSource {
  Future<String?> getToken();
  Future<void> deleteToken();
}

class FirebasePushTokenSource implements PushTokenSource {
  @override
  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      // Keys missing / unsupported platform — inbox+email still work (O10B).
      return null;
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // ignore
    }
  }
}

class FakePushTokenSource implements PushTokenSource {
  String? token;
  FakePushTokenSource([this.token]);

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> deleteToken() async {
    token = null;
  }
}

class PushRegistration {
  final PushTokenSource tokenSource;
  final Future<void> Function(String? fcmToken) bindSession;
  final Future<void> Function() clearSession;

  PushRegistration({
    required this.tokenSource,
    required this.bindSession,
    required this.clearSession,
  });

  // [REQ-NOTIF-002] After login/signup, bind fcm_token when available.
  Future<String?> registerAfterLogin() async {
    final token = await tokenSource.getToken();
    await bindSession(token);
    return token;
  }

  // [REQ-NOTIF-002] On logout, delete local push token and clear API session binding.
  Future<void> unregisterOnLogout() async {
    await tokenSource.deleteToken();
    await clearSession();
  }
}
