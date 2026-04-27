import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/cache_service.dart';
import '../widgets/section_header.dart';
import '../widgets/home_shimmer.dart';
import '../widgets/flash_sale_card.dart';
import '../widgets/modern_deal_card.dart';
import 'deal_detail_screen.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'nearby_deals_screen.dart';
import 'all_deals_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToFavorites;
  
  const HomeScreen({super.key, this.onNavigateToFavorites});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<Promotion> _allDeals = [];
  bool _loading = true;
  bool _isOffline = false;

  String _userName = 'there';
  String _userId = '';
  String _userToken = '';
  int _notificationCount = 0;

  String _locationName = 'Near You';
  Position? _position;

  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadAll();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    // Load user first (needed for token)
    await _loadUser();
    
    // Load location and deals in parallel
    await Future.wait([
      _loadLocation(),
      _loadDeals(),
    ]);
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('userName') ?? 'there';
      _userId = prefs.getString('userId') ?? '';
      _userToken = prefs.getString('userToken') ?? '';
    });
    // Load notification count in background (don't block UI)
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    if (_userId.isEmpty) return;
    try {
      final n = await _api.fetchNotifications(_userId, _userToken);
      if (mounted) setState(() => _notificationCount = n.length);
    } catch (_) {}
  }

  Future<void> _loadLocation() async {
    final pos = await LocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => _position = pos);
    if (pos != null) {
      // Get location name
      final locationName = await LocationService.getLocationName(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() => _locationName = locationName ?? 'Current Location');
      }
      // Fetch nearby deals from backend
      _loadNearbyDeals(pos.latitude, pos.longitude);
    }
  }

  Future<void> _loadNearbyDeals(double lat, double lng) async {
    try {
      final nearbyDeals = await _api.fetchNearbyPromotions(lat, lng, radiusKm: 10);
      if (mounted) {
        setState(() {
          // Update deals with distance information
          for (var deal in nearbyDeals) {
            final index = _allDeals.indexWhere((d) => d.id == deal.id);
            if (index != -1) {
              _allDeals[index] = deal;
            }
          }
        });
      }
    } catch (e) {
      // Silently fail - nearby deals are optional
    }
  }

  Future<void> _loadDeals() async {
    // Show cached data immediately
    final cached = await CacheService.loadPromotions();
    if (cached != null && cached.isNotEmpty && mounted) {
      setState(() {
        _allDeals = cached;
        _loading = false;
      });
    }
    
    // Then fetch fresh data in background
    try {
      final deals = await _api.fetchPromotions(forceRefresh: true);
      if (mounted) {
        setState(() {
          _allDeals = deals;
          _loading = false;
          _isOffline = false;
        });
      }
    } catch (e) {
      // If network fails and we have no cache, show offline
      if (cached == null || cached.isEmpty) {
        if (mounted) {
          setState(() {
            _loading = false;
            _isOffline = true;
          });
        }
      }
    }
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    await _loadDeals();
    await _loadLocation();
    
    if (mounted && !_isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('${_allDeals.length} deals loaded'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    }
  }

  List<Promotion> get _filteredDeals {
    final now = DateTime.now();
    return _allDeals.where((p) =>
      (p.endDate == null || p.endDate!.isAfter(now)) &&
      (_selectedCategory == null || p.category == _selectedCategory)
    ).toList();
  }

  List<Promotion> get _flashSales {
    final now = DateTime.now();
    final cutoff = now.add(const Duration(hours: 24));
    return _filteredDeals
        .where((p) => p.endDate != null && p.endDate!.isBefore(cutoff) && p.endDate!.isAfter(now))
        .toList()
      ..sort((a, b) => a.endDate!.compareTo(b.endDate!));
  }

  List<Promotion> get _nearbyDeals {
    if (_position == null) return [];
    final withDist = _filteredDeals.where((p) => p.distance != null).toList()
      ..sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
    return withDist.take(10).toList();
  }

  List<Promotion> get _featuredDeals {
    return _filteredDeals.where((p) => p.featured == true).take(5).toList();
  }

  List<Promotion> get _newDeals {
    final sorted = [..._filteredDeals]
      ..sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
    return sorted.take(10).toList();
  }

  void _openDeal(Promotion p) => Navigator.push(
    context, MaterialPageRoute(builder: (_) => DealDetailScreen(promotion: p)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: Theme.of(context).colorScheme.primary,
            child: CustomScrollView(
                slivers: [
                  _buildHeader(),
                  _buildGreeting(),
                  _buildSearchBar(),
                  _buildCategories(),
                  if (!_loading && _featuredDeals.isNotEmpty) _buildFeaturedBanner(),
                  if (_isOffline) _buildOfflineBanner(),
                  if (_loading)
                    const SliverToBoxAdapter(child: HomeShimmer())
                  else
                  _buildContent(),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header with logo, location, notifications ────────────────────────────
  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            // App Logo/Branding
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_offer,
                      size: 20,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'DealFinder',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Location
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NearbyDealsScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFFE53935)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _locationName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Notification bell
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 26),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationsScreen(
                        userId: _userId,
                        token: _userToken,
                      ),
                    ),
                  ),
                ),
                if (_notificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _notificationCount > 9 ? '9+' : '$_notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Greeting Section ──────────────────────────────────────────────────────
  Widget _buildGreeting() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $_userName 👋',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Find amazing deals today!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Hero(
          tag: 'search_bar',
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Search deals, stores...',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Featured Banner Carousel ─────────────────────────────────────────────
  Widget _buildFeaturedBanner() {
    return SliverToBoxAdapter(
      child: Container(
        height: 180,
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: PageView.builder(
          itemCount: _featuredDeals.length > 3 ? 3 : _featuredDeals.length,
          itemBuilder: (context, index) {
            final deal = _featuredDeals[index];
            return GestureDetector(
              onTap: () => _openDeal(deal),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Image
                      if (deal.imageDataString != null && deal.imageDataString!.isNotEmpty)
                        Image.network(
                          deal.imageDataString!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primary.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      // Content
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Discount Badge
                            if (deal.discount != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5252),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  deal.discount!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            // Title
                            Text(
                              deal.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Subtitle
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Featured Deal',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Categories ────────────────────────────────────────────────────────────
  Widget _buildCategories() {
    final categories = [null, ...predefinedCategories.map((c) => c.id)];
    final labels = ['All', ...predefinedCategories.map((c) => c.name)];
    final icons = [
      Icons.all_inclusive,
      Icons.fastfood_outlined,
      Icons.devices_other_outlined,
      Icons.checkroom_outlined,
      Icons.flight_takeoff_outlined,
      Icons.home_outlined,
      Icons.spa_outlined,
      Icons.sports_esports_outlined,
      Icons.miscellaneous_services_outlined,
      Icons.category_outlined,
    ];

    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        margin: const EdgeInsets.only(top: 20),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final selected = _selectedCategory == categories[i];
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = categories[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[i],
                      size: 16,
                      color: selected ? Colors.white : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Offline Banner ────────────────────────────────────────────────────────
  Widget _buildOfflineBanner() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange[700], size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Offline — showing cached deals',
                style: TextStyle(color: Colors.orange[800], fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _refresh,
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Content Sections ──────────────────────────────────────────────────────
  Widget _buildContent() {
    if (_filteredDeals.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'No deals found',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Try a different category',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        // Flash Sales Section
        if (_flashSales.isNotEmpty) ...[
          const SectionHeader(
            title: '⚡ Flash Sales',
            subtitle: 'Ending soon - Hurry up!',
            icon: Icons.flash_on,
          ),
          Stack(
            children: [
              SizedBox(
                height: 240,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _flashSales.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => FlashSaleCard(
                    promotion: _flashSales[i],
                    width: 180,
                    onTap: () => _openDeal(_flashSales[i]),
                  ),
                ),
              ),
              // Swipe indicator - right side
              if (_flashSales.length > 2)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],

        // Featured Deals Section
        if (_featuredDeals.isNotEmpty) ...[
          const SizedBox(height: 8),
          const SectionHeader(
            title: '🔥 Hot Deals',
            subtitle: 'Trending now',
            icon: Icons.local_fire_department,
          ),
          Stack(
            children: [
              SizedBox(
                height: 240,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _featuredDeals.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => ModernDealCard(
                    promotion: _featuredDeals[i],
                    width: 170,
                    onTap: () => _openDeal(_featuredDeals[i]),
                  ),
                ),
              ),
              // Swipe indicator - right side
              if (_featuredDeals.length > 2)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],

        // Nearby Deals Section
          if (_nearbyDeals.isNotEmpty) ...[
            const SizedBox(height: 8),
            SectionHeader(
              title: '📍 Near You',
              subtitle: _locationName == 'Near You' ? 'Deals around your location' : 'Deals around $_locationName',
              icon: Icons.location_on,
              onSeeAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NearbyDealsScreen()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.near_me, color: Color(0xFF2E7D32), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Closest deals first',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _nearbyDeals.first.distance != null
                                      ? 'Closest deal is ${( _nearbyDeals.first.distance! < 1000 ? '${_nearbyDeals.first.distance!.round()}m' : '${(_nearbyDeals.first.distance! / 1000).toStringAsFixed(1)}km')} away'
                                      : 'Open the full nearby view for map and directions',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NearbyDealsScreen()),
                      ),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Map'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _nearbyDeals.length > 4 ? 4 : _nearbyDeals.length,
              itemBuilder: (_, i) => ModernDealCard(
                promotion: _nearbyDeals[i],
                onTap: () => _openDeal(_nearbyDeals[i]),
              ),
            ),
          ),
        ] else if (_position == null) ...[
          const SizedBox(height: 8),
          const SectionHeader(
            title: '📍 Near You',
            subtitle: 'Enable location to see nearby deals',
            icon: Icons.location_on,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.location_off, size: 48, color: Colors.blue[700]),
                  const SizedBox(height: 12),
                  Text(
                    'Location Access Required',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Allow location access to discover amazing deals near you',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _loadLocation();
                      if (_position != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Location enabled! Loading nearby deals...'),
                            backgroundColor: Color(0xFF4CAF50),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('Enable Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // New This Week Section
        if (_newDeals.isNotEmpty) ...[
          const SizedBox(height: 8),
          const SectionHeader(
            title: '🆕 New This Week',
            subtitle: 'Fresh deals just added',
            icon: Icons.fiber_new,
          ),
          Stack(
            children: [
              SizedBox(
                height: 240,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _newDeals.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => ModernDealCard(
                    promotion: _newDeals[i],
                    width: 170,
                    onTap: () => _openDeal(_newDeals[i]),
                  ),
                ),
              ),
              // Swipe indicator - right side
              if (_newDeals.length > 2)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],

        // All Deals Section
        const SizedBox(height: 8),
        SectionHeader(
          title: '🎯 All Deals',
          subtitle: '${_filteredDeals.length} deals available',
          icon: Icons.grid_view,
          onSeeAll: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AllDealsScreen()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _filteredDeals.length > 6 ? 6 : _filteredDeals.length,
            itemBuilder: (_, i) => ModernDealCard(
              promotion: _filteredDeals[i],
              onTap: () => _openDeal(_filteredDeals[i]),
            ),
          ),
        ),
        // View All Button
        if (_filteredDeals.length > 6)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllDealsScreen()),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View All ${_filteredDeals.length} Deals',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
      ]),
    );
  }
}
