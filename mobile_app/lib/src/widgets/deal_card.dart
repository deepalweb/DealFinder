import 'dart:convert'; // For base64Decode
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/promotion.dart';
import '../services/favorites_manager.dart';
import '../services/review_service.dart';
import '../widgets/rating_widget.dart';

class DealCard extends StatefulWidget {
  final Promotion promotion;
  final double? width;

  const DealCard({super.key, required this.promotion, this.width});
  
  @override
  State<DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<DealCard> {
  bool _isFavorite = false;
  double _averageRating = 0.0;
  int _reviewCount = 0;
  
  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _loadRating();
  }
  
  Future<void> _loadRating() async {
    final rating = await ReviewService.getAverageRating(widget.promotion.id);
    final count = await ReviewService.getReviewCount(widget.promotion.id);
    setState(() {
      _averageRating = rating;
      _reviewCount = count;
    });
  }
  
  Future<void> _checkFavoriteStatus() async {
    final isFav = await FavoritesManager.isFavorite(widget.promotion.id);
    setState(() {
      _isFavorite = isFav;
    });
  }
  
  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await FavoritesManager.removeFavorite(widget.promotion.id);
    } else {
      await FavoritesManager.addFavorite(widget.promotion.id);
    }
    setState(() {
      _isFavorite = !_isFavorite;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  void _shareDeal() {
    final promo = widget.promotion;
    final shareText = '🔥 ${promo.title}\n\n${promo.description}\n\n💰 ${promo.discount ?? "Great Deal"}\n\n📱 Get DealFinder app for more deals!';
    Share.share(shareText);
  }

  Widget _buildImageWidget(BuildContext context, String imageUrl) {
    Widget errorDisplayWidget = Container(
      constraints: const BoxConstraints(
        maxHeight: 220,
        minWidth: 0,
        maxWidth: double.infinity,
      ),
      width: double.infinity,
      color: Colors.grey[300],
      child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
    );

    void showFullScreenImage(Widget imageWidget) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              child: imageWidget,
            ),
          ),
        ),
      );
    }

    Widget buildImage(Widget image) {
      return GestureDetector(
        onTap: () => showFullScreenImage(image),
        child: image,
      );
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Data = imageUrl.substring(imageUrl.indexOf(',') + 1);
        final Uint8List bytes = base64Decode(base64Data);
        return buildImage(
          Image.memory(
            bytes,
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => errorDisplayWidget,
          ),
        );
      } catch (e) {
        return errorDisplayWidget;
      }
    } else if (imageUrl.startsWith('http')) {
      return buildImage(
        Image.network(
          imageUrl,
          width: double.infinity,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => errorDisplayWidget,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              constraints: const BoxConstraints(maxHeight: 180),
              width: double.infinity,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      );
    } else {
      return errorDisplayWidget;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateFormat dateFormat = DateFormat('MMM d, yyyy');

    // Helper to build rich text for discount
    InlineSpan buildDiscountText() {
      if (widget.promotion.discount == null || widget.promotion.discount!.isEmpty) {
        return const TextSpan(text: '');
      }
      if (widget.promotion.discount!.contains('%')) {
        return TextSpan(
          text: widget.promotion.discount,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        );
      } else if (widget.promotion.discount!.startsWith('\$') || widget.promotion.discount!.startsWith('USD')) {
         return TextSpan(
          text: widget.promotion.discount,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        );
      }
      return TextSpan(text: widget.promotion.discount, style: const TextStyle(fontSize: 14));
    }

    return Container(
      width: widget.width,
      constraints: widget.width != null ? BoxConstraints(maxWidth: widget.width!) : const BoxConstraints(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        elevation: 3.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Promotion Image with Hero animation and favorite button
              Stack(
                children: [
                  Hero(
                    tag: 'dealImage_${widget.promotion.id}',
                    child: _buildImageWidget(context, widget.promotion.imageDataString ?? ''),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.promotion.url != null && widget.promotion.url!.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextButton.icon(
                              icon: const Icon(Icons.launch, color: Colors.white, size: 16),
                              label: const Text('Go', style: TextStyle(color: Colors.white, fontSize: 12)),
                              onPressed: () async {
                                final Uri url = Uri.parse(widget.promotion.url!);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Could not launch ${widget.promotion.url}')),
                                  );
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        if (widget.promotion.url != null && widget.promotion.url!.isNotEmpty)
                          const SizedBox(width: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.share, color: Colors.blue, size: 20),
                            onPressed: _shareDeal,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorite ? Colors.red : Colors.grey[600],
                              size: 20,
                            ),
                            onPressed: _toggleFavorite,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // Badges and Highlights (e.g., Featured, New, Popular)
              Row(
                children: [
                  if (widget.promotion.featured == true)
                    Container(
                      margin: const EdgeInsets.only(right: 6.0),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text('FEATURED', style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  // Example: Add more badges as needed (e.g., New, Popular)
                  // if (promotion.isNew == true)
                  //   ...
                ],
              ),
              if (widget.promotion.featured == true)
                const SizedBox(height: 6.0),

              // Title
              Text(
                widget.promotion.title,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6.0),

              // Merchant Name (if available)
              if (widget.promotion.merchantName != null && widget.promotion.merchantName!.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.storefront, size: 16, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(width: 4.0),
                    Text(
                      widget.promotion.merchantName!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              if (widget.promotion.merchantName != null && widget.promotion.merchantName!.isNotEmpty)
                const SizedBox(height: 8.0),

              // Description (shortened)
              Text(
                widget.promotion.description,
                style: theme.textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10.0),

              // Discount and Code Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Discount
                  Flexible(
                    flex: 2,
                    child: RichText(
                      text: buildDiscountText(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  // Promo Code (if available)
                  if (widget.promotion.code != null && widget.promotion.code!.isNotEmpty)
                    Flexible(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(color: theme.colorScheme.secondaryContainer, width: 1)
                        ),
                        child: Text(
                          'CODE: ${widget.promotion.code}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10.0),

              // Visual Price Section
              if (widget.promotion.originalPrice != null || widget.promotion.discountedPrice != null || widget.promotion.price != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Row(
                    children: [
                      if (widget.promotion.originalPrice != null)
                        Text(
                          'Rs. ${widget.promotion.originalPrice!.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                      if (widget.promotion.discountedPrice != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            'Rs. ${widget.promotion.discountedPrice!.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      if (widget.promotion.price != null && widget.promotion.discountedPrice == null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            'Rs. ${widget.promotion.price!.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      if (widget.promotion.discount != null && widget.promotion.discount!.contains('%'))
                        Container(
                          margin: const EdgeInsets.only(left: 12.0),
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            widget.promotion.discount!,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),

              // Divider
              Divider(height: 1, color: Colors.grey[300]),
              const SizedBox(height: 8.0),

              // Rating and Expiry Date
              Row(
                children: [
                  if (_reviewCount > 0) ...[
                    RatingWidget(rating: _averageRating, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$_averageRating ($_reviewCount)',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (widget.promotion.endDate != null) ...[
                    Icon(Icons.calendar_today, size: 14, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(width: 6.0),
                    Text(
                      'Expires: ${dateFormat.format(widget.promotion.endDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
