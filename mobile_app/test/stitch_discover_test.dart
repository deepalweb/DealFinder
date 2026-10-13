import 'package:deal_finder_mobile/src/models/promotion.dart';
import 'package:deal_finder_mobile/src/services/api_service.dart';
import 'package:deal_finder_mobile/src/services/favorites_manager.dart';
import 'package:deal_finder_mobile/src/services/saved_offer_service.dart';
import 'package:deal_finder_mobile/src/widgets/discovery_offer_card.dart';
import 'package:deal_finder_mobile/src/widgets/offer_save_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design_system_test.dart' show host;

class FavoriteApi extends ApiService {
  FavoriteApi({this.fail = false});
  final bool fail;
  int writes = 0;
  @override
  Future<void> addFavorite(
      String userId, String promotionId, String token) async {
    writes++;
    if (fail) throw Exception('Rejected by server');
  }

  @override
  Future<void> removeFavorite(
      String userId, String promotionId, String token) async {
    writes++;
    if (fail) throw Exception('Rejected by server');
  }
}

Promotion offer() => Promotion(
    id: 'test-offer',
    merchantId: 'merchant',
    merchantName: 'Test store',
    title: 'Weekend lunch with selected credit cards',
    description: 'Test',
    discount: '25% OFF',
    category: 'food_dining',
    bankName: 'Test Bank',
    cardTypes: ['credit'],
    minimumSpend: 2500,
    discountedPrice: 2400,
    originalPrice: 3200,
    distance: 800,
    endDate: DateTime.now().add(const Duration(days: 2)),
    deliveryAvailable: true);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({
        'userId': 'test-user',
        'userToken': 'test-token',
      }));
  test('rejected API writes leave Saved state unchanged', () async {
    final api = FavoriteApi(fail: true);
    await expectLater(
        SavedOfferService.setSaved(offer(), true, api: api), throwsException);
    expect(await FavoritesManager.isFavorite('test-offer'), false);
    await FavoritesManager.addFavoritePromotion(offer());
    await expectLater(
        SavedOfferService.setSaved(offer(), false, api: api), throwsException);
    expect(await FavoritesManager.isFavorite('test-offer'), true);
    expect(api.writes, 2);
  });
  test('accepted save and removal update persistent snapshots', () async {
    final api = FavoriteApi();
    await SavedOfferService.setSaved(offer(), true, api: api);
    expect((await FavoritesManager.getFavoritePromotions()).single.title,
        offer().title);
    await SavedOfferService.setSaved(offer(), false, api: api);
    expect(await FavoritesManager.isFavorite('test-offer'), false);
    expect(api.writes, 2);
  });
  testWidgets(
      'featured card keeps conditions readable at double text size in dark mode',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(
        Scaffold(
            body: SingleChildScrollView(
                child: DiscoveryOfferCard(
                    offer: offer(), featured: true, onOpen: () {}))),
        dark: true,
        scale: 2));
    await tester.pumpAndSettle();
    expect(find.text('800 m'), findsOneWidget);
    expect(find.textContaining('Ends '), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);
    expect(find.byType(OfferSaveButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
