import 'package:flutter/material.dart';
import '../widgets/deal_card_shimmer.dart'; // Import the DealCardShimmer
import '../models/category.dart'; // Import the category model and predefined list
import '../models/promotion.dart'; // Import the promotion model
import '../services/api_service.dart'; // Import the API service
import '../widgets/deal_card.dart'; // Import the DealCard widget
import 'deal_detail_screen.dart'; // Import DealDetailScreen for navigation
import 'deals_list_screen.dart'; // Import DealsListScreen for "View All"
import 'search_screen.dart';
import 'notifications_screen.dart'; // Import NotificationsScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Promotion>> _allPromotionsFuture;
  late Future<List<BannerItem>> _bannersFuture;
  late Future<List<MerchantItem>> _popularMerchantsFuture;
  late Future<List<Promotion>> _latestDealsFuture;
  final ApiService _apiService = ApiService();
  String? _userName;
  int _unreadNotifications = 0;
  int _selectedFilterChip = 0;
  final List<String> _filterChipLabels = [
    'All', 'Food', 'Electronics', 'Fashion', 'Nearby', 'Trending'
  ];
  final List<String> _allCategories = [
    'All', 'Food', 'Electronics', 'Fashion', 'Nearby', 'Trending', 'Health', 'Beauty', 'Travel', 'Sports', 'Toys', 'Books', 'Home', 'Pets', 'Automotive', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _allPromotionsFuture = _fetchAllPromotions();
    _bannersFuture = _fetchBanners();
    _popularMerchantsFuture = _fetchPopularMerchants();
    _latestDealsFuture = _apiService.fetchPromotions().then((list) => list.take(5).toList());
    _fetchUserName();
    _fetchUnreadNotifications();
  }

  Future<List<Promotion>> _fetchAllPromotions() async {
    try {
      return await _apiService.fetchPromotions();
    } catch (e) {
      print('Error fetching all promotions: $e');
      return [];
    }
  }

  Future<List<BannerItem>> _fetchBanners() async {
    try {
      // TODO: Replace with real API call
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        BannerItem(imageUrl: 'https://via.placeholder.com/400x120?text=Summer+Sale', title: 'Summer Sale'),
        BannerItem(imageUrl: 'https://via.placeholder.com/400x120?text=Flash+Deals', title: 'Flash Deals'),
        BannerItem(imageUrl: 'https://via.placeholder.com/400x120?text=New+Arrivals', title: 'New Arrivals'),
      ];
    } catch (e) {
      print('Error fetching banners: $e');
      return [];
    }
  }

  Future<List<MerchantItem>> _fetchPopularMerchants() async {
    try {
      // TODO: Replace with real API call
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        MerchantItem(name: 'SuperMart', logoUrl: 'https://via.placeholder.com/60?text=S'),
        MerchantItem(name: 'TechZone', logoUrl: 'https://via.placeholder.com/60?text=T'),
        MerchantItem(name: 'FashionHub', logoUrl: 'https://via.placeholder.com/60?text=F'),
        MerchantItem(name: 'Foodies', logoUrl: 'https://via.placeholder.com/60?text=Fo'),
        MerchantItem(name: 'HomeStyle', logoUrl: 'https://via.placeholder.com/60?text=H'),
      ];
    } catch (e) {
      print('Error fetching merchants: $e');
      return [];
    }
  }

  void _fetchUserName() async {
    // TODO: Replace with real user fetching logic
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _userName = 'Alex'; // Placeholder
    });
  }

  void _fetchUnreadNotifications() async {
    // TODO: Replace with real API call
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _unreadNotifications = 3; // Placeholder
    });
  }

  // --- Personalized greeting helper ---
  String _getPersonalizedGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 18) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }
    return _userName != null ? '$greeting, $_userName!' : '$greeting!';
  }

  // --- Location-based message helper ---
  String _getLocationBasedMessage() {
    // TODO: Replace with real location/city if available
    String city = 'Colombo'; // Placeholder
    final hour = DateTime.now().hour;
    if (hour >= 17 && hour <= 21) {
      return 'Hot dinner deals await in $city!';
    } else if (hour >= 11 && hour <= 14) {
      return 'Lunch specials near you in $city!';
    } else {
      return 'Find the best deals and save more today.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.percent, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('DealFinder'),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined),
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => NotificationsScreen(userId: 'userId', token: 'token')),
                  );
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_unreadNotifications',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          // --- Welcome Header ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (context) => _ProfileOverviewSheet(userName: _userName ?? 'User'),
                          );
                        },
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Icon(Icons.person, color: Colors.white, size: 32),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPersonalizedGreeting(),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getLocationBasedMessage(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.local_offer_outlined, color: Theme.of(context).colorScheme.primary, size: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- Featured Banner/Carousel ---
          SliverToBoxAdapter(
            child: _FeaturedBannerCarousel(bannersFuture: _bannersFuture),
          ),

          // --- Quick Links Row ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _QuickLinkButton(icon: Icons.favorite, label: 'Favorites', onTap: () => Navigator.pushNamed(context, '/favorites')),
                  _QuickLinkButton(
                    icon: Icons.star,
                    label: 'Top Picks',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DealsListScreen(categoryFilter: Category(id: 'top_picks', name: 'Top Picks')),
                        ),
                      );
                    },
                  ),
                  _QuickLinkButton(
                    icon: Icons.store,
                    label: 'Merchants',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DealsListScreen(categoryFilter: Category(id: 'merchants', name: 'Merchants')),
                        ),
                      );
                    },
                  ),
                  _QuickLinkButton(
                    icon: Icons.trending_up,
                    label: 'Trending',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DealsListScreen(categoryFilter: Category(id: 'trending', name: 'Trending')),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // --- Search Bar ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: GestureDetector(
                onTap: () {
                  // TODO: Implement search navigation
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen()));
                },
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(Icons.search, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text('Search deals, stores, categories...', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- Sticky Filter Chips ---
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterChipsHeaderDelegate(
              filterChipLabels: _filterChipLabels,
              allCategories: _allCategories,
              selectedFilterChip: _selectedFilterChip,
              onChipSelected: (index) {
                setState(() {
                  _selectedFilterChip = index;
                });
                // TODO: Implement actual filtering logic
              },
              onMoreTap: () async {
                final selected = await showModalBottomSheet<int>(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) {
                    return ListView.builder(
                      itemCount: _allCategories.length,
                      itemBuilder: (context, idx) => ListTile(
                        title: Text(_allCategories[idx]),
                        selected: _selectedFilterChip == idx,
                        onTap: () => Navigator.pop(context, idx),
                      ),
                    );
                  },
                );
                if (selected != null) {
                  setState(() {
                    _selectedFilterChip = selected;
                  });
                  // TODO: Implement actual filtering logic
                }
              },
            ),
          ),

          // --- Latest Deals Horizontal Section ---
          SliverToBoxAdapter(
            child: FutureBuilder<List<Promotion>>(
              future: _latestDealsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                final latestDeals = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('Latest Deals', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        itemCount: latestDeals.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final promotion = latestDeals[index];
                          return SizedBox(
                            width: 260,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DealDetailScreen(promotion: promotion),
                                  ),
                                );
                              },
                              child: DealCard(promotion: promotion),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // --- Popular Merchants Section Header ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Popular Merchants',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // --- Popular Merchants ---
          SliverToBoxAdapter(
            child: _PopularMerchantsRow(merchantsFuture: _popularMerchantsFuture),
          ),

          // --- Recommended for You Section ---
          SliverToBoxAdapter(
            child: RecommendedForYouSection(
              recommendationsFuture: _allPromotionsFuture.then((list) => list.take(5).toList()),
            ),
          ),

          // --- Section Divider ---
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Divider(thickness: 1.2),
            ),
          ),

          // --- Latest Deals List (vertical, previous design) ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('Latest Deals', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          FutureBuilder<List<Promotion>>(
            future: _allPromotionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const DealCardShimmer(),
                    childCount: 4,
                  ),
                );
              } else if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: Text('Could not load deals.', style: TextStyle(color: Colors.red[400]))),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: Text('No deals available currently.', style: TextStyle(color: Colors.grey[600]))),
                  ),
                );
              }
              // Filtering logic for filter chips
              List<Promotion> filteredPromotions = snapshot.data!;
              if (_selectedFilterChip != 0) {
                final label = _filterChipLabels[_selectedFilterChip].toLowerCase();
                filteredPromotions = filteredPromotions.where((p) => p.category?.toLowerCase().contains(label) ?? false).toList();
              }
              final sortedPromotions = List<Promotion>.from(filteredPromotions)
                ..sort((a, b) => b.startDate?.compareTo(a.startDate ?? DateTime(1970)) ?? 0);
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final promotion = sortedPromotions[index];
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
                  childCount: sortedPromotions.length,
                ),
              );
            },
          ),

          // --- Recommended for You Horizontal Section ---
          SliverToBoxAdapter(
            child: FutureBuilder<List<Promotion>>(
              future: _allPromotionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => Container(
                        width: 260,
                        margin: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recommended for You', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('We’ll show you recommendations soon!', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }
                // Example: take top 5 deals as recommendations (replace with real logic if available)
                final recommended = snapshot.data!.take(5).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Recommended for You', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('Based on your interests', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                            ],
                          ),
                          // Optionally add a "Why?" info icon
                          Tooltip(
                            message: 'Recommendations are based on your interests and activity.',
                            child: Icon(Icons.info_outline, color: Colors.grey[500], size: 20),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        itemCount: recommended.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final promotion = recommended[index];
                          return Dismissible(
                            key: ValueKey(promotion.id),
                            direction: DismissDirection.horizontal,
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 24),
                              color: Colors.green[400],
                              child: const Icon(Icons.favorite, color: Colors.white, size: 32),
                            ),
                            secondaryBackground: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              color: Colors.red[400],
                              child: const Icon(Icons.hide_source, color: Colors.white, size: 32),
                            ),
                            onDismissed: (direction) {
                              // TODO: Implement save/hide logic
                              if (direction == DismissDirection.startToEnd) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to favorites')));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hidden from recommendations')));
                              }
                            },
                            child: SizedBox(
                              width: 260,
                              child: DealCard(
                                promotion: promotion,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Add some bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          )
        ],
      ),
    );
  }
}

