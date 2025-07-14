import 'package:shared_preferences/shared_preferences.dart';

class MerchantFollowingManager {
  static const String _followingKey = 'followingMerchants';

  static Future<List<String>> getFollowingMerchants() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_followingKey) ?? [];
  }

  static Future<bool> isFollowing(String merchantId) async {
    final following = await getFollowingMerchants();
    return following.contains(merchantId);
  }

  static Future<void> followMerchant(String merchantId) async {
    final prefs = await SharedPreferences.getInstance();
    final following = await getFollowingMerchants();
    if (!following.contains(merchantId)) {
      following.add(merchantId);
      await prefs.setStringList(_followingKey, following);
    }
  }

  static Future<void> unfollowMerchant(String merchantId) async {
    final prefs = await SharedPreferences.getInstance();
    final following = await getFollowingMerchants();
    following.remove(merchantId);
    await prefs.setStringList(_followingKey, following);
  }

  static Future<int> getFollowingCount() async {
    final following = await getFollowingMerchants();
    return following.length;
  }
}