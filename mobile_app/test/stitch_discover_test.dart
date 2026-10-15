import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deal_finder_mobile/src/screens/home_screen.dart';
import 'package:deal_finder_mobile/src/services/api_service.dart';
import 'package:deal_finder_mobile/src/models/promotion.dart';
import 'package:deal_finder_mobile/src/services/browsing_area.dart';
import 'package:deal_finder_mobile/src/widgets/stitch_discover_components.dart';
import 'design_system_test.dart' show host;
import '../tool/stitch_discover_preview_test.dart'
    show StitchFixtureApi, fixtureNow;

class FailedSectionsApi extends StitchFixtureApi {
  @override
  Future<CuratedHomeSectionsResponse> fetchCuratedHomeSections() async =>
      throw StateError('Unavailable');
}

class NearbyPreviewApi extends StitchFixtureApi {
  @override
  Future<List<Promotion>> fetchPromotions({bool forceRefresh = false}) async =>
      [
        for (final point in [
          ('second', 6.921, 79.854, false),
          ('close', 6.912, 79.854, false),
          ('far', 7.29, 80.63, false),
          ('online', 6.911, 79.854, true),
        ])
          Promotion(
              id: point.$1,
              title: point.$1,
              description: '',
              latitude: point.$2,
              longitude: point.$3,
              merchantId: 'store',
              merchantType: point.$4 ? 'online' : 'offline'),
        Promotion(id: 'unknown', title: 'Unknown coordinates', description: ''),
      ];
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
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await BrowsingArea.select(BrowsingArea.initial);
  });

  testWidgets(
      'Nearby preview uses selected area, excludes online and unknown locations, and opens Nearby',
      (tester) async {
    tester.view.physicalSize = const Size(390, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var openedNearby = false;
    await tester.pumpWidget(host(HomeScreen(
        api: NearbyPreviewApi(), onNavigateNearby: () => openedNearby = true)));
    await tester.pumpAndSettle();
    List<String> ids() => tester
        .widgetList<StitchNearbyOfferCard>(find.byType(StitchNearbyOfferCard))
        .map((w) => w.offer.id)
        .toList();
    expect(ids(), ['close', 'second']);
    expect(tester.getSize(find.byType(StitchNearbyOfferCard).first).width, 173);
    final title = find.text('Nearby Deals');
    final section =
        find.ancestor(of: title, matching: find.byType(Padding)).first;
    await tester
        .tap(find.descendant(of: section, matching: find.byType(TextButton)));
    await tester.pumpAndSettle();
    expect(openedNearby, isTrue);
    await BrowsingArea.select(
        const BrowsingArea(latitude: 7.29, longitude: 80.63, label: 'Kandy'));
    await tester.pumpAndSettle();
    expect(ids(), ['far']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'curated banner, expiry, rail, bank grid and feed stay ordered and deduplicated',
      (tester) async {
    tester.view.physicalSize = const Size(390, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
        host(HomeScreen(api: StitchFixtureApi(), now: () => fixtureNow)));
    await tester.pumpAndSettle();
    expect(find.byType(StitchFeaturedBanner), findsOneWidget);
    expect(find.byType(StitchExpiringOfferStrip), findsOneWidget);
    expect(find.byType(StitchHorizontalOfferCard), findsNWidgets(2));
    expect(find.byType(StitchBankGridCard), findsNWidgets(4));
    expect(find.byType(StitchFullWidthOfferCard), findsNWidgets(3));
    final ordered = [
      find.byType(StitchFeaturedBanner),
      find.byType(StitchExpiringOfferStrip),
      find.byType(StitchHorizontalOfferCard).first,
      find.byType(StitchBankGridCard).first,
      find.byType(StitchFullWidthOfferCard).first
    ];
    for (var i = 1; i < ordered.length; i++) {
      expect(tester.getTopLeft(ordered[i]).dy,
          greaterThan(tester.getTopLeft(ordered[i - 1]).dy));
    }
    final ids = [
      tester
          .widget<StitchFeaturedBanner>(find.byType(StitchFeaturedBanner))
          .offer
          .id,
      tester
          .widget<StitchExpiringOfferStrip>(
              find.byType(StitchExpiringOfferStrip))
          .offer
          .id,
      ...tester
          .widgetList<StitchHorizontalOfferCard>(
              find.byType(StitchHorizontalOfferCard))
          .map((w) => w.offer.id),
      ...tester
          .widgetList<StitchBankGridCard>(find.byType(StitchBankGridCard))
          .map((w) => w.offer.id),
      ...tester
          .widgetList<StitchFullWidthOfferCard>(
              find.byType(StitchFullWidthOfferCard))
          .map((w) => w.offer.id),
    ];
    expect(ids.toSet().length, 11);
    expect(find.textContaining('claimed'), findsNothing);
    expect(find.textContaining('registered cards'), findsNothing);
    expect(find.textContaining('Ends in 1 h 42 m'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'failed bank and curated requests expose retries rather than empty inventory claims',
      (tester) async {
    final api = FailedSectionsApi()..lastBankOffersFailed = true;
    await tester.pumpWidget(host(HomeScreen(api: api, now: () => fixtureNow)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Featured offers could not be refreshed.'),
        findsOneWidget);
    final scroll = find
        .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(
        find.textContaining('Bank offers could not be refreshed.'), 200,
        scrollable: scroll);
    expect(find.textContaining('Bank offers could not be refreshed.'),
        findsOneWidget);
    expect(find.text('No offers returned by the service.'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
