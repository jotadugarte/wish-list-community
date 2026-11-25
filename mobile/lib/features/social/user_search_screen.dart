import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/theme/app_icon_badge.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/social/social_repository.dart';

// Anti-Stalking @username search screen: displays only @username and friend request
// action button for non-friends, never exposing personal wishlists or email_address.
// Traceability: [REQ-SOC-001], [REQ-WISH-001], [REQ-BLOCK-001], [REQ-DISC-001]
class UserSearchScreen extends StatefulWidget {
  final DesignTokens tokens;
  final SocialRepository socialRepository;

  const UserSearchScreen({
    super.key,
    required this.tokens,
    required this.socialRepository,
  });

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _queryController = TextEditingController();
  List<PublicUserCard> _results = const [];
  String? _error;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _executeSearch() async {
    setState(() => _error = null);
    try {
      final matches = await widget.socialRepository.searchUsers(
        _queryController.text,
      );
      if (mounted) {
        setState(() => _results = matches);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('search_username_field'),
                  controller: _queryController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por @username',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                key: const Key('search_submit_button'),
                onPressed: _executeSearch,
                child: const Text('Buscar'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Color(0xFFD9383A))),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) => _buildUserCard(_results[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(PublicUserCard card) {
    return Card(
      child: ListTile(
        leading: AppIconBadge(
          icon: Icons.alternate_email,
          tokens: widget.tokens,
        ),
        title: Text('@${card.username.value}'),
        subtitle: Text(
          card.friendshipStatus == 'accepted'
              ? 'Amigos'
              : 'Solo perfil básico visible (Anti-Stalking)',
        ),
        trailing: card.friendshipStatus == 'none'
            ? ElevatedButton(
                key: Key('send_friend_request_${card.id}'),
                onPressed: () async {
                  await widget.socialRepository.sendFriendRequest(
                    addresseeId: card.id,
                  );
                },
                child: const Text('Agregar'),
              )
            : Text(card.friendshipStatus),
      ),
    );
  }
}