// --- BannerItem and MerchantItem models ---
class BannerItem {
  final String imageUrl;
  final String title;
  BannerItem({required this.imageUrl, required this.title});
}

class MerchantItem {
  final String name;
  final String logoUrl;
  MerchantItem({required this.name, required this.logoUrl});
}

// --- Featured Banner Carousel Widget ---
class _FeaturedBannerCarousel extends StatefulWidget {
  final Future<List<BannerItem>> bannersFuture;
  const _FeaturedBannerCarousel({Key? key, required this.bannersFuture}) : super(key: key);

  @override
  State<_FeaturedBannerCarousel> createState() => _FeaturedBannerCarouselState();
}

class _FeaturedBannerCarouselState extends State<_FeaturedBannerCarousel> {
  int _currentPage = 0;
  PageController? _pageController;
  bool _userInteracting = false;
  List<BannerItem> _banners = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _loadBanners();
    _startAutoScroll();
  }

  void _loadBanners() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final banners = await widget.bannersFuture;
      setState(() {
        _banners = banners;
        _loading = false;
        _error = banners.isEmpty;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 6), () {
      if (!mounted || _userInteracting || _banners.length <= 1) return;
      int nextPage = (_currentPage + 1) % _banners.length;
      _pageController?.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage = nextPage;
      });
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 2,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => Container(
              width: 340,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      );
    } else if (_error) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: SizedBox(
          height: 120,
          child: Center(child: Text('No banners available', style: TextStyle(color: Colors.grey[600]))),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: GestureDetector(
              onPanDown: (_) => setState(() => _userInteracting = true),
              onPanCancel: () => setState(() => _userInteracting = false),
              onPanEnd: (_) => setState(() => _userInteracting = false),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _banners.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final banner = _banners[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        // TODO: Implement navigation or action for banner CTA
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Shop Now: \\${banner.title}')),
                        );
                      },
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              banner.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 120,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[300],
                                  width: double.infinity,
                                  height: 120,
                                  child: const Center(child: CircularProgressIndicator()),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[300],
                                width: double.infinity,
                                height: 120,
                                child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            bottom: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    banner.title,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Shop Now',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[400],
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }),
          ),
        ],
      );
  }
}

