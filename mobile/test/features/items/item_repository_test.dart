import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/features/items/item_repository.dart';

void main() {
  test('ItemRepository lists creates and previews links [REQ-ITEM-001] [REQ-ITEM-006]', () async {
    final tokenStorage = InMemoryTokenStorage();
    await tokenStorage.saveToken('t');
    final client = ApiClient(
      baseUrl: 'https://api.wishlist.test',
      tokenStorage: tokenStorage,
      transport: (req) async {
        if (req.path.endsWith('/link_previews')) {
          return const ApiResponse(
            statusCode: 200,
            body: {
              'title': 'Gadget',
              'image_url': 'https://cdn.example/i.png',
              'source_url': 'https://shop.example/p/1',
            },
          );
        }
        if (req.method == 'POST' && req.path.contains('/items')) {
          return const ApiResponse(
            statusCode: 201,
            body: {
              'item': {
                'id': 9,
                'wishlist_id': 1,
                'title': 'Gadget',
                'specifications': 'Navy',
                'priority': 'high',
                'price_cents': 1000,
                'currency': 'USD',
                'position': 0,
                'links': [
                  {'id': 1, 'url': 'https://shop.example/p/1', 'position': 0},
                ],
                'images': [],
              },
            },
          );
        }
        return const ApiResponse(
          statusCode: 200,
          body: {
            'items': [
              {
                'id': 9,
                'wishlist_id': 1,
                'title': 'Gadget',
                'specifications': 'Navy',
                'priority': 'high',
                'price_cents': 1000,
                'currency': 'USD',
                'position': 0,
                'links': [],
                'images': [],
              },
            ],
          },
        );
      },
    );
    final repo = ItemRepository(apiClient: client);

    final preview = await repo.previewLink(url: 'https://shop.example/p/1');
    expect(preview.title, 'Gadget');

    final created = await repo.createItem(
      wishlistId: 1,
      title: 'Gadget',
      specifications: 'Navy',
      priority: 'high',
      priceCents: 1000,
      currency: 'USD',
      linkUrls: ['https://shop.example/p/1'],
      confirmedPreview: preview,
    );
    expect(created.id, 9);
    expect(created.priority, 'high');

    final list = await repo.fetchItems(wishlistId: 1);
    expect(list.single.title, 'Gadget');
  });
}
