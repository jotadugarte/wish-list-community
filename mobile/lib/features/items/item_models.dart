// Wishlist item models for Sprint 4.
// Traceability: [REQ-ITEM-001], [REQ-ITEM-003], [REQ-ITEM-005]
class ItemLinkModel {
  final int? id;
  final String url;
  final int position;

  const ItemLinkModel({this.id, required this.url, this.position = 0});

  factory ItemLinkModel.fromJson(Map<String, dynamic> json) {
    return ItemLinkModel(
      id: json['id'] as int?,
      url: json['url'] as String? ?? '',
      position: json['position'] as int? ?? 0,
    );
  }
}

class ItemImageModel {
  final int id;
  final String? contentType;
  final int? byteSize;
  final String? url;

  const ItemImageModel({
    required this.id,
    this.contentType,
    this.byteSize,
    this.url,
  });

  factory ItemImageModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    if (rawId is! int) {
      throw ArgumentError('Pre-condition failed: image id must be int');
    }
    return ItemImageModel(
      id: rawId,
      contentType: json['content_type'] as String?,
      byteSize: json['byte_size'] as int?,
      url: json['url'] as String?,
    );
  }
}

class WishlistItem {
  final int id;
  final int wishlistId;
  final String title;
  final String? specifications;
  final String priority;
  final int? priceCents;
  final String? currency;
  final int position;
  final List<ItemLinkModel> links;
  final List<ItemImageModel> images;

  const WishlistItem({
    required this.id,
    required this.wishlistId,
    required this.title,
    required this.priority,
    required this.position,
    this.specifications,
    this.priceCents,
    this.currency,
    this.links = const [],
    this.images = const [],
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    if (rawId is! int) {
      throw ArgumentError('Pre-condition failed: item id must be int');
    }
    final linksJson = json['links'] as List<dynamic>? ?? const [];
    final imagesJson = json['images'] as List<dynamic>? ?? const [];
    return WishlistItem(
      id: rawId,
      wishlistId: json['wishlist_id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      specifications: json['specifications'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      priceCents: json['price_cents'] as int?,
      currency: json['currency'] as String?,
      position: json['position'] as int? ?? 0,
      links: linksJson
          .whereType<Map<String, dynamic>>()
          .map(ItemLinkModel.fromJson)
          .toList(growable: false),
      images: imagesJson
          .whereType<Map<String, dynamic>>()
          .map(ItemImageModel.fromJson)
          .toList(growable: false),
    );
  }
}

class LinkPreview {
  final String title;
  final String imageUrl;
  final String sourceUrl;

  const LinkPreview({
    required this.title,
    required this.imageUrl,
    required this.sourceUrl,
  });

  factory LinkPreview.fromJson(Map<String, dynamic> json) {
    return LinkPreview(
      title: json['title'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      sourceUrl: json['source_url'] as String? ?? '',
    );
  }
}
