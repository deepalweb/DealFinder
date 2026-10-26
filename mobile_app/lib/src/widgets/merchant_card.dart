import '../utils/merchant_hours.dart';
import '../models/category.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MerchantCard extends StatelessWidget {
  final Map<String, dynamic> merchant;
  final VoidCallback onVisit;
  final VoidCallback onFollowToggle;
  final bool isFollowing;
  final bool isFollowUpdating;
  final VoidCallback onShare;
  final bool compact;

  const MerchantCard({
    super.key,
    required this.merchant,
    required this.onVisit,
    required this.onFollowToggle,
    required this.isFollowing,
    this.isFollowUpdating = false,
    required this.onShare,
    this.compact = false,
  });

  Widget _buildImageWidget(
    String? imageUrl,
    Widget placeholder, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) return placeholder;

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(imageUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => placeholder);
    }
    if (imageUrl.startsWith('data:image')) {
      try {
        final bytes =
            base64Decode(imageUrl.substring(imageUrl.indexOf(',') + 1));
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => placeholder,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error decoding base64 image: $e');
        }
        return placeholder;
      }
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder;
        },
      );
    }

    return placeholder;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final large = MediaQuery.textScalerOf(context).scale(16) > 24;
    final scaler = MediaQuery.textScalerOf(context);
    final name = (merchant['name'] ?? l10n.stores).toString();
    final address = (merchant['address'] ?? '').toString();
    final photo = (merchant['banner'] ?? merchant['logo'])?.toString();
    final rating = (merchant['averageRating'] as num?)?.toDouble();
    final ratingsCount = (merchant['ratingsCount'] as num?)?.toInt() ?? 0;
    final count = (merchant['activeDeals'] as num?)?.toInt();
    final hours = merchant['openingHours'];
    final open = merchant['merchantType'] == 'online'
        ? null
        : MerchantHours.isOpen(
            hours is Map ? Map<String, dynamic>.from(hours) : null);
    Widget slot(String value, double size, int lines, {FontWeight? weight}) =>
        SizedBox(
            width: double.infinity,
            height: scaler.scale(size) * 1.3 * lines,
            child: Tooltip(
                message: value,
                child: Text(value,
                    maxLines: lines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: size,
                        height: 1.3,
                        fontWeight: weight,
                        color: colors.onSurface))));
    final facts = [
      if (rating != null &&
          rating.isFinite &&
          rating >= 0 &&
          rating <= 5 &&
          ratingsCount > 0)
        '${rating.toStringAsFixed(1)} ($ratingsCount)',
      if (count != null && count >= 0) '${l10n.profileOffersLabel}: $count',
      if (open != null) open ? l10n.openNowLabel : l10n.profileClosedLabel,
    ].join(' · ');
    final image = ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 0 : 12),
        child: SizedBox(
            width: compact ? double.infinity : 88,
            height: compact ? 130 : 88,
            child: _buildImageWidget(
                photo,
                ColoredBox(
                    color: colors.primaryContainer,
                    child: Icon(Icons.storefront_outlined,
                        size: 36, color: colors.primary)),
                width: compact ? double.infinity : 88,
                height: compact ? 130 : 88)));
    final info =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      slot(name, 15, 2, weight: FontWeight.w700),
      const SizedBox(height: 4),
      slot(getCategoryLabel(merchant['category']?.toString()), 12, 1),
      const SizedBox(height: 4),
      slot(facts, 12, 2),
      const SizedBox(height: 4),
      slot(address, 12, 2),
    ]);
    final view =
        TextButton(onPressed: onVisit, child: Text(l10n.viewStoreLabel));
    final follow = OutlinedButton.icon(
        onPressed: isFollowUpdating ? null : onFollowToggle,
        icon: isFollowUpdating
            ? const SizedBox.square(
                dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(isFollowing ? Icons.check_rounded : Icons.add_rounded,
                size: 18),
        label: Text(isFollowing ? l10n.following : l10n.followStoreLabel));
    return Material(
        color: colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: colors.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onVisit,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (compact) image,
                  Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(children: [
                        if (compact || large)
                          info
                        else
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                image,
                                const SizedBox(width: 12),
                                Expanded(child: info)
                              ]),
                        const SizedBox(height: 8),
                        if (large) ...[
                          SizedBox(width: double.infinity, child: follow),
                          Row(children: [
                            Expanded(child: view),
                            IconButton(
                                onPressed: onShare,
                                tooltip: l10n.profileShareStoreLabel,
                                icon: const Icon(Icons.ios_share, size: 20))
                          ]),
                        ] else
                          Row(children: [
                            Expanded(child: view),
                            Expanded(child: follow),
                            IconButton(
                                onPressed: onShare,
                                tooltip: l10n.profileShareStoreLabel,
                                icon: const Icon(Icons.ios_share, size: 20))
                          ]),
                      ])),
                ])));
  }
}
