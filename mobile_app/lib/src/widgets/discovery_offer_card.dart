import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../models/promotion.dart';
import '../services/image_helper.dart';
import 'offer_save_button.dart';

String offerMoney(Promotion offer, double amount) => NumberFormat.currency(
      name: offer.merchantCurrency ?? 'LKR',
      symbol: offer.merchantCurrency ?? 'LKR',
      decimalDigits: amount % 1 == 0 ? 0 : 2,
    ).format(amount);

class OfferConditions extends StatelessWidget {
  const OfferConditions({super.key, required this.offer});
  final Promotion offer;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = <String>[
      if (offer.bankName?.isNotEmpty == true) offer.bankName!,
      if (offer.cardTypes.isNotEmpty)
        offer.cardTypes
            .map((type) => switch (type) {
                  'credit' => l10n.creditCardLabel,
                  'debit' => l10n.debitCardLabel,
                  'prepaid' => l10n.prepaidCardLabel,
                  _ => type,
                })
            .join(' · '),
      if (offer.minimumSpend != null)
        l10n.minimumSpendLabel(offerMoney(offer, offer.minimumSpend!)),
      if (offer.endDate != null)
        l10n.offerEndsOn(
            DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
                .format(offer.endDate!
                    .toUtc()
                    .add(const Duration(hours: 5, minutes: 30)))),
      if (offer.supportsVisit) l10n.inStoreLabel,
      if (offer.supportsDelivery) l10n.deliveryLabel,
      if (offer.supportsPickup) l10n.pickupLabel,
    ];
    return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: labels
            .map((label) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(label,
                      style: Theme.of(context).textTheme.labelMedium),
                ))
            .toList());
  }
}

class DiscoveryOfferCard extends StatelessWidget {
  const DiscoveryOfferCard(
      {super.key,
      required this.offer,
      required this.onOpen,
      this.featured = false});
  final Promotion offer;
  final VoidCallback onOpen;
  final bool featured;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final price = offer.discountedPrice ?? offer.price;
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: theme.colorScheme.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onOpen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(children: [
                SizedBox(
                    height: featured ? 230 : 170,
                    width: double.infinity,
                    child: ImageHelper.buildOptimizedImage(
                        offer.imageDataString,
                        fit: BoxFit.cover)),
                Positioned(
                    top: 12,
                    left: 12,
                    right: 70,
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(
                              featured
                                  ? l10n.featuredLabel
                                  : offer.discount ?? l10n.viewOfferLabel,
                              style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onPrimary)),
                        ))),
                Positioned(
                    top: 8, right: 8, child: OfferSaveButton(offer: offer)),
              ]),
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (offer.merchantName?.isNotEmpty == true)
                              Text(offer.merchantName!,
                                  style: theme.textTheme.bodySmall),
                            if (offer.adminVerified ||
                                offer.trustStatus == 'verified')
                              Icon(Icons.verified_outlined,
                                  size: 16, color: theme.colorScheme.primary),
                            if (offer.distance != null)
                              Text(
                                  offer.distance! < 1000
                                      ? '${offer.distance!.round()} m'
                                      : '${(offer.distance! / 1000).toStringAsFixed(1)} km',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.primary)),
                          ]),
                      const SizedBox(height: 8),
                      Text(offer.title,
                          style: featured
                              ? theme.textTheme.titleLarge
                              : theme.textTheme.titleMedium),
                      if (price != null) ...[
                        const SizedBox(height: 10),
                        Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(offerMoney(offer, price),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.primary)),
                              if (offer.originalPrice != null &&
                                  offer.originalPrice! > price)
                                Text(offerMoney(offer, offer.originalPrice!),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        decoration:
                                            TextDecoration.lineThrough)),
                            ]),
                      ],
                      const SizedBox(height: 12),
                      OfferConditions(offer: offer),
                    ],
                  )),
            ],
          )),
    );
  }
}
