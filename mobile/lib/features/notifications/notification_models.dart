// API models for in-app inbox + preference channels (O1A/O7A).
// Traceability: [REQ-NOTIF-001]

class InboxNotification {
  final int id;
  final String eventKey;
  final String title;
  final String? body;
  final Map<String, dynamic>? payload;
  final DateTime? readAt;
  final DateTime? createdAt;

  const InboxNotification({
    required this.id,
    required this.eventKey,
    required this.title,
    this.body,
    this.payload,
    this.readAt,
    this.createdAt,
  });

  bool get isUnread => readAt == null;

  factory InboxNotification.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int || id <= 0) {
      throw ArgumentError('Pre-condition failed: notification id must be > 0');
    }
    final eventKey = (json['event_key'] ?? '').toString();
    final title = (json['title'] ?? '').toString();
    if (eventKey.isEmpty || title.isEmpty) {
      throw ArgumentError('Pre-condition failed: event_key and title required');
    }
    return InboxNotification(
      id: id,
      eventKey: eventKey,
      title: title,
      body: json['body']?.toString(),
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : null,
      readAt: _parseTime(json['read_at']),
      createdAt: _parseTime(json['created_at']),
    );
  }

  static DateTime? _parseTime(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}

class NotificationPreferenceSnapshot {
  final Map<String, Map<String, bool>> channels;
  final List<String> defaultsEvents;

  const NotificationPreferenceSnapshot({
    required this.channels,
    required this.defaultsEvents,
  });

  factory NotificationPreferenceSnapshot.fromJson(Map<String, dynamic> json) {
    final rawChannels = json['channels'];
    final channels = <String, Map<String, bool>>{};
    if (rawChannels is Map) {
      rawChannels.forEach((eventKey, channelHash) {
        if (channelHash is! Map) return;
        channels[eventKey.toString()] = {
          for (final e in channelHash.entries)
            e.key.toString(): e.value == true,
        };
      });
    }
    final defaults = (json['defaults_events'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList(growable: false);
    return NotificationPreferenceSnapshot(
      channels: channels,
      defaultsEvents: defaults,
    );
  }

  bool channelEnabled(String eventKey, String channel) {
    final stored = channels[eventKey]?[channel];
    if (stored != null) return stored;
    return true;
  }
}
