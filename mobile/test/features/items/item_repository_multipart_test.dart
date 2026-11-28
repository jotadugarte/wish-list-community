import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/network/api_client.dart';
import 'package:wish_list_mobile/core/network/token_storage.dart';
import 'package:wish_list_mobile/features/items/image_compressor.dart';
import 'package:wish_list_mobile/features/items/item_repository.dart';

void main() {
  test('ItemRepository createItem uploads compressed images multipart [REQ-ITEM-002]', () async {
    final tokenStorage = InMemoryTokenStorage();
    await tokenStorage.saveToken('t');
    RecordedApiRequest? captured;
    final client = ApiClient(
      baseUrl: 'https://api.wishlist.test',
      tokenStorage: tokenStorage,
      transport: (req) async {
        captured = req;
        return const ApiResponse(
          statusCode: 201,
          body: {
            'item': {
              'id': 11,
              'wishlist_id': 2,
              'title': 'Foto',
              'specifications': null,
              'priority': 'medium',
              'price_cents': null,
              'currency': null,
              'position': 0,
              'links': [],
              'images': [
                {'id': 1, 'url': 'https://cdn.example/1.webp'},
              ],
            },
          },
        );
      },
    );
    final repo = ItemRepository(apiClient: client);
    final blob = CompressedImageBlob(
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      filename: 'shot.jpg',
      contentType: 'image/jpeg',
    );

    final created = await repo.createItem(
      wishlistId: 2,
      title: 'Foto',
      images: [blob],
    );

    expect(created.id, 11);
    expect(created.images, isNotEmpty);
    expect(captured?.isMultipart, isTrue);
    expect(captured?.files, isNotNull);
    expect(captured!.files!, hasLength(1));
    expect(captured!.files!.first.fieldName, 'images[]');
    expect(captured!.files!.first.filename, 'shot.jpg');
    expect(captured!.files!.first.bytes, [1, 2, 3, 4]);
    expect(captured?.body?['images'], isNull);
  });

  test('ItemRepository updateItem uploads compressed images multipart [REQ-ITEM-002]', () async {
    final tokenStorage = InMemoryTokenStorage();
    await tokenStorage.saveToken('t');
    RecordedApiRequest? captured;
    final client = ApiClient(
      baseUrl: 'https://api.wishlist.test',
      tokenStorage: tokenStorage,
      transport: (req) async {
        captured = req;
        return const ApiResponse(
          statusCode: 200,
          body: {
            'item': {
              'id': 11,
              'wishlist_id': 2,
              'title': 'Foto',
              'priority': 'medium',
              'position': 0,
              'links': [],
              'images': [
                {'id': 2, 'url': 'https://cdn.example/2.webp'},
              ],
            },
          },
        );
      },
    );
    final repo = ItemRepository(apiClient: client);
    final blob = CompressedImageBlob(
      bytes: Uint8List.fromList([9, 8, 7]),
      filename: 'edit.jpg',
      contentType: 'image/jpeg',
    );

    final updated = await repo.updateItem(itemId: 11, title: 'Foto', images: [blob]);

    expect(updated.id, 11);
    expect(captured?.method, 'PATCH');
    expect(captured?.isMultipart, isTrue);
    expect(captured!.files!.first.filename, 'edit.jpg');
    expect(captured!.files!.first.bytes, [9, 8, 7]);
  });
}
