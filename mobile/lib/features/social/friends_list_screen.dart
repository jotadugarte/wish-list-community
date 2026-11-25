import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/theme/app_icon_badge.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/social/social_repository.dart';

// Displays accepted friends and incoming/outgoing pending friend requests.
// Traceability: [REQ-SOC-001], [REQ-BLOCK-001]
class FriendsListScreen extends StatefulWidget {
  final DesignTokens tokens;
  final SocialRepository socialRepository;

  const FriendsListScreen({
    super.key,
    required this.tokens,
    required this.socialRepository,
  });

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  FriendshipsSummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriendships();
  }

  Future<void> _loadFriendships() async {
    setState(() => _isLoading = true);
    try {
      final res = await widget.socialRepository.fetchFriendships();
      if (mounted) {
        setState(() => _summary = res);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final summary = _summary;
    if (summary == null) {
      return const Center(child: Text('Sin conexiones'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (summary.incomingRequests.isNotEmpty) ...[
          const Text(
            'Solicitudes Recibidas',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...summary.incomingRequests.map(_buildIncomingCard),
          const SizedBox(height: 16),
        ],
        const Text(
          'Mis Amigos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...summary.friends.map(_buildFriendCard),
      ],
    );
  }

  Widget _buildIncomingCard(FriendshipItem item) {
    return Card(
      child: ListTile(
        leading: AppIconBadge(
          icon: Icons.person_add_alt_1,
          tokens: widget.tokens,
        ),
        title: Text('@${item.friend.username.value}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () async {
                await widget.socialRepository.acceptFriendRequest(
                  friendshipId: item.id,
                );
                await _loadFriendships();
              },
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                await widget.socialRepository.removeFriendship(
                  friendshipId: item.id,
                );
                await _loadFriendships();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendCard(FriendshipItem item) {
    return Card(
      child: ListTile(
        leading: AppIconBadge(icon: Icons.people, tokens: widget.tokens),
        title: Text('@${item.friend.username.value}'),
        subtitle: const Text('Amigo conectado'),
      ),
    );
  }
}
