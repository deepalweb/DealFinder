import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/promotion.dart';

class DealCardNew extends StatelessWidget {
  final Promotion promotion;
  final VoidCallback? onTap;
  final double? width;

  const DealCardNew({
    super.key,
    required this.promotion,
    this.onTap,
    this.width,
  });

  String _formatCountdown(DateTime endDate) {
    final diff = endDate.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays >= 1) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    return '${diff.inMinutes}m left';
  }

  String _formatDistance(double? distanceMeters) {
    if (distanceMeters == null) return '';
    if (distanceMeters < 1000) return '${distanceMeters.round()}m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
  }

  Widget _buildImage() {
    final img = promotion.imageDataString;

    final shimmer = Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    );

    if (img == null || img.isEmpty) return shimmer;

    if (img.startsWith('data:image')) {
      try {
        final bytes = base64Decode(img.substring(img.indexOf(',') + 1));
        return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity,
            errorBuilder: (_, __, ___) => shimmer);
      } catch (_) {
        return shimmer;
      }
    }

    if (img.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: img,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, __) => shimmer,
        errorWidget: (_, __, ___) => shimmer,
      );
    }

    return shimmer;
  }

  @override
  Widget build(BuildContext context) {
    final p = promotion;
    final countdown = p.endDate != null ? _formatCountdown(p.endDate!) : null;
    final distance = _formatDistance(p.distance);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image — 60% of card
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(),
                  // Discount badge top-left
                  if (p.discount != null && p.discount!.isNotEmpty)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p.discount!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Countdown badge bottom-right
                  if (countdown != null && countdown != 'Expired')
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer, size: 11, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              countdown,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info — 40% of card
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      p.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                    ),
                    // Merchant name
                    if (p.merchantName != null && p.merchantName!.isNotEmpty)
                      Text(
                        p.merchantName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    // Price + Distance row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price
                        if (p.discountedPrice != null || p.originalPrice != null || p.price != null)
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  'Rs.${(p.discountedPrice ?? p.price ?? p.originalPrice)!.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE53935),
                                  ),
                                ),
                                if (p.originalPrice != null && p.discountedPrice != null) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    'Rs.${p.originalPrice!.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF9E9E9E),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        else
                          const Spacer(),
                        // Distance
                        if (distance.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, size: 11, color: Color(0xFF1E88E5)),
                              const SizedBox(width: 2),
                              Text(
                                distance,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF1E88E5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
