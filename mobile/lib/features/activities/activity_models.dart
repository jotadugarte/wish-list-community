import 'package:wish_list_mobile/features/activities/activity_enums.dart';

// Activity shell models for Sprint A Flutter parity.
// Traceability: [REQ-ACT-001], [REQ-ACT-005]
class ActivityShell {
  final int id;
  final String name;
  final String currency;
  final ActivityAssignmentMode assignmentMode;
  final ActivityVisibilityMode visibilityMode;
  final ActivityReservationVisibility reservationVisibility;
  final ActivityBudgetMode budgetMode;
  final int? budgetAmountCents;
  final int? budgetMaxCents;
  final ActivityLifecycleStatus status;
  final String? shareToken;
  final bool needsDropoutRecovery;
  final String? creatorUsername;
  final ActivityViewerStatus? viewerStatus;
  final bool viewerCanManage;

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
    this.viewerCanManage = false,
  });

  factory ActivityShell.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'];
    return ActivityShell(
      id: json['id'] as int,
      name: json['name'] as String,
      currency: json['currency'] as String,
      assignmentMode: ActivityAssignmentMode.parse(
        json['assignment_mode'] as String,
      ),
      visibilityMode: ActivityVisibilityMode.parse(
        json['visibility_mode'] as String,
      ),
      reservationVisibility: ActivityReservationVisibility.parse(
        json['reservation_visibility'] as String,
      ),
      budgetMode: ActivityBudgetMode.parse(json['budget_mode'] as String),
      budgetAmountCents: json['budget_amount_cents'] as int?,
      budgetMaxCents: json['budget_max_cents'] as int?,
      status: ActivityLifecycleStatus.parse(json['status'] as String),
      shareToken: json['share_token'] as String?,
      needsDropoutRecovery: json['needs_dropout_recovery'] == true,
      creatorUsername: creator is Map<String, dynamic>
          ? creator['username'] as String?
          : null,
      viewerStatus: ActivityViewerStatus.tryParse(
        json['viewer_status'] as String?,
      ),
      viewerCanManage: json['viewer_can_manage'] == true,
    );
  }

  bool get isSecretSanta =>
      assignmentMode == ActivityAssignmentMode.secretSanta;
  bool get isOpenGifting =>
      assignmentMode == ActivityAssignmentMode.openGifting;
  bool get isSealed => status == ActivityLifecycleStatus.sealed;
  bool get isInvited => viewerStatus == ActivityViewerStatus.invited;
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

// Activity-scoped wishlist shell (FC1A / FC4A — no Secret Link).
// Traceability: [REQ-ACT-001], [REQ-ARCH-002], [REQ-MOB-001]
class ActivityWishlistView {
  final int id;
  final int activityId;
  final String title;
  final String? ownerUsername;
  final int? ownerId;
  final bool viewerIsOwner;
  final String? shareToken;
  final int? maxReservationsPerUser;

  const ActivityWishlistView({
    required this.id,
    required this.activityId,
    required this.title,
    this.ownerUsername,
    this.ownerId,
    this.viewerIsOwner = false,
    this.shareToken,
    this.maxReservationsPerUser,
  });

  factory ActivityWishlistView.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'];
    return ActivityWishlistView(
      id: json['id'] as int,
      activityId: json['activity_id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      ownerUsername: owner is Map<String, dynamic>
          ? owner['username'] as String?
          : null,
      ownerId: owner is Map<String, dynamic> ? owner['id'] as int? : null,
      viewerIsOwner: json['viewer_is_owner'] == true,
      shareToken: json['share_token'] as String?,
      maxReservationsPerUser: json['max_reservations_per_user'] as int?,
    );
  }
}
