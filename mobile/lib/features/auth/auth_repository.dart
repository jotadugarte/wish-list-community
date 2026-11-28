import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/core/values/domain_values.dart';
import 'package:wish_list_mobile/features/auth/user_profile.dart';

export 'package:wish_list_mobile/features/auth/user_profile.dart';

// Repository managing /api/v1 authentication, password reset, and 30-day account soft-delete/restore.
// Traceability: [REQ-AUTH-001], [REQ-AUTH-003], [REQ-LIFE-002], [REQ-NOTIF-002]
class AuthRepository {
  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  const AuthRepository({required this.apiClient, required this.tokenStorage});

  // [REQ-AUTH-001] [REQ-NOTIF-002] Authenticates via POST /api/v1/session and stores Bearer token.
  Future<UserProfile> login({
    required String rawEmail,
    required String password,
    String? deviceName,
    String? fcmToken,
  }) async {
    final emailVo = EmailAddressVo(rawEmail);
    if (password.isEmpty) {
      throw ArgumentError('Pre-condition failed: password cannot be empty');
    }

    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/session',
      authenticated: false,
      body: {
        'email_address': emailVo.value,
        'password': password,
        'device_name': ?deviceName,
        'device_token': ?fcmToken,
        'fcm_token': ?fcmToken,
      },
    );

    return _persistSession(response);
  }

  // [REQ-NOTIF-002] Binds FCM device_token to the current authenticated API session.
  Future<void> bindDeviceToken({String? fcmToken}) async {
    if (fcmToken == null || fcmToken.isEmpty) return;
    await apiClient.request(
      method: 'PATCH',
      path: '/api/v1/session',
      body: {
        'device_token': fcmToken,
        'fcm_token': fcmToken,
      },
    );
  }

  // [REQ-AUTH-001] [REQ-AUTH-002] Registers via POST /api/v1/signup with mandatory terms acceptance.
  Future<UserProfile> signUp({
    required String rawEmail,
    required String rawUsername,
    required String password,
    required String locale,
    required String timeZone,
    required bool termsAccepted,
    String? deviceName,
    String? fcmToken,
  }) async {
    if (!termsAccepted) {
      throw ArgumentError('Pre-condition failed: terms must be accepted');
    }
    if (password.isEmpty) {
      throw ArgumentError('Pre-condition failed: password cannot be empty');
    }

    final emailVo = EmailAddressVo(rawEmail);
    final usernameVo = UsernameVo(rawUsername);

    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/signup',
      authenticated: false,
      body: {
        'email_address': emailVo.value,
        'username': usernameVo.value,
        'password': password,
        'password_confirmation': password,
        'locale': locale,
        'time_zone': timeZone,
        'terms_accepted': true,
        'device_name': ?deviceName,
        'device_token': ?fcmToken,
        'fcm_token': ?fcmToken,
      },
    );

    return _persistSession(response);
  }

  Future<UserProfile> _persistSession(ApiResponse response) async {
    final token = response.body['token'] as String;
    await tokenStorage.saveToken(token);

    final saved = await tokenStorage.readToken();
    if (saved != token) {
      throw StateError('Post-condition failed: token must be stored');
    }

    return UserProfile.fromJson(response.body['user'] as Map<String, dynamic>);
  }

  // [REQ-AUTH-001] [REQ-NOTIF-002] Revokes API token and unbinds FCM device_token on server.
  Future<void> logout() async {
    try {
      await apiClient.request(method: 'DELETE', path: '/api/v1/session');
    } on ApiException catch (e) {
      // A 401 means the token is already invalid server-side; any other failure
      // (e.g. no network) is rethrown so the session is not silently kept alive.
      if (!e.isUnauthorized) rethrow;
    }
    await tokenStorage.clearToken();
    if (await tokenStorage.readToken() != null) {
      throw StateError(
        'Post-condition failed: token must be cleared on logout',
      );
    }
  }

  // [REQ-USER-001] Fetches the authenticated user's private profile via GET /api/v1/me.
  Future<UserProfile> fetchCurrentProfile() async {
    final response = await apiClient.request(method: 'GET', path: '/api/v1/me');
    return UserProfile.fromJson(response.body);
  }

  // [REQ-AUTH-003] Requests an anti-enumeration password reset via POST /api/v1/passwords.
  Future<String> requestPasswordReset(String rawEmail) async {
    final emailVo = EmailAddressVo(rawEmail);
    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/passwords',
      authenticated: false,
      body: {'email_address': emailVo.value},
    );
    return (response.body['message'] ?? '').toString();
  }

  // [REQ-LIFE-002] Soft-deletes the account via DELETE /api/v1/account and clears local token.
  Future<void> softDeleteAccount() async {
    await apiClient.request(method: 'DELETE', path: '/api/v1/account');
    await tokenStorage.clearToken();
  }

  // [REQ-LIFE-002] Restores a soft-deleted account within the 30-day grace window.
  Future<UserProfile> restoreAccount({
    required String rawEmail,
    required String password,
  }) async {
    final emailVo = EmailAddressVo(rawEmail);
    if (password.isEmpty) {
      throw ArgumentError('Pre-condition failed: password cannot be empty');
    }

    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/account/restore',
      authenticated: false,
      body: {'email_address': emailVo.value, 'password': password},
    );

    final token = response.body['token'] as String;
    await tokenStorage.saveToken(token);

    return UserProfile.fromJson(response.body['user'] as Map<String, dynamic>);
  }
}
