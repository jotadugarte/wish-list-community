import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:wish_list_mobile/features/items/image_compressor.dart';

void main() {
  group('ImageCompressor [REQ-ITEM-002] [REQ-MOB-001] O5A', () {
    test('resizes long side to at most 1600 and encodes jpeg', () {
      final raw = img.Image(width: 2000, height: 1000);
      final png = Uint8List.fromList(img.encodePng(raw));
      final blob = ImageCompressor.compress(rawBytes: png, filename: 'big.png');

      expect(blob.contentType, 'image/jpeg');
      expect(blob.withinBudget, isTrue);
      final decoded = img.decodeJpg(blob.bytes)!;
      expect([decoded.width, decoded.height].reduce((a, b) => a > b ? a : b), lessThanOrEqualTo(1600));
    });
  });
}
