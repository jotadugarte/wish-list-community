// Domain Value Objects enforcing Correct-by-Construction invariants in the
// Flutter mobile client before network calls.
// Traceability: [REQ-USER-001], [REQ-USER-004], [REQ-AUTH-001], [REQ-SOC-001], [REQ-DISC-001]

class EmailAddressVo {
  static const int maxLength = 254;
  static final RegExp _formatRegex = RegExp(
    r'^[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}$',
  );

  final String value;

  // [REQ-USER-001] [REQ-AUTH-001] Pre-condition: rawEmail must be non-empty, <= 254 chars, and RFC-valid.
  // Post-condition: value is lowercase and trimmed.
  factory EmailAddressVo(String rawEmail) {
    final normalized = rawEmail.trim().toLowerCase();
    if (normalized.isEmpty || normalized.length > maxLength) {
      throw ArgumentError('Email length must be between 1 and $maxLength');
    }
    if (!_formatRegex.hasMatch(normalized)) {
      throw ArgumentError('Email format is invalid');
    }
    final vo = EmailAddressVo._(normalized);
    if (vo.value.isEmpty) {
      throw StateError('Post-condition failed: email value must be non-empty');
    }
    return vo;
  }

  const EmailAddressVo._(this.value);

  // [REQ-USER-001] Prevents accidental PII email leakage in mobile console logs.
  @override
  String toString() => '[REDACTED_EMAIL]';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmailAddressVo && other.value == value);

  @override
  int get hashCode => value.hashCode;
}

class UsernameVo {
  static const int minLength = 3;
  static const int maxLength = 30;
  static final RegExp _formatRegex = RegExp(r'^[a-z0-9_]+$');
  static const Set<String> reservedWords = {
    'admin',
    'api',
    'login',
    'logout',
    'signup',
    'wishlists',
    'settings',
    'support',
    'discover',
    'activities',
    'notifications',
    'profile',
    'root',
    'system',
    'help',
  };

  final String value;

  // [REQ-USER-001] [REQ-USER-004] Pre-condition: rawUsername must be 3..30 chars, [a-z0-9_], and not reserved.
  // Post-condition: value is normalized without leading @.
  factory UsernameVo(String rawUsername) {
    final normalized = rawUsername
        .trim()
        .replaceFirst(RegExp(r'^@+'), '')
        .toLowerCase();
    if (normalized.length < minLength || normalized.length > maxLength) {
      throw ArgumentError(
        'Username length must be between $minLength and $maxLength',
      );
    }
    if (!_formatRegex.hasMatch(normalized)) {
      throw ArgumentError(
        'Username format only allows lowercase letters, numbers, and underscores',
      );
    }
    if (reservedWords.contains(normalized)) {
      throw ArgumentError("Username '$normalized' is a reserved word");
    }
    return UsernameVo._(normalized);
  }

  const UsernameVo._(this.value);

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UsernameVo && other.value == value);

  @override
  int get hashCode => value.hashCode;
}

class SearchQueryVo {
  static const int minLength = 2;
  static const int maxLength = 30;
  static final RegExp _formatRegex = RegExp(r'^[a-z0-9_.]+$');

  final String value;

  // [REQ-SOC-001] [REQ-WISH-001] Pre-condition: rawQuery must normalize to 2..30 safe handle characters.
  factory SearchQueryVo(String rawQuery) {
    final normalized = rawQuery
        .trim()
        .replaceFirst(RegExp(r'^@+'), '')
        .toLowerCase();
    if (normalized.length < minLength || normalized.length > maxLength) {
      throw ArgumentError(
        'Search query length must be between $minLength and $maxLength',
      );
    }
    if (!_formatRegex.hasMatch(normalized)) {
      throw ArgumentError(
        'Search query format only allows lowercase letters, numbers, underscores, and dots',
      );
    }
    return SearchQueryVo._(normalized);
  }

  const SearchQueryVo._(this.value);

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchQueryVo && other.value == value);

  @override
  int get hashCode => value.hashCode;
}

class ReportReasonVo {
  static const Set<String> allowedReasons = {
    'spam',
    'harassment',
    'impersonation',
    'inappropriate_content',
    'scam',
  };

  final String value;

  // [REQ-SOC-001] [REQ-DISC-001] Pre-condition: rawReason must belong to allowedReasons.
  factory ReportReasonVo(String rawReason) {
    final normalized = rawReason.trim().toLowerCase();
    if (!allowedReasons.contains(normalized)) {
      throw ArgumentError("Invalid report reason '$normalized'");
    }
    return ReportReasonVo._(normalized);
  }

  const ReportReasonVo._(this.value);

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReportReasonVo && other.value == value);

  @override
  int get hashCode => value.hashCode;
}
