import 'package:flutter/material.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../models/promotion.dart';
import 'discover_offer_image.dart';
import 'discovery_offer_card.dart';
import 'offer_save_button.dart';

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
                          maxLines: large ? null : 2,
                          overflow: large ? null : TextOverflow.ellipsis),
                      if (offer.averageRating != null && offer.ratingsCount > 0)
                        Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Wrap(
                                spacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Icon(Icons.star_rounded, size: 14),
                                  Text(
                                      '${offer.averageRating!.toStringAsFixed(1)} (${offer.ratingsCount})',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontSize: 11))
                                ])),
                      if (offer.distance != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                                '${(offer.distance! / 1000).toStringAsFixed(1)} km',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontSize: 11))),
                      const Divider(height: 12),
                      if (offer.bankName?.isNotEmpty == true)
                        Text(offer.bankName!,
                            style: theme.textTheme.labelLarge?.copyWith(
                                fontSize: 12,
                                color: theme.colorScheme.primary)),
                      if (offer.minimumSpend != null)
                        Text(
                            l10n.minimumSpendLabel(
                                offerMoney(offer, offer.minimumSpend!)),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontSize: 11)),
                      if (offer.discountedPrice ?? offer.price
                          case final price?)
                        Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(offerMoney(offer, price),
                                style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.primary))),
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
