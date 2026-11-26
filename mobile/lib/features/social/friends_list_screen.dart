import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/app_icon_badge.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/social/social_repository.dart';

// Displays accepted friends and incoming/outgoing pending friend requests.
// Traceability: [REQ-SOC-001], [REQ-BLOCK-001], [REQ-DISC-001], [REQ-USER-002]
class FriendsListScreen extends StatefulWidget {
  final DesignTokens tokens;
  final AppStrings strings;
  final SocialRepository socialRepository;

  const FriendsListScreen({
    super.key,
    required this.tokens,
    required this.strings,
    required this.socialRepository,
  });

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  FriendshipsSummary? _summary;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriendships();
  }

  Future<void> _loadFriendships() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await widget.socialRepository.fetchFriendships();
      if (mounted) {
        setState(() => _summary = res);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = widget.strings.errorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _runFriendAction(Future<void> Function() action) async {
    try {
      await action();
      await _loadFriendships();
    } catch (e) {
      if (mounted) {
        setState(() => _error = widget.strings.errorMessage(e));
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
      return Center(child: Text(_error ?? widget.strings.noConnections));
    }

    final s = widget.strings;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: Color(0xFFD9383A))),
          const SizedBox(height: 8),
        ],
        if (summary.incomingRequests.isNotEmpty) ...[
          Text(
            s.incomingRequestsTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...summary.incomingRequests.map(_buildIncomingCard),
          const SizedBox(height: 16),
        ],
        Text(
          s.myFriendsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              onPressed: () => _runFriendAction(() async {
                await widget.socialRepository.acceptFriendRequest(
                  friendshipId: item.id,
                );
              }),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _runFriendAction(() async {
                await widget.socialRepository.removeFriendship(
                  friendshipId: item.id,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendCard(FriendshipItem item) {
    final s = widget.strings;
    return Card(
      child: ListTile(
        leading: AppIconBadge(icon: Icons.people, tokens: widget.tokens),
        title: Text('@${item.friend.username.value}'),
        subtitle: Text(s.connectedFriendSubtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: Key('block_friend_${item.friend.id}'),
              tooltip: s.blockUserAction,
              icon: const Icon(Icons.block),
              onPressed: () => _runFriendAction(() async {
                await widget.socialRepository.blockUser(
                  blockedUserId: item.friend.id,
                );
              }),
            ),
            IconButton(
              key: Key('report_friend_${item.friend.id}'),
              tooltip: s.reportUserAction,
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => _runFriendAction(() async {
                await widget.socialRepository.reportUser(
                  targetUserId: item.friend.id,
                  rawReason: 'spam',
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
