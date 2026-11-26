import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/features/reservations/reservation_models.dart';

// Repository for secret reservations and My Reservations.
// Traceability: [REQ-RES-001], [REQ-RES-004], [REQ-RES-006]
class ReservationRepository {
  static const int maxList = 200;

  final ApiClient apiClient;

  const ReservationRepository({required this.apiClient});

  // [REQ-RES-001] Creates a reservation on an item.
  Future<ReservationModel> create({
    required int itemId,
    required String estimatedDate,
    String? privateNote,
  }) async {
    if (itemId <= 0) {
      throw ArgumentError('Pre-condition failed: itemId must be > 0');
    }
    final cleaned = estimatedDate.trim();
    if (cleaned.isEmpty) {
      throw ArgumentError('Pre-condition failed: estimatedDate required');
    }
    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/items/$itemId/reservations',
      body: {
        'reservation': {
          'estimated_date': cleaned,
          'private_note': ?privateNote,
        },
      },
    );
    return ReservationModel.fromJson(
      response.body['reservation'] as Map<String, dynamic>,
    );
  }

  // [REQ-RES-006] Extends estimated_date (and optional note).
  Future<ReservationModel> extend({
    required int reservationId,
    required String estimatedDate,
    String? privateNote,
  }) async {
    if (reservationId <= 0) {
      throw ArgumentError('Pre-condition failed: reservationId must be > 0');
    }
    final response = await apiClient.request(
      method: 'PATCH',
      path: '/api/v1/reservations/$reservationId',
      body: {
        'reservation': {
          'estimated_date': estimatedDate.trim(),
          'private_note': ?privateNote,
        },
      },
    );
    return ReservationModel.fromJson(
      response.body['reservation'] as Map<String, dynamic>,
    );
  }

  // [REQ-RES-001] Voluntary cancel.
  Future<void> cancel({required int reservationId}) async {
    if (reservationId <= 0) {
      throw ArgumentError('Pre-condition failed: reservationId must be > 0');
    }
    await apiClient.request(
      method: 'DELETE',
      path: '/api/v1/reservations/$reservationId',
    );
  }

  // [REQ-RES-004] Lists active/grace reservations for the current user.
  Future<List<ReservationModel>> fetchMine() async {
    final response = await apiClient.request(
      method: 'GET',
      path: '/api/v1/my_reservations',
    );
    final raw = response.body['reservations'] as List<dynamic>? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .take(maxList)
        .map(ReservationModel.fromJson)
        .toList(growable: false);
  }
}
