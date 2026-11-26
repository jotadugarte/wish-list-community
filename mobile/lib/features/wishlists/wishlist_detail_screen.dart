import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/wishlists/wishlist_repository.dart';

// Empty wishlist shell detail with optional Secret Link copy/rotate for owners.
// Traceability: [REQ-WISH-001], [REQ-WISH-002], [REQ-WISH-006]
class WishlistDetailScreen extends StatefulWidget {
  final DesignTokens tokens;
  final AppStrings strings;
  final WishlistRepository wishlistRepository;
  final int wishlistId;
  final bool canManage;

  const WishlistDetailScreen({
    super.key,
    required this.tokens,
    required this.strings,
    required this.wishlistRepository,
    required this.wishlistId,
    required this.canManage,
  });

  @override
  State<WishlistDetailScreen> createState() => _WishlistDetailScreenState();
}

class _WishlistDetailScreenState extends State<WishlistDetailScreen> {
  WishlistShell? _wishlist;
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
      if (mounted) setState(() => _wishlist = shell);
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

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.wishlistDetailTitle)),
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
                Text(s.wishlistEmptyShellHint),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: widget.tokens.accent)),
                ],
                if (widget.canManage) ...[
                  const SizedBox(height: 16),
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
                ],
              ],
            ),
    );
  }
}
