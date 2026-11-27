import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/notifications/notification_repository.dart';

// In-app notification inbox (campanita). Traceability: [REQ-NOTIF-001]
class InboxScreen extends StatefulWidget {
  final DesignTokens tokens;
  final AppStrings strings;
  final NotificationRepository notificationRepository;

  const InboxScreen({
    super.key,
    required this.tokens,
    required this.strings,
    required this.notificationRepository,
  });

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<InboxNotification>? _notes;
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
      final notes = await widget.notificationRepository.fetchInbox();
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = widget.strings.errorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _markRead(InboxNotification note) async {
    if (!note.isUnread) return;
    try {
      final updated = await widget.notificationRepository.markRead(note.id);
      if (!mounted) return;
      setState(() {
        _notes = [
          for (final n in _notes ?? const <InboxNotification>[])
            if (n.id == updated.id) updated else n,
        ];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.errorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            TextButton(onPressed: _load, child: Text(widget.strings.navInbox)),
          ],
        ),
      );
    }
    final notes = _notes ?? const <InboxNotification>[];
    if (notes.isEmpty) {
      return Center(child: Text(widget.strings.noNotificationsYet));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notes.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final note = notes[index];
          return ListTile(
            key: Key('inbox_note_${note.id}'),
            title: Text(note.title),
            subtitle: Text(note.body ?? note.eventKey),
            trailing: note.isUnread
                ? const Icon(Icons.mark_email_unread_outlined)
                : const Icon(Icons.done),
            onTap: () => _markRead(note),
          );
        },
      ),
    );
  }
}
