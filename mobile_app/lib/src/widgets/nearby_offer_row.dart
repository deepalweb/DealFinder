import 'package:flutter/material.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../models/promotion.dart';
import '../utils/offer_presentation.dart';
import 'discover_offer_image.dart';
import 'offer_save_button.dart';
import 'stitch_discover_components.dart' show StitchOfferCopy, stitchLabel;

/// Consistent summary slots; selection synchronizes the map, arrow opens details.
class NearbyOfferRow extends StatelessWidget {
  const NearbyOfferRow(
      {super.key,
      required this.offer,
      required this.selected,
      required this.onSelect,
      required this.onOpen});
  final Promotion offer;
  final bool selected;
  final VoidCallback onSelect, onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scaler = MediaQuery.textScalerOf(context);
    final large = scaler.scale(16) > 24;
    final view = OfferPresentation(offer);
    final copy = StitchOfferCopy(context, offer);
    final rating = offer.averageRating;
    final rated = rating != null &&
        rating.isFinite &&
        rating >= 0 &&
        rating <= 5 &&
        offer.ratingsCount > 0;
    final distance = view.distance;
    final ratingText = rated
        ? '${rating.toStringAsFixed(1)} (${offer.ratingsCount})'
        : stitchLabel(context, 'Not rated', 'ඇගයීම් නැත', 'மதிப்பீடு இல்லை');
    final distanceText = distance == null
        ? '—'
        : '≈ ${distance < 1000 ? '${distance.round()} m' : '${(distance / 1000).toStringAsFixed(1)} km'}';

    // Reserve identical line counts even for missing or short data. System text
    // scaling grows every card equally rather than clipping a fixed pixel height.
    Widget slot(String text, double size,
            {int lines = 1,
            FontWeight weight = FontWeight.w400,
            Color? color}) =>
        SizedBox(
            height: scaler.scale(size) * 1.35 * lines,
            width: double.infinity,
            child: Tooltip(
                message: text,
                child: Text(text,
                    maxLines: lines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: size,
                        height: 1.35,
                        fontWeight: weight,
                        color: color ?? colors.onSurface))));

    final summary = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          slot(offer.title, 14, lines: 2, weight: FontWeight.w700),
          const SizedBox(height: 3),
          slot(
              offer.merchantName?.trim().isNotEmpty == true
                  ? offer.merchantName!
                  : '—',
              12,
              color: colors.onSurfaceVariant),
          const SizedBox(height: 5),
          if (large) ...[
            slot(ratingText, 12, color: colors.onSurfaceVariant),
            slot(distanceText, 12, color: colors.onSurfaceVariant),
          ] else
            Row(children: [
              Expanded(
                  flex: 3,
                  child: slot(ratingText, 12, color: colors.onSurfaceVariant)),
              const SizedBox(width: 6),
              Expanded(
                  flex: 2,
                  child:
                      slot(distanceText, 12, color: colors.onSurfaceVariant)),
            ]),
          const SizedBox(height: 5),
          slot(copy.benefit.isNotEmpty ? copy.benefit : '—', 16,
              lines: large ? 2 : 1,
              weight: FontWeight.w800,
              color: colors.primary),
        ]);
    final image = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
            width: 80, height: 80, child: DiscoverOfferImage(offer: offer)));
    final actions = Column(mainAxisSize: MainAxisSize.min, children: [
      OfferSaveButton(offer: offer, compact: true),
      IconButton(
          onPressed: onOpen,
          tooltip: AppLocalizations.of(context)!.viewOfferLabel,
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          icon: const Icon(Icons.arrow_forward_rounded, size: 20)),
    ]);
    return Semantics(
        selected: selected,
        child: Material(
            color: selected
                ? colors.primary.withValues(alpha: .035)
                : colors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: selected ? colors.primary : colors.outlineVariant,
                    width: selected ? 1.5 : 1)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
                onTap: onSelect,
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: large
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [image, actions]),
                                const SizedBox(height: 10),
                                summary
                              ])
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                image,
                                const SizedBox(width: 10),
                                Expanded(child: summary),
                                actions,
                              ])))));
  }
}
