import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/notifications/notification_repository.dart';

// Per-event channel toggles (in_app / email / push). Traceability: [REQ-NOTIF-001]
class NotificationPrefsScreen extends StatefulWidget {
  final DesignTokens tokens;
  final AppStrings strings;
  final NotificationRepository notificationRepository;

  const NotificationPrefsScreen({
    super.key,
    required this.tokens,
    required this.strings,
    required this.notificationRepository,
  });

  @override
  State<NotificationPrefsScreen> createState() =>
      _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends State<NotificationPrefsScreen> {
  NotificationPreferenceSnapshot? _prefs;
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
      final prefs = await widget.notificationRepository.fetchPreferences();
      if (!mounted) return;
      setState(() {
        _prefs = prefs;
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

  Future<void> _toggle(String eventKey, String channel, bool value) async {
    try {
      final updated = await widget.notificationRepository.updateChannel(
        eventKey: eventKey,
        channel: channel,
        enabled: value,
      );
      if (!mounted) return;
      setState(() => _prefs = updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.errorMessage(e))),
      );
    }
  }

  String _channelLabel(String channel) {
    switch (channel) {
      case 'push':
        return widget.strings.pushChannelLabel;
      case 'email':
        return widget.strings.emailChannelLabel;
      default:
        return widget.strings.inAppChannelLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _prefs == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.strings.notificationPrefsTitle)),
        body: Center(child: Text(_error ?? widget.strings.genericError)),
      );
    }
    final prefs = _prefs!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.strings.notificationPrefsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final eventKey in prefs.defaultsEvents) ...[
            Text(eventKey, style: Theme.of(context).textTheme.titleSmall),
            for (final channel in const ['in_app', 'email', 'push'])
              SwitchListTile(
                key: Key('pref_${eventKey}_$channel'),
                title: Text(_channelLabel(channel)),
                value: prefs.channelEnabled(eventKey, channel),
                onChanged: (v) => _toggle(eventKey, channel, v),
              ),
            const Divider(),
          ],
        ],
      ),
    );
  }
}
