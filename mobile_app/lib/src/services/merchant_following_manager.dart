import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class MerchantFollowingManager {
  static const String _followingKey = 'followingMerchants';

  static Future<List<String>> getFollowingMerchants() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null && userId.isNotEmpty) {
      try {
        final ids = await ApiService().fetchFollowingMerchantIds(userId);
        await prefs.setStringList(_followingKey, ids);
        return ids;
      } catch (_) {}
    }
    return prefs.getStringList(_followingKey) ?? [];
  }

  static Future<bool> isFollowing(String merchantId) async {
    final following = await getFollowingMerchants();
    return following.contains(merchantId);
  }

  static Future<int?> followMerchant(String merchantId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null && userId.isNotEmpty) {
      final followers = await ApiService().followMerchant(userId, merchantId);
      final following = await getFollowingMerchants();
      if (!following.contains(merchantId)) {
        following.add(merchantId);
        await prefs.setStringList(_followingKey, following);
      }
      return followers;
    }
    final following = await getFollowingMerchants();
    if (!following.contains(merchantId)) {
      following.add(merchantId);
      await prefs.setStringList(_followingKey, following);
    }
    return null;
  }

  static Future<int?> unfollowMerchant(String merchantId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null && userId.isNotEmpty) {
      final followers = await ApiService().unfollowMerchant(userId, merchantId);
      final following = await getFollowingMerchants();
      following.remove(merchantId);
      await prefs.setStringList(_followingKey, following);
      return followers;
    }
    final following = await getFollowingMerchants();
    following.remove(merchantId);
    await prefs.setStringList(_followingKey, following);
    return null;
  }

  static Future<int> getFollowingCount() async {
    final following = await getFollowingMerchants();
    return following.length;
  }
}
