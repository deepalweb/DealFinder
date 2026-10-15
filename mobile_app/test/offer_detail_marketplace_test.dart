import 'package:deal_finder_mobile/src/models/promotion.dart';
import 'package:deal_finder_mobile/src/screens/deal_detail_screen.dart';
import 'package:deal_finder_mobile/src/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design_system_test.dart' show host;

class DetailApi extends ApiService {
  int promotionCalls = 0;
  @override
  Future<Map<String, dynamic>> fetchMerchantById(String id) async => {};
  @override
  Future<List<Map<String, dynamic>>> fetchPromotionComments(String id) async {
    promotionCalls++;
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPromotionRatings(String id) async {
    promotionCalls++;
    return [];
  }

  @override
  Future<Map<String, dynamic>> fetchPromotionStats(String id) async {
    promotionCalls++;
    return {};
  }

  @override
  Future<Map<String, dynamic>> fetchPromotionRedemptionFeedback(
      String id) async {
    promotionCalls++;
    return {};
  }

  @override
  Future<void> recordPromotionClick(String id,
      {String type = 'click', String? token, String? userId}) async {
    promotionCalls++;
  }

  @override
  Future<List<Promotion>> fetchPromotions({bool forceRefresh = false}) async =>
      [];
  @override
  Future<List<Promotion>> fetchRecommendedPromotions(
          {int limit = 10,
          double? latitude,
          double? longitude,
          String? excludePromotionId}) async =>
      [];
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
      'details show real gallery and conditions without expanding a disclosure',
      (tester) async {
    await tester.pumpWidget(host(DealDetailScreen(
        api: DetailApi(),
        promotion: Promotion(
            id: 'fixture',
            title: '[DEMO] Lunch',
            description: 'Lunch description',
            imageDataString: 'assets/discover/stitch-1.jpg',
            images: [
              'assets/discover/stitch-2.jpg',
              'assets/discover/stitch-3.jpg'
            ],
            termsAndConditions: 'Selected cards only. Reservation required.',
            discountedPrice: 2400,
            originalPrice: 3200))));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.drag(find.byType(PageView).first, const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.textContaining('Selected cards only.'), 300,
        scrollable: find
            .descendant(
                of: find.byType(SingleChildScrollView).first,
                matching: find.byType(Scrollable))
            .first);
    expect(find.textContaining('Selected cards only.'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'standalone bank details never call merchant promotion analytics or reviews',
      (tester) async {
    final api = DetailApi();
    await tester.pumpWidget(host(DealDetailScreen(
        api: api,
        promotion: Promotion(
            id: 'bank-id',
            title: 'Card offer',
            description: 'Terms',
            category: 'bank_cards'))));
    await tester.pumpAndSettle();
    expect(api.promotionCalls, 0);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'detail summary leads with title and keeps one primary destination',
      (tester) async {
    await tester.pumpWidget(host(DealDetailScreen(
        api: DetailApi(),
        promotion: Promotion(
            id: 'summary',
            merchantId: 'fixture-store',
            title: 'Weekend lunch set',
            description: 'Fixture',
            merchantName: 'Fixture Cafe',
            discountedPrice: 2400,
            originalPrice: 3200,
            averageRating: 4.8,
            ratingsCount: 12,
            distance: 650,
            fulfillmentType: 'order',
            url: 'https://example.com/offer',
            minimumSpend: 3000,
            maximumBenefit: 1000,
            bankName: 'Fixture Bank'))));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Weekend lunch set')).dy,
        lessThan(tester.getTopLeft(find.text('LKR2,400')).dy));
    expect(find.text('4.8 (12)'), findsOneWidget);
    expect(find.textContaining('650'), findsNothing);
    expect(find.text('Get directions'), findsNothing);
    final bar = tester
        .widget<Scaffold>(find.byType(Scaffold).first)
        .bottomNavigationBar!;
    expect(
        find.descendant(
            of: find.byWidget(bar), matching: find.byType(FilledButton)),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'detail conditions and sticky action fit narrow enlarged dark text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(
        DealDetailScreen(
            api: DetailApi(),
            promotion: Promotion(
                id: 'large',
                merchantId: 'fixture-store',
                title: '25% off your food bill',
                description: 'Fixture description',
                merchantName: 'Fixture Cafe',
                discount: '25% off',
                bankName: 'Fixture Bank',
                cardTypes: ['credit'],
                minimumSpend: 3000,
                maximumBenefit: 1000,
                url: 'https://example.com/offer',
                termsAndConditions: 'Reservation required.')),
        scale: 2,
        dark: true));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Reservation required.'), 200,
        scrollable: find
            .descendant(
                of: find.byType(SingleChildScrollView).first,
                matching: find.byType(Scrollable))
            .first);
    expect(find.text('Reservation required.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
