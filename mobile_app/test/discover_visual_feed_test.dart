import 'package:deal_finder_mobile/src/models/promotion.dart';
import 'package:deal_finder_mobile/src/screens/home_screen.dart';
import 'package:deal_finder_mobile/src/screens/all_deals_screen.dart';
import 'package:deal_finder_mobile/src/services/api_service.dart';
import 'package:deal_finder_mobile/src/services/browsing_area.dart';
import 'package:deal_finder_mobile/src/widgets/discover_feed_card.dart';
import 'package:deal_finder_mobile/src/widgets/discover_marketplace_card.dart';
import 'package:deal_finder_mobile/src/screens/categories_screen.dart';
import 'package:deal_finder_mobile/src/widgets/stitch_discover_components.dart';
import 'package:deal_finder_mobile/src/widgets/discover_offer_tile.dart';
import 'package:deal_finder_mobile/src/widgets/discover_offer_image.dart';
import 'package:deal_finder_mobile/src/widgets/discover_filter_sheet.dart';
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
          latitude: 6.911,
          longitude: 79.854,
          visitAvailable: true,
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

class MarketplaceApi extends FeedApi {
  @override
  Future<List<Promotion>> fetchPromotions({bool forceRefresh = false}) async =>
      [
        Promotion(
            id: 'low',
            title: 'Low discount',
            description: 'Fixture',
            discount: '10%',
            endDate: DateTime.now().add(const Duration(days: 10))),
        Promotion(
            id: 'high',
            title: 'High discount',
            description: 'Fixture',
            discount: '50%',
            endDate: DateTime.now().add(const Duration(days: 1))),
        Promotion(
            id: 'middle',
            title: 'Middle discount',
            description: 'Fixture',
            discount: '25%',
            endDate: DateTime.now().add(const Duration(days: 20))),
      ];
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await BrowsingArea.select(BrowsingArea.initial);
  });
  testWidgets(
      'nearby results respond to manual area without relabeling distant offers',
      (tester) async {
    await tester.pumpWidget(host(HomeScreen(api: NearbyFeedApi())));
    await tester.pumpAndSettle();
    expect(find.text('Colombo 03'), findsOneWidget);
    expect(find.text('Nearby lunch'), findsWidgets);
    await tester.scrollUntilVisible(find.byType(StitchNearbyOfferCard), 160,
        scrollable: find
            .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable))
            .first);
    expect(find.byType(StitchNearbyOfferCard), findsOneWidget);
    await BrowsingArea.select(
        const BrowsingArea(latitude: 7.29, longitude: 80.63, label: 'Kandy'));
    await tester.pumpAndSettle();
    tester
        .state<ScrollableState>(find
            .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable))
            .first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('Kandy'), findsOneWidget);
    expect(find.byType(StitchNearbyOfferCard), findsNothing);
    expect(find.text('Matching offers loaded so far'), findsOneWidget);
    expect(find.text('1 offer within 3 km'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'sorting uses percentage data and availability excludes later offers',
      (tester) async {
    await tester.pumpWidget(host(HomeScreen(api: MarketplaceApi())));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filters').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Highest Discount'));
    await tester.scrollUntilVisible(find.text('Apply filters'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Middle discount'), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.scrollUntilVisible(find.text('Low discount'), 100,
        scrollable: find.byType(Scrollable).first);
    expect(tester.getTopLeft(find.text('Middle discount')).dx,
        lessThan(tester.getTopLeft(find.text('Low discount')).dx));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 3000));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filters').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile).last);
    await tester.scrollUntilVisible(find.text('Apply filters'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('High discount'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Middle discount'), findsNothing);
    expect(find.text('Low discount'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('photo-led nearby savings appear before bank offers',
      (tester) async {
    await tester.pumpWidget(host(HomeScreen(api: FeedApi())));
    await tester.pumpAndSettle();
    expect(find.byType(StitchQuickFilters), findsOneWidget);
    expect(find.byType(StitchHorizontalOfferCard), findsWidgets);
    final firstTitle = tester.getTopLeft(find.text('Weekend lunch')).dy;
    await tester.scrollUntilVisible(find.text('Bank Perks'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(firstTitle,
        lessThan(tester.getTopLeft(find.text('Bank Perks')).dy + 1000));
    await tester.scrollUntilVisible(
        find.byWidgetPredicate(
            (w) => w is StitchBankGridCard && w.offer.id == 'bank'),
        150,
        scrollable: find.byType(Scrollable).first);
    expect(find.byType(StitchBankGridCard), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'marketplace survives small and landscape layouts with enlarged text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(375, 812), const Size(812, 375)]) {
      tester.view.physicalSize = size;
      await tester
          .pumpWidget(host(HomeScreen(api: FeedApi()), dark: true, scale: 2));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
  testWidgets('localized marketplace categories and header fit enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final locale in [const Locale('si'), const Locale('ta')]) {
      final base =
          host(HomeScreen(api: FeedApi()), dark: true, scale: 2) as MaterialApp;
      await tester.pumpWidget(MaterialApp(
          theme: base.theme,
          locale: locale,
          supportedLocales: base.supportedLocales,
          localizationsDelegates: base.localizationsDelegates,
          builder: base.builder,
          home: base.home));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
  testWidgets(
      'photo listing opens details and shows supported conditions in dark large text',
      (tester) async {
    var opened = false;
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(
        Scaffold(
            body: SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DiscoverMarketplaceCard(
                        offer: Promotion(
                            id: 'listing',
                            title: 'Lunch offer',
                            merchantName: 'Sample café',
                            description: 'Fixture',
                            discount: '25% off',
                            bankName: 'Sample Bank',
                            cardTypes: ['credit'],
                            minimumSpend: 2000,
                            originalPrice: 3200,
                            discountedPrice: 2400,
                            maximumBenefit: 1500,
                            distance: 850),
                        onOpen: () => opened = true)))),
        dark: true,
        scale: 2));
    await tester.pumpAndSettle();
    expect(find.text('25% off'), findsOneWidget);
    expect(find.textContaining('Sample Bank'), findsOneWidget);
    expect(find.textContaining('850 m'), findsOneWidget);
    expect(find.textContaining('Maximum discount'), findsOneWidget);
    await tester.ensureVisible(find.text('Sample café'));
    await tester.tap(find.text('Sample café'));
    expect(opened, true);
    expect(tester.takeException(), isNull);
  });
  testWidgets('filter sheet stays usable at double text size in dark mode',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester
        .pumpWidget(host(HomeScreen(api: FeedApi()), dark: true, scale: 2));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1800));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filters').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Apply filters'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.scrollUntilVisible(find.text('Apply filters'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    expect(find.byType(DiscoverFilterSheet), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('filter sheet edits drafts and cancel leaves feed unchanged',
      (tester) async {
    await tester.pumpWidget(host(HomeScreen(api: FeedApi())));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Weekend lunch'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Weekend lunch'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1800));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filters').first);
    await tester.pumpAndSettle();
    expect(find.byType(DiscoverFilterSheet), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Weekend lunch'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Weekend lunch'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1800));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filters').first);
    await tester.pumpAndSettle();
    expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
        false);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('applying empty filter combination provides a working reset',
      (tester) async {
    await tester.pumpWidget(host(HomeScreen(api: FeedApi())));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1800));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filters').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Delivery'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Apply filters'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Clear filters').first, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Clear filters').first);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1200));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Weekend lunch'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Weekend lunch'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'compact tile exposes card requirements, expiry, and metre distances',
      (tester) async {
    await tester.pumpWidget(host(Scaffold(
        body: SingleChildScrollView(
            child: SizedBox(
                width: 180,
                child: DiscoverOfferTile(
                    offer: Promotion(
                        id: 'tile',
                        title: 'Lunch offer',
                        merchantName: 'Sample café',
                        description: 'Fixture',
                        bankName: 'Sample Bank',
                        cardTypes: ['credit'],
                        distance: 850,
                        endDate: DateTime.now().add(const Duration(days: 2))),
                    onOpen: () {}))))));
    await tester.pumpAndSettle();
    expect(find.text('Credit cards'), findsOneWidget);
    expect(find.text('850 m'), findsOneWidget);
    expect(find.textContaining('Ends '), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'map action is reachable in the header without a floating obstruction',
      (tester) async {
    var opened = false;
    await tester.pumpWidget(host(HomeScreen(
        api: NearbyFeedApi(), onNavigateNearby: () => opened = true)));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.tap(find.text('Colombo 03'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nearby'));
    await tester.pumpAndSettle();
    expect(opened, true);
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
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1800));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filters').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Delivery'));
    await tester.scrollUntilVisible(find.text('Apply filters'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.scrollUntilVisible(find.text('Apply filters'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('All Deals'), 400,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Home essentials card offer'), findsNothing);
    await tester.tap(find.text('All Deals'));
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
    await tester.scrollUntilVisible(
        find.widgetWithText(TextButton, 'All Categories'), 200,
        scrollable: find
            .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable))
            .first);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'All Categories'));
    await tester.pumpAndSettle();
    expect(find.byType(CategoriesScreen), findsOneWidget);
    await tester.tap(find.text('Food & Dining'));
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
