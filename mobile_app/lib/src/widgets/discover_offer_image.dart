import 'package:flutter/material.dart';
import '../models/promotion.dart';
import '../services/image_helper.dart';

/// Bundled Stitch artwork is used for clearly identified demo records only.
/// Merchant photos remain sourced from the actual promotion record.
class DiscoverOfferImage extends StatelessWidget {
  const DiscoverOfferImage({super.key, required this.offer});
  final Promotion offer;
  @override
  Widget build(BuildContext context) {
    final source = offer.imageDataString;
    final path = source?.startsWith('assets/') == true
        ? source
        : offer.title.startsWith('[DEMO]')
            ? switch (offer.category) {
                'food_dining' => offer.title.toLowerCase().contains('burger')
                    ? 'assets/discover/stitch-2.jpg'
                    : 'assets/discover/stitch-1.jpg',
                'daily_essentials' => 'assets/discover/stitch-3.jpg',
                _ => offer.imageDataString,
              }
            : offer.imageDataString;
    if (path?.startsWith('assets/') == true) {
      return Image.asset(path!, fit: BoxFit.cover, excludeFromSemantics: true);
    }
    return ImageHelper.buildOptimizedImage(path, fit: BoxFit.cover);
  }
}
