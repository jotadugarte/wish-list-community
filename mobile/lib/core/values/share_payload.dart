// SharePayload VO: parsed OS share blob → primary URL + optional title hint.
// Traceability: [REQ-ITEM-006] O4B
class SharePayload {
  final Uri? url;
  final String titleHint;

  const SharePayload._({required this.url, required this.titleHint});

  /// Parses shared text; first http(s) URL wins; leftover text is title hint.
  factory SharePayload.parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return const SharePayload._(url: null, titleHint: '');
    }

    final match = RegExp(r'https?://[^\s]+', caseSensitive: false).firstMatch(text);
    if (match == null) {
      return SharePayload._(url: null, titleHint: text);
    }

    final urlStr = match.group(0)!;
    final uri = Uri.tryParse(urlStr);
    final leftover = (text.substring(0, match.start) + text.substring(match.end))
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return SharePayload._(
      url: (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) ? uri : null,
      titleHint: leftover,
    );
  }

  bool get canOpenAddItem => url != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SharePayload && other.url == url && other.titleHint == titleHint);

  @override
  int get hashCode => Object.hash(url, titleHint);
}
