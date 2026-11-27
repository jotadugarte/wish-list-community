import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wish_list_mobile/features/share/last_wishlist_memory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LastWishlistMemory O11A', () {
    test('remembers and reads last wishlist id', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final memory = LastWishlistMemory(prefs);

      await memory.remember(42);
      expect(memory.read(), 42);
    });

    test('safeOwnedId clears when wishlist no longer owned', () async {
      SharedPreferences.setMockInitialValues({'share_last_wishlist_id': 7});
      final prefs = await SharedPreferences.getInstance();
      final memory = LastWishlistMemory(prefs);

      expect(memory.safeOwnedId(ownedWishlistIds: {7, 8}), 7);
      expect(memory.safeOwnedId(ownedWishlistIds: {8, 9}), isNull);
    });
  });
}
