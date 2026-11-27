// Gift models for Sprint 6 dual-path fulfillment.
// Traceability: [REQ-GIFT-001], [REQ-GIFT-004]
class GiftModel {
  final int id;
  final int itemId;
  final int? wishlistId;
  final int? gifterId;
  final String status;
  final String? thankYouNote;
  final String? itemTitle;
  final String? wishlistTitle;

  const GiftModel({
    required this.id,
    required this.itemId,
    required this.status,
    this.wishlistId,
    this.gifterId,
    this.thankYouNote,
    this.itemTitle,
    this.wishlistTitle,
  });

  factory GiftModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    if (rawId is! int) {
      throw ArgumentError('Pre-condition failed: gift id must be int');
    }
    return GiftModel(
      id: rawId,
      itemId: json['item_id'] as int? ?? 0,
      wishlistId: json['wishlist_id'] as int?,
      gifterId: json['gifter_id'] as int?,
      status: json['status'] as String? ?? 'purchased_secret',
      thankYouNote: json['thank_you_note'] as String?,
      itemTitle: json['item_title'] as String?,
      wishlistTitle: json['wishlist_title'] as String?,
    );
  }
}