// --- Popular Merchants Row Widget ---
class _PopularMerchantsRow extends StatelessWidget {
  final Future<List<MerchantItem>> merchantsFuture;
  const _PopularMerchantsRow({Key? key, required this.merchantsFuture}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MerchantItem>>(
      future: merchantsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => Column(
                children: [
                  CircleAvatar(radius: 28, backgroundColor: Colors.grey[300]),
                  const SizedBox(height: 6),
                  Container(width: 60, height: 10, color: Colors.grey[300]),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            height: 90,
            child: Center(child: Text('No merchants available', style: TextStyle(color: Colors.grey[600]))),
          );
        }
        final merchants = snapshot.data!;
        return SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: merchants.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final merchant = merchants[index];
              return Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(merchant.logoUrl),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    merchant.name,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// --- Quick Link Button Widget ---
class _QuickLinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickLinkButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// --- Profile Overview Sheet Widget ---
class _ProfileOverviewSheet extends StatelessWidget {
  final String userName;
  const _ProfileOverviewSheet({required this.userName});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 28, child: Icon(Icons.person, size: 32)),
              const SizedBox(width: 16),
              Text(userName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // TODO: Navigate to settings
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () {
              // TODO: Implement sign out
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// --- Sticky Filter Chips Delegate ---
class _FilterChipsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> filterChipLabels;
  final List<String> allCategories;
  final int selectedFilterChip;
  final ValueChanged<int> onChipSelected;
  final VoidCallback onMoreTap;
  _FilterChipsHeaderDelegate({
    required this.filterChipLabels,
    required this.allCategories,
    required this.selectedFilterChip,
    required this.onChipSelected,
    required this.onMoreTap,
  });
  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final visibleChips = filterChipLabels.length > 5 ? filterChipLabels.sublist(0, 5) : filterChipLabels;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...List.generate(visibleChips.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(visibleChips[index]),
                  selected: selectedFilterChip == index,
                  onSelected: (_) => onChipSelected(index),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: selectedFilterChip == index ? Colors.white : Colors.black,
                    fontWeight: selectedFilterChip == index ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: selectedFilterChip == index ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
                      width: selectedFilterChip == index ? 2 : 1,
                    ),
                  ),
                  backgroundColor: Colors.grey[100],
                ),
              );
            }),
            if (filterChipLabels.length > 5)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: const Text('More'),
                  selected: false,
                  onSelected: (_) => onMoreTap(),
                  backgroundColor: Colors.grey[200],
                ),
              ),
          ],
        ),
      ),
    );
  }
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

