import 'dart:async';

import 'package:flutter/material.dart';
import '../models/promotion.dart';
import '../services/image_helper.dart';
import '../config/app_theme.dart';
import 'deal_verification_badge.dart';

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
      'EUR': '\u20ac',
      'GBP': '\u00a3',
      'INR': '\u20b9',
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

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
    bool compact = false,
    double? iconSize,
    double? fontSize,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.sm : AppSpacing.md,
            vertical: compact ? AppSpacing.xxs : AppSpacing.xs,
          ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize ?? (compact ? 10 : 11), color: foreground),
          SizedBox(width: compact ? AppSpacing.xxs : AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize ?? (compact ? 9 : 10),
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCountdown(Duration duration) {
    final totalHours = duration.inHours;
    final days = duration.inDays;
    final hours = totalHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (totalHours >= 24) {
      return '${days}d ${hours.toString().padLeft(2, '0')}h '
          '${minutes.toString().padLeft(2, '0')}m';
    }

    return '${totalHours.toString().padLeft(2, '0')}h '
        '${minutes.toString().padLeft(2, '0')}m '
        '${seconds.toString().padLeft(2, '0')}s';
  }

  Widget _buildGlassChip({
    required IconData icon,
    required String label,
    required bool compact,
    required BuildContext context,
    Color? iconColor,
    double? iconSize,
    double? fontSize,
    EdgeInsetsGeometry? padding,
  }) {
    final theme = Theme.of(context).extension<DealFinderThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: compact ? 7 : 9,
            vertical: compact ? AppSpacing.xs : 5,
          ),
      decoration: BoxDecoration(
        color: theme.glassBackground.withValues(alpha: AppOpacity.glass),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: theme.glassBackground.withValues(alpha: AppOpacity.overlay),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize ?? (compact ? 11 : 12),
            color: iconColor ??
                (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
          ),
          SizedBox(width: compact ? AppSpacing.xxs : AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize ?? (compact ? 8.5 : 9.5),
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<DealFinderThemeExtension>()!;
    final cardTheme = Theme.of(context).cardTheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final p = widget.promotion;
          final distance = _formatDistance(p.distance);
          final showCountdown = _timeLeft != null && p.endDate != null;
          final effectiveWidth = widget.width ?? constraints.maxWidth;
          final compact = effectiveWidth <= 190;
          final imageFlex = compact ? 8 : 9;
          final contentFlex = compact ? 6 : 5;
          final contentPadding = compact ? AppSpacing.md : 10.0;
          final merchantName = p.merchantName?.trim();
          final distanceLabel = distance.isNotEmpty ? distance : null;
          final hoursLeft = _timeLeft?.inHours ?? 0;
          final showCountdownNow =
              showCountdown && _timeLeft != null && hoursLeft < 48;
          final expiryLabel = showCountdownNow
              ? (_timeLeft == Duration.zero
                  ? 'Expired'
                  : _formatCountdown(_timeLeft!))
              : null;
          final averageRating = p.averageRating ?? 0.0;
          final hasRatings = p.ratingsCount > 0 && p.averageRating != null;
          final hasTrustBadge =
              (p.trustStatus ?? '').isNotEmpty && p.trustStatus != 'standard';
          final currentPrice = p.discountedPrice ?? p.price ?? p.originalPrice;
          final savings = p.originalPrice != null &&
                  currentPrice != null &&
                  p.originalPrice! > currentPrice
              ? p.originalPrice! - currentPrice
              : null;
          final discountLabel = p.discountPercentage != null
              ? '${p.discountPercentage}% OFF'
              : (p.discount != null && p.discount!.isNotEmpty)
                  ? p.discount!
                  : null;

          final borderSide = cardTheme.shape is RoundedRectangleBorder
              ? (cardTheme.shape as RoundedRectangleBorder).side
              : BorderSide.none;

          return Container(
            width: widget.width,
            decoration: BoxDecoration(
              color: cardTheme.color,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: borderSide != BorderSide.none
                  ? Border.all(
                      color: borderSide.color,
                      width: borderSide.width,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: theme.cardShadow.withValues(alpha: AppOpacity.light),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color:
                      AppColors.iosPrimary.withValues(alpha: AppOpacity.subtle),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: imageFlex,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: AppOpacity.medium),
                              Colors.black.withValues(alpha: AppOpacity.strong),
                            ],
                          ),
                        ),
                      ),
                      if (discountLabel != null)
                        Positioned(
                          top: AppSpacing.md,
                          left: AppSpacing.md,
                          child: _buildInfoChip(
                            icon: Icons.local_offer_rounded,
                            label: discountLabel,
                            background: AppColors.iosError,
                            foreground: Colors.white,
                            compact: compact,
                            iconSize: compact ? 12 : 13,
                            fontSize: compact ? 11 : 12,
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 8 : 10,
                              vertical: compact ? 5 : 6,
                            ),
                          ),
                        ),
                      if (hasRatings)
                        Positioned(
                          top: AppSpacing.md,
                          right: AppSpacing.md,
                          child: _buildGlassChip(
                            icon: Icons.star_rounded,
                            label:
                                '${averageRating.toStringAsFixed(1)} (${p.ratingsCount})',
                            compact: compact,
                            context: context,
                            iconColor: theme.ratingColor,
                            iconSize: compact ? 11 : 12,
                            fontSize: compact ? 8.5 : 9,
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 7 : 9,
                              vertical: compact ? AppSpacing.xs : 5,
                            ),
                          ),
                        ),
                      if (hasTrustBadge)
                        Positioned(
                          bottom: AppSpacing.md,
                          left: AppSpacing.md,
                          child: DealVerificationBadge(
                            status: p.trustStatus!,
                            label: p.trustLabel,
                            compact: compact,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: contentFlex,
                  child: Padding(
                    padding: EdgeInsets.all(contentPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Deal Title (Primary - Most Important)
                        Text(
                          p.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 13.5 : 15,
                            fontWeight: FontWeight.w900,
                            color:
                                Theme.of(context).textTheme.titleMedium?.color,
                            height: 1.1,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: compact ? 3 : 4),

                        // Merchant Name (Secondary)
                        if (merchantName != null && merchantName.isNotEmpty)
                          Text(
                            merchantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 11 : 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                              letterSpacing: -0.1,
                            ),
                          ),
                        if (merchantName != null && merchantName.isNotEmpty)
                          SizedBox(
                              height: compact ? AppSpacing.xs : AppSpacing.sm),

                        // Distance & Expiry
                        Row(
                          children: [
                            if (distanceLabel != null) ...[
                              Icon(
                                Icons.location_on,
                                size: compact ? 12 : 13,
                                color: theme.distanceColor,
                              ),
                              SizedBox(width: compact ? 3 : 4),
                              Text(
                                distanceLabel,
                                style: TextStyle(
                                  fontSize: compact ? 11 : 12,
                                  fontWeight: FontWeight.w700,
                                  color: theme.distanceColor,
                                ),
                              ),
                            ],
                            if (distanceLabel != null && expiryLabel != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '•',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                    fontSize: compact ? 10 : 11,
                                  ),
                                ),
                              ),
                            if (expiryLabel != null)
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _timeLeft == Duration.zero
                                          ? Icons.timer_off_outlined
                                          : Icons.schedule_rounded,
                                      size: compact ? 11 : 12,
                                      color: _timeLeft == Duration.zero
                                          ? theme.expiredColor
                                          : theme.savingsColor,
                                    ),
                                    SizedBox(width: compact ? 3 : 4),
                                    Flexible(
                                      child: Text(
                                        expiryLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: compact ? 9 : 10,
                                          fontWeight: FontWeight.w600,
                                          color: _timeLeft == Duration.zero
                                              ? theme.expiredColor
                                              : Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        SizedBox(
                            height: compact ? AppSpacing.sm : AppSpacing.md),
                        // Price (Quaternary - Clear Hierarchy)
                        if (currentPrice != null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _priceLabel(
                                  currentPrice,
                                  currencyCode: p.merchantCurrency,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: compact ? 16 : 18,
                                  fontWeight: FontWeight.w900,
                                  color: theme.priceColor,
                                  letterSpacing: -0.3,
                                  height: 1,
                                ),
                              ),
                              if (p.originalPrice != null &&
                                  p.discountedPrice != null) ...[
                                const SizedBox(width: AppSpacing.md),
                                Text(
                                  _priceLabel(
                                    p.originalPrice!,
                                    currencyCode: p.merchantCurrency,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: compact ? 11 : 12,
                                    color: AppColors.textTertiary,
                                    decoration: TextDecoration.lineThrough,
                                    decorationThickness: 2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        if (savings != null) ...[
                          SizedBox(height: compact ? 3 : 4),
                          Text(
                            'Save ${_priceLabel(savings, currencyCode: p.merchantCurrency)}',
                            style: TextStyle(
                              fontSize: compact ? 10 : 11,
                              fontWeight: FontWeight.w700,
                              color: theme.savingsColor,
                            ),
                          ),
                        ],
                      ],
                    ),
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
