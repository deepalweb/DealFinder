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
  late Future<List<Promotion>> _allPromotionsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _allPromotionsFuture = _fetchAllPromotions();
  }

  Future<List<Promotion>> _fetchAllPromotions() async {
    try {
      // Optional: Add a print statement here to confirm it's called once.
      // print('Fetching all promotions from API...');
      return await _apiService.fetchPromotions();
    } catch (e) {
      print('Error fetching all promotions: $e');
      // Return an empty list or rethrow based on how you want to handle errors globally
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DealFinder'), // Or a logo
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const UserProfileScreen()),
              );
            },
          ),
          // Potential other actions like notifications
          // IconButton(
          //   icon: const Icon(Icons.notifications_none_outlined),
          //   tooltip: 'Notifications',
          //   onPressed: () {
          //     // TODO: Navigate to Notifications Screen
          //   },
          // ),
        ],
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchScreen()),
                  );
                },
                readOnly: true, // Keep true as tapping just navigates
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
                  SizedBox(
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
                    future: _allPromotionsFuture, // Use the single future
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildFeaturedDealsShimmer(); // Shimmer for featured deals
                      } else if (snapshot.hasError) {
                        return SizedBox(
                          height: 220,
                          child: Center(child: Text('Could not load featured deals.', style: TextStyle(color: Colors.red[400]))),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return SizedBox(
                          height: 220,
                          child: Center(child: Text('No featured deals available.', style: TextStyle(color: Colors.grey[600]))),
                        );
                      }
                      // Sort all promotions by startDate descending (newest first)
                      final sortedPromotions = List<Promotion>.from(snapshot.data!)
                        ..sort((a, b) => b.startDate?.compareTo(a.startDate ?? DateTime(1970)) ?? 0);
                      // Featured: first 10, Latest: rest
                      final featuredDeals = sortedPromotions.take(10).toList();
                      List<Promotion> latestDeals = [];
                      if (sortedPromotions.length > 10) {
                        latestDeals = sortedPromotions.skip(10).toList();
                      } else {
                        latestDeals = sortedPromotions;
                      }

                      if (featuredDeals.isEmpty) {
                        return SizedBox(
                          height: 220,
                          child: Center(child: Text('No featured deals available.', style: TextStyle(color: Colors.grey[600]))),
                        );
                      }

                      return SizedBox(
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
              // Row is no longer needed if "View All" is removed, title can be directly in Padding
              child: Text(
                'Latest Deals', // Renamed from 'Nearby Deals'
                 style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // --- Latest Deals List (previously Nearby Deals) ---
          FutureBuilder<List<Promotion>>(
            future: _allPromotionsFuture, // Use the single future
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Show a limited number of shimmer cards for the preview
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const DealCardShimmer(),
                    childCount: 4, // Show 4 shimmer cards for a better preview of a list of 10
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
              // Sort all promotions by startDate descending (newest first)
              final sortedPromotions = List<Promotion>.from(snapshot.data!)
                ..sort((a, b) => b.startDate?.compareTo(a.startDate ?? DateTime(1970)) ?? 0);
              // Featured: first 10, Latest: rest
              final featuredDeals = sortedPromotions.take(10).toList();
              List<Promotion> latestDeals = [];
              if (sortedPromotions.length > 10) {
                latestDeals = sortedPromotions.skip(10).toList();
              } else {
                latestDeals = sortedPromotions;
              }

              if (latestDeals.isEmpty) {
                 return SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: Text('No other deals available currently.', style: TextStyle(color: Colors.grey[600]))),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final promotion = latestDeals[index];
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
                  childCount: latestDeals.length,
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
    return SizedBox(
      height: 270,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4, // Show 4 shimmer cards for a better preview of a list of 10
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
