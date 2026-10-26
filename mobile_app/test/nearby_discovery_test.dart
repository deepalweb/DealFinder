import 'dart:async';
import 'package:deal_finder_mobile/src/models/promotion.dart';
import 'package:deal_finder_mobile/src/services/api_service.dart';
import 'package:deal_finder_mobile/src/services/browsing_area.dart';
import 'package:deal_finder_mobile/src/services/nearby_discovery_controller.dart';
import 'package:deal_finder_mobile/src/utils/merchant_hours.dart';
import 'package:deal_finder_mobile/src/widgets/nearby_offer_row.dart';
import 'package:deal_finder_mobile/src/screens/nearby_deals_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design_system_test.dart' show host;

GoogleMap? testMap;
Widget testMapBuilder(GoogleMap map) {
  testMap = map;
  return const SizedBox.expand();
}

class NearbyApi extends ApiService {
  final requests = <({double lat, double lng, double radius})>[];
  final pending = <Completer<NearbyPromotionsResult>>[];
  @override
  Future<NearbyPromotionsResult> fetchNearbyPromotionsWithCache(
      double lat, double lng,
      {double radiusKm = 10, String? locationName}) {
    requests.add((lat: lat, lng: lng, radius: radiusKm));
    final result = Completer<NearbyPromotionsResult>();
    pending.add(result);
    return result.future;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMerchants(
          {bool forceRefresh = false}) async =>
      [];
}

Promotion offer(String id,
        {double lat = 6.911, String category = 'food_dining'}) =>
    Promotion(
        id: id,
        merchantId: 'store',
        title: 'Selected card lunch offer',
        description: 'Test',
        latitude: lat,
        longitude: 79.854,
        category: category,
        discountedPrice: 1400,
        originalPrice: 2000,
        bankName: 'Test Bank',
        cardTypes: ['credit'],
        endDate: DateTime.now().add(const Duration(days: 2)));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('map search uses the panned center only after explicit search',
      (tester) async {
    final api = NearbyApi();
    await tester.pumpWidget(
        host(NearbyDealsScreen(api: api, mapBuilder: testMapBuilder)));
    await tester.pump();
    await tester.pump();
    api.pending.first
        .complete(NearbyPromotionsResult(promotions: [offer('initial')]));
    await tester.pumpAndSettle();
    testMap!.onCameraMove!(
        const CameraPosition(target: LatLng(6.895, 79.858), zoom: 13));
    await tester.pumpAndSettle();
    expect(api.requests.length, 1);
    await tester.tap(find.text('Search this area'));
    await tester.pump();
    await tester.pump();
    expect(api.requests.last.lat, 6.895);
    expect(api.requests.last.lng, 79.858);
    api.pending.last.complete(
        NearbyPromotionsResult(promotions: [offer('new', lat: 6.895)]));
    await tester.pumpAndSettle();
    expect((await BrowsingArea.read())!.latitude, 6.895);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'results expand without dragging and selecting a row does not refetch',
      (tester) async {
    final api = NearbyApi();
    await tester.pumpWidget(
        host(NearbyDealsScreen(api: api, mapBuilder: testMapBuilder)));
    await tester.pump();
    await tester.pump();
    api.pending.first
        .complete(NearbyPromotionsResult(promotions: [offer('selected')]));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show results').first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Show map'), findsOneWidget);
    await tester.ensureVisible(find.text('Selected card lunch offer'));
    await tester.tap(find.text('Selected card lunch offer'));
    await tester.pumpAndSettle();
    expect(tester.widget<NearbyOfferRow>(find.byType(NearbyOfferRow)).selected,
        true);
    expect(api.requests.length, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test('latest selected area wins when requests finish out of order', () async {
    final api = NearbyApi();
    final data = NearbyDiscoveryController(api: api);
    final first = data.search(BrowsingArea.initial, persist: false);
    const nextArea =
        BrowsingArea(latitude: 7, longitude: 79.854, label: 'New area');
    final second = data.search(nextArea, persist: false);
    api.pending[1]
        .complete(NearbyPromotionsResult(promotions: [offer('new', lat: 7)]));
    await second;
    api.pending[0].complete(NearbyPromotionsResult(promotions: [offer('old')]));
    await first;
    expect(data.area.label, 'New area');
    expect(data.offers.single.id, 'new');
    expect(api.requests[1].lat, 7);
    expect(api.requests[1].radius, 3);
    data.dispose();
  });
  test(
      'category and radius maintain valid selection and exclude distant offers',
      () async {
    final api = NearbyApi();
    final data = NearbyDiscoveryController(api: api);
    final search = data.search(BrowsingArea.initial, persist: false);
    api.pending.single.complete(NearbyPromotionsResult(promotions: [
      offer('food'),
      offer('retail', category: 'shopping_retail'),
      offer('far', lat: 7)
    ]));
    await search;
    expect(data.offers.map((p) => p.id), ['food', 'retail']);
    data.select('retail');
    expect(data.selected!.id, 'retail');
    data.filter(categoryId: 'food_dining');
    expect(data.selected, isNull);
    expect(data.offers.single.id, 'food');
    data.filter(onlyOpen: true);
    expect(data.offers, isEmpty); // Unknown schedules are not labelled open.
    data.dispose();
  });
  test('cache from another area is never shown as current results', () async {
    final api = NearbyApi();
    final data = NearbyDiscoveryController(api: api);
    final search = data.search(BrowsingArea.initial, persist: false);
    api.pending.single.complete(NearbyPromotionsResult(
        promotions: [offer('old')], fromCache: true, locationChanged: true));
    await search;
    expect(data.cacheMismatch, true);
    expect(data.offers, isEmpty);
    data.dispose();
  });
  test('manual area persists without any GPS dependency', () async {
    await BrowsingArea.select(const BrowsingArea(
        latitude: 6.895, longitude: 79.858, label: 'Colombo 04'));
    final restored = await BrowsingArea.read();
    expect(restored!.latitude, 6.895);
    expect(restored.source, 'manual');
    expect(restored.label, 'Colombo 04');
  });
  test('published Colombo hours handle overnight and exact close boundaries',
      () {
    final hours = <String, dynamic>{
      'monday': {'open': '22:00', 'close': '02:00'},
      'tuesday': {'closed': true},
    };
    expect(MerchantHours.isOpen(hours, now: DateTime.utc(2026, 10, 12, 19, 30)),
        true); // Tuesday 01:00
    expect(MerchantHours.isOpen(hours, now: DateTime.utc(2026, 10, 12, 20, 30)),
        false); // Tuesday 02:00
    expect(MerchantHours.isOpen(null), isNull);
    expect(
        MerchantHours.isOpen({
          'tuesday': {'open': '25:00', 'close': '17:00'}
        }, now: DateTime.utc(2026, 10, 13, 5)),
        isNull);
  });
  testWidgets('nearby summary keeps price readable with large text',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(
        Scaffold(
            body: SingleChildScrollView(
                child: NearbyOfferRow(
                    offer: offer('row'),
                    selected: true,
                    onSelect: () {},
                    onOpen: () {}))),
        dark: true,
        scale: 2));
    await tester.pumpAndSettle();
    expect(find.textContaining('Test Bank'), findsNothing);
    expect(find.text('LKR1,400'), findsOneWidget);
    expect(find.byTooltip('View offer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('shared area changes refresh Nearby without duplicate own requests',
      () async {
    await BrowsingArea.select(BrowsingArea.initial);
    final api = NearbyApi();
    final data = NearbyDiscoveryController(api: api);
    const next =
        BrowsingArea(latitude: 6.895, longitude: 79.858, label: 'Colombo 04');
    await BrowsingArea.select(next);
    expect(api.requests.length, 1);
    api.pending.single.complete(
        NearbyPromotionsResult(promotions: [offer('new', lat: 6.895)]));
    await Future<void>.delayed(Duration.zero);
    expect(data.area.label, 'Colombo 04');
    final own = data.search(BrowsingArea.initial);
    await Future<void>.delayed(Duration.zero);
    expect(api.requests.length, 2);
    api.pending.last
        .complete(NearbyPromotionsResult(promotions: [offer('own')]));
    await own;
    expect(api.requests.length, 2);
    data.dispose();
  });
  test('Nearby excludes private offers and invalid coordinates', () async {
    final api = NearbyApi();
    final data = NearbyDiscoveryController(api: api);
    final result = data.search(BrowsingArea.initial, persist: false);
    api.pending.single.complete(NearbyPromotionsResult(promotions: [
      offer('public'),
      offer('private').copyWith(status: 'pending_review'),
      offer('invalid', lat: 95)
    ]));
    await result;
    expect(data.offers.map((p) => p.id), ['public']);
    data.dispose();
  });
  testWidgets(
      'nearby cards have equal size despite optional details and titles',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = false;
    var opened = false;
    final first = offer('short').copyWith(
        title: 'Lunch',
        merchantName: 'Cafe',
        averageRating: 4.5,
        ratingsCount: 12,
        distance: 650);
    final second = offer('long').copyWith(
        title: 'A much longer offer title that wraps across several lines',
        merchantName: 'A longer store name for this second card',
        minimumSpend: 3000,
        maximumBenefit: 1000);
    await tester.pumpWidget(host(Scaffold(
        body: Column(children: [
      NearbyOfferRow(
          offer: first,
          selected: false,
          onSelect: () => selected = true,
          onOpen: () => opened = true),
      NearbyOfferRow(
          offer: second, selected: true, onSelect: () {}, onOpen: () {}),
    ]))));
    await tester.pumpAndSettle();
    final rows = find.byType(NearbyOfferRow);
    expect(tester.getSize(rows.at(0)), tester.getSize(rows.at(1)));
    expect(find.text('4.5 (12)'), findsOneWidget);
    expect(find.textContaining('650 m'), findsOneWidget);
    expect(find.text('Not rated'), findsOneWidget);
    expect(find.textContaining('Test Bank'), findsNothing);
    await tester.tap(find.text('Lunch'));
    expect(selected, isTrue);
    await tester.tap(find.byTooltip('View offer').first);
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });
}
