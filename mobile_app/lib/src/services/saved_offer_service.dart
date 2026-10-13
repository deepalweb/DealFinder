import '../models/promotion.dart';
import '../utils/bank_card_promotion_support.dart';
import 'api_service.dart';
import 'app_session.dart';
import 'favorites_manager.dart';

class SavedOfferService {
  static Future<void> setSaved(Promotion offer, bool saved,
      {ApiService? api}) async {
    final session = await AppSession.read();
    if (!session.isSignedIn) throw StateError('Sign in required');
    // Platform bank offers are not accepted by the promotion favorites API.
    // Their snapshots are saved on this device until that API supports them.
    if (!(offer.merchantId == null &&
        BankCardPromotionSupport.isBankCardPromotion(offer))) {
      final client = api ?? ApiService();
      if (saved) {
        await client.addFavorite(session.userId, offer.id, session.token);
      } else {
        await client.removeFavorite(session.userId, offer.id, session.token);
      }
    }
    if (saved) {
      await FavoritesManager.addFavoritePromotion(offer);
    } else {
      await FavoritesManager.removeFavorite(offer.id);
    }
  }
}
