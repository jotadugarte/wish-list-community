import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/app_icon_badge.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/social/social_repository.dart';

// Anti-Stalking @username search screen: displays only @username and friend request
// action button for non-friends, never exposing personal wishlists or email_address.
// Traceability: [REQ-SOC-001], [REQ-WISH-001], [REQ-BLOCK-001], [REQ-DISC-001], [REQ-USER-002]
class UserSearchScreen extends StatefulWidget {
  final DesignTokens tokens;
  final AppStrings strings;
  final SocialRepository socialRepository;

  const UserSearchScreen({
    super.key,
    required this.tokens,
    required this.strings,
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
        setState(() => _error = widget.strings.errorMessage(e));
      }
    }
  }

  Future<void> _runSocialAction(Future<void> Function() action) async {
    setState(() => _error = null);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(() => _error = widget.strings.errorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
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
                  decoration: InputDecoration(labelText: s.searchInputLabel),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                key: const Key('search_submit_button'),
                onPressed: _executeSearch,
                child: Text(s.searchButton),
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
    final s = widget.strings;
    return Card(
      child: ListTile(
        leading: AppIconBadge(
          icon: Icons.alternate_email,
          tokens: widget.tokens,
        ),
        title: Text('@${card.username.value}'),
        subtitle: Text(
          card.friendshipStatus == 'accepted'
              ? s.connectedFriendSubtitle
              : s.antiStalkingSubtitle,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (card.friendshipStatus == 'none')
              ElevatedButton(
                key: Key('send_friend_request_${card.id}'),
                onPressed: () => _runSocialAction(() async {
                  await widget.socialRepository.sendFriendRequest(
                    addresseeId: card.id,
                  );
                }),
                child: Text(s.addFriendButton),
              )
            else
              Text(card.friendshipStatus),
            IconButton(
              key: Key('block_user_${card.id}'),
              tooltip: s.blockUserAction,
              icon: const Icon(Icons.block),
              onPressed: () => _runSocialAction(() async {
                await widget.socialRepository.blockUser(blockedUserId: card.id);
              }),
            ),
            IconButton(
              key: Key('report_user_${card.id}'),
              tooltip: s.reportUserAction,
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => _runSocialAction(() async {
                await widget.socialRepository.reportUser(
                  targetUserId: card.id,
                  rawReason: 'harassment',
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
