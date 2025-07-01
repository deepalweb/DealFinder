import 'dart:convert'; // For base64Decode
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:url_launcher/url_launcher.dart'; // For launching URLs
import '../models/promotion.dart';

class DealCard extends StatelessWidget {
  final Promotion promotion;

  const DealCard({super.key, required this.promotion});

  Widget _buildImageWidget(BuildContext context, String imageUrl) {
    Widget errorDisplayWidget = Container(
      constraints: BoxConstraints(
        maxHeight: 220,
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
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => errorDisplayWidget,
          ),
        );
      } catch (e) {
        print('Error decoding Base64 image: $e');
        return errorDisplayWidget;
      }
    } else if (imageUrl.startsWith('http')) {
      return buildImage(
        Image.network(
          imageUrl,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => errorDisplayWidget,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              constraints: BoxConstraints(maxHeight: 220),
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
    final DateFormat dateFormat = DateFormat('MMM d, yyyy'); // Example: Jan 1, 2023

    // Helper to build rich text for discount
    InlineSpan buildDiscountText() {
      if (promotion.discount == null || promotion.discount!.isEmpty) {
        return const TextSpan(text: '');
      }
      if (promotion.discount!.contains('%')) {
        return TextSpan(
          text: promotion.discount,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        );
      } else if (promotion.discount!.startsWith('\$') || promotion.discount!.startsWith('USD')) {
         return TextSpan(
          text: promotion.discount,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        );
      }
      return TextSpan(text: promotion.discount, style: const TextStyle(fontSize: 14));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Promotion Image
            _buildImageWidget(context, promotion.imageDataString ?? ''),
            const SizedBox(height: 12.0),

            // Title
            Text(
              promotion.title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6.0),

            // Merchant Name (if available)
            if (promotion.merchantName != null && promotion.merchantName!.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.storefront, size: 16, color: theme.textTheme.bodySmall?.color),
                  const SizedBox(width: 4.0),
                  Text(
                    promotion.merchantName!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            if (promotion.merchantName != null && promotion.merchantName!.isNotEmpty)
              const SizedBox(height: 8.0),

            // Description (shortened)
            Text(
              promotion.description,
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
                RichText(text: buildDiscountText()),
                // Promo Code (if available)
                if (promotion.code != null && promotion.code!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(color: theme.colorScheme.secondaryContainer, width: 1)
                    ),
                    child: Text(
                      'CODE: ${promotion.code}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10.0),

            // Divider
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 8.0),

            // Expiry Date (if available)
            if (promotion.endDate != null)
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: theme.textTheme.bodySmall?.color),
                  const SizedBox(width: 6.0),
                  Text(
                    'Expires: ${dateFormat.format(promotion.endDate!)}',
                    style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            // Get Directions Button (if location is available)
            if (promotion.location != null && promotion.location!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.directions),
                    label: const Text('Get Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final location = promotion.location!;
                      final encodedLocation = Uri.encodeComponent(location);
                      final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$encodedLocation';
                      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
                        await launchUrl(Uri.parse(googleMapsUrl));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open Maps.')),
                        );
                      }
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
