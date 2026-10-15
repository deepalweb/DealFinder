import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../models/promotion.dart';
import 'discover_offer_image.dart';
import 'discovery_offer_card.dart';
import 'offer_save_button.dart';
import 'discover_offer_rating.dart';

/// Reusable photo tile for the horizontal highlight rail and adaptive grid.
class DiscoverOfferTile extends StatelessWidget {
  const DiscoverOfferTile(
      {super.key, required this.offer, required this.onOpen});
  final Promotion offer;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final large = MediaQuery.textScalerOf(context).scale(14) > 21;
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onOpen,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              SizedBox(
                  height: large ? 132 : 104,
                  width: double.infinity,
                  child: DiscoverOfferImage(offer: offer)),
              Positioned(
                  top: 8,
                  left: 8,
                  right: 60,
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(offer.discount ?? l10n.viewOfferLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimary))))),
              Positioned(
                  top: 4, right: 4, child: OfferSaveButton(offer: offer)),
            ]),
            Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (offer.merchantName?.isNotEmpty == true)
                        Text(offer.merchantName!,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontSize: 13),
                            maxLines: large ? null : 1,
                            overflow: large ? null : TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(offer.title,
                          style:
                              theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                          maxLines: large ? null : 1,
                          overflow: large ? null : TextOverflow.ellipsis),
                      if ((offer.averageRating != null &&
                              offer.ratingsCount > 0) ||
                          offer.distance != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                                spacing: 8,
                                runSpacing: 3,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (offer.averageRating != null &&
                                      offer.ratingsCount > 0)
                                    DiscoverOfferRating(offer: offer),
                                  if (offer.distance != null)
                                    Text(
                                        offer.distance! < 1000
                                            ? '${offer.distance!.round()} m'
                                            : '${(offer.distance! / 1000).toStringAsFixed(1)} km',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(fontSize: 11)),
                                ])),
                      const Divider(height: 12),
                      if (offer.bankName?.isNotEmpty == true)
                        Text(offer.bankName!,
                            style: theme.textTheme.labelLarge?.copyWith(
                                fontSize: 11, color: theme.colorScheme.primary),
                            maxLines: large ? null : 1,
                            overflow: large ? null : TextOverflow.ellipsis),
                      if (offer.cardTypes.isNotEmpty)
                        Text(
                            offer.cardTypes
                                .map((type) => type == 'credit'
                                    ? l10n.creditCardLabel
                                    : type == 'debit'
                                        ? l10n.debitCardLabel
                                        : type)
                                .join(' · '),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontSize: 11)),
                      const SizedBox(height: 3),
                      Wrap(
                          spacing: 8,
                          runSpacing: 3,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (offer.minimumSpend != null)
                              Text(
                                  l10n.minimumSpendLabel(
                                      offerMoney(offer, offer.minimumSpend!)),
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(fontSize: 11)),
                            if (offer.discountedPrice ?? offer.price
                                case final price?)
                              Text(offerMoney(offer, price),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                      fontSize: 12,
                                      color: theme.colorScheme.primary)),
                          ]),
                      if (offer.endDate != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                                l10n.offerEndsOn(DateFormat.MMMd(
                                        Localizations.localeOf(context)
                                            .toLanguageTag())
                                    .format(offer.endDate!.toUtc().add(
                                        const Duration(
                                            hours: 5, minutes: 30)))),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontSize: 11))),
                    ])),
          ])),
    );
  }
}

class DiscoverOfferGrid extends StatelessWidget {
  const DiscoverOfferGrid(
      {super.key, required this.offers, required this.onOpen});
  final List<Promotion> offers;
  final ValueChanged<Promotion> onOpen;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final large = MediaQuery.textScalerOf(context).scale(16) > 22;
        final columns = large || constraints.maxWidth < 320
            ? 1
            : constraints.maxWidth > 720
                ? 3
                : 2;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: offers
                .map((offer) => SizedBox(
                    width: width,
                    child: DiscoverOfferTile(
                        offer: offer, onOpen: () => onOpen(offer))))
                .toList());
      });
}
