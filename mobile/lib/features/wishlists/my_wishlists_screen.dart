import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/wishlists/wishlist_detail_screen.dart';
import 'package:wish_list_mobile/features/items/item_repository.dart';
import 'package:wish_list_mobile/features/wishlists/wishlist_repository.dart';
import 'package:wish_list_mobile/features/reservations/reservation_repository.dart';
import 'package:wish_list_mobile/features/reservations/my_reservations_screen.dart';
import 'package:wish_list_mobile/features/gifts/gift_repository.dart';

// Lists the owner's wishlists and supports create with default friends privacy.
// Traceability: [REQ-WISH-001], [REQ-USER-002]
class MyWishlistsScreen extends StatefulWidget {
  final DesignTokens tokens;
  final AppStrings strings;
  final WishlistRepository wishlistRepository;
  final ReservationRepository? reservationRepository;
  final GiftRepository? giftRepository;

  const MyWishlistsScreen({
    super.key,
    required this.tokens,
    required this.strings,
    required this.wishlistRepository,
    this.reservationRepository,
    this.giftRepository,
  });

  @override
  State<MyWishlistsScreen> createState() => _MyWishlistsScreenState();
}

class _MyWishlistsScreenState extends State<MyWishlistsScreen> {
  List<WishlistShell> _wishlists = const [];
  String? _error;
  bool _loading = true;
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.wishlistRepository.fetchMyWishlists();
      if (mounted) setState(() => _wishlists = list);
    } catch (e) {
      if (mounted) setState(() => _error = widget.strings.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    try {
      await widget.wishlistRepository.createWishlist(
        title: _titleController.text,
      );
      _titleController.clear();
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = widget.strings.errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(s.myWishlistsTitle, style: Theme.of(context).textTheme.titleLarge),
        if (widget.reservationRepository != null) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MyReservationsScreen(
                    tokens: widget.tokens,
                    strings: widget.strings,
                    reservationRepository: widget.reservationRepository!,
                    giftRepository: widget.giftRepository,
                  ),
                ),
              );
            },
            child: Text(s.openMyReservationsAction),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(labelText: s.wishlistTitleLabel),
        ),
        const SizedBox(height: 8),
        FilledButton(onPressed: _create, child: Text(s.createWishlistButton)),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: widget.tokens.accent)),
        ],
        const SizedBox(height: 16),
        if (_wishlists.isEmpty) Text(s.noWishlistsYet),
        ..._wishlists.map((w) {
          return ListTile(
            title: Text(w.title),
            subtitle: Text(
              w.isShared ? s.privacySharedLabel : s.privacyFriendsLabel,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WishlistDetailScreen(
                      reservationRepository: widget.reservationRepository,
                      giftRepository: widget.giftRepository,
                    tokens: widget.tokens,
                    strings: s,
                    wishlistRepository: widget.wishlistRepository,
                    itemRepository: ItemRepository(apiClient: widget.wishlistRepository.apiClient),
                    wishlistId: w.id,
                    canManage: true,
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}
