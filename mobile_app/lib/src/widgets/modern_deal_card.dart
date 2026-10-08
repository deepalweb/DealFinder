import 'dart:async';

import 'package:flutter/material.dart';
import '../models/promotion.dart';
import '../services/image_helper.dart';
import '../config/app_theme.dart';
import 'deal_pills.dart';

class ModernDealCard extends StatefulWidget {
  final Promotion promotion;
  final VoidCallback? onTap;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final String? primaryActionLabel;
  final String? secondaryActionLabel;
  final double? width;

  const ModernDealCard({
    super.key,
    required this.promotion,
    this.onTap,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.primaryActionLabel,
    this.secondaryActionLabel,
    this.width,
  });

  @override
  State<ModernDealCard> createState() => _ModernDealCardState();
}

class _ModernDealCardState extends State<ModernDealCard> {
  Timer? _timer;
  Duration? _timeLeft;

  @override
  void initState() {
    super.initState();
    if (widget.promotion.endDate != null) {
      _updateTimeLeft();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateTimeLeft();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimeLeft() {
    final endDate = widget.promotion.endDate;
    if (endDate == null || !mounted) return;
    final diff = endDate.difference(DateTime.now());
    setState(() {
      _timeLeft = diff.isNegative ? Duration.zero : diff;
    });
  }

  String _formatDistance(double? distanceMeters) {
    if (distanceMeters == null) return '';
    if (distanceMeters < 1000) return '${distanceMeters.round()}m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
  }

  Widget _buildImage() {
    return ImageHelper.buildOptimizedImage(
      widget.promotion.imageDataString,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  String _priceLabel(double amount, {String? currencyCode}) {
    const symbols = {
      'USD': r'$',
      'LKR': 'Rs.',
      'EUR': '€',
      'GBP': '£',
      'INR': '₹',
      'AUD': 'A\$',
      'CAD': 'C\$',
      'SGD': 'S\$',
      'AED': 'AED',
      'MYR': 'RM',
    };
    final symbol = symbols[currencyCode ?? 'LKR'] ?? (currencyCode ?? 'Rs.');
    final whole = amount.roundToDouble() == amount;
    return '$symbol ${amount.toStringAsFixed(whole ? 0 : 2)}';
  }

  String _formatCountdown(Duration duration) {
    final totalHours = duration.inHours;
    final days = duration.inDays;
    final hours = totalHours % 24;

    if (totalHours >= 24) {
      return 'Ends in ${days}d ${hours}h';
    }
    if (totalHours >= 1) {
      return 'Ends in ${totalHours}h ${duration.inMinutes % 60}m';
    }
    return 'Ends in ${duration.inMinutes}m';
  }

  // Rounds three corners and leaves one square — a deliberate asymmetry so
  // the feed doesn't read as a repeated grid of identical rounded tiles.
  static const _cardRadius = BorderRadius.only(
    topLeft: Radius.circular(AppRadius.lg),
    topRight: Radius.circular(AppRadius.lg),
    bottomRight: Radius.circular(AppRadius.lg),
    bottomLeft: Radius.circular(4),
  );
  static const _imageRadius = BorderRadius.only(
    topLeft: Radius.circular(AppRadius.lg),
    topRight: Radius.circular(AppRadius.lg),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderSubtle;
    final titleColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final p = widget.promotion;
          final distance = _formatDistance(p.distance);
          final effectiveWidth = widget.width ?? constraints.maxWidth;
          final compact = effectiveWidth <= 190;
          final merchantName = p.merchantName?.trim();
          final distanceLabel = distance.isNotEmpty ? distance : null;
          final hoursLeft = _timeLeft?.inHours ?? 0;
          final showCountdownNow = _timeLeft != null && p.endDate != null && hoursLeft < 48;
          final expired = _timeLeft == Duration.zero;
          final expiryLabel = showCountdownNow
              ? (expired ? 'Expired' : _formatCountdown(_timeLeft!))
              : null;
          final isVerified = (p.trustStatus ?? '').isNotEmpty && p.trustStatus != 'standard';
          final currentPrice = p.discountedPrice ?? p.price ?? p.originalPrice;
          final discountLabel = p.discountPercentage != null
              ? '-${p.discountPercentage}%'
              : (p.discount != null && p.discount!.isNotEmpty ? p.discount! : null);

          return Container(
            width: widget.width,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: _cardRadius,
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: AppColors.charcoal.withValues(alpha: AppOpacity.light),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  // ~40% of card height, per the design system's card image cap.
                  aspectRatio: compact ? 1.35 : 1.6,
                  child: ClipRRect(
                    borderRadius: _imageRadius,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImage(),
                        if (discountLabel != null)
                          Positioned(
                            top: AppSpacing.md,
                            left: AppSpacing.md,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.ceylonInk,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                discountLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.turmeric,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Merchant name + verified badge (inline, not a separate row).
                      if (merchantName != null && merchantName.isNotEmpty)
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                merchantName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: AppTypeScale.title,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor,
                                ),
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: AppSpacing.xs),
                              const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.betelGreen),
                            ],
                          ],
                        ),
                      if (distanceLabel != null) ...[
                        SizedBox(height: compact ? AppSpacing.xxs : AppSpacing.xs),
                        DistanceTravelChip(distanceLabel: distanceLabel, compact: compact),
                      ],
                      SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),

                      // Deal title.
                      Text(
                        p.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? AppTypeScale.body : AppTypeScale.title,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),

                      if (currentPrice != null)
                        PriceBlock(
                          currentPriceLabel: _priceLabel(currentPrice, currencyCode: p.merchantCurrency),
                          originalPriceLabel: (p.originalPrice != null && p.discountedPrice != null)
                              ? _priceLabel(p.originalPrice!, currencyCode: p.merchantCurrency)
                              : null,
                          compact: compact,
                        ),

                      if (expiryLabel != null) ...[
                        SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
                        ExpiryChip(label: expiryLabel, expired: expired, compact: compact),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
