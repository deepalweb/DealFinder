import 'package:deal_finder_mobile/l10n/app_localizations.dart';
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
      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = widget.promotion;
    final distance = _formatDistance(p.distance);
    final currentPrice = p.discountedPrice ?? p.price ?? p.originalPrice;
    final discount = p.discountPercentage != null
        ? '${p.discountPercentage}% off'
        : p.discount;
    final expiry = _timeLeft != null && _timeLeft!.inHours < 48
        ? (_timeLeft == Duration.zero
            ? 'Expired'
            : _formatCountdown(_timeLeft!))
        : null;
    final verified = p.trustStatus == 'verified';
    return Semantics(
      button: widget.onTap != null,
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
            width: widget.width,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.6))),
            child: LayoutBuilder(builder: (context, constraints) {
              final compact = (widget.width ?? constraints.maxWidth) <= 210;
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AspectRatio(
                        aspectRatio: compact ? 1.55 : 1.8,
                        child: Stack(fit: StackFit.expand, children: [
                          _buildImage(),
                          if (discount?.isNotEmpty ?? false)
                            Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: AppColors.brand,
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Text(discount!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)))),
                        ])),
                    Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (p.merchantName?.isNotEmpty ?? false)
                                Row(children: [
                                  Expanded(
                                      child: Text(p.merchantName!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: scheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w500))),
                                  if (verified)
                                    Tooltip(
                                        message: AppLocalizations.of(context)!
                                            .verifiedDealLabel,
                                        child: const Icon(Icons.verified_rounded,
                                            size: 16,
                                            color: AppColors.betelGreen)),
                                ]),
                              const SizedBox(height: 6),
                              Text(p.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      height: 1.25,
                                      letterSpacing: -0.2,
                                      color: scheme.onSurface)),
                              if (currentPrice != null) ...[
                                const SizedBox(height: 10),
                                PriceBlock(
                                    currentPriceLabel: _priceLabel(currentPrice,
                                        currencyCode: p.merchantCurrency),
                                    originalPriceLabel: p.originalPrice !=
                                                null &&
                                            p.discountedPrice != null
                                        ? _priceLabel(p.originalPrice!,
                                            currencyCode: p.merchantCurrency)
                                        : null,
                                    compact: compact),
                              ],
                              if (distance.isNotEmpty || expiry != null) ...[
                                const SizedBox(height: 8),
                                if (expiry != null)
                                  ExpiryChip(
                                      label: expiry,
                                      expired: _timeLeft == Duration.zero,
                                      compact: true)
                                else
                                  DistanceTravelChip(
                                      distanceLabel: distance, compact: true),
                              ],
                            ])),
                  ]);
            }),
          ),
        ),
      ),
    );
  }
}
