import 'dart:async';

import 'package:flutter/material.dart';
import '../models/promotion.dart';
import '../services/image_helper.dart';
import '../utils/bank_card_promotion_support.dart';

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
          Icon(icon, size: iconSize ?? (compact ? 10 : 11), color: foreground),
          SizedBox(width: compact ? 3 : 4),
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
    Color? iconColor,
    double? iconSize,
    double? fontSize,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: compact ? 7 : 9,
            vertical: compact ? 4 : 5,
          ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize ?? (compact ? 11 : 12),
            color: iconColor ?? const Color(0xFF0F172A),
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize ?? (compact ? 8.5 : 9.5),
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final p = widget.promotion;
          final distance = _formatDistance(p.distance);
          final showCountdown = _timeLeft != null && p.endDate != null;
          final bankName = BankCardPromotionSupport.bankName(p);
          final effectiveWidth = widget.width ?? constraints.maxWidth;
          final compact = effectiveWidth <= 190;
          final imageFlex = compact ? 9 : 10;
          final contentFlex = compact ? 5 : 4;
          final contentPadding = compact ? 6.0 : 8.0;
          final titleFontSize = compact ? 12.0 : 13.5;
          final merchantFontSize = compact ? 9.5 : 10.5;
          final priceFontSize = compact ? 14.0 : 16.0;
          final sectionGap = compact ? 1.0 : 3.0;
          final merchantLabel = (p.merchantName?.trim().isNotEmpty ?? false)
              ? p.merchantName!.trim()
              : (bankName?.trim().isNotEmpty ?? false)
                  ? bankName!.trim()
                  : '';
          final distanceLabel = distance.isNotEmpty ? '$distance away' : '';
          final expiryLabel = showCountdown && _timeLeft != null
              ? (_timeLeft == Duration.zero
                  ? 'Expired'
                  : _formatCountdown(_timeLeft!))
              : '';
          final averageRating = p.averageRating ?? 0.0;
          final hasRatings = p.ratingsCount > 0;

          return Container(
            width: widget.width,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8EEF7)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.04),
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
                              Colors.black.withValues(alpha: 0.12),
                              Colors.black.withValues(alpha: 0.34),
                            ],
                          ),
                        ),
                      ),
                      if (p.discount != null && p.discount!.isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _buildInfoChip(
                            icon: Icons.local_offer_rounded,
                            label: p.discount!,
                            background: const Color(0xFFE53935),
                            foreground: Colors.white,
                            compact: compact,
                            iconSize: compact ? 11 : 12,
                            fontSize: compact ? 10 : 11,
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 7 : 9,
                              vertical: compact ? 4 : 5,
                            ),
                          ),
                        ),
                      if (hasRatings)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _buildGlassChip(
                            icon: Icons.star_rounded,
                            label: averageRating.toStringAsFixed(1),
                            compact: compact,
                            iconColor: const Color(0xFFF59E0B),
                            iconSize: compact ? 12 : 13,
                            fontSize: compact ? 9.5 : 10.5,
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 8 : 10,
                              vertical: compact ? 4 : 5,
                            ),
                          ),
                        ),
                      if (distanceLabel.isNotEmpty || expiryLabel.isNotEmpty)
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: Row(
                            children: [
                              if (distanceLabel.isNotEmpty)
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: _buildGlassChip(
                                      icon: Icons.near_me_rounded,
                                      label: distanceLabel,
                                      compact: compact,
                                      iconColor: const Color(0xFF1565C0),
                                    ),
                                  ),
                                ),
                              if (distanceLabel.isNotEmpty &&
                                  expiryLabel.isNotEmpty)
                                SizedBox(width: compact ? 6 : 8),
                              if (expiryLabel.isNotEmpty)
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: _buildGlassChip(
                                      icon: _timeLeft == Duration.zero
                                          ? Icons.timer_off_outlined
                                          : Icons.schedule_rounded,
                                      label: expiryLabel,
                                      compact: compact,
                                      iconColor: _timeLeft == Duration.zero
                                          ? const Color(0xFFB91C1C)
                                          : const Color(0xFFC2410C),
                                    ),
                                  ),
                                ),
                            ],
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
                          maxLines: compact ? 2 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1A1A),
                            height: 1.2,
                            letterSpacing: -0.1,
                          ),
                        ),
                        SizedBox(height: compact ? 1 : 2),
                        if (merchantLabel.isNotEmpty) ...[
                          Text(
                            merchantLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: merchantFontSize,
                              color: const Color(0xFF475569),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: sectionGap),
                        ],
                        if (p.discountedPrice != null ||
                            p.originalPrice != null ||
                            p.price != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _priceLabel(
                                  (p.discountedPrice ??
                                      p.price ??
                                      p.originalPrice)!,
                                  currencyCode: p.merchantCurrency,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: priceFontSize,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFE53935),
                                  letterSpacing: -0.25,
                                ),
                              ),
                              if (p.originalPrice != null &&
                                  p.discountedPrice != null)
                                Text(
                                  _priceLabel(
                                    p.originalPrice!,
                                    currencyCode: p.merchantCurrency,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: compact ? 8.5 : 10,
                                    color: const Color(0xFF9E9E9E),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        SizedBox(height: compact ? 2 : 4),
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
