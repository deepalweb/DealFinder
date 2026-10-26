import 'package:deal_finder_mobile/src/utils/bank_card_promotion_support.dart';
import 'package:deal_finder_mobile/src/models/promotion.dart';
import 'package:deal_finder_mobile/src/utils/offer_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Promotion offer({double? price, double? previous, String? discount}) =>
      Promotion(
          id: 'a',
          title: 'Offer',
          description: '',
          price: price,
          originalPrice: previous,
          discount: discount);
  test(
      'unknown and invalid prices never become free or previous-price bargains',
      () {
    expect(OfferPresentation(offer(previous: 3000)).price, isNull);
    expect(OfferPresentation(offer(previous: 3000)).previous, isNull);
    expect(OfferPresentation(offer(price: double.nan)).price, isNull);
    expect(OfferPresentation(offer(price: -100)).price, isNull);
    expect(OfferPresentation(offer(price: 0)).price, 0);
    expect(
        OfferPresentation(offer(price: 3000, previous: 2000)).previous, isNull);
  });
  test('currency savings do not become percentage discounts', () {
    expect(OfferPresentation(offer(discount: 'Save LKR 1,500')).percentage, 0);
    expect(OfferPresentation(offer(discount: '25% off')).percentage, 25);
    expect(OfferPresentation(offer(discount: '1500%')).percentage, 0);
    expect(
        OfferPresentation(offer(price: 2400, previous: 3200)).percentage, 25);
  });
  test('resource identities separate bank offers and merchant promotions', () {
    final bank = Promotion(
        id: 'same',
        title: 'Bank offer',
        description: '',
        category: 'bank_cards');
    final merchant = bank.copyWith(merchantId: 'store');
    expect(OfferPresentation(bank).identity, 'bank:same');
    expect(OfferPresentation(merchant).identity, 'promotion:same');
  });
  test('online offers never acquire physical visits or distance', () {
    final online = Promotion(
        id: 'web',
        title: 'Online',
        description: '',
        fulfillmentType: 'order',
        visitAvailable: true,
        distance: 100);
    expect(OfferPresentation(online).distance, isNull);
    expect(online.supportsVisit, false);
  });
  test('date-only boundaries use Sri Lanka start and end of day', () {
    final parsed = Promotion.fromJson(
        {'_id': 'a', 'startDate': '2026-10-15', 'endDate': '2026-10-15'});
    expect(parsed.startDate!.toUtc(), DateTime.utc(2026, 10, 14, 18, 30));
    expect(
        parsed.endDate!.toUtc(), DateTime.utc(2026, 10, 15, 18, 29, 59, 999));
  });
  test('gallery survives serialization and pending offers remain private', () {
    final parsed = Promotion.fromJson({
      '_id': 'a',
      'images': ['one.jpg', 'two.jpg'],
      'status': 'pending_review'
    });
    expect(Promotion.fromJson(parsed.toJson()).images, ['one.jpg', 'two.jpg']);
    expect(OfferPresentation(parsed).public, false);
  });
  test('unknown current prices sort last in both directions', () {
    final unknown = offer(previous: 100), priced = offer(price: 100);
    expect(OfferPresentation.comparePrices(unknown, priced), 1);
    expect(
        OfferPresentation.comparePrices(unknown, priced, descending: true), 1);
  });
  test(
      'spend-threshold discount uses its stated benefit rather than an inferred item price',
      () {
    final bill = Promotion(
        id: 'bill',
        title: 'Dining',
        description: '',
        discount: '25% off your food bill',
        minimumSpend: 3000,
        discountedPrice: 2400,
        originalPrice: 3200);
    expect(OfferPresentation(bill).useDiscountHeadline, true);
    expect(OfferPresentation(offer(price: 1900)).useDiscountHeadline, false);
    expect(bill.copyWith(distance: 650).copyWith(clearDistance: true).distance,
        isNull);
  });
  test(
      'bank eligibility is a facet rather than a replacement for shopping categories',
      () {
    final dining = Promotion(
        id: 'food-bank',
        title: 'Dining offer',
        description: '',
        category: 'food_dining',
        bankName: 'Example Bank',
        cardTypes: ['credit']);
    expect(
        BankCardPromotionSupport.matchesCategory(dining, 'food_dining'), true);
    expect(
        BankCardPromotionSupport.matchesCategory(dining, 'bank_cards'), true);
    expect(BankCardPromotionSupport.matchesCategory(dining, 'shopping_retail'),
        false);
  });
}
