import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Trust/status pill — Verified, Open Now. Betel Green by default; icon and
/// text always appear together since status/urgency is never color-alone.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.icon,
    required this.label,
    this.color = AppColors.betelGreen,
    this.compact = false,
  });

  factory StatusPill.verified({bool compact = false}) => StatusPill(
        icon: Icons.check_circle_rounded,
        label: 'Verified',
        compact: compact,
      );

  factory StatusPill.open({bool compact = false}) => StatusPill(
        icon: Icons.circle,
        label: 'Open now',
        compact: compact,
      );

  factory StatusPill.closed({String? opensAt, bool compact = false}) => StatusPill(
        icon: Icons.circle,
        label: opensAt != null && opensAt.isNotEmpty ? 'Closed · opens $opensAt' : 'Closed',
        color: AppColors.ash,
        compact: compact,
      );

  final IconData icon;
  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 11 : 12, color: color),
        SizedBox(width: compact ? 3 : 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? AppTypeScale.caption : AppTypeScale.label,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Distance + travel time, always paired — the design system calls for
/// "never distance alone." [travelTimeLabel] is optional since travel-time
/// data isn't always available from the API; distance still renders alone
/// in that case rather than hiding the whole chip.
class DistanceTravelChip extends StatelessWidget {
  const DistanceTravelChip({
    super.key,
    required this.distanceLabel,
    this.travelTimeLabel,
    this.compact = false,
  });

  final String distanceLabel;
  final String? travelTimeLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? AppTypeScale.caption : AppTypeScale.label;
    final label = travelTimeLabel != null && travelTimeLabel!.isNotEmpty
        ? '$distanceLabel · $travelTimeLabel'
        : distanceLabel;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.place_rounded, size: compact ? 12 : 13, color: AppColors.ash),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: size, fontWeight: FontWeight.w500, color: AppColors.ash),
          ),
        ),
      ],
    );
  }
}

/// New price (Turmeric, bold) + strikethrough old price (Ash) + a "-X%"
/// badge. Discount badges use Turmeric on Ceylon Ink, never red — red (Chili)
/// is reserved for genuine urgency elsewhere.
class PriceBlock extends StatelessWidget {
  const PriceBlock({
    super.key,
    required this.currentPriceLabel,
    this.originalPriceLabel,
    this.discountLabel,
    this.compact = false,
  });

  final String currentPriceLabel;
  final String? originalPriceLabel;
  final String? discountLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: 2,
      children: [
        Text(
          currentPriceLabel,
          style: TextStyle(
            fontSize: compact ? 16 : 18,
            fontWeight: FontWeight.w700,
            color: AppColors.turmeric,
            letterSpacing: -0.2,
          ),
        ),
        if (originalPriceLabel != null)
          Text(
            originalPriceLabel!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.ash,
              decoration: TextDecoration.lineThrough,
              decorationThickness: 1.5,
            ),
          ),
        if (discountLabel != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.ceylonInk,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              discountLabel!,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.turmeric),
            ),
          ),
      ],
    );
  }
}

/// Relative expiry ("Ends in 7 days") in Chili — the design system's
/// canonical urgency color. Only shown when expiry is actually close, so it
/// always signals real urgency rather than diluting the signal.
class ExpiryChip extends StatelessWidget {
  const ExpiryChip({super.key, required this.label, this.expired = false, this.compact = false});

  final String label;
  final bool expired;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          expired ? Icons.timer_off_rounded : Icons.schedule_rounded,
          size: compact ? 12 : 13,
          color: AppColors.chili,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? AppTypeScale.caption : AppTypeScale.label,
              fontWeight: FontWeight.w600,
              color: AppColors.chili,
            ),
          ),
        ),
      ],
    );
  }
}
