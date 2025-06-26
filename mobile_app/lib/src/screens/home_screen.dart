import 'package:flutter/material.dart';
import '../widgets/deal_card_shimmer.dart'; // Import the DealCardShimmer
// import 'package:flutter/material.dart'; // Duplicate import removed
import '../models/category.dart'; // Import the category model and predefined list
import '../models/promotion.dart'; // Import the promotion model
import '../services/api_service.dart'; // Import the API service
import '../widgets/deal_card.dart'; // Import the DealCard widget
import 'deal_detail_screen.dart'; // Import DealDetailScreen for navigation
import 'deals_list_screen.dart'; // Import DealsListScreen for "View All"

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Promotion>> _featuredDealsFuture;
  late Future<List<Promotion>> _nearbyDealsPreviewFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _featuredDealsFuture = _fetchFeaturedDeals();
    _nearbyDealsPreviewFuture = _fetchNearbyDealsPreview();
  }

  Future<List<Promotion>> _fetchFeaturedDeals() async {
    // For now, fetch all promotions and take the first 3-5 as "featured"
    // In a real app, this might be a separate API endpoint: /api/promotions/featured
    try {
      final allPromotions = await _apiService.fetchPromotions();
      // Ensure we don't try to take more items than available
      return allPromotions.take(5).toList();
    } catch (e) {
      // Handle error, e.g., return empty list or rethrow
      print('Error fetching featured deals: $e');
      return [];
    }
  }

  Future<List<Promotion>> _fetchNearbyDealsPreview() async {
    // Fetch all promotions and take a small number for preview (e.g., 3)
    // This assumes no specific "nearby" logic yet, just a general preview.
    // If location services were active, this would fetch based on location.
    try {
      final allPromotions = await _apiService.fetchPromotions();
      // Shuffling to make it seem more dynamic, or take from a different part of the list
      // For now, just taking a different slice.
      if (allPromotions.length > 8) { // ensure there are enough deals
        return allPromotions.skip(5).take(3).toList();
      } else if (allPromotions.length > 5) {
         return allPromotions.skip(5).toList();
      }
      // If fewer than 5 deals, featured might show all, so nearby preview might be empty or repeat.
      // A more robust solution would be needed for small datasets or actual location filtering.
      return [];
    } catch (e) {
      print('Error fetching nearby deals preview: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DealFinder'), // Or a logo
        // actions: [ // Potential actions like notifications or profile
        //   IconButton(
        //     icon: const Icon(Icons.notifications_none),
        //     onPressed: () {},
        //   ),
        //   IconButton(
        //     icon: const Icon(Icons.account_circle),
        //     onPressed: () {},
        //   ),
        // ],
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          // --- Search Bar Placeholder ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search deals, categories, merchants...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                onTap: () {
                  // Placeholder: Navigate to a dedicated search screen or show overlay
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search bar tapped! Full search page TBD.')),
                  );
                },
                readOnly: true, // Make it readOnly if onTap is used for navigation
              ),
            ),
          ),

          // --- Categories Section ---
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 10.0, bottom:10.0, left: 0, right: 0), // Adjusted padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Categories',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 90, // Height for category items
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: predefinedCategories.length,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0), // Padding for the list itself
                      itemBuilder: (context, index) {
                        final category = predefinedCategories[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0), // Spacing between items
                          child: InkWell(
                            onTap: () {
                              // Navigate to DealsListScreen, passing category info for filtering (TBD)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DealsListScreen(categoryFilter: category), // Assuming DealsListScreen can handle a category filter
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Tapped on ${category.name}. Filtered list TBD.')),
                              );
                            },
                            borderRadius: BorderRadius.circular(12.0),
                            child: Container(
                              width: 80, // Width of each category item
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12.0),
                                // border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5))
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Icon placeholder - In a real app, you'd use SVG or Image.asset
                                  Icon(
                                    _getIconForCategory(category.id), // Helper to get an icon
                                    size: 30,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    category.name,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Featured Deals Carousel Placeholder ---
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Featured Deals',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<Promotion>>(
                    future: _featuredDealsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildFeaturedDealsShimmer(); // Shimmer for featured deals
                      } else if (snapshot.hasError) {
                        return Container(
                          height: 220,
                          child: Center(child: Text('Could not load featured deals.', style: TextStyle(color: Colors.red[400]))),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Container(
                          height: 220,
                          child: Center(child: Text('No featured deals available.', style: TextStyle(color: Colors.grey[600]))),
                        );
                      }
                      final featuredDeals = snapshot.data!;
                      return Container(
                        height: 270, // Adjusted height for larger cards with some vertical padding
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: featuredDeals.length,
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          itemBuilder: (context, index) {
                            final promotion = featuredDeals[index];
                            return Container(
                              width: MediaQuery.of(context).size.width * 0.75, // Card width
                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DealDetailScreen(promotion: promotion),
                                    ),
                                  );
                                },
                                child: DealCard(
                                  promotion: promotion,
                                  // Optional: Add a flag or different styling for featured cards if needed
                                  // isFeatured: true,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // --- Nearby Deals Preview Section Title ---
           SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nearby Deals',
                     style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DealsListScreen()),
                      );
                    },
                    child: const Text('View All'),
                  )
                ],
              ),
            ),
          ),

          // --- Nearby Deals List ---
          FutureBuilder<List<Promotion>>(
            future: _nearbyDealsPreviewFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Show a limited number of shimmer cards for the preview
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const DealCardShimmer(),
                    childCount: 2, // Show 2 shimmer cards for preview
                  ),
                );
              } else if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: Text('Could not load nearby deals.', style: TextStyle(color: Colors.red[400]))),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: Text('No other deals available currently.', style: TextStyle(color: Colors.grey[600]))),
                  ),
                );
              }
              final nearbyDeals = snapshot.data!;
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final promotion = nearbyDeals[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DealDetailScreen(promotion: promotion),
                          ),
                        );
                      },
                      child: DealCard(promotion: promotion),
                    );
                  },
                  childCount: nearbyDeals.length,
                ),
              );
            },
          ),

          // Add some bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          )
        ],
      ),
    );
  }

  // Helper function to map category IDs to Material Icons (placeholder)
  // In a real app, you might use SVGs from local assets or network URLs as defined in Category model
  IconData _getIconForCategory(String categoryId) {
    switch (categoryId) {
      case 'food_bev':
        return Icons.fastfood_outlined;
      case 'electronics':
        return Icons.devices_other_outlined;
      case 'fashion':
        return Icons.checkroom_outlined;
      case 'travel':
        return Icons.flight_takeoff_outlined;
      case 'home_garden':
        return Icons.home_outlined;
      case 'beauty_health':
        return Icons.spa_outlined;
      case 'entertainment':
        return Icons.sports_esports_outlined;
      case 'services':
        return Icons.miscellaneous_services_outlined;
      case 'other':
        return Icons.category_outlined;
      default:
        return Icons.label_important_outline;
    }
  }

  // Shimmer placeholder for Featured Deals section
  Widget _buildFeaturedDealsShimmer() {
    return Container(
      height: 270,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3, // Show 3 shimmer cards
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemBuilder: (context, index) {
          return Container(
            width: MediaQuery.of(context).size.width * 0.75,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: const DealCardShimmer(), // Reuse the existing DealCardShimmer
          );
        },
      ),
    );
  }
}
