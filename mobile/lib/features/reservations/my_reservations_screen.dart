import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/gifts/gift_models.dart';
import 'package:wish_list_mobile/features/gifts/gift_repository.dart';
import 'package:wish_list_mobile/features/reservations/reservation_models.dart';
import 'package:wish_list_mobile/features/reservations/reservation_repository.dart';

// My Reservations + open gifts dashboard (Sprint 5/6).
// Traceability: [REQ-RES-004], [REQ-GIFT-001]
class MyReservationsScreen extends StatefulWidget {
  final DesignTokens tokens;
  final AppStrings strings;
  final ReservationRepository reservationRepository;
  final GiftRepository? giftRepository;

  const MyReservationsScreen({
    super.key,
    required this.tokens,
    required this.strings,
    required this.reservationRepository,
    this.giftRepository,
  });

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  List<ReservationModel> _rows = const [];
  List<GiftModel> _gifts = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bundle =
          await widget.reservationRepository.fetchMineWithOpenGifts();
      if (mounted) {
        setState(() {
          _rows = bundle.reservations;
          _gifts = bundle.openGifts;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = widget.strings.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel(ReservationModel row) async {
    try {
      await widget.reservationRepository.cancel(reservationId: row.id);
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = widget.strings.errorMessage(e));
    }
  }

  Future<void> _markPurchased(ReservationModel row) async {
    final gifts = widget.giftRepository;
    if (gifts == null) return;
    try {
      await gifts.markPurchased(reservationId: row.id);
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = widget.strings.errorMessage(e));
    }
  }

  Future<void> _markDelivered(GiftModel gift) async {
    final gifts = widget.giftRepository;
    if (gifts == null) return;
    try {
      await gifts.markDelivered(giftId: gift.id);
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = widget.strings.errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.myReservationsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Text(_error!, style: TextStyle(color: widget.tokens.accent)),
                  if (_rows.isEmpty && _gifts.isEmpty) Text(s.noReservationsYet),
                  for (final row in _rows)
                    ListTile(
                      title: Text(row.itemTitle ?? '#${row.itemId}'),
                      subtitle: Text(
                        '${row.wishlistTitle ?? ''} · ${row.status} · ${row.estimatedDate}',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          TextButton(
                            onPressed: () => _markPurchased(row),
                            child: Text(s.markPurchasedButton),
                          ),
                          TextButton(
                            onPressed: () => _cancel(row),
                            child: Text(s.cancelReservationButton),
                          ),
                        ],
                      ),
                    ),
                  for (final gift in _gifts)
                    ListTile(
                      title: Text(gift.itemTitle ?? '#${gift.itemId}'),
                      subtitle: Text(
                        '${gift.wishlistTitle ?? ''} · ${gift.status}',
                      ),
                      trailing: gift.status == 'purchased_secret'
                          ? TextButton(
                              onPressed: () => _markDelivered(gift),
                              child: Text(s.markDeliveredButton),
                            )
                          : null,
                    ),
                ],
              ),
            ),
    );
  }
}
