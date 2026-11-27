import 'package:flutter_test/flutter_test.dart';
import 'package:wish_list_mobile/core/values/share_payload.dart';

void main() {
  group('SharePayload [REQ-ITEM-006] O4B', () {
    test('extracts first https URL and leftover title hint', () {
      final payload = SharePayload.parse(
        'Cool gadget https://store.example/g?x=1 leftover text',
      );
      expect(payload.canOpenAddItem, isTrue);
      expect(payload.url.toString(), 'https://store.example/g?x=1');
      expect(payload.titleHint, 'Cool gadget leftover text');
    });

    test('empty URL cannot open Add Item', () {
      final payload = SharePayload.parse('just some text');
      expect(payload.canOpenAddItem, isFalse);
      expect(payload.url, isNull);
      expect(payload.titleHint, 'just some text');
    });

    test('blank input yields empty payload', () {
      final payload = SharePayload.parse('   ');
      expect(payload.canOpenAddItem, isFalse);
      expect(payload.titleHint, '');
    });
  });
}
