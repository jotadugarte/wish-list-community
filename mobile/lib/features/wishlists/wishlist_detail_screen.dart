import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/items/item_form_screen.dart';
import 'package:wish_list_mobile/features/items/item_models.dart';
import 'package:wish_list_mobile/features/items/item_repository.dart';
import 'package:wish_list_mobile/features/wishlists/wishlist_repository.dart';
import 'package:wish_list_mobile/features/reservations/reservation_repository.dart';

// Wishlist detail with item list, specs box, and optional Secret Link management.
// Traceability: [REQ-WISH-001], [REQ-WISH-002], [REQ-WISH-006], [REQ-ITEM-001]
class WishlistDetailScreen extends StatefulWidget {
  final DesignTokens tokens;
  final AppStrings strings;
  final WishlistRepository wishlistRepository;
  final ItemRepository itemRepository;
  final ReservationRepository? reservationRepository;
  final int wishlistId;
  final bool canManage;

  const WishlistDetailScreen({
    super.key,
    required this.tokens,
    required this.strings,
    required this.wishlistRepository,
    required this.itemRepository,
    this.reservationRepository,
    required this.wishlistId,
    required this.canManage,
  });

  @override
  State<WishlistDetailScreen> createState() => _WishlistDetailScreenState();
}

class _WishlistDetailScreenState extends State<WishlistDetailScreen> {
  WishlistShell? _wishlist;
  List<WishlistItem> _items = const [];
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
      final shell = await widget.wishlistRepository.fetchWishlist(
        widget.wishlistId,
      );
      final items = await widget.itemRepository.fetchItems(
        wishlistId: widget.wishlistId,
      );
      if (mounted) {
        setState(() {
          _wishlist = shell;
          _items = items;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = widget.strings.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setPrivacy(String mode) async {
    try {
      final updated = await widget.wishlistRepository.updateWishlist(
        wishlistId: widget.wishlistId,
        privacyMode: mode,
      );
      if (mounted) setState(() => _wishlist = updated);
    } catch (e) {
      if (mounted) setState(() => _error = widget.strings.errorMessage(e));
    }
  }

  Future<void> _rotate() async {
    try {
      final updated = await widget.wishlistRepository.rotateShareToken(
        wishlistId: widget.wishlistId,
      );
      if (mounted) setState(() => _wishlist = updated);
    } catch (e) {
      if (mounted) setState(() => _error = widget.strings.errorMessage(e));
    }
  }

  Future<void> _copyLink() async {
    final token = _wishlist?.shareToken;
    if (token == null || token.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: '/s/$token'));
  }

  Future<void> _openForm({WishlistItem? existing}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ItemFormScreen(
          tokens: widget.tokens,
          strings: widget.strings,
          itemRepository: widget.itemRepository,
          wishlistId: widget.wishlistId,
          existing: existing,
        ),
      ),
    );
    if (saved == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.wishlistDetailTitle)),
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              label: Text(s.addItemButton),
              icon: const Icon(Icons.add),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _wishlist == null
          ? Center(child: Text(_error ?? s.notFoundError))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _wishlist!.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                if (_error != null) ...[
                  Text(_error!, style: TextStyle(color: widget.tokens.accent)),
                  const SizedBox(height: 8),
                ],
                if (widget.canManage) ...[
                  Text(s.privacyModeLabel),
                  Row(
                    children: [
                      ChoiceChip(
                        label: Text(s.privacyFriendsLabel),
                        selected: _wishlist!.isFriends,
                        onSelected: (_) => _setPrivacy('friends'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(s.privacySharedLabel),
                        selected: _wishlist!.isShared,
                        onSelected: (_) => _setPrivacy('shared'),
                      ),
                    ],
                  ),
                  if (_wishlist!.isShared) ...[
                    const SizedBox(height: 12),
                    Text(s.secretLinkLabel),
                    SelectableText('/s/${_wishlist!.shareToken ?? ''}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _copyLink,
                          child: Text(s.copySecretLinkButton),
                        ),
                        OutlinedButton(
                          onPressed: _rotate,
                          child: Text(s.rotateSecretLinkButton),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
                if (_items.isEmpty)
                  Text(s.noItemsYet)
                else
                  ..._items.map(_itemTile),
              ],
            ),
    );
  }

  Future<void> _reserve(WishlistItem item) async {
    final repo = widget.reservationRepository;
    if (repo == null) return;
    final date = DateTime.now().add(const Duration(days: 7));
    final iso =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      await repo.create(itemId: item.id, estimatedDate: iso);
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = widget.strings.errorMessage(e));
    }
  }

  String _availabilityLabel(String? availability) {
    final s = widget.strings;
    switch (availability) {
      case 'reserved_by_me':
        return s.availabilityReservedByMe;
      case 'unavailable':
        return s.availabilityUnavailable;
      case 'available':
        return s.availabilityAvailable;
      default:
        return '';
    }
  }

  Widget _itemTile(WishlistItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: widget.canManage ? () => _openForm(existing: item) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
            if (item.specifications != null && item.specifications!.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.tokens.specBg,
                  border: Border(
                    left: BorderSide(color: widget.tokens.accent, width: 4),
                  ),
                ),
                child: Text(item.specifications!),
              ),
            const SizedBox(height: 4),
            Text(item.priority, style: Theme.of(context).textTheme.labelSmall),
            for (final link in item.links.take(5))
              Text(link.url, style: Theme.of(context).textTheme.bodySmall),
            if (!widget.canManage && item.availability != null) ...[
              const SizedBox(height: 6),
              Text(_availabilityLabel(item.availability)),
              if (item.availability == 'available')
                TextButton(
                  onPressed: () => _reserve(item),
                  child: Text(widget.strings.reserveButton),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
