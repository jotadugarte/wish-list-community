import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/features/items/image_compressor.dart';
import 'package:wish_list_mobile/features/items/item_models.dart';

// Repository for Item CRUD, link previews, and reorder.
// Traceability: [REQ-ITEM-001], [REQ-ITEM-003], [REQ-ITEM-006], [REQ-ARCH-002]
class ItemRepository {
  static const int maxList = 200;
  static const allowedPriorities = {'low', 'medium', 'high', 'must_have'};

  final ApiClient apiClient;

  const ItemRepository({required this.apiClient});

  // [REQ-ITEM-001] Lists kept items for a wishlist.
  Future<List<WishlistItem>> fetchItems({required int wishlistId}) async {
    if (wishlistId <= 0) {
      throw ArgumentError('Pre-condition failed: wishlistId must be > 0');
    }
    final response = await apiClient.request(
      method: 'GET',
      path: '/api/v1/wishlists/$wishlistId/items',
    );
    final raw = response.body['items'] as List<dynamic>? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .take(maxList)
        .map(WishlistItem.fromJson)
        .toList(growable: false);
  }

  // [REQ-ITEM-001] [REQ-ITEM-002] [REQ-ITEM-003] Creates an item; images via multipart when present.
  Future<WishlistItem> createItem({
    required int wishlistId,
    required String title,
    String? specifications,
    String priority = 'medium',
    int? priceCents,
    String? currency,
    List<String> linkUrls = const [],
    LinkPreview? confirmedPreview,
    List<CompressedImageBlob> images = const [],
  }) async {
    _validatePriority(priority);
    final cleaned = title.trim();
    final previewTitle = confirmedPreview?.title.trim() ?? '';
    if (cleaned.isEmpty && previewTitle.isEmpty) {
      throw ArgumentError('Pre-condition failed: title cannot be blank');
    }
    if (images.length > CompressedImageBlob.maxImages) {
      throw ArgumentError('Pre-condition failed: at most ${CompressedImageBlob.maxImages} images');
    }
    final useMultipart = images.isNotEmpty;
    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/wishlists/$wishlistId/items',
      multipart: useMultipart,
      body: {
        'item': {
          'title': cleaned.isEmpty ? previewTitle : cleaned,
          'specifications': ?specifications,
          'priority': priority,
          'price_cents': ?priceCents,
          'currency': ?currency,
          'links': [
            for (final u in linkUrls.take(20)) {'url': u},
          ],
        },
        if (confirmedPreview != null)
          'confirmed_preview': {
            'title': confirmedPreview.title,
            'image_url': confirmedPreview.imageUrl,
            'source_url': confirmedPreview.sourceUrl,
          },
        if (useMultipart)
          'images': [
            for (final img in images.take(CompressedImageBlob.maxImages))
              {
                'filename': img.filename,
                'content_type': img.contentType,
                'bytes_length': img.bytes.lengthInBytes,
              },
          ],
      },
    );
    return WishlistItem.fromJson(
      response.body['item'] as Map<String, dynamic>,
    );
  }

  // [REQ-ITEM-001] Updates an item.
  Future<WishlistItem> updateItem({
    required int itemId,
    String? title,
    String? specifications,
    String? priority,
    int? priceCents,
    String? currency,
    List<String>? linkUrls,
  }) async {
    if (itemId <= 0) {
      throw ArgumentError('Pre-condition failed: itemId must be > 0');
    }
    if (priority != null) _validatePriority(priority);
    final response = await apiClient.request(
      method: 'PATCH',
      path: '/api/v1/items/$itemId',
      body: {
        'item': {
          'title': ?title,
          'specifications': ?specifications,
          'priority': ?priority,
          'price_cents': ?priceCents,
          'currency': ?currency,
          if (linkUrls != null)
            'links': [
              for (final u in linkUrls.take(20)) {'url': u},
            ],
        },
      },
    );
    return WishlistItem.fromJson(
      response.body['item'] as Map<String, dynamic>,
    );
  }

  // [REQ-LIFE-001] Soft-deletes an item.
  Future<void> deleteItem({required int itemId}) async {
    if (itemId <= 0) {
      throw ArgumentError('Pre-condition failed: itemId must be > 0');
    }
    await apiClient.request(method: 'DELETE', path: '/api/v1/items/$itemId');
  }

  // [REQ-ITEM-006] Best-effort store link preview (confirm before create — O3A).
  Future<LinkPreview> previewLink({required String url}) async {
    final cleaned = url.trim();
    if (cleaned.isEmpty) {
      throw ArgumentError('Pre-condition failed: url cannot be blank');
    }
    final response = await apiClient.request(
      method: 'POST',
      path: '/api/v1/link_previews',
      body: {'url': cleaned},
    );
    return LinkPreview.fromJson(response.body);
  }

  void _validatePriority(String priority) {
    if (!allowedPriorities.contains(priority)) {
      throw ArgumentError('Pre-condition failed: invalid priority');
    }
  }
}
