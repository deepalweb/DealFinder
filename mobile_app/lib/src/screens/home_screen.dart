import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/deal_card_shimmer.dart';
import '../models/category.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/notification_alert_service.dart';
import '../widgets/deal_card.dart';
import 'deal_detail_screen.dart';
import 'deals_list_screen.dart';
import 'advanced_search_screen.dart';
import 'notifications_screen.dart';
import 'qr_scanner_screen.dart';
import 'nearby_deals_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToFavorites;
  const HomeScreen({super.key, this.onNavigateToFavorites});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Promotion>> _featuredDealsFuture;
  late Future<List<Promotion>> _nearbyDealsPreviewFuture;
  late Future<List<Promotion>> _trendingDealsFuture;
  final ApiService _apiService = ApiService();
  String? _profilePicture;
  String _userName = 'User';
  String _userId = '';
  String _token = '';
  int _notificationCount = 0;
  int _dealsCount = 0;
  int _merchantsCount = 0;

  @override
  void initState() {
    super.initState();
    _featuredDealsFuture = _fetchFeaturedDeals();
    _nearbyDealsPreviewFuture = _fetchNearbyDealsPreview();
    _trendingDealsFuture = _fetchTrendingDeals();
    _loadUserData();
    _checkAlerts();
    _loadStats();
  }

  Future<void> _checkAlerts() async {
    await NotificationAlertService.checkAndSendAlerts();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profilePicture = prefs.getString('userProfilePicture');
      _userName = prefs.getString('userName') ?? 'User';
      _userId = prefs.getString('userId') ?? '';
      _token = prefs.getString('token') ?? '';
    });
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    if (_userId.isEmpty || _token.isEmpty) return;
    try {
      final notifications = await ApiService().fetchNotifications(_userId, _token);
      if (mounted) setState(() => _notificationCount = notifications.length);
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _apiService.fetchStats();
      if (mounted) {
        setState(() {
          _dealsCount = stats['deals'] ?? 0;
          _merchantsCount = stats['merchants'] ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<List<Promotion>> _fetchTrendingDeals() async {
    final allPromotions = await _apiService.fetchPromotions();
    final sorted = [...allPromotions]
      ..sort((a, b) => b.ratingsCount.compareTo(a.ratingsCount));
    return sorted.take(5).toList();
  }

  Future<List<Promotion>> _fetchFeaturedDeals() async {
    try {
      final allPromotions = await _apiService.fetchPromotions();
      final featuredDeals = allPromotions.where((p) => p.featured == true).toList();
      if (featuredDeals.isNotEmpty) return featuredDeals.take(5).toList();
      return allPromotions.take(5).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Promotion>> _fetchNearbyDealsPreview() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        final nearbyDeals = await _apiService.fetchNearbyPromotions(
          position.latitude,
          position.longitude,
          radiusKm: 50,
        );
        return nearbyDeals.take(3).toList();
      }
      final allPromotions = await _apiService.fetchPromotions();
      return allPromotions.skip(5).take(3).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DealFinder'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(userId: _userId, token: _token),
                    ),
                  );
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                    child: Text(
                      '$_notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          // Welcome section
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search bar
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

          // Category chips
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
                    label: Text(category.name, style: const TextStyle(fontSize: 13)),
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DealsListScreen(categoryFilter: category)),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Featured Deals
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
                        return SizedBox(
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
                                  onPressed: () => setState(() => _featuredDealsFuture = _fetchFeaturedDeals()),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return SizedBox(
                          height: 220,
                          child: Center(child: Text('No featured deals available.', style: TextStyle(color: Colors.grey[600]))),
                        );
                      }
                      final featuredDeals = snapshot.data!;
                      return SizedBox(
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
                                        MaterialPageRoute(builder: (context) => DealDetailScreen(promotion: promotion)),
                                      );
                                    },
                                    child: DealCard(promotion: promotion),
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
                                              style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 12),
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

          // Nearby Deals header
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

          // Nearby Deals list
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
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: Text('Could not load nearby deals.', style: TextStyle(color: Colors.red[400]))),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
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
                          MaterialPageRoute(builder: (context) => DealDetailScreen(promotion: promotion)),
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

          // Quick Actions
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
                        const SnackBar(content: Text('Coupons coming soon!')),
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
                    onTap: () => widget.onNavigateToFavorites?.call(),
                  ),
                ],
              ),
            ),
          ),

          // Trending Now
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
                    future: _trendingDealsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildFeaturedDealsShimmer();
                      } else if (snapshot.hasError) {
                        return SizedBox(
                          height: 120,
                          child: Center(child: Text('Could not load trending deals.', style: TextStyle(color: Colors.red[400]))),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return SizedBox(
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
                                    MaterialPageRoute(builder: (context) => DealDetailScreen(promotion: promotion)),
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

          // Stats
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
                      _StatPreview(icon: Icons.local_offer, label: 'Deals', value: '$_dealsCount+'),
                      _StatPreview(icon: Icons.store, label: 'Merchants', value: '$_merchantsCount+'),
                      const _StatPreview(icon: Icons.people, label: 'Users', value: '2k+'),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Footer
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 18,
                    children: [
                      TextButton(onPressed: () {}, child: const Text('Privacy Policy')),
                      TextButton(onPressed: () {}, child: const Text('About')),
                      TextButton(onPressed: () {}, child: const Text('Contact')),
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

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String categoryId) {
    switch (categoryId) {
      case 'food_bev': return Icons.fastfood_outlined;
      case 'electronics': return Icons.devices_other_outlined;
      case 'fashion': return Icons.checkroom_outlined;
      case 'travel': return Icons.flight_takeoff_outlined;
      case 'home_garden': return Icons.home_outlined;
      case 'beauty_health': return Icons.spa_outlined;
      case 'entertainment': return Icons.sports_esports_outlined;
      case 'services': return Icons.miscellaneous_services_outlined;
      case 'other': return Icons.category_outlined;
      default: return Icons.label_important_outline;
    }
  }

  Widget _buildFeaturedDealsShimmer() {
    return SizedBox(
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
