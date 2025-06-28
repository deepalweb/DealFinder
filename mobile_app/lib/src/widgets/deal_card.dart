import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'dart:convert'; // For base64Decode
import 'dart:typed_data'; // For Uint8List
import '../models/promotion.dart';

class DealCard extends StatelessWidget {
  final Promotion promotion;

  const DealCard({super.key, required this.promotion});

  Widget _buildImageWidget(BuildContext context, String imageUrl) {
    Widget errorDisplayWidget = Container(
      height: 150,
      width: double.infinity,
      color: Colors.grey[300],
      child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
    );

    if (imageUrl.startsWith('data:image')) {
      try {
        // Find the start of the Base64 data
        final base64Data = imageUrl.substring(imageUrl.indexOf(',') + 1);
        final Uint8List bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => errorDisplayWidget,
        );
      } catch (e) {
        print('Error decoding Base64 image: $e');
        return errorDisplayWidget;
      }
    } else if (imageUrl.startsWith('http')) {
      // Standard network image
      return Image.network(
        imageUrl,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => errorDisplayWidget,
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 150,
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
      );
    } else {
      // If it's not a data URI and not an HTTP/HTTPS URL, it's an invalid format
      print('Invalid image URL format: $imageUrl');
      return errorDisplayWidget;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final NumberFormat currencyFormat = NumberFormat.simpleCurrency(locale: 'en_US', name: 'USD'); // Adjust locale/currency as needed
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
            // Image Section (Optional)
            if (promotion.imageUrl != null && promotion.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: _buildImageWidget(context, promotion.imageUrl!),
              ),
            if (promotion.imageUrl != null && promotion.imageUrl!.isNotEmpty)
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
          ],
        ),
      ),
    );
  }
}
