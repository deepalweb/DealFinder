import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/promotion.dart';
import '../widgets/deal_card.dart'; // Import the new DealCard widget
import '../widgets/deal_card_shimmer.dart'; // Import the shimmer widget
import '../models/category.dart'; // Import Category model
import 'deal_detail_screen.dart'; // Import DealDetailScreen for navigation
import 'search_screen.dart'; // Import SearchScreen for navigation


class DealsListScreen extends StatefulWidget {
  final Category? categoryFilter; // Optional category to filter by

  const DealsListScreen({super.key, this.categoryFilter});

  @override
  State<DealsListScreen> createState() => _DealsListScreenState();
}

class _DealsListScreenState extends State<DealsListScreen> {
  late Future<List<Promotion>> _promotionsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _refreshPromotions();
  }

  Future<void> _refreshPromotions() async {
    setState(() {
      _promotionsFuture = _apiService.fetchPromotions();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine the AppBar title based on whether a category filter is active
    final appBarTitle = widget.categoryFilter != null
        ? 'Deals: ${widget.categoryFilter!.name}'
        : 'All Deals & Promotions';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Deals',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Deals',
            onPressed: () {
              // Placeholder for filter functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter functionality coming soon!')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPromotions,
        child: FutureBuilder<List<Promotion>>(
          future: _promotionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              // Initial loading state (before first data arrives)
              // Use the shimmer effect
              return buildDealsListShimmer();
            } else if (snapshot.hasError) {
              // Error state
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[400], size: 50),
                      const SizedBox(height: 10),
                      Text(
                        'Failed to load deals: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        onPressed: _refreshPromotions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    ],
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // Empty state (no deals found)
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sentiment_dissatisfied, color: Colors.grey[600], size: 50),
                      const SizedBox(height: 10),
                      Text(
                        'No deals found at the moment.',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Pull down to refresh or check back later!',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              // Data loaded successfully
              List<Promotion> promotions = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0), // Add some padding for the list
                itemCount: promotions.length,
                itemBuilder: (context, index) {
                  Promotion promo = promotions[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DealDetailScreen(promotion: promo),
                        ),
                      );
                    },
                    child: DealCard(promotion: promo),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
