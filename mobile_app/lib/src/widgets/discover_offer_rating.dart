import 'package:flutter/material.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../models/promotion.dart';

/// Uses the app icon font instead of a platform-dependent star glyph.
class DiscoverOfferRating extends StatelessWidget {
  const DiscoverOfferRating({super.key, required this.offer});
  final Promotion offer;
  @override
  Widget build(BuildContext context) {
    final value = offer.averageRating;
    if (value == null ||
        !value.isFinite ||
        value < 0 ||
        value > 5 ||
        offer.ratingsCount <= 0) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Semantics(
        label: '${value.toStringAsFixed(1)} · ${offer.ratingsCount} '
            '${offer.ratingsCount == 1 ? l10n.ratingSingular : l10n.ratingsPlural}',
        child: ExcludeSemantics(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.star_rounded, size: 14, color: theme.colorScheme.tertiary),
          const SizedBox(width: 3),
          Text('${value.toStringAsFixed(1)} (${offer.ratingsCount})',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
        ])));
  }
}
