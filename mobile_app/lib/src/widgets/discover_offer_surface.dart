import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../models/promotion.dart';
import 'discover_offer_image.dart';
import 'discovery_offer_card.dart';
import 'offer_save_button.dart';

enum DiscoverSurfaceLayout { editorial, detail, expiry }

/// Compact surfaces matching the supplied Stitch composition.
class DiscoverOfferSurface extends StatelessWidget {
  const DiscoverOfferSurface(
      {super.key,
      required this.offer,
      required this.onOpen,
      this.layout = DiscoverSurfaceLayout.detail});
  final Promotion offer;
  final VoidCallback onOpen;
  final DiscoverSurfaceLayout layout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final large = MediaQuery.textScalerOf(context).scale(14) > 21;
    final price = offer.discountedPrice ?? offer.price;
    final end = offer.endDate == null
        ? null
        : l10n.offerEndsOn(
            DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag())
                .format(offer.endDate!
                    .toUtc()
                    .add(const Duration(hours: 5, minutes: 30))));
    final meta = [
      if (offer.minimumSpend != null)
        l10n.minimumSpendLabel(offerMoney(offer, offer.minimumSpend!)),
      if (end != null) end,
      if (offer.bankName?.isNotEmpty == true) offer.bankName!,
      ...offer.cardTypes.map((type) => type == 'credit'
          ? l10n.creditCardLabel
          : type == 'debit'
              ? l10n.debitCardLabel
              : type),
    ];
    final button = TextButton.icon(
        onPressed: onOpen,
        style: TextButton.styleFrom(
            minimumSize: const Size(48, 44),
            textStyle: theme.textTheme.labelLarge
                ?.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
            padding: const EdgeInsets.symmetric(horizontal: 10)),
        icon: const Icon(Icons.arrow_forward, size: 16),
        label: Text(l10n.viewOfferLabel));
    final body =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (offer.merchantName?.isNotEmpty == true)
        Text(offer.merchantName!,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(offer.title,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
          maxLines: large ? null : 2,
          overflow: large ? null : TextOverflow.ellipsis),
      if (offer.averageRating != null && offer.ratingsCount > 0)
        Text(
            '★ ${offer.averageRating!.toStringAsFixed(1)} (${offer.ratingsCount})',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
    ]);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onOpen,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (layout == DiscoverSurfaceLayout.editorial)
              Stack(children: [
                Positioned.fill(child: DiscoverOfferImage(offer: offer)),
                Positioned.fill(
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                      Colors.black.withValues(alpha: .12),
                      Colors.black.withValues(alpha: .88)
                    ])))),
                Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(
                                    offer.bankName ?? l10n.featuredLabel,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600))),
                            OfferSaveButton(offer: offer)
                          ]),
                          const SizedBox(height: 22),
                          if (offer.discount != null)
                            Text(offer.discount!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800)),
                          Text(offer.merchantName ?? offer.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          if (offer.merchantName != null)
                            Text(offer.title,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                                maxLines: large ? null : 2,
                                overflow: large ? null : TextOverflow.ellipsis),
                          if (end != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(end,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 11))),
                        ])),
              ])
            else if (layout == DiscoverSurfaceLayout.detail) ...[
              Stack(children: [
                SizedBox(
                    height: large ? 160 : 140,
                    width: double.infinity,
                    child: DiscoverOfferImage(offer: offer)),
                Positioned(
                    top: 8,
                    left: 8,
                    right: 56,
                    child: Wrap(spacing: 4, runSpacing: 4, children: [
                      if (offer.bankName != null)
                        _badge(context, offer.bankName!),
                      if (offer.discount != null)
                        _badge(context, offer.discount!),
                    ])),
                Positioned(
                    top: 2, right: 2, child: OfferSaveButton(offer: offer)),
              ]),
              Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        body,
                        const SizedBox(height: 8),
                        Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: meta
                                .map((label) => Text(label,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(fontSize: 11)))
                                .toList()),
                        if (offer.maximumBenefit != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                  '${switch (Localizations.localeOf(context).languageCode) {
                                    'si' => 'උපරිම ප්‍රතිලාභය',
                                    'ta' => 'அதிகபட்ச பலன்',
                                    _ => 'Maximum benefit'
                                  }} ${offerMoney(offer, offer.maximumBenefit!)}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600))),
                        const Divider(height: 12),
                        Wrap(
                            spacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (price != null)
                                Text(offerMoney(offer, price),
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.primary)),
                              ...[
                                if (offer.supportsVisit) l10n.inStoreLabel,
                                if (offer.supportsDelivery) l10n.deliveryLabel,
                                if (offer.supportsPickup) l10n.pickupLabel
                              ].map((s) => Text(s,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(fontSize: 11))),
                              button,
                            ]),
                      ])),
            ] else
              Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                      width: 58,
                                      height: 58,
                                      child: DiscoverOfferImage(offer: offer))),
                              const SizedBox(width: 10),
                              Expanded(child: body),
                            ]),
                        Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (end != null)
                                Text(end,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(fontSize: 11)),
                              if (offer.discount != null)
                                Text(offer.discount!,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.error)),
                              button,
                            ]),
                      ])),
          ])),
    );
  }

  Widget _badge(BuildContext context, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style:
              Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11)));
}
