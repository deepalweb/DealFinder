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

  String _todayKey() {
    switch (DateTime.now().weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      default:
        return 'sunday';
    }
  }

  int? _parseClock(dynamic value) {
    final text = value?.toString().trim() ?? '';
    final parts = text.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }

  ({bool? openNow, String label}) _openStatus(Map<String, dynamic> merchant) {
    final hours = merchant['openingHours'];
    if (hours is! Map) return (openNow: null, label: 'Hours unavailable');
    final today = hours[_todayKey()];
    if (today is! Map) return (openNow: null, label: 'Hours unavailable');
    if (today['closed'] == true) return (openNow: false, label: 'Closed today');
    final openText = (today['open'] ?? '').toString();
    final closeText = (today['close'] ?? '').toString();
    final open = _parseClock(openText);
    final close = _parseClock(closeText);
    if (open == null || close == null) {
      return (openNow: null, label: 'Hours unavailable');
    }
    final now = DateTime.now();
    final current = now.hour * 60 + now.minute;
    final isOpen = close < open
        ? current >= open || current <= close
        : current >= open && current <= close;
    return (
      openNow: isOpen,
      label: isOpen ? 'Open now' : 'Closed now',
    );
  }

  Widget _buildImageWidget(
    String? imageUrl,
    Widget placeholder, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) return placeholder;

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
    final scheme = theme.colorScheme;
    final name = (merchant['name'] ?? 'Store').toString();
    final category = (merchant['category'] ?? 'other').toString();
    final location = (merchant['address'] ?? '').toString();
    final photo = (merchant['banner'] ?? merchant['logo'])?.toString();
    final rating = (merchant['averageRating'] as num?)?.toDouble() ?? 0;
    final count = (merchant['activeDeals'] as num?)?.toInt() ?? 0;
    final open = _openStatus(merchant);
    final fallback = Container(
        color: scheme.primaryContainer,
        child:
            Icon(Icons.storefront_outlined, size: 48, color: scheme.primary));
    return Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onVisit,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                  height: compact ? 130 : 170,
                  width: double.infinity,
                  child: _buildImageWidget(photo, fallback,
                      width: double.infinity)),
              Padding(
                  padding: EdgeInsets.all(compact ? 16 : 18),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(name,
                                  style: theme.textTheme.titleLarge)),
                          IconButton(
                              tooltip:
                                  AppLocalizations.of(context)!.shareStoreLabel,
                              onPressed: onShare,
                              icon:
                                  const Icon(Icons.ios_share_rounded, size: 20))
                        ]),
                        const SizedBox(height: 4),
                        Wrap(spacing: 12, runSpacing: 8, children: [
                          Text(category.replaceAll('_', ' '),
                              style: theme.textTheme.bodySmall),
                          if (rating > 0)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.star_rounded,
                                  size: 16, color: scheme.primary),
                              const SizedBox(width: 4),
                              Text(rating.toStringAsFixed(1),
                                  style: theme.textTheme.bodySmall)
                            ]),
                          if (count > 0)
                            Text('$count active deals',
                                style: theme.textTheme.bodySmall),
                          if (open.openNow != null)
                            Text(open.label, style: theme.textTheme.bodySmall),
                        ]),
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(children: [
                            Icon(Icons.location_on_outlined,
                                size: 16, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 5),
                            Expanded(
                                child: Text(location,
                                    maxLines: compact ? 1 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall))
                          ])
                        ],
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                              child: FilledButton.tonal(
                                  style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 12)),
                                  onPressed: onVisit,
                                  child: Text(AppLocalizations.of(context)!
                                      .viewStoreLabel))),
                          const SizedBox(width: 10),
                          Expanded(
                              child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 12)),
                                  onPressed:
                                      isFollowUpdating ? null : onFollowToggle,
                                  icon: isFollowUpdating
                                      ? const SizedBox.square(
                                          dimension: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : Icon(
                                          isFollowing
                                              ? Icons.check_rounded
                                              : Icons.add_rounded,
                                          size: 18),
                                  label: Text(isFollowing
                                      ? AppLocalizations.of(context)!.following
                                      : AppLocalizations.of(context)!
                                          .followStoreLabel)))
                        ]),
                      ])),
            ])));
  }
}
