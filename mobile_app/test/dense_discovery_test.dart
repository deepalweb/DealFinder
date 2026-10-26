import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deal_finder_mobile/src/models/promotion.dart';
import 'package:deal_finder_mobile/src/screens/home_screen.dart';
import 'package:deal_finder_mobile/src/services/browsing_area.dart';
import 'package:deal_finder_mobile/src/widgets/stitch_discover_components.dart';
import 'design_system_test.dart' show host;
import 'discover_visual_feed_test.dart' show FeedApi;

class DenseFeedApi extends FeedApi {
  @override
  Future<List<Promotion>> fetchPromotions({bool forceRefresh = false}) async =>
      [
        for (var i = 0; i < 12; i++)
          Promotion(
              id: 'dense-$i',
              merchantId: 'store',
              title: 'Offer $i',
              description: '',
              merchantName: 'Store $i',
              discount: '25% off',
              minimumSpend: 3000,
              maximumBenefit: 1000,
              bankName: i >= 4 && i < 8 ? 'Fixture Bank' : null,
              visitAvailable: true),
      ];
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await BrowsingArea.select(BrowsingArea.initial);
  });

  testWidgets('Discover shows a peeking rail, bank grid and full-width feed',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(HomeScreen(api: DenseFeedApi())));
    await tester.pumpAndSettle();
    Finder card(String id) => find.byWidgetPredicate(
        (w) => w is StitchHorizontalOfferCard && w.offer.id == id);
    expect(tester.getSize(card('dense-0')).width, lessThan(320));
    expect(tester.getTopLeft(card('dense-1')).dx, lessThan(390));
    final scroll = find
        .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(find.text('Bank Perks'), 180,
        scrollable: scroll);
    final bankCards = find.byType(StitchBankGridCard);
    expect(tester.getTopLeft(bankCards.at(0)).dy,
        tester.getTopLeft(bankCards.at(1)).dy);
    expect(tester.getTopLeft(bankCards.at(0)).dx,
        lessThan(tester.getTopLeft(bankCards.at(1)).dx));
    await tester.scrollUntilVisible(find.text('More deals to explore'), 180,
        scrollable: scroll);
    final feed = find.byType(StitchFullWidthOfferCard).first;
    expect(tester.getSize(feed).width, 358);
    expect(find.textContaining('Max discount'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Discover restores roomy cards at enlarged text', (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(HomeScreen(api: DenseFeedApi()), scale: 2));
    await tester.pumpAndSettle();
    final scroll = find
        .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(find.text('Bank Perks'), 200,
        scrollable: scroll);
    final firstBank = find.byWidgetPredicate(
        (w) => w is StitchBankGridCard && w.offer.id == 'dense-4');
    await tester.scrollUntilVisible(firstBank, 200, scrollable: scroll);
    expect(tester.getSize(firstBank).width, 288);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Discover matches dimensions within each compact card variant',
      (tester) async {
    final short = Promotion(
        id: 'short',
        title: 'Lunch',
        description: '',
        merchantName: 'Cafe',
        discountedPrice: 1400);
    final long = Promotion(
        id: 'long',
        title: 'A long offer title that wraps differently from a short title',
        description: '',
        merchantName: 'Longer store name',
        discount: '25% off',
        bankName: 'Test Bank',
        minimumSpend: 10000,
        maximumBenefit: 5000,
        averageRating: 4.8,
        ratingsCount: 22,
        distance: 400);
    for (final scale in [1.0, 2.0]) {
      for (final kind in ['nearby', 'rail', 'bank']) {
        Widget card(Promotion offer, Key key) => switch (kind) {
              'nearby' =>
                StitchNearbyOfferCard(key: key, offer: offer, onOpen: () {}),
              'bank' =>
                StitchBankGridCard(key: key, offer: offer, onOpen: () {}),
              _ => StitchHorizontalOfferCard(
                  key: key, offer: offer, onOpen: () {}),
            };
        const first = ValueKey('first-card'), second = ValueKey('second-card');
        await tester.pumpWidget(host(
            Scaffold(
                body: SingleChildScrollView(
                    child: Column(children: [
              SizedBox(
                  width: kind == 'rail' ? 250 : 173, child: card(short, first)),
              SizedBox(
                  width: kind == 'rail' ? 250 : 173, child: card(long, second)),
            ]))),
            scale: scale,
            dark: scale == 2));
        await tester.pumpAndSettle();
        expect(tester.getSize(find.byKey(first)),
            tester.getSize(find.byKey(second)),
            reason: '$kind cards must match at text scale $scale');
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