// --- Recommended for You Section Widget ---
class RecommendedForYouSection extends StatelessWidget {
  final Future<List<Promotion>> recommendationsFuture;
  const RecommendedForYouSection({Key? key, required this.recommendationsFuture}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Promotion>>(
      future: recommendationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 2,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => Container(
                width: 260,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(child: Text('Could not load recommendations.', style: TextStyle(color: Colors.red[400]))),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Recommended for You', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('We\'ll show you recommendations soon!', style: TextStyle(color: Colors.grey[600])),
                ),
              ],
            ),
          );
        }
        final recommendations = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Text('Recommended for You', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Icon(Icons.info_outline, color: Colors.blueGrey[400], size: 18),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Text(
                'Based on your interests and recent activity',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: recommendations.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final promotion = recommendations[index];
                  return Dismissible(
                    key: ValueKey(promotion.id),
                    direction: DismissDirection.horizontal,
                    background: _buildSwipeAction(context, Icons.bookmark, 'Save', Colors.green),
                    secondaryBackground: _buildSwipeAction(context, Icons.hide_source, 'Hide', Colors.red),
                    onDismissed: (direction) {
                      // TODO: Implement save/hide logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(direction == DismissDirection.startToEnd ? 'Saved!' : 'Hidden!'),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 260,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DealDetailScreen(promotion: promotion),
                            ),
                          );
                        },
                        child: DealCard(promotion: promotion),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSwipeAction(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      alignment: icon == Icons.bookmark ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: color.withOpacity(0.15),
      child: Row(
        mainAxisAlignment: icon == Icons.bookmark ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
