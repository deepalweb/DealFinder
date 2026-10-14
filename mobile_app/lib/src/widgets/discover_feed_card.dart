import 'package:flutter/material.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../models/promotion.dart';
import 'discover_offer_image.dart';
import 'discovery_offer_card.dart';
import 'offer_save_button.dart';

/// Image-led editorial and compact offer layouts for the Discover feed.
class DiscoverFeedCard extends StatelessWidget {
  const DiscoverFeedCard(
      {super.key,
      required this.offer,
      required this.onOpen,
      this.hero = false});
  final Promotion offer;
  final VoidCallback onOpen;
  final bool hero;

  Widget _image(double height) => SizedBox(
      height: height,
      width: double.infinity,
      child: DiscoverOfferImage(offer: offer));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final price = offer.discountedPrice ?? offer.price;
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
    final title = Text(offer.title, style: theme.textTheme.titleMedium);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.colorScheme.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onOpen,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (hero)
              Stack(children: [
                Positioned.fill(child: _image(210)),
                Positioned.fill(
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                      Colors.black.withValues(alpha: .08),
                      Colors.black.withValues(alpha: .88)
                    ])))),
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                                color:
                                                    theme.colorScheme.primary,
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: Text(
                                                offer.featured == true
                                                    ? l10n.featuredLabel
                                                    : offer.discount ??
                                                        l10n.viewOfferLabel,
                                                style: theme
                                                    .textTheme.labelMedium
                                                    ?.copyWith(
                                                        color: theme.colorScheme
                                                            .onPrimary))))),
                                OfferSaveButton(offer: offer),
                              ]),
                          const SizedBox(height: 80),
                          if (offer.merchantName?.isNotEmpty == true)
                            Text(offer.merchantName!,
                                style: theme.textTheme.labelLarge
                                    ?.copyWith(color: Colors.white)),
                          if (!largeText) ...[
                            const SizedBox(height: 6),
                            Text(offer.title,
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(color: Colors.white))
                          ],
                        ])),
              ]),
            Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!hero)
                        LayoutBuilder(builder: (context, constraints) {
                          final details = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (offer.merchantName?.isNotEmpty == true)
                                  Text(offer.merchantName!,
                                      style: theme.textTheme.bodySmall),
                                const SizedBox(height: 6),
                                title,
                                if (offer.distance != null)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                          offer.distance! < 1000
                                              ? '${offer.distance!.round()} m'
                                              : '${(offer.distance! / 1000).toStringAsFixed(1)} km',
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                  color: theme
                                                      .colorScheme.primary))),
                              ]);
                          final image = ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                  width: largeText ? constraints.maxWidth : 88,
                                  child: _image(largeText ? 140 : 96)));
                          return largeText || constraints.maxWidth < 240
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      image,
                                      const SizedBox(height: 12),
                                      details
                                    ])
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      image,
                                      const SizedBox(width: 12),
                                      Expanded(child: details)
                                    ]);
                        }),
                      if (hero && largeText) title,
                      const SizedBox(height: 12),
                      OfferConditions(offer: offer),
                      const SizedBox(height: 12),
                      Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (price != null)
                              Text(offerMoney(offer, price),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.primary)),
                            if (price == null && offer.discount != null)
                              Text(offer.discount!,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.primary)),
                            if (price != null &&
                                offer.originalPrice != null &&
                                offer.originalPrice! > price)
                              Text(offerMoney(offer, offer.originalPrice!),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      decoration: TextDecoration.lineThrough)),
                            if (!hero) OfferSaveButton(offer: offer),
                            FilledButton.tonalIcon(
                                onPressed: onOpen,
                                icon: const Icon(Icons.arrow_forward, size: 18),
                                label: Text(l10n.viewOfferLabel)),
                          ]),
                    ])),
          ])),
    );
  }
}
