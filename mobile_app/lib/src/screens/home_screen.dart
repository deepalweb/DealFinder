import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/category.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/cache_service.dart';
import '../widgets/deal_card_new.dart';
import 'deal_detail_screen.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'user_profile_screen.dart';
import 'nearby_deals_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToFavorites;
  const HomeScreen({super.key, this.onNavigateToFavorites});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _bg = Color(0xFFF8F9FA);
  static const _red = Color(0xFFE53935);
  static const _blue = Color(0xFF1E88E5);

  final ApiService _api = ApiService();
  List<Promotion> _allDeals = [];
  bool _loading = true;
  bool _isOffline = false;

  String _userName = 'there';
  String _userId = '';
  String _userToken = '';
  String? _profilePicture;
  int _notificationCount = 0;

  String _locationName = 'Near You';
  Position? _position;

  String? _selectedCategory;
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadUser(), _loadLocation(), _loadDeals()]);
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('userName') ?? 'there';
      _userId = prefs.getString('userId') ?? '';
      _userToken = prefs.getString('userToken') ?? '';
      _profilePicture = prefs.getString('userProfilePicture');
    });
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
      setState(() => _locationName = '${pos.latitude.toStringAsFixed(2)}°N');
    }
  }

  Future<void> _loadDeals() async {
    try {
      final deals = await _api.fetchPromotions();
      if (mounted) setState(() { _allDeals = deals; _loading = false; _isOffline = false; });
      _startBannerTimer();
    } catch (_) {
      final cached = await CacheService.loadPromotions(forceStale: true);
      if (mounted) setState(() {
        _allDeals = cached ?? [];
        _loading = false;
        _isOffline = true;
      });
      _startBannerTimer();
    }
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    final banners = _bannerDeals;
    if (banners.length < 2) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_bannerController.hasClients) return;
      final next = (_bannerController.page?.round() ?? 0) + 1;
      _bannerController.animateToPage(
        next % banners.length,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await _loadDeals();
    await _loadLocation();
  }

  List<Promotion> get _filteredDeals {
    final now = DateTime.now();
    return _allDeals.where((p) =>
      (p.endDate == null || p.endDate!.isAfter(now)) &&
      (_selectedCategory == null || p.category == _selectedCategory)
    ).toList();
  }

  List<Promotion> get _bannerDeals =>
      _filteredDeals.where((p) => p.featured == true).take(5).toList();

  List<Promotion> get _expiringSoon {
    final now = DateTime.now();
    final cutoff = now.add(const Duration(hours: 48));
    return _filteredDeals
        .where((p) => p.endDate != null && p.endDate!.isBefore(cutoff) && p.endDate!.isAfter(now))
        .toList()
      ..sort((a, b) => a.endDate!.compareTo(b.endDate!));
  }

  List<Promotion> get _nearbyDeals {
    if (_position == null) return [];
    final withDist = _filteredDeals.where((p) => p.distance != null).toList()
      ..sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
    return withDist;
  }

  List<Promotion> get _justAdded {
    final sorted = [..._filteredDeals]
      ..sort((a, b) => (b.startDate ?? DateTime(0)).compareTo(a.startDate ?? DateTime(0)));
    return sorted.take(10).toList();
  }

  void _openDeal(Promotion p) => Navigator.push(
    context, MaterialPageRoute(builder: (_) => DealDetailScreen(promotion: p)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: _blue,
          child: CustomScrollView(
            slivers: [
              _buildHeader(),
              _buildActionZone(),
              _buildCategories(),
              if (_isOffline) _buildOfflineBanner(),
              if (_loading) _buildLoadingShimmer(),
              if (!_loading) ...[
                if (_bannerDeals.isNotEmpty) _buildBannerCarousel(),
                if (_expiringSoon.isNotEmpty) _buildSection(
                  title: '🔥 Expiring Soon',
                  subtitle: 'Grab them before they\'re gone',
                  child: _buildHorizontalScroll(_expiringSoon),
                ),
                if (_nearbyDeals.isNotEmpty) _buildSection(
                  title: '📍 Deals Near You',
                  subtitle: 'Sorted by distance',
                  child: _buildGrid(_nearbyDeals),
                ),
                if (_justAdded.isNotEmpty) _buildSection(
                  title: '🆕 Just Added',
                  subtitle: 'Fresh deals today',
                  child: _buildHorizontalScroll(_justAdded),
                ),
                if (_filteredDeals.isEmpty && !_loading)
                  SliverToBoxAdapter(child: _buildEmpty()),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Smart Header ──────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            // Location
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NearbyDealsScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 14, color: _red),
                    const SizedBox(width: 4),
                    Text(_locationName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Notification bell
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 26),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => NotificationsScreen(userId: _userId, token: _userToken))),
                ),
                if (_notificationCount > 0)
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            // Profile avatar
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const UserProfileScreen())),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: _blue.withOpacity(0.1),
                backgroundImage: _profilePicture != null && _profilePicture!.contains(',')
                    ? MemoryImage(base64Decode(_profilePicture!.split(',')[1]))
                    : null,
                child: (_profilePicture == null || !_profilePicture!.contains(','))
                    ? const Icon(Icons.person, size: 18, color: _blue)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Action Zone ───────────────────────────────────────────────────────────
  Widget _buildActionZone() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $_userName 👋',
                style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E))),
            const SizedBox(height: 4),
            const Text('Find the best deals near you.',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 14),
            // Search bar
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SearchScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF9E9E9E), size: 20),
                    const SizedBox(width: 10),
                    Text('Search KFC, Pizza, Shoes...',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category Pills ────────────────────────────────────────────────────────
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
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final selected = _selectedCategory == categories[i];
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = categories[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _blue : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icons[i], size: 14, color: selected ? Colors.white : _blue),
                    const SizedBox(width: 5),
                    Text(labels[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : const Color(0xFF1A1A1A),
                        )),
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
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
              child: Text('Offline — showing cached deals',
                  style: TextStyle(color: Colors.orange[800], fontSize: 13)),
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

  // ── Loading Shimmer ───────────────────────────────────────────────────────
  Widget _buildLoadingShimmer() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 160, decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16))),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Container(height: 180, decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)))),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 180, decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)))),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ── Banner Carousel ───────────────────────────────────────────────────────
  Widget _buildBannerCarousel() {
    final banners = _bannerDeals;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            SizedBox(
              height: 170,
              child: PageView.builder(
                controller: _bannerController,
                itemCount: banners.length,
                itemBuilder: (_, i) {
                  final p = banners[i];
                  return GestureDetector(
                    onTap: () => _openDeal(p),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (p.imageDataString != null && p.imageDataString!.startsWith('http'))
                            CachedNetworkImage(
                              imageUrl: p.imageDataString!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(color: Colors.white),
                              ),
                              errorWidget: (_, __, ___) => Container(color: Colors.grey[200]),
                            )
                          else
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                                ),
                              ),
                            ),
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                              ),
                            ),
                          ),
                          // Text overlay
                          Positioned(
                            bottom: 14, left: 14, right: 14,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (p.discount != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _red,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(p.discount!,
                                        style: const TextStyle(color: Colors.white,
                                            fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                const SizedBox(height: 4),
                                Text(p.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white,
                                        fontSize: 15, fontWeight: FontWeight.bold)),
                                if (p.merchantName != null)
                                  Text(p.merchantName!,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Dots indicator
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(banners.length, (i) {
                return AnimatedBuilder(
                  animation: _bannerController,
                  builder: (_, __) {
                    final page = _bannerController.hasClients
                        ? (_bannerController.page?.round() ?? 0)
                        : 0;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: page == i ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: page == i ? _blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section wrapper ───────────────────────────────────────────────────────
  Widget _buildSection({required String title, required String subtitle, required Widget child}) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A))),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                  ],
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  // ── Horizontal scroll row ─────────────────────────────────────────────────
  Widget _buildHorizontalScroll(List<Promotion> deals) {
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: deals.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => DealCardNew(
          promotion: deals[i],
          width: 160,
          onTap: () => _openDeal(deals[i]),
        ),
      ),
    );
  }

  // ── 2-column grid ─────────────────────────────────────────────────────────
  Widget _buildGrid(List<Promotion> deals) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: deals.length > 6 ? 6 : deals.length,
        itemBuilder: (_, i) => DealCardNew(
          promotion: deals[i],
          onTap: () => _openDeal(deals[i]),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('No deals found', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 4),
          Text('Try a different category', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }
}
