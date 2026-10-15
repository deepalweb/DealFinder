import '../models/promotion.dart';
import 'bank_card_promotion_support.dart';

/// Resource-aware consumer presentation, independent of widgets and repositories.
class OfferPresentation {
  final Promotion offer;
  const OfferPresentation(this.offer);
  bool get standaloneBank =>
      offer.merchantId == null &&
      BankCardPromotionSupport.isBankCardPromotion(offer);
  String get identity => '${standaloneBank ? 'bank' : 'promotion'}:${offer.id}';
  double? get price =>
      validAmount(offer.discountedPrice) ?? validAmount(offer.price);
  double? get previous => price != null &&
          validAmount(offer.originalPrice) != null &&
          offer.originalPrice! > price!
      ? offer.originalPrice
      : null;
  // Bill-level restrictions do not establish an individual item's sale price.
  bool get useDiscountHeadline =>
      offer.discount?.trim().isNotEmpty == true &&
      (price == null || (validAmount(offer.minimumSpend) ?? 0) > 0);
  double? get savings => previous == null ? null : previous! - price!;
  bool get onlineOnly =>
      offer.fulfillmentType == 'order' || offer.merchantType == 'online';
  bool get public =>
      (offer.status == null ||
          ['active', 'approved', 'scheduled'].contains(offer.status)) &&
      offer.hasStarted &&
      !offer.isExpired;
  double? get distance => !onlineOnly &&
          offer.distance != null &&
          offer.distance!.isFinite &&
          offer.distance! >= 0
      ? offer.distance
      : null;
  double get percentage {
    if (previous != null && previous! > 0) return savings! / previous! * 100;
    // "Up to X%" is a cap, not a saving, so it does not count for sorting or filtering.
    final match =
        RegExp(r'^(\d+(?:\.\d+)?)\s*%').firstMatch(offer.discount?.trim() ?? '');
    final value = double.tryParse(match?.group(1) ?? '');
    return value != null && value >= 0 && value <= 100 ? value : 0;
  }

  static int comparePrices(Promotion a, Promotion b,
      {bool descending = false}) {
    final first = OfferPresentation(a).price,
        second = OfferPresentation(b).price;
    if (first == null) return second == null ? 0 : 1;
    if (second == null) return -1;
    return descending ? second.compareTo(first) : first.compareTo(second);
  }

  static double? validAmount(double? value) =>
      value != null && value.isFinite && value >= 0 ? value : null;
}
