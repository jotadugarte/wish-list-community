import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/wishlists/wishlist_detail_screen.dart';
import 'package:wish_list_mobile/features/wishlists/wishlist_repository.dart';

// Policy-scoped wishlists for a friend's @username (O3A).
// Traceability: [REQ-WISH-001]
class FriendWishlistsScreen extends StatefulWidget {
  final DesignTokens tokens;
  final AppStrings strings;
  final WishlistRepository wishlistRepository;
  final String username;

  const FriendWishlistsScreen({
    super.key,
    required this.tokens,
    required this.strings,
    required this.wishlistRepository,
    required this.username,
  });

  @override
  State<FriendWishlistsScreen> createState() => _FriendWishlistsScreenState();
}

class _FriendWishlistsScreenState extends State<FriendWishlistsScreen> {
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
      final list = await widget.wishlistRepository.fetchUserWishlists(
        widget.username,
      );
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
    return Scaffold(
      appBar: AppBar(title: Text(s.friendWishlistsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) Text(_error!),
                if (_wishlists.isEmpty && _error == null)
                  Text(s.noFriendWishlists),
                ..._wishlists.map((w) {
                  return ListTile(
                    title: Text(w.title),
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
            ),
    );
  }
}
