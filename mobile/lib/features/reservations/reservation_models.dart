// Reservation models for Sprint 5.
// Traceability: [REQ-RES-001], [REQ-RES-004]
class ReservationModel {
  final int id;
  final int itemId;
  final int? wishlistId;
  final int? activityId;
  final String status;
  final String estimatedDate;
  final String? privateNote;
  final String? itemTitle;
  final String? wishlistTitle;
  final bool warnEventDateExceeded;

  const ReservationModel({
    required this.id,
    required this.itemId,
    required this.status,
    required this.estimatedDate,
    this.wishlistId,
    this.activityId,
    this.privateNote,
    this.itemTitle,
    this.wishlistTitle,
    this.warnEventDateExceeded = false,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    if (rawId is! int) {
      throw ArgumentError('Pre-condition failed: reservation id must be int');
    }
    return ReservationModel(
      id: rawId,
      itemId: json['item_id'] as int? ?? 0,
      wishlistId: json['wishlist_id'] as int?,
      activityId: json['activity_id'] as int?,
      status: json['status'] as String? ?? 'active',
      estimatedDate: json['estimated_date'] as String? ?? '',
      privateNote: json['private_note'] as String?,
      itemTitle: json['item_title'] as String?,
      wishlistTitle: json['wishlist_title'] as String?,
      warnEventDateExceeded: json['warn_event_date_exceeded'] == true,
    );
  }
}
