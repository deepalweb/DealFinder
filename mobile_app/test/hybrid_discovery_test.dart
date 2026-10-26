import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deal_finder_mobile/src/models/promotion.dart';
import 'package:deal_finder_mobile/src/screens/home_screen.dart';
import 'package:deal_finder_mobile/src/screens/all_deals_screen.dart';
import 'package:deal_finder_mobile/src/services/browsing_area.dart';
import 'package:deal_finder_mobile/src/widgets/discover_filter_sheet.dart';
import 'package:deal_finder_mobile/src/utils/deal_filter_support.dart';
import 'design_system_test.dart' show host;
import 'discover_visual_feed_test.dart' show FeedApi;

class HybridApi extends FeedApi {
  bool failPage = true;
  bool empty = false;
  Completer<List<Promotion>>? pending;
  final skips = <int>[];
  @override
  Future<List<Promotion>> fetchPromotions({bool forceRefresh = false}) async =>
      empty
          ? []
          : [
              Promotion(
                  id: 'shop',
                  merchantId: 'm',
                  title: 'Loaded shopping offer',
                  description: '',
                  category: 'shopping_retail'),
              for (var i = 1; i < 50; i++)
                Promotion(
                    id: '$i',
                    title: 'Hidden pending',
                    description: '',
                    status: 'pending_review')
            ];
  @override
  Future<List<Promotion>> fetchPromotionPage(
      {int limit = 50, int skip = 0}) async {
    skips.add(skip);
    if (pending != null) return pending!.future;
    if (failPage) throw StateError('Offline');
    return [
      Promotion(
          id: 'food',
          merchantId: 'm',
          title: 'Food from next page',
          description: '',
          category: 'food_dining')
    ];
  }
}

class FilterApi extends FeedApi {
  @override
  Future<List<Promotion>> fetchPromotions({bool forceRefresh = false}) async =>
      [
        Promotion(
            id: 'online',
            merchantId: 'm',
            title: 'Online dining offer',
            description: '',
            category: 'food_dining',
            merchantType: 'online',
            distance: 200,
            latitude: 6.91,
            longitude: 79.85,
            bankName: 'Example Bank',
            cardTypes: ['credit']),
        Promotion(
            id: 'local',
            merchantId: 'm',
            title: 'In-store dining offer',
            description: '',
            category: 'food_dining',
            visitAvailable: true,
            latitude: 6.91,
            longitude: 79.85),
        Promotion(
            id: 'other',
            merchantId: 'm',
            title: 'Unrelated shopping bank offer',
            description: '',
            category: 'shopping_retail',
            bankName: 'Example Bank',
            cardTypes: ['credit']),
      ];
}

Finder get feedScroll => find
    .descendant(
        of: find.byType(CustomScrollView).first,
        matching: find.byType(Scrollable))
    .first;

Future<void> selectFood(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Filters'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
      find.widgetWithText(ChoiceChip, 'Food & Dining'), 150,
      scrollable: find.byType(Scrollable).last);
  await tester.tap(find.widgetWithText(ChoiceChip, 'Food & Dining'));
  await tester.scrollUntilVisible(find.text('Apply filters'), 200,
      scrollable: find.byType(Scrollable).last);
  await tester.tap(find.text('Apply filters'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await BrowsingArea.select(BrowsingArea.initial);
  });
  testWidgets('zero loaded matches keep filters through page failure and retry',
      (tester) async {
    final api = HybridApi();
    await tester.pumpWidget(host(HomeScreen(api: api)));
    await tester.pumpAndSettle();
    await selectFood(tester);
    expect(
        find.textContaining('No matches in loaded results.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Load more offers'), 200,
        scrollable: feedScroll);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load more offers'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('No matches in loaded results.'), findsOneWidget);
    api.failPage = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    tester.state<ScrollableState>(feedScroll).position.jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('Food from next page'), findsOneWidget);
    expect(find.text('Loaded shopping offer'), findsNothing);
    expect(api.skips, [50, 50]);
    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<DiscoverFilterSheet>(find.byType(DiscoverFilterSheet))
            .initial
            .category,
        'food_dining');
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('fresh inventory response disregards an old page response',
      (tester) async {
    final api = HybridApi()..pending = Completer<List<Promotion>>();
    await tester.pumpWidget(host(HomeScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Load more offers'), 250,
        scrollable: feedScroll);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load more offers'));
    await tester.pump();
    api.empty = true;
    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    api.pending!.complete(
        [Promotion(id: 'late', title: 'Late stale offer', description: '')]);
    await tester.pumpAndSettle();
    expect(find.text('Late stale offer'), findsNothing);
    expect(find.text('No offers returned by the service.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'category and online filters exclude unrelated bank offers and distance',
      (tester) async {
    await tester.pumpWidget(host(HomeScreen(api: FilterApi())));
    await tester.pumpAndSettle();
    await selectFood(tester);
    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Online'));
    await tester.scrollUntilVisible(find.text('Apply filters'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    expect(find.text('Online dining offer'), findsOneWidget);
    expect(find.textContaining('from selected area'), findsNothing);
    expect(find.text('In-store dining offer'), findsNothing);
    expect(find.text('Unrelated shopping bank offer'), findsNothing);
    await tester.scrollUntilVisible(find.text('All Deals'), 250,
        scrollable: feedScroll);
    await tester.ensureVisible(find.text('All Deals'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Deals'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<AllDealsScreen>(find.byType(AllDealsScreen))
            .initialCapabilityPresetId,
        'online');
    expect(
        matchesDealCapabilityPreset(
            Promotion(
                id: 'x',
                title: 'Online',
                description: '',
                merchantType: 'online'),
            'online'),
        true);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('raw page continuation survives consumer visibility filtering',
      (tester) async {
    final api = HybridApi()..empty = true;
    api.lastPromotionPageHasMore = true;
    await tester.pumpWidget(host(HomeScreen(api: api)));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('No matches in loaded results.'), findsOneWidget);
    expect(find.text('Load more offers'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
