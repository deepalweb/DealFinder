import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deal_finder_mobile/src/services/api_service.dart';
import 'package:deal_finder_mobile/src/screens/stores_screen.dart';
import 'package:deal_finder_mobile/src/screens/merchant_profile_screen.dart';
import 'package:deal_finder_mobile/src/widgets/merchant_card.dart';
import 'package:deal_finder_mobile/src/widgets/stitch_discover_components.dart';
import 'design_system_test.dart' show host;

class StoreFixtureApi extends ApiService {
  bool fail = false;
  final merchants = <Map<String, dynamic>>[
    {
      '_id': 'cafe',
      'name': '[FIXTURE] Ceylon Cafe',
      'category': 'food_dining',
      'address': 'Colombo 03',
      'banner': 'assets/discover/stitch-1.jpg',
      'logo': 'assets/discover/stitch-2.jpg',
      'description': 'Fixture store, not live inventory.',
      'activeDeals': 2,
      'averageRating': 4.8,
      'ratingsCount': 1,
      'phone': '+94111234567',
      'website': 'https://example.com',
      'location': {
        'type': 'Point',
        'coordinates': [79.854, 6.911]
      }
    },
    {
      '_id': 'retail',
      'name': '[FIXTURE] Everyday Shopping and Essentials',
      'category': 'shopping_retail',
      'address': 'Nugegoda',
      'activeDeals': 1
    },
  ];
  @override
  Future<List<Map<String, dynamic>>> fetchMerchants(
      {bool forceRefresh = false}) async {
    if (fail) throw Exception('Fixture connection failure');
    return merchants;
  }

  @override
  Future<Map<String, dynamic>> fetchMerchantById(String id) async =>
      merchants.first;
  @override
  Future<List<Map<String, dynamic>>> fetchPromotionsByMerchant(
          String id) async =>
      [
        {
          '_id': 'active',
          'title': '[FIXTURE] 25% off lunch',
          'description': 'Fixture',
          'discount': '25% off',
          'status': 'active',
          'bankName': 'Sample Bank',
          'imageUrl': 'assets/discover/stitch-1.jpg',
          'minimumSpend': 3000
        },
        {
          '_id': 'expired',
          'title': '[FIXTURE] Previous offer',
          'description': '',
          'status': 'approved',
          'endDate': '2020-01-01T00:00:00Z'
        },
        {
          '_id': 'private',
          'title': 'Private expired draft',
          'description': '',
          'status': 'draft',
          'endDate': '2020-01-01T00:00:00Z'
        },
      ];
  @override
  Future<List<Map<String, dynamic>>> fetchMerchantRatings(String id) async => [
        {'value': 4.8}
      ];
  @override
  Future<List<Map<String, dynamic>>> fetchMerchantReviews(String id) async =>
      [];
}

class PartialStoreApi extends StoreFixtureApi {
  bool offersFail = true;
  bool missing = false;
  @override
  Future<Map<String, dynamic>> fetchMerchantById(String id) async {
    if (missing) throw const MerchantRequestException('Store details', 404);
    return super.fetchMerchantById(id);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPromotionsByMerchant(
      String id) async {
    if (offersFail) throw const MerchantRequestException('Store offers', 500);
    return super.fetchPromotionsByMerchant(id);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('directory search clear restores results and opens a store',
      (tester) async {
    final api = StoreFixtureApi();
    await tester.pumpWidget(host(StoresScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.byType(MerchantCard), findsNWidgets(2));
    await tester.enterText(find.byType(TextField), 'Ceylon');
    await tester.pumpAndSettle();
    expect(find.byType(MerchantCard), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
    expect(find.byType(MerchantCard), findsNWidgets(2));
    await tester.tap(find.text('View store').first);
    await tester.pumpAndSettle();
    expect(find.byType(MerchantProfileScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'store profile preserves sections and hides private expired offers',
      (tester) async {
    await tester.pumpWidget(host(MerchantProfileScreen(
        merchantId: 'cafe',
        api: StoreFixtureApi(),
        mapBuilder: (_) => const Text('Fixture map'))));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(StitchFullWidthOfferCard), 160,
        scrollable: find.byType(Scrollable).first);
    expect(find.byType(StitchFullWidthOfferCard), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('Expired'), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.textContaining('Expired'));
    await tester.pumpAndSettle();
    expect(find.text('Private expired draft'), findsNothing);
    expect(find.byType(StitchFullWidthOfferCard), findsOneWidget);
    await tester.scrollUntilVisible(find.text('About'), -160,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('Fixture store, not live inventory.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('directory cards remain consistent at narrow enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
        host(StoresScreen(api: StoreFixtureApi()), dark: true, scale: 2));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(MerchantCard), 180,
        scrollable: find.byType(Scrollable).first);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'offers failure leaves store details available and retries independently',
      (tester) async {
    final api = PartialStoreApi();
    await tester
        .pumpWidget(host(MerchantProfileScreen(merchantId: 'cafe', api: api)));
    await tester.pumpAndSettle();
    expect(find.text('[FIXTURE] Ceylon Cafe'), findsOneWidget);
    expect(find.text('Store details are unavailable. Please try again.'),
        findsNothing);
    await tester.scrollUntilVisible(
        find.text(
            'Offers could not be loaded. Store details are still available.'),
        160,
        scrollable: find.byType(Scrollable).first);
    api.offersFail = false;
    await tester.ensureVisible(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Offers could not be loaded. Store details are still available.'),
        findsNothing);
    expect(find.byType(StitchFullWidthOfferCard), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('missing store has distinct message', (tester) async {
    await tester.pumpWidget(host(MerchantProfileScreen(
        merchantId: 'missing', api: PartialStoreApi()..missing = true)));
    await tester.pumpAndSettle();
    expect(find.text('This store is no longer available.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
