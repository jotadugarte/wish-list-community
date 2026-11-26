import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/features/gifts/gift_models.dart';

// Repository for dual-path gift fulfillment (Sprint 6).
// Traceability: [REQ-GIFT-001], [REQ-GIFT-003], [REQ-GIFT-004]
class GiftRepository {
  final ApiClient apiClient;

  const GiftRepository({required this.apiClient});

  // [REQ-GIFT-001] Path 1 mark purchased from an active/grace reservation.
  Future<GiftModel> markPurchased({
    required int reservationId,
    String? purchaseLinkRef,
  }) async {
    if (reservationId <= 0) {
      throw ArgumentError('Pre-condition failed: reservationId must be > 0');
    }
    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/reservations/$reservationId/mark_purchased',
      body: {
        'gift': {'purchase_link_ref': ?purchaseLinkRef},
      },
    );
    return GiftModel.fromJson(response.body['gift'] as Map<String, dynamic>);
  }

  // [REQ-GIFT-001] Path 1 mark delivered.
  Future<GiftModel> markDelivered({required int giftId}) async {
    if (giftId <= 0) {
      throw ArgumentError('Pre-condition failed: giftId must be > 0');
    }
    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/gifts/$giftId/mark_delivered',
    );
    return GiftModel.fromJson(response.body['gift'] as Map<String, dynamic>);
  }

  // [REQ-GIFT-001] [REQ-GIFT-004] Owner confirms delivery with optional thank-you.
  Future<GiftModel> confirmReceived({
    required int giftId,
    String? thankYouNote,
  }) async {
    if (giftId <= 0) {
      throw ArgumentError('Pre-condition failed: giftId must be > 0');
    }
    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/gifts/$giftId/confirm_received',
      body: {
        'gift': {'thank_you_note': ?thankYouNote},
      },
    );
    return GiftModel.fromJson(response.body['gift'] as Map<String, dynamic>);
  }

  // [REQ-GIFT-003] Path 2 owner mark received.
  Future<GiftModel> ownerMarkReceived({
    required int itemId,
    String? thankYouNote,
  }) async {
    if (itemId <= 0) {
      throw ArgumentError('Pre-condition failed: itemId must be > 0');
    }
    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/items/$itemId/mark_received',
      body: {
        'gift': {'thank_you_note': ?thankYouNote},
      },
    );
    return GiftModel.fromJson(response.body['gift'] as Map<String, dynamic>);
  }
}
