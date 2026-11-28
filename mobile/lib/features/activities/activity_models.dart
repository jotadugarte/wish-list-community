// Activity shell models for Sprint A Flutter parity.
// Traceability: [REQ-ACT-001], [REQ-ACT-005]
class ActivityShell {
  final int id;
  final String name;
  final String currency;
  final String assignmentMode;
  final String visibilityMode;
  final String reservationVisibility;
  final String budgetMode;
  final int? budgetAmountCents;
  final int? budgetMaxCents;
  final String status;
  final String? shareToken;
  final bool needsDropoutRecovery;
  final String? creatorUsername;
  final String? viewerStatus;

  const ActivityShell({
    required this.id,
    required this.name,
    required this.currency,
    required this.assignmentMode,
    required this.visibilityMode,
    required this.reservationVisibility,
    required this.budgetMode,
    required this.status,
    required this.needsDropoutRecovery,
    this.budgetAmountCents,
    this.budgetMaxCents,
    this.shareToken,
    this.creatorUsername,
    this.viewerStatus,
  });

  factory ActivityShell.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'];
    return ActivityShell(
      id: json['id'] as int,
      name: json['name'] as String,
      currency: json['currency'] as String,
      assignmentMode: json['assignment_mode'] as String,
      visibilityMode: json['visibility_mode'] as String,
      reservationVisibility: json['reservation_visibility'] as String,
      budgetMode: json['budget_mode'] as String,
      budgetAmountCents: json['budget_amount_cents'] as int?,
      budgetMaxCents: json['budget_max_cents'] as int?,
      status: json['status'] as String,
      shareToken: json['share_token'] as String?,
      needsDropoutRecovery: json['needs_dropout_recovery'] == true,
      creatorUsername: creator is Map<String, dynamic>
          ? creator['username'] as String?
          : null,
      viewerStatus: json['viewer_status'] as String?,
    );
  }

  bool get isSecretSanta => assignmentMode == 'secret_santa';
  bool get isOpenGifting => assignmentMode == 'open_gifting';
  bool get isSealed => status == 'sealed';
  bool get isInvited => viewerStatus == 'invited';
}

class ActivityAssignmentView {
  final int giverId;
  final int recipientId;
  final String? recipientUsername;

  const ActivityAssignmentView({
    required this.giverId,
    required this.recipientId,
    this.recipientUsername,
  });

  factory ActivityAssignmentView.fromJson(Map<String, dynamic> json) {
    final recipient = json['recipient'];
    return ActivityAssignmentView(
      giverId: json['giver_id'] as int,
      recipientId: json['recipient_id'] as int,
      recipientUsername: recipient is Map<String, dynamic>
          ? recipient['username'] as String?
          : null,
    );
  }
}
