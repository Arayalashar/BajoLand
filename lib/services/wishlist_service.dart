import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Layanan penyimpanan Wishlist destinasi favorit lokal (SharedPreferences - Modul 6)
class WishlistService {
  static const String _key = 'user_wishlist_ids';

  static Future<Set<int>> getWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toSet();
  }

  static Future<bool> toggleWishlist(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final set = list.map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toSet();
    final bool isAdded;
    if (set.contains(id)) {
      set.remove(id);
      isAdded = false;
    } else {
      set.add(id);
      isAdded = true;
    }
    await prefs.setStringList(_key, set.map((e) => e.toString()).toList());
    return isAdded;
  }

  static Future<bool> isWishlisted(int id) async {
    final set = await getWishlist();
    return set.contains(id);
  }
}

/// Controller GetX untuk sinkronisasi reaktif Wishlist di seluruh aplikasi (Home, Explore, Detail)
class WishlistController extends GetxController {
  static WishlistController get to {
    if (!Get.isRegistered<WishlistController>()) {
      return Get.put(WishlistController(), permanent: true);
    }
    return Get.find<WishlistController>();
  }

  final wishlist = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadWishlist();
  }

  Future<void> loadWishlist() async {
    final list = await WishlistService.getWishlist();
    wishlist.assignAll(list);
  }

  bool isFavorite(int id) => wishlist.contains(id);

  Future<bool> toggleWishlist(int id) async {
    final isAdded = await WishlistService.toggleWishlist(id);
    if (isAdded) {
      wishlist.add(id);
    } else {
      wishlist.remove(id);
    }
    return isAdded;
  }
}
