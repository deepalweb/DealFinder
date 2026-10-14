import 'package:deal_finder_mobile/src/models/promotion.dart';
import 'package:deal_finder_mobile/src/screens/home_screen.dart';
import 'package:deal_finder_mobile/src/screens/all_deals_screen.dart';
import 'package:deal_finder_mobile/src/services/api_service.dart';
import 'package:deal_finder_mobile/src/services/browsing_area.dart';
import 'package:deal_finder_mobile/src/widgets/discover_feed_card.dart';
import 'package:deal_finder_mobile/src/widgets/discover_offer_tile.dart';
import 'package:deal_finder_mobile/src/widgets/discover_offer_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design_system_test.dart' show host;

class FeedApi extends ApiService {
  bool fail = false;
  @override
  Future<List<Promotion>> fetchPromotions({bool forceRefresh = false}) async {
    if (fail) throw Exception('Offline');
    return [
      Promotion(
          id: 'featured',
          title: 'Weekend lunch',
          description: 'Lunch',
          merchantName: 'Ceylon Dining',
          category: 'food_dining',
          featured: true,
          deliveryAvailable: true),
      Promotion(
          id: 'bank',
          title: 'Home essentials card offer',
          description: 'Home',
          merchantName: 'Home Store',
          category: 'shopping_retail',
          bankName: 'Sample Bank',
          cardTypes: ['credit'],
          minimumSpend: 5000),
    ];
  }

  @override
  Future<CuratedHomeSectionsResponse> fetchCuratedHomeSections() async =>
      const CuratedHomeSectionsResponse(
          banner: [],
          hotDeals: [],
          newThisWeek: [],
          flashSales: [],
          bannerManaged: false,
          hotDealsManaged: false,
          newThisWeekManaged: false,
          flashSalesManaged: false);
  @override
  Future<List<Promotion>> fetchRecommendedPromotions(
          {int limit = 10,
          double? latitude,
          double? longitude,
          String? excludePromotionId}) async =>
      [];
}

class NearbyFeedApi extends FeedApi {
  @override
  Future<List<Promotion>> fetchPromotions({bool forceRefresh = false}) async =>
      [
        Promotion(
            id: 'nearby',
            title: 'Nearby lunch',
            description: 'Fixture',
            latitude: 6.911,
            longitude: 79.854,
            visitAvailable: true),
      ];
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await BrowsingArea.select(BrowsingArea.initial);
  });
  testWidgets('floating map entry reserves space outside the feed viewport',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(HomeScreen(api: NearbyFeedApi())));
    await tester.pumpAndSettle();
    final feed = tester.getRect(find.byType(CustomScrollView));
    final caption = tester.getRect(find.text('1 offer within 3 km'));
    expect(caption.top, greaterThan(feed.bottom));
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('explicit bundled artwork is preserved for demo offers',
      (tester) async {
    await tester.pumpWidget(host(Scaffold(
        body: DiscoverOfferImage(
            offer: Promotion(
                id: 'photo',
                title: '[DEMO] Burger',
                description: 'Fixture',
                category: 'food_dining',
                imageDataString: 'assets/discover/stitch-2.jpg')))));
    await tester.pumpAndSettle();
    expect(
        (tester.widget<Image>(find.byType(Image)).image as AssetImage)
            .assetName,
        'assets/discover/stitch-2.jpg');
  });
  testWidgets(
      'delivery filter uses supported capability and carries into all offers',
      (tester) async {
    await tester.pumpWidget(host(HomeScreen(api: FeedApi())));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Delivery').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Browse all offers'), 400,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Home essentials card offer'), findsNothing);
    await tester.tap(find.text('Browse all offers'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<AllDealsScreen>(find.byType(AllDealsScreen))
            .initialCapabilityPresetId,
        'delivery');
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'photo grid expands into one column with large text and keeps taps usable',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var opened = false;
    await tester.pumpWidget(host(
        Scaffold(
            body: SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DiscoverOfferGrid(offers: [
                      Promotion(
                          id: 'tile',
                          title: 'Selected card lunch discount',
                          description: 'Fixture',
                          bankName: 'Sample Bank',
                          minimumSpend: 5000)
                    ], onOpen: (_) => opened = true)))),
        dark: true,
        scale: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selected card lunch discount'));
    expect(opened, true);
    expect(tester.takeException(), isNull);
  });
  testWidgets('category filters bank feed and survives Browse all navigation',
      (tester) async {
    await tester.pumpWidget(host(HomeScreen(api: FeedApi())));
    await tester.pumpAndSettle();
    expect(find.text('Weekend lunch'), findsWidgets);
    final chips =
        tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
    final food = chips.firstWhere((c) =>
        c.label is Text &&
        (c.label as Text).data!.toLowerCase().contains('food'));
    await tester.tap(find.byWidget(food));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Browse all offers'), 400,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Home essentials card offer'), findsNothing);
    await tester.tap(find.text('Browse all offers'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<AllDealsScreen>(find.byType(AllDealsScreen))
            .initialCategoryId,
        'food_dining');
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('failed loading can retry successfully without cached claims',
      (tester) async {
    final api = FeedApi()..fail = true;
    await tester.pumpWidget(host(HomeScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Could not load offers.'), findsOneWidget);
    api.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Weekend lunch'), findsWidgets);
    expect(find.text('Could not load offers.'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('editorial and compact cards adapt to dark mode and large text',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final hero in [true, false]) {
      var opened = false;
      await tester.pumpWidget(host(
          Scaffold(
            body: SingleChildScrollView(
                child: DiscoverFeedCard(
                    hero: hero,
                    onOpen: () => opened = true,
                    offer: Promotion(
                        id: 'offer',
                        title: 'Selected cards weekend lunch offer',
                        description: 'Fixture',
                        bankName: 'Sample Bank',
                        minimumSpend: 5000,
                        cardTypes: ['credit'],
                        endDate: DateTime.now().add(const Duration(days: 2))))),
          ),
          dark: true,
          scale: 2));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.widgetWithText(FilledButton, 'View offer'), 250,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.widgetWithText(FilledButton, 'View offer'));
      expect(opened, true);
      expect(tester.takeException(), isNull);
    }
  });
}
