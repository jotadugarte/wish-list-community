// Branded enums for activity domain values.
// Traceability: [REQ-ACT-001], [REQ-ACT-005]

enum ActivityAssignmentMode {
  secretSanta('secret_santa'),
  openGifting('open_gifting');

  final String apiValue;
  const ActivityAssignmentMode(this.apiValue);

  static ActivityAssignmentMode parse(String raw) {
    return ActivityAssignmentMode.values.firstWhere(
      (mode) => mode.apiValue == raw,
      orElse: () => throw ArgumentError('Invalid assignment_mode: $raw'),
    );
  }
}

enum ActivityLifecycleStatus {
  open('open'),
  sealed('sealed'),
  cancelled('cancelled');

  final String apiValue;
  const ActivityLifecycleStatus(this.apiValue);

  static ActivityLifecycleStatus parse(String raw) {
    return ActivityLifecycleStatus.values.firstWhere(
      (status) => status.apiValue == raw,
      orElse: () => throw ArgumentError('Invalid activity status: $raw'),
    );
  }
}

enum ActivityBudgetMode {
  none('none'),
  fixed('fixed'),
  minOnly('min_only'),
  maxOnly('max_only'),
  range('range');

  final String apiValue;
  const ActivityBudgetMode(this.apiValue);

  static ActivityBudgetMode parse(String raw) {
    return ActivityBudgetMode.values.firstWhere(
      (mode) => mode.apiValue == raw,
      orElse: () => throw ArgumentError('Invalid budget_mode: $raw'),
    );
  }
}
