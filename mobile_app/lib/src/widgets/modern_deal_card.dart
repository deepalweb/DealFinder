import 'dart:async';

import 'package:flutter/material.dart';
import '../models/promotion.dart';
import '../services/image_helper.dart';
import '../utils/bank_card_promotion_support.dart';
import '../utils/deal_expiry_helper.dart';
import 'deal_verification_badge.dart';

class ModernDealCard extends StatefulWidget {
  final Promotion promotion;
  final VoidCallback? onTap;
  final double? width;
  final bool showCountdown;
  final bool prioritizeDistance;

  const ModernDealCard({
    super.key,
    required this.promotion,
    this.onTap,
    this.width,
    this.showCountdown = false,
    this.prioritizeDistance = false,
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
    if (widget.showCountdown && widget.promotion.endDate != null) {
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

  Widget _buildLogo(String logoUrl) {
    return ImageHelper.buildThumbnail(
      logoUrl,
      size: 16,
      borderRadius: BorderRadius.circular(4),
    );
  }

  String _formatDistance(double? distanceMeters) {
    if (distanceMeters == null) return '';
    if (distanceMeters < 1000) return '${distanceMeters.round()}m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
  }

  String _formatDistanceWithContext(double? distanceMeters) {
    final distance = _formatDistance(distanceMeters);
    if (distance.isEmpty) return '';
    return '$distance away';
  }

  Widget _buildImage() {
    return ImageHelper.buildOptimizedImage(
      widget.promotion.imageDataString,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  String? _primaryModeLabel(Promotion promotion) {
    if (promotion.supportsDelivery) return 'Delivery';
    if (promotion.supportsPickup) return 'Pickup';
    if (promotion.supportsVisit) return 'Visit';
    return null;
  }

  String? _nearbyLocationLabel(Promotion promotion) {
    final location = promotion.location?.trim();
    if (location != null && location.isNotEmpty) return location;

    final category = promotion.category?.trim();
    if (category != null && category.isNotEmpty) return category;

    return null;
  }

  int? _savingAmount(Promotion promotion) {
    if (promotion.originalPrice == null || promotion.discountedPrice == null) {
      return null;
    }

    final savings = promotion.originalPrice! - promotion.discountedPrice!;
    if (savings <= 0) return null;
    return savings.round();
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 10 : 11, color: foreground),
          SizedBox(width: compact ? 3 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 9 : 10,
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final p = widget.promotion;
          final distance = _formatDistance(p.distance);
          final distanceWithContext = _formatDistanceWithContext(p.distance);
          final showCountdown =
              widget.showCountdown && _timeLeft != null && p.endDate != null;
          final primaryModeLabel = _primaryModeLabel(p);
          final locationLabel = _nearbyLocationLabel(p);
          final savingAmount = _savingAmount(p);
          final bankName = BankCardPromotionSupport.bankName(p);
          final cardTypes = BankCardPromotionSupport.cardTypes(p);
          final offerTypes = BankCardPromotionSupport.offerTypes(p);
          final isBankCardPromotion =
              BankCardPromotionSupport.isBankCardPromotion(p);
          final effectiveWidth = widget.width ?? constraints.maxWidth;
          final compact = effectiveWidth <= 190;
          final badgeCompact = compact;
          final imageFlex = compact ? 5 : 6;
          final contentFlex = compact ? 7 : 5;
          final contentPadding = compact ? 10.0 : 12.0;
          final titleFontSize = compact ? 13.0 : 14.5;
          final merchantFontSize = compact ? 10.5 : 11.5;
          final bodyFontSize = compact ? 10.0 : 11.0;
          final priceFontSize = compact ? 14.0 : 16.0;
          final supportingMeta = isBankCardPromotion
              ? bankName ??
                  (offerTypes.isNotEmpty ? offerTypes.join(' • ') : locationLabel)
              : widget.prioritizeDistance
                  ? locationLabel
                  : (savingAmount != null
                      ? 'Save Rs.$savingAmount'
                      : locationLabel);

          return Container(
            width: widget.width,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
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
                              Colors.black.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                      if (p.discount != null && p.discount!.isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 7 : 8,
                              vertical: compact ? 3 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              p.discount!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 10 : 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (showCountdown)
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 8 : 10,
                              vertical: compact ? 5 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.38),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _timeLeft == Duration.zero
                                      ? Icons.timer_off_outlined
                                      : Icons.timer_outlined,
                                  size: compact ? 12 : 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _timeLeft == Duration.zero
                                      ? 'Expired'
                                      : _formatCountdown(_timeLeft!),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: compact ? 10.5 : 12,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (p.featured == true)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 5 : 6,
                              vertical: compact ? 2 : 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[700],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: compact ? 9 : 10,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'HOT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: compact ? 8 : 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
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
                        Text(
                          p.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1A1A),
                            height: 1.2,
                            letterSpacing: -0.1,
                          ),
                        ),
                        SizedBox(height: compact ? 4 : 6),
                        if (p.merchantName != null &&
                            p.merchantName!.isNotEmpty)
                          Row(
                            children: [
                              if (p.merchantLogoUrl != null &&
                                  p.merchantLogoUrl!.isNotEmpty)
                                _buildLogo(p.merchantLogoUrl!)
                              else
                                const Icon(
                                  Icons.store,
                                  size: 11,
                                  color: Color(0xFF1E88E5),
                                ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  p.merchantName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: merchantFontSize,
                                    color: const Color(0xFF1E88E5),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        SizedBox(height: compact ? 6 : 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (p.discountedPrice != null ||
                                p.originalPrice != null ||
                                p.price != null)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Rs.${(p.discountedPrice ?? p.price ?? p.originalPrice)!.toStringAsFixed(0)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: priceFontSize,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFFE53935),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    if (p.originalPrice != null &&
                                        p.discountedPrice != null)
                                      Text(
                                        'Rs.${p.originalPrice!.toStringAsFixed(0)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: compact ? 9 : 10,
                                          color: const Color(0xFF9E9E9E),
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            else
                              const Spacer(),
                            if (!widget.prioritizeDistance &&
                                distance.isNotEmpty)
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: compact ? 7 : 8,
                                    vertical: compact ? 4 : 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 10,
                                        color: Color(0xFF1E88E5),
                                      ),
                                      const SizedBox(width: 2),
                                      Flexible(
                                        child: Text(
                                          distanceWithContext,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: compact ? 10 : 11,
                                            color: const Color(0xFF1E88E5),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: compact ? 6 : 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (p.isVerifiedActiveDeal)
                              const DealVerificationBadge(),
                            if (isBankCardPromotion)
                              _buildInfoChip(
                                icon: Icons.credit_card_rounded,
                                label: cardTypes.isNotEmpty
                                    ? cardTypes.join(' + ')
                                    : 'Card Offer',
                                background: const Color(0xFFE8F0FE),
                                foreground: const Color(0xFF0F4C81),
                                compact: badgeCompact,
                              ),
                            if (isBankCardPromotion && offerTypes.isNotEmpty)
                              _buildInfoChip(
                                icon: Icons.account_balance_wallet_outlined,
                                label: offerTypes.first,
                                background: const Color(0xFFECFDF5),
                                foreground: const Color(0xFF047857),
                                compact: badgeCompact,
                              ),
                            if (primaryModeLabel != null)
                              _buildInfoChip(
                                icon: promotionModeIcon(primaryModeLabel),
                                label: primaryModeLabel,
                                background: const Color(0xFFF1F8E9),
                                foreground: const Color(0xFF33691E),
                                compact: badgeCompact,
                              ),
                            if (widget.prioritizeDistance &&
                                distance.isNotEmpty)
                              _buildInfoChip(
                                icon: Icons.near_me_rounded,
                                label: distanceWithContext,
                                background: const Color(0xFFE3F2FD),
                                foreground: const Color(0xFF1E88E5),
                                compact: badgeCompact,
                              ),
                          ],
                        ),
                        if (showCountdown && _timeLeft != null) ...[
                          SizedBox(height: compact ? 6 : 8),
                          Text(
                            _timeLeft == Duration.zero
                                ? 'Offer expired'
                                : 'Ends in ${_formatCountdown(_timeLeft!)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: bodyFontSize,
                              fontWeight: FontWeight.w700,
                              color: _timeLeft == Duration.zero
                                  ? DealExpiryHelper.urgencyColor(
                                      context,
                                      p.endDate,
                                    )
                                  : const Color(0xFF9A3412),
                            ),
                          ),
                        ],
                        if (supportingMeta != null && supportingMeta.isNotEmpty) ...[
                          SizedBox(height: compact ? 6 : 8),
                          Text(
                            supportingMeta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: bodyFontSize,
                              color: const Color(0xFF64748B),
                              height: 1.25,
                              fontWeight: FontWeight.w500,
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

  IconData promotionModeIcon(String label) {
    switch (label) {
      case 'Delivery':
        return Icons.delivery_dining;
      case 'Pickup':
        return Icons.shopping_bag_outlined;
      case 'Visit':
        return Icons.storefront_outlined;
      default:
        return Icons.local_offer_outlined;
    }
  }
}
