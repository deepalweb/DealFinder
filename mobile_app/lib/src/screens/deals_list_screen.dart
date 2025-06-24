import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/promotion.dart';

class DealsListScreen extends StatefulWidget {
  const DealsListScreen({super.key});

  @override
  State<DealsListScreen> createState() => _DealsListScreenState();
}

class _DealsListScreenState extends State<DealsListScreen> {
  late Future<List<Promotion>> _promotionsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _promotionsFuture = _apiService.fetchPromotions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Deals'), // Updated title
      ),
      body: FutureBuilder<List<Promotion>>(
        future: _promotionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No deals found.'));
          } else {
            List<Promotion> promotions = snapshot.data!;
            return ListView.builder(
              itemCount: promotions.length,
              itemBuilder: (context, index) {
                Promotion promo = promotions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    // Leading: promo.imageUrl != null && promo.imageUrl!.isNotEmpty
                    //     ? Image.network(promo.imageUrl!, width: 80, height: 80, fit: BoxFit.cover,
                    //         errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 60))
                    //     : const Icon(Icons.store, size: 60), // Placeholder if no image
                    title: Text(promo.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(promo.description),
                        const SizedBox(height: 4),
                        if (promo.merchantName != null) Text('Merchant: ${promo.merchantName}'),
                        if (promo.discount != null) Text('Discount: ${promo.discount}'),
                        if (promo.code != null) Text('Code: ${promo.code}'),
                        // Basic date display, can be formatted better
                        if (promo.endDate != null)
                           Text('Expires: ${promo.endDate!.toLocal().toString().split(' ')[0]}'),
                      ],
                    ),
                    isThreeLine: true, // Adjust based on content
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
