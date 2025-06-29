import 'dart:convert'; // For base64Decode
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:intl/intl.dart'; // For date formatting
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/promotion.dart';
import '../services/favorites_manager.dart';
import 'dart:convert'; // For base64 decoding

class DealDetailScreen extends StatefulWidget {
  final Promotion promotion;
  const DealDetailScreen({super.key, required this.promotion});

  @override
  State<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends State<DealDetailScreen> {
  bool _isFavorite = false;
  bool _showTerms = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
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
  }

  // Helper to launch URL - requires url_launcher package
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $urlString')),
      );
    }
  }

  void _shareDeal() {
    final promo = widget.promotion;
    final text = '${promo.title}\n${promo.description}\n${promo.websiteUrl ?? ''}';
    Share.share(text.trim());
  }

  // Helper to decode base64 image
  Uint8List _decodeBase64Image(String dataUrl) {
    final base64String = dataUrl.split(',').last;
    return base64Decode(base64String);
  }

  @override
  Widget build(BuildContext context) {
    final promotion = widget.promotion;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(promotion.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            tooltip: 'Toggle Favorite',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Deal',
            onPressed: _shareDeal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[

              const SizedBox(height: 20.0),

            // Promotion Title
            Text(
              promotion.title,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),

            // Merchant Information (if available)
            if (promotion.merchantName != null && promotion.merchantName!.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.storefront_outlined, size: 20, color: theme.textTheme.bodyMedium?.color),
                  const SizedBox(width: 8.0),
                  Text(
                    promotion.merchantName!,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            if (promotion.merchantName != null && promotion.merchantName!.isNotEmpty)
              const SizedBox(height: 16.0),

            // Discount & Code Section
            if (promotion.discount != null || promotion.code != null)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (promotion.discount != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Discount:', style: theme.textTheme.labelMedium),
                              Text(
                                promotion.discount!,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (promotion.code != null)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.content_copy, size: 16),
                          label: Text(promotion.code!),
                          style: ElevatedButton.styleFrom(
                             backgroundColor: theme.colorScheme.secondary,
                             foregroundColor: theme.colorScheme.onSecondary,
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: promotion.code!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Code "${promotion.code}" copied to clipboard!')),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16.0),

            // Price Section
            if (promotion.price != null || promotion.originalPrice != null || promotion.discountedPrice != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    if (promotion.originalPrice != null)
                      Text(
                        'Rs. ${promotion.originalPrice!.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                    if (promotion.discountedPrice != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          'Rs. ${promotion.discountedPrice!.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (promotion.price != null && promotion.discountedPrice == null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          'Rs. ${promotion.price!.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Full Description
            Text(
              'Details:',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6.0),
            Text(
              promotion.description, // Assuming this is the full description
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 16.0),

            // Validity Period
            if (promotion.startDate != null || promotion.endDate != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Validity:',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6.0),
                  if (promotion.startDate != null)
                    Text('Starts: ${dateFormat.format(promotion.startDate!)}', style: theme.textTheme.bodyMedium),
                  if (promotion.endDate != null)
                    Text('Expires: ${dateFormat.format(promotion.endDate!)}', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16.0),
                ],
              ),

            // Terms & Conditions (Collapsible)
            if (promotion.termsAndConditions != null && promotion.termsAndConditions!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showTerms = !_showTerms;
                      });
                    },
                    child: Row(
                      children: [
                        Text(
                          'Terms & Conditions',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Icon(_showTerms ? Icons.expand_less : Icons.expand_more),
                      ],
                    ),
                  ),
                  if (_showTerms)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0, bottom: 16.0),
                      child: Text(
                        promotion.termsAndConditions!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),

            // Action Buttons
            Wrap(
              spacing: 12.0, // Horizontal space between buttons
              runSpacing: 8.0, // Vertical space if buttons wrap
              alignment: WrapAlignment.center,
              children: [
                if (promotion.websiteUrl != null && promotion.websiteUrl!.isNotEmpty)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.public),
                    label: const Text('Visit Website'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.tertiary,
                      foregroundColor: theme.colorScheme.onTertiary,
                    ),
                    onPressed: () => _launchURL(promotion.websiteUrl!),
                  ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share Deal'),
                  onPressed: _shareDeal,
                ),
                OutlinedButton.icon(
                  icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border_outlined, color: theme.colorScheme.primary),
                  label: Text(_isFavorite ? 'Remove Favorite' : 'Save to Favorites'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                  onPressed: _toggleFavorite,
                ),
              ],
            ),

            // Recommendations/Similar Deals (Placeholder)
            const SizedBox(height: 32.0),
            Text(
              'You might also like',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12.0),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3, // Placeholder count
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return Container(
                    width: 140,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 70,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.local_offer, size: 40, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text('Deal Title', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Short description...', style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context, String? imageDataString) {
    if (imageDataString == null || imageDataString.isEmpty) {
      return _buildImageErrorPlaceholder(context);
    }
    if (imageDataString.startsWith('data:image') && imageDataString.contains(';base64,')) {
      try {
        final String base64Data = imageDataString.substring(imageDataString.indexOf(',') + 1);
        final Uint8List decodedBytes = base64Decode(base64Data);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Image.memory(
            decodedBytes,
            width: double.infinity,
            height: 250,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildImageErrorPlaceholder(context, error: error),
          ),
        );
      } catch (e) {
        print('Error decoding Base64 image for DetailScreen: $e');
        return _buildImageErrorPlaceholder(context, error: e);
      }
    } else if (imageDataString.startsWith('http')) {
      // Support for network images
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Image.network(
          imageDataString,
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildImageErrorPlaceholder(context, error: error),
        ),
      );
    }
    // Fallback for non-Base64 or if only Base64 is expected and it's malformed
    return _buildImageErrorPlaceholder(context);
  }

  Widget _buildImageErrorPlaceholder(BuildContext context, {Object? error}) {
    if (error != null) {
      print("DetailScreen Image loading/decoding error: $error");
    }
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Icon(Icons.broken_image_outlined, size: 60, color: Colors.grey[600]),
    );
  }
}
