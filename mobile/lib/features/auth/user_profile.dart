import 'package:wish_list_mobile/core/values/domain_values.dart';

// Immutable model representing an authenticated user's profile from /api/v1.
// Traceability: [REQ-USER-001], [REQ-USER-002], [REQ-USER-003]
class UserProfile {
  final int id;
  final UsernameVo username;
  final EmailAddressVo? email;
  final String locale;
  final String timeZone;

  const UserProfile({
    required this.id,
    required this.username,
    this.email,
    this.locale = 'es',
    this.timeZone = 'UTC',
  });

  // [REQ-USER-001] Parses user JSON from /api/v1/session or /api/v1/me using Value Objects.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    if (rawId is! int) {
      throw ArgumentError('Pre-condition failed: user id must be int');
    }
    final rawEmail = json['email_address'] as String?;
    return UserProfile(
      id: rawId,
      username: UsernameVo(json['username'] as String),
      email: (rawEmail != null && rawEmail.isNotEmpty)
          ? EmailAddressVo(rawEmail)
          : null,
      locale: (json['locale'] as String?) ?? 'es',
      timeZone: (json['time_zone'] as String?) ?? 'UTC',
    );
  }
}
