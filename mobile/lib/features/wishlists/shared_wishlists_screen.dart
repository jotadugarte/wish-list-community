import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/wishlists/wishlist_detail_screen.dart';
import 'package:wish_list_mobile/features/wishlists/wishlist_repository.dart';

// Shared-with-me list of wishlist shells opened via Secret Link or explicit share.
// Traceability: [REQ-WISH-003], [REQ-USER-002]
class SharedWishlistsScreen extends StatefulWidget {
  final DesignTokens tokens;
  final AppStrings strings;
  final WishlistRepository wishlistRepository;

  const SharedWishlistsScreen({
    super.key,
    required this.tokens,
    required this.strings,
    required this.wishlistRepository,
  });

  @override
  State<SharedWishlistsScreen> createState() => _SharedWishlistsScreenState();
}

class _SharedWishlistsScreenState extends State<SharedWishlistsScreen> {
  List<WishlistShell> _wishlists = const [];
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
      final list = await widget.wishlistRepository.fetchSharedWishlists();
      if (mounted) setState(() => _wishlists = list);
    } catch (e) {
      if (mounted) setState(() => _error = widget.strings.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(s.sharedWithMeTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (_wishlists.isEmpty) Text(s.noSharedWishlists),
        ..._wishlists.map((w) {
          return ListTile(
            title: Text(w.title),
            subtitle: Text('@${w.ownerUsername.value}'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WishlistDetailScreen(
                    tokens: widget.tokens,
                    strings: s,
                    wishlistRepository: widget.wishlistRepository,
                    wishlistId: w.id,
                    canManage: false,
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
