import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../models/promotion.dart';
import '../utils/offer_presentation.dart';
import 'discover_offer_image.dart';
import 'discovery_offer_card.dart';
import 'offer_save_button.dart';
import 'hybrid_offer_layout.dart';

/// Live-data adapter for the approved shared marketplace layout.
class DiscoverMarketplaceCard extends StatelessWidget {
  const DiscoverMarketplaceCard(
      {super.key,
      required this.offer,
      required this.onOpen,
      this.trailing,
      this.compact = false,
      this.distanceFromSelectedArea = false});
  final Promotion offer;
  final VoidCallback onOpen;
  final Widget? trailing;
  final bool distanceFromSelectedArea;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = OfferPresentation(offer);
    String t(String en, String si, String ta) =>
        switch (Localizations.localeOf(context).languageCode) {
          'si' => si,
          'ta' => ta,
          _ => en
        };
    final bank = [
      if (offer.bankName?.isNotEmpty == true) offer.bankName!,
      ...offer.cardTypes.map((type) => switch (type) {
            'credit' => l10n.creditCardLabel,
            'debit' => l10n.debitCardLabel,
            'prepaid' => l10n.prepaidCardLabel,
            _ => type
          })
    ].join(' · ');
    final conditions = [
      if (OfferPresentation.validAmount(offer.minimumSpend) != null)
        l10n.minimumSpendLabel(offerMoney(offer, offer.minimumSpend!)),
      if (OfferPresentation.validAmount(offer.maximumBenefit) != null)
        '${t('Maximum discount', 'උපරිම වට්ටම', 'அதிகபட்ச தள்ளுபடி')}: ${offerMoney(offer, offer.maximumBenefit!)}'
    ].join(' · ');
    final fulfillment = v.onlineOnly
        ? t('Online offer', 'මාර්ගගත දීමනාව', 'இணையச் சலுகை')
        : [
            if (offer.supportsVisit) l10n.inStoreLabel,
            if (offer.supportsDelivery) l10n.deliveryLabel,
            if (offer.supportsPickup) l10n.pickupLabel
          ].join(' · ');
    final expiry = offer.isExpired
        ? l10n.expired
        : offer.endDate == null
            ? t('Expiry not provided', 'අවසන් දිනය සපයා නැත',
                'முடிவுத் தேதி வழங்கப்படவில்லை')
            : l10n.offerEndsOn(
                DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag())
                    .format(offer.endDate!
                        .toUtc()
                        .add(const Duration(hours: 5, minutes: 30))));
    final metadata = [
      if (fulfillment.isNotEmpty) fulfillment,
      if (v.distance != null)
        '≈ ${v.distance! < 1000 ? '${v.distance!.round()} m' : '${(v.distance! / 1000).toStringAsFixed(1)} km'} ${distanceFromSelectedArea ? t('from selected area', 'තෝරාගත් ප්‍රදේශයෙන්', 'தேர்ந்தெடுத்த பகுதியிலிருந்து') : ''}',
      expiry
    ].join(' · ');
    if (compact) {
      return CompactDiscoverCardLayout(
          image: DiscoverOfferImage(offer: offer),
          save: SizedBox(
              width: 48, height: 48, child: OfferSaveButton(offer: offer)),
          merchant: offer.merchantName ?? '',
          title: offer.title,
          benefit: v.useDiscountHeadline
              ? offer.discount!.trim()
              : v.price != null
                  ? offerMoney(offer, v.price!)
                  : offer.discount?.trim() ?? '',
          previousPrice: !v.useDiscountHeadline && v.previous != null
              ? offerMoney(offer, v.previous!)
              : null,
          eligibility: bank,
          conditions: conditions,
          metadata: [
            if (fulfillment.isNotEmpty) fulfillment,
            if (v.distance != null)
              '≈ ${v.distance! < 1000 ? '${v.distance!.round()} m' : '${(v.distance! / 1000).toStringAsFixed(1)} km'}',
            expiry
          ].join(' · '),
          onOpen: onOpen);
    }
    return HybridOfferCardLayout(
        image: DiscoverOfferImage(offer: offer),
        save: SizedBox(
            width: 48, height: 48, child: OfferSaveButton(offer: offer)),
        merchant: [
          if (offer.merchantName?.isNotEmpty == true) offer.merchantName!,
          if (!v.onlineOnly && offer.location?.isNotEmpty == true)
            offer.location!
        ].join(' · '),
        benefit: v.useDiscountHeadline
            ? offer.discount!.trim()
            : v.price != null
                ? offerMoney(offer, v.price!)
                : offer.discount?.trim() ?? '',
        previousPrice: !v.useDiscountHeadline && v.previous != null
            ? offerMoney(offer, v.previous!)
            : null,
        title: offer.title,
        eligibility: bank,
        conditions: conditions,
        metadata: metadata,
        onOpen: onOpen,
        trailing: trailing);
  }
}
