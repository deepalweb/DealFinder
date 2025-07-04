import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:intl/intl.dart'; // For date formatting
import '../models/promotion.dart';
// import 'package:url_launcher/url_launcher.dart'; // For launching URLs - add to pubspec if used

class DealDetailScreen extends StatelessWidget {
  final Promotion promotion;

  const DealDetailScreen({super.key, required this.promotion});

  // Helper to launch URL - requires url_launcher package
  // Future<void> _launchURL(String urlString) async {
  //   final Uri url = Uri.parse(urlString);
  //   if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
  //     throw Exception('Could not launch $urlString');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateFormat dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(promotion.title, overflow: TextOverflow.ellipsis),
        // actions: [ // Placeholder for Share action
        //   IconButton(
        //     icon: const Icon(Icons.share_outlined),
        //     tooltip: 'Share Deal',
        //     onPressed: () {
        //       // Implement sharing functionality
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         const SnackBar(content: Text('Share functionality TBD')),
        //       );
        //     },
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Promotion Image
            if (promotion.imageUrl != null && promotion.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  promotion.imageUrl!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Icon(Icons.broken_image, size: 60, color: Colors.grey[600]),
                  ),
                ),
              ),
            if (promotion.imageUrl != null && promotion.imageUrl!.isNotEmpty)
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

            // Terms & Conditions (Placeholder)
            // Text(
            //   'Terms & Conditions:',
            //   style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            // ),
            // const SizedBox(height: 6.0),
            // Text(
            //   promotion.termsAndConditions ?? 'Not specified.', // Assuming a field like this in Promotion model
            //   style: theme.textTheme.bodyMedium,
            // ),
            // const SizedBox(height: 24.0),

            // Action Buttons
            Wrap(
              spacing: 12.0, // Horizontal space between buttons
              runSpacing: 8.0, // Vertical space if buttons wrap
              alignment: WrapAlignment.center,
              children: [
                // Placeholder for Visit Website - needs url_launcher
                // if (promotion.websiteUrl != null && promotion.websiteUrl!.isNotEmpty)
                //   ElevatedButton.icon(
                //     icon: const Icon(Icons.public),
                //     label: const Text('Visit Website'),
                //     onPressed: () => _launchURL(promotion.websiteUrl!),
                //   ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.language_outlined),
                  label: const Text('Visit Website (TBD)'),
                  style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.tertiary, foregroundColor: theme.colorScheme.onTertiary),
                  onPressed: () {
                     ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Visit Website functionality TBD. Needs URL in promotion data and url_launcher package.')),
                      );
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share Deal'),
                  onPressed: () {
                    // Placeholder: Implement sharing functionality (e.g., using share_plus package)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share functionality TBD (e.g., using share_plus).')),
                    );
                  },
                ),
                // Placeholder for Save to Favorites
                OutlinedButton.icon(
                  icon: const Icon(Icons.favorite_border_outlined), // Change to Icons.favorite for filled
                  label: const Text('Save to Favorites'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                  onPressed: () {
                    // Placeholder: Implement save to favorites
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Save to Favorites functionality TBD.')),
                    );
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
