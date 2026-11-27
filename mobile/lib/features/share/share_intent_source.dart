import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

// Abstraction over OS share intents for headless tests (O4B).
// Traceability: [REQ-MOB-001], [REQ-MOB-002]
abstract class ShareIntentSource {
  Stream<String> get sharedTextStream;
  Future<String?> getInitialSharedText();
}

class ReceiveSharingIntentSource implements ShareIntentSource {
  @override
  Stream<String> get sharedTextStream => ReceiveSharingIntent.instance
      .getMediaStream()
      .map(_joinShared)
      .where((s) => s.trim().isNotEmpty);

  @override
  Future<String?> getInitialSharedText() async {
    final media = await ReceiveSharingIntent.instance.getInitialMedia();
    final text = _joinShared(media);
    return text.trim().isEmpty ? null : text;
  }

  static String _joinShared(List<SharedMediaFile> files) {
    final parts = <String>[];
    for (final f in files.take(20)) {
      if (f.path.isNotEmpty) parts.add(f.path);
      final msg = f.message;
      if (msg != null && msg.isNotEmpty) parts.add(msg);
    }
    return parts.join(' ');
  }
}

class FakeShareIntentSource implements ShareIntentSource {
  final StreamController<String> _controller = StreamController<String>.broadcast();
  String? initial;

  void emit(String text) => _controller.add(text);

  @override
  Stream<String> get sharedTextStream => _controller.stream;

  @override
  Future<String?> getInitialSharedText() async => initial;
}
