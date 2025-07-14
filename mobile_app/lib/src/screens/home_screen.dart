import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/deal_card_shimmer.dart';
import '../models/category.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/recommendation_service.dart';
import '../services/deal_history_service.dart';
import '../services/notification_alert_service.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/deal_card.dart';
import 'deal_detail_screen.dart';
import 'deals_list_screen.dart';
import 'search_screen.dart';
import 'advanced_search_screen.dart';
import 'notifications_screen.dart';
import 'qr_scanner_screen.dart';
import 'debug_screen.dart';
import 'nearby_deals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Promotion>> _featuredDealsFuture;
  late Future<List<Promotion>> _nearbyDealsPreviewFuture;
  late Future<List<Promotion>> _recommendationsFuture;
  final ApiService _apiService = ApiService();
  String? _profilePicture;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _featuredDealsFuture = _fetchFeaturedDeals();
    _nearbyDealsPreviewFuture = _fetchNearbyDealsPreview();
    _recommendationsFuture = RecommendationService.getRecommendations();
    _loadUserData();
    _checkAlerts();
  }
  
  Future<void> _checkAlerts() async {
    await NotificationAlertService.checkAndSendAlerts();
  }
  
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profilePicture = prefs.getString('userProfilePicture');
      _userName = prefs.getString('userName') ?? 'User';
    });
  }

  Future<List<Promotion>> _fetchFeaturedDeals() async {
    try {
      print('🔄 Fetching promotions from API...');
      final allPromotions = await _apiService.fetchPromotions();
      print('✅ Successfully fetched ${allPromotions.length} promotions');
      
      final featuredDeals = allPromotions.where((p) => p.featured == true).toList();
      print('🌟 Found ${featuredDeals.length} featured deals');
      
      if (featuredDeals.isNotEmpty) {
        return featuredDeals.take(5).toList();
      }
      // If no featured deals, return first 5 deals
      final firstFive = allPromotions.take(5).toList();
      print('📋 Returning first ${firstFive.length} deals as featured');
      return firstFive;
    } catch (e) {
      print('❌ Error fetching featured deals: $e');
      rethrow; // Let the UI handle the error
    }
  }

  Future<List<Promotion>> _fetchNearbyDealsPreview() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        final nearbyDeals = await _apiService.fetchNearbyPromotions(
          position.latitude, 
          position.longitude,
          radiusKm: 5,
        );
        return nearbyDeals.take(3).toList();
      }
      
      // Fallback to regular promotions
      final allPromotions = await _apiService.fetchPromotions();
      return allPromotions.skip(5).take(3).toList();
    } catch (e) {
      print('Error fetching nearby deals preview: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DealFinder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DebugScreen()),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen(userId: 'user123', token: 'token123')),
                  );
                },
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: FutureBuilder<int>(
                    future: _getNotificationCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    backgroundImage: _profilePicture != null 
                        ? MemoryImage(base64Decode(_profilePicture!.split(',')[1]))
                        : null,
                    child: _profilePicture == null
                        ? Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 28)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, $_userName!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Find the best deals for you',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

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
                    MaterialPageRoute(builder: (context) => const AdvancedSearchScreen()),
                  );
                },
                readOnly: true,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              height: 48,
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: predefinedCategories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = predefinedCategories[index];
                  return ActionChip(
                    avatar: Icon(_getIconForCategory(category.id), size: 18, color: Theme.of(context).colorScheme.primary),
                    label: Text(category.name, style: TextStyle(fontSize: 13)),
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DealsListScreen(categoryFilter: category),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 10.0, bottom:10.0, left: 0, right: 0),
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
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: predefinedCategories.length,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      itemBuilder: (context, index) {
                        final category = predefinedCategories[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DealsListScreen(categoryFilter: category),
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Tapped on ${category.name}. Filtered list TBD.')),
                              );
                            },
                            borderRadius: BorderRadius.circular(12.0),
                            child: Container(
                              width: 80,
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getIconForCategory(category.id),
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
                        return _buildFeaturedDealsShimmer();
                      } else if (snapshot.hasError) {
                        return Container(
                          height: 220,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, color: Colors.red[400], size: 48),
                                const SizedBox(height: 8),
                                Text('API Connection Failed', style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('${snapshot.error}', style: TextStyle(color: Colors.red[300], fontSize: 12), textAlign: TextAlign.center),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _featuredDealsFuture = _fetchFeaturedDeals();
                                    });
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Container(
                          height: 220,
                          child: Center(child: Text('No featured deals available.', style: TextStyle(color: Colors.grey[600]))),
                        );
                      }
                      final featuredDeals = snapshot.data!;
                      return Container(
                        height: 270,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: featuredDeals.length,
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          itemBuilder: (context, index) {
                            final promotion = featuredDeals[index];
                            final now = DateTime.now();
                            final end = promotion.endDate;
                            String? countdown;
                            if (end != null) {
                              final diff = end.difference(now);
                              if (diff.inDays >= 1) {
                                countdown = '${diff.inDays}d left';
                              } else if (diff.inHours > 0) {
                                countdown = '${diff.inHours}h left';
                              } else if (diff.inMinutes > 0) {
                                countdown = '${diff.inMinutes}m left';
                              } else {
                                countdown = 'Expired';
                              }
                            }
                            return Container(
                              width: MediaQuery.of(context).size.width * 0.75,
                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Stack(
                                children: [
                                  InkWell(
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
                                    ),
                                  ),
                                  Positioned(
                                    left: 10,
                                    top: 10,
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.white,
                                      backgroundImage: promotion.merchantLogoUrl != null
                                        ? NetworkImage(promotion.merchantLogoUrl!)
                                        : null,
                                      child: promotion.merchantLogoUrl == null
                                        ? Icon(Icons.storefront, color: Colors.grey[400], size: 22)
                                        : null,
                                    ),
                                  ),
                                  if (countdown != null && countdown != 'Expired')
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.timer, size: 14, color: Colors.red[700]),
                                            const SizedBox(width: 4),
                                            Text(
                                              countdown,
                                              style: TextStyle(
                                                color: Colors.red[700],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: IconButton(
                                      icon: const Icon(Icons.share_outlined, size: 22),
                                      tooltip: 'Share Deal',
                                      color: Theme.of(context).colorScheme.primary,
                                      onPressed: () {
                                        final link = 'https://dealfinder.app/deal/${promotion.id}';
                                        Share.share('Check out this deal: ${promotion.title}\n$link');
                                      },
                                    ),
                                  ),
                                ],
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
                        MaterialPageRoute(builder: (context) => const NearbyDealsScreen()),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<List<Promotion>>(
            future: _nearbyDealsPreviewFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const DealCardShimmer(),
                    childCount: 2,
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
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickActionButton(
                    icon: Icons.near_me,
                    label: 'Nearby',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NearbyDealsScreen()),
                      );
                    },
                  ),
                  _QuickActionButton(
                    icon: Icons.card_giftcard,
                    label: 'Coupons',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coupons (to be implemented)')),
                      );
                    },
                  ),
                  _QuickActionButton(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan QR',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const QRScannerScreen()),
                      );
                    },
                  ),
                  _QuickActionButton(
                    icon: Icons.favorite_border,
                    label: 'Favorites',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Favorites (to be implemented)')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Icon(Icons.whatshot, color: Colors.orange[700], size: 26),
                        const SizedBox(width: 8),
                        Text(
                          'Trending Now',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<Promotion>>(
                    future: _featuredDealsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildFeaturedDealsShimmer();
                      } else if (snapshot.hasError) {
                        return Container(
                          height: 120,
                          child: Center(child: Text('Could not load trending deals.', style: TextStyle(color: Colors.red[400]))),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Container(
                          height: 120,
                          child: Center(child: Text('No trending deals available.', style: TextStyle(color: Colors.grey[600]))),
                        );
                      }
                      final trendingDeals = snapshot.data!;
                      return SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: trendingDeals.length,
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          itemBuilder: (context, index) {
                            final promotion = trendingDeals[index];
                            return Container(
                              width: 200,
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
                                child: Card(
                                  color: Colors.orange[50],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.white,
                                          backgroundImage: promotion.merchantLogoUrl != null
                                            ? NetworkImage(promotion.merchantLogoUrl!)
                                            : null,
                                          child: promotion.merchantLogoUrl == null
                                            ? Icon(Icons.storefront, color: Colors.grey[400], size: 22)
                                            : null,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                promotion.title,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                promotion.description,
                                                style: Theme.of(context).textTheme.bodySmall,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const Spacer(),
                                              Row(
                                                children: [
                                                  Icon(Icons.trending_up, color: Colors.orange[700], size: 16),
                                                  const SizedBox(width: 4),
                                                  Text('Hot', style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold, fontSize: 12)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                color: Colors.blueGrey[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatPreview(icon: Icons.local_offer, label: 'Deals', value: '120+'),
                      _StatPreview(icon: Icons.store, label: 'Merchants', value: '30+'),
                      _StatPreview(icon: Icons.people, label: 'Users', value: '2k+'),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 18,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text('Privacy Policy'),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('About'),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Contact'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '© 2025 DealFinder. All rights reserved.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

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

  Future<int> _getNotificationCount() async {
    // In a real app, fetch from API or local storage
    return 3; // Placeholder
  }

  Widget _buildFeaturedDealsShimmer() {
    return Container(
      height: 270,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemBuilder: (context, index) {
          return Container(
            width: MediaQuery.of(context).size.width * 0.75,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: const DealCardShimmer(),
          );
        },
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _StatPreview extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatPreview({required this.icon, required this.label, required this.value, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])),
      ],
    );
  }
}
