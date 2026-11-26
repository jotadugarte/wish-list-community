import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/reservations/reservation_models.dart';
import 'package:wish_list_mobile/features/reservations/reservation_repository.dart';

// My Reservations dashboard across wishlists.
// Traceability: [REQ-RES-004]
class MyReservationsScreen extends StatefulWidget {
  final DesignTokens tokens;
  final AppStrings strings;
  final ReservationRepository reservationRepository;

  const MyReservationsScreen({
    super.key,
    required this.tokens,
    required this.strings,
    required this.reservationRepository,
  });

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  List<ReservationModel> _rows = const [];
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
      final rows = await widget.reservationRepository.fetchMine();
      if (mounted) setState(() => _rows = rows);
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
                  if (_rows.isEmpty) Text(s.noReservationsYet),
                  for (final row in _rows)
                    ListTile(
                      title: Text(row.itemTitle ?? '#${row.itemId}'),
                      subtitle: Text(
                        '${row.wishlistTitle ?? ''} · ${row.status} · ${row.estimatedDate}',
                      ),
                      trailing: TextButton(
                        onPressed: () => _cancel(row),
                        child: Text(s.cancelReservationButton),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
