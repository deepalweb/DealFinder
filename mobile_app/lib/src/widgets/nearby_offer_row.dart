import 'package:flutter/material.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../models/promotion.dart';
import '../services/image_helper.dart';
import 'discovery_offer_card.dart';
import 'offer_save_button.dart';

class NearbyOfferRow extends StatelessWidget {
  const NearbyOfferRow(
      {super.key,
      required this.offer,
      required this.selected,
      required this.onSelect,
      required this.onOpen});
  final Promotion offer;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = offer.discountedPrice ?? offer.price;
    final image = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
            width: 96,
            height: 96,
            child: ImageHelper.buildOptimizedImage(offer.imageDataString,
                fit: BoxFit.cover)));
    final content =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: Text(offer.merchantName ?? '',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.primary))),
        OfferSaveButton(offer: offer),
      ]),
      const SizedBox(height: 4),
      Text(offer.title, style: theme.textTheme.titleMedium),
      if (offer.distance != null)
        Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
                offer.distance! < 1000
                    ? '${offer.distance!.round()} m'
                    : '${(offer.distance! / 1000).toStringAsFixed(1)} km',
                style: theme.textTheme.bodySmall)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 4, children: [
        if (price != null)
          Text(offerMoney(offer, price),
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.primary))
        else if (offer.discount != null)
          Text(offer.discount!,
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.primary)),
        if (price != null &&
            offer.originalPrice != null &&
            offer.originalPrice! > price)
          Text(offerMoney(offer, offer.originalPrice!),
              style: theme.textTheme.bodySmall
                  ?.copyWith(decoration: TextDecoration.lineThrough)),
      ]),
    ]);
    return Semantics(
        selected: selected,
        child: Material(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: selected ? 2 : 1)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: onSelect,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (MediaQuery.textScalerOf(context).scale(16) > 24)
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                image,
                                const SizedBox(height: 12),
                                content
                              ])
                        else
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                image,
                                const SizedBox(width: 12),
                                Expanded(child: content)
                              ]),
                        const SizedBox(height: 12),
                        OfferConditions(offer: offer),
                        const SizedBox(height: 8),
                        Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                                onPressed: onOpen,
                                iconAlignment: IconAlignment.end,
                                icon: const Icon(Icons.arrow_forward),
                                label: Text(AppLocalizations.of(context)!
                                    .viewOfferLabel))),
                      ]))),
        ));
  }
}
