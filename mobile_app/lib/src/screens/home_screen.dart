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
import '../services/push_notification_service.dart';
import '../widgets/section_header.dart';
import '../widgets/home_shimmer.dart';
import '../widgets/flash_sale_card.dart';
import '../widgets/modern_deal_card.dart';
import 'deal_detail_screen.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'nearby_deals_screen.dart';
import 'all_deals_screen.dart';
import 'deals_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToFavorites;

  const HomeScreen({super.key, this.onNavigateToFavorites});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _endingSoonTicker;

  List<Promotion> _allDeals = [];
  List<Promotion> _bannerDeals = [];
  List<Promotion> _hotDeals = [];
  List<Promotion> _newThisWeekDeals = [];
  List<Promotion> _flashSalesDeals = [];
  bool _bannerManaged = false;
  bool _hotDealsManaged = false;
  bool _newThisWeekManaged = false;
  bool _flashSalesManaged = false;
  List<Promotion> _nearbyDealsFromLocation = [];
  bool _loading = true;
  bool _isOffline = false;

  String _userName = 'there';
  String _userId = '';
  int _notificationCount = 0;

  String _locationName = 'Near You';
  Position? _position;
  String? _locationIssue;

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
    _startEndingSoonTicker();
  }

  @override
  void dispose() {
    _endingSoonTicker?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startEndingSoonTicker() {
    _endingSoonTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _featuredDeals.isEmpty) return;
      setState(() {});
    });
  }

  Future<void> _loadAll() async {
    // Load user first (needed for token)
    await _loadUser();

    // Load location and deals in parallel
    await Future.wait([
      _loadLocation(),
      _loadDeals(),
      _loadCuratedSections(),
    ]);
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('userName') ?? 'there';
      _userId = prefs.getString('userId') ?? '';
    });
    // Load notification count in background (don't block UI)
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    if (_userId.isEmpty) return;
    try {
      final count = await _api.fetchUnreadNotificationCount();
      await PushNotificationService.setAppIconBadgeCount(count);
      if (mounted) setState(() => _notificationCount = count);
    } catch (_) {}
  }

  Future<void> _loadLocation() async {
    final result = await LocationService.resolveCurrentLocation();
    final pos = result.position;
    if (!mounted) return;
    setState(() {
      _position = pos;
      _locationIssue = result.isSuccess ? null : result.message;
      if (!result.isSuccess) {
        _locationName = result.status == LocationFetchStatus.serviceDisabled
            ? 'Location off'
            : 'Near You';
      }
    });
    if (pos != null) {
      if (mounted) {
        setState(() {
          _allDeals = _withComputedDistances(_allDeals);
          _bannerDeals = _withComputedDistances(_bannerDeals);
          _hotDeals = _withComputedDistances(_hotDeals);
          _newThisWeekDeals = _withComputedDistances(_newThisWeekDeals);
          _flashSalesDeals = _withComputedDistances(_flashSalesDeals);
        });
      }
      // Get location name
      final locationName =
          await LocationService.getLocationName(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _locationName = locationName ?? 'Current Location';
          if (result.usedLastKnownPosition) {
            _locationIssue = 'Using your recent location while GPS refreshes.';
          }
        });
      }
      // Fetch nearby deals from backend
      _loadNearbyDeals(pos.latitude, pos.longitude);
    }
  }

  Future<void> _loadNearbyDeals(double lat, double lng) async {
    try {
      final nearbyDeals = await _api.fetchNearbyPromotions(
        lat,
        lng,
        radiusKm: 10,
      );
      if (mounted) {
        setState(() {
          _nearbyDealsFromLocation = nearbyDeals;
          // Update deals with distance information
          for (var deal in _nearbyDealsFromLocation) {
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

  List<Promotion> _withComputedDistances(List<Promotion> promotions) {
    final pos = _position;
    if (pos == null) return promotions;

    return promotions.map((promotion) {
      if (promotion.distance != null) return promotion;
      if (promotion.latitude == null || promotion.longitude == null) {
        return promotion;
      }

      final distanceKm = LocationService.calculateDistance(
        pos.latitude,
        pos.longitude,
        promotion.latitude!,
        promotion.longitude!,
      );

      return promotion.copyWith(distance: distanceKm * 1000);
    }).toList();
  }

  Future<void> _loadCuratedSections() async {
    try {
      final sections = await _api.fetchCuratedHomeSections();
      if (!mounted) return;
      setState(() {
        _bannerDeals = _withComputedDistances(sections.banner);
        _hotDeals = _withComputedDistances(sections.hotDeals);
        _newThisWeekDeals = _withComputedDistances(sections.newThisWeek);
        _flashSalesDeals = _withComputedDistances(sections.flashSales);
        _bannerManaged = sections.bannerManaged;
        _hotDealsManaged = sections.hotDealsManaged;
        _newThisWeekManaged = sections.newThisWeekManaged;
        _flashSalesManaged = sections.flashSalesManaged;
      });
    } catch (_) {
      // Fall back to local heuristics if curated sections are unavailable
    }
  }

  Future<void> _loadDeals() async {
    // Show cached data immediately
    final cached = await CacheService.loadPromotions();
    if (cached != null && cached.isNotEmpty && mounted) {
      setState(() {
        _allDeals = _withComputedDistances(cached);
        _loading = false;
      });
    }

    // Then fetch fresh data in background
    try {
      final deals = await _api.fetchPromotions(forceRefresh: true);
      if (mounted) {
        setState(() {
          _allDeals = _withComputedDistances(deals);
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
    await _loadCuratedSections();
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

  int _compareByRecent(Promotion a, Promotion b) {
    final aDate = a.createdAt ?? a.startDate ?? DateTime(1970);
    final bDate = b.createdAt ?? b.startDate ?? DateTime(1970);
    return bDate.compareTo(aDate);
  }

  List<Promotion> get _filteredDeals {
    final now = DateTime.now();
    final filtered = _allDeals
        .where((p) =>
            (p.endDate == null || p.endDate!.isAfter(now)) &&
            (_selectedCategory == null || p.category == _selectedCategory))
        .toList()
      ..sort(_compareByRecent);
    return filtered;
  }

  List<Promotion> get _flashSales {
    if (_flashSalesDeals.isNotEmpty || _flashSalesManaged) {
      final curatedFlashSales =
          _flashSalesDeals.where((p) => !p.isExpired && p.hasStarted).toList()
            ..sort((a, b) {
              final aEnd = a.endDate ?? DateTime(2100);
              final bEnd = b.endDate ?? DateTime(2100);
              final byEndDate = aEnd.compareTo(bEnd);
              if (byEndDate != 0) return byEndDate;
              return _compareByRecent(a, b);
            });
      if (curatedFlashSales.isNotEmpty || _flashSalesManaged) {
        return curatedFlashSales.take(10).toList();
      }
    }
    final now = DateTime.now();
    final cutoff = now.add(const Duration(hours: 24));
    return _filteredDeals
        .where((p) =>
            p.endDate != null &&
            p.endDate!.isBefore(cutoff) &&
            p.endDate!.isAfter(now))
        .toList()
      ..sort((a, b) {
        final byEndDate = a.endDate!.compareTo(b.endDate!);
        if (byEndDate != 0) return byEndDate;
        return _compareByRecent(a, b);
      });
  }

  List<Promotion> get _nearbyDeals {
    if (_nearbyDealsFromLocation.isNotEmpty) {
      return _nearbyDealsFromLocation.take(10).toList();
    }
    if (_position == null) return [];
    final withDist = _filteredDeals.where((p) => p.distance != null).toList()
      ..sort((a, b) {
        final byDistance = (a.distance ?? 0).compareTo(b.distance ?? 0);
        if (byDistance != 0) return byDistance;
        return _compareByRecent(a, b);
      });
    return withDist.take(10).toList();
  }

  List<Promotion> get _allEndingSoonDeals {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day + 1);
    final localEndingSoon = _filteredDeals
        .where((p) =>
            p.endDate != null &&
            p.endDate!.isAfter(now) &&
            p.endDate!.isBefore(endOfToday))
        .toList()
      ..sort((a, b) {
        final byEndDate = a.endDate!.compareTo(b.endDate!);
        if (byEndDate != 0) return byEndDate;
        return _compareByRecent(a, b);
      });

    if (_hotDeals.isNotEmpty || _hotDealsManaged) {
      final curatedEndingSoon = _hotDeals
          .where((p) =>
              p.endDate != null &&
              p.endDate!.isAfter(now) &&
              p.endDate!.isBefore(endOfToday))
          .toList()
        ..sort((a, b) {
          final byEndDate = a.endDate!.compareTo(b.endDate!);
          if (byEndDate != 0) return byEndDate;
          return _compareByRecent(a, b);
        });
      if (curatedEndingSoon.isNotEmpty) {
        return curatedEndingSoon;
      }
    }

    return localEndingSoon;
  }

  List<Promotion> get _featuredDeals {
    return _allEndingSoonDeals.take(5).toList();
  }

  Duration? get _nextEndingSoonDuration {
    if (_featuredDeals.isEmpty) return null;
    final nextEnding = _featuredDeals.first.endDate;
    if (nextEnding == null) return null;
    final diff = nextEnding.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String get _endingSoonSectionSubtitle {
    final duration = _nextEndingSoonDuration;
    if (duration == null) return 'Deals ending today';
    if (duration == Duration.zero) return 'Last chance deals';
    return 'Closest expiry today';
  }

  List<Promotion> get _newDeals {
    if (_newThisWeekDeals.isNotEmpty || _newThisWeekManaged) {
      return _newThisWeekDeals.take(10).toList();
    }
    return _filteredDeals.take(10).toList();
  }

  List<Promotion> get _bannerSectionDeals {
    if (_bannerDeals.isNotEmpty || _bannerManaged) {
      return _bannerDeals.take(5).toList();
    }
    return _featuredDeals;
  }

  void _openDeal(Promotion p) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => DealDetailScreen(promotion: p)));

  void _openAllDeals({
    String? sectionPreset,
    String? sortBy,
    String? contextTitle,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllDealsScreen(
          initialSectionPreset: sectionPreset,
          initialSortBy: sortBy,
          initialCategoryId: _selectedCategory,
          initialContextTitle: contextTitle,
        ),
      ),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    ).then((_) => _loadNotificationCount());
  }

  void _openPopularDeals() {
    final curated = _hotDeals.isNotEmpty ? _hotDeals : _featuredDeals;
    if (curated.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DealsListScreen(
            promotions: curated,
            title: 'Popular',
          ),
        ),
      );
      return;
    }

    _openAllDeals(
      sortBy: 'recent',
      contextTitle: 'Popular',
    );
  }

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
                _buildDiscoveryHero(),
                _buildCategories(),
                if (!_loading && _bannerSectionDeals.isNotEmpty)
                  _buildFeaturedBanner(),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Color(0xFFE53935)),
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
                      const Icon(Icons.keyboard_arrow_down,
                          size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Notification bell
            SizedBox(
              width: 48,
              height: 48,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _openNotifications,
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(Icons.notifications_outlined, size: 26),
                      ),
                      if (_notificationCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: IgnorePointer(
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
                                  _notificationCount > 9
                                      ? '9+'
                                      : '$_notificationCount',
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
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickBrowseCard({
    required String emoji,
    required String title,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 116,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Discovery Hero ────────────────────────────────────────────────────────
  Widget _buildDiscoveryHero() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE8EEF8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Hello, $_userName',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Find great deals fast.',
                style: TextStyle(
                  fontSize: 22,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Hero(
                tag: 'search_bar',
                child: Material(
                  color: Colors.transparent,
                  child: Semantics(
                    button: true,
                    label: 'Open search for deals and stores',
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFD9E3F3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.045),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F1FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF1D4ED8),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Search deals, stores, categories',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Quick picks',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 86,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildQuickBrowseCard(
                      emoji: '📍',
                      title: 'Near Me',
                      accent: const Color(0xFF0EA5E9),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NearbyDealsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildQuickBrowseCard(
                      emoji: '🔥',
                      title: 'Best Deals',
                      accent: const Color(0xFFEF4444),
                      onTap: () => _openAllDeals(
                        sortBy: 'discount',
                        contextTitle: 'Best Deals',
                      ),
                    ),
                    _buildQuickBrowseCard(
                      emoji: '⏳',
                      title: 'Ending Soon',
                      accent: const Color(0xFFF59E0B),
                      onTap: () => _openAllDeals(
                        sectionPreset: 'ending_soon',
                        sortBy: 'ending_soon',
                        contextTitle: 'Ending Soon',
                      ),
                    ),
                    _buildQuickBrowseCard(
                      emoji: '⭐',
                      title: 'Popular',
                      accent: const Color(0xFF8B5CF6),
                      onTap: _openPopularDeals,
                    ),
                  ],
                ),
              ),
            ],
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
          itemCount:
              _bannerSectionDeals.length > 3 ? 3 : _bannerSectionDeals.length,
          itemBuilder: (context, index) {
            final deal = _bannerSectionDeals[index];
            return GestureDetector(
              onTap: () => _openDeal(deal),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
                      if (deal.imageDataString != null &&
                          deal.imageDataString!.isNotEmpty)
                        Image.network(
                          deal.imageDataString!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.7),
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
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.7),
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
                              Colors.black.withValues(alpha: 0.7),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
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
                                  'Curated Banner',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
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
    final categories = [null, ...launchCategories.map((c) => c.id)];
    final labels = ['All', ...launchCategories.map((c) => c.name)];
    final icons = [
      Icons.all_inclusive,
      Icons.fastfood_outlined,
      Icons.content_cut_outlined,
      Icons.build_outlined,
      Icons.shopping_bag_outlined,
      Icons.favorite_outline,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
                      color: selected
                          ? Colors.white
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            selected ? Colors.white : const Color(0xFF1A1A1A),
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
              child: const Text('Retry',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDealsState() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 42,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No deals found in this view',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF14213D),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _selectedCategory == null
                    ? 'Try refreshing, explore nearby deals, or open the full deals list to keep browsing.'
                    : 'No deals match the selected category right now. Clear the filter or switch to another category.',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (_selectedCategory != null)
                    FilledButton.tonalIcon(
                      onPressed: () => setState(() => _selectedCategory = null),
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text('Clear category'),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh deals'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openAllDeals(
                      contextTitle: _selectedCategory == null
                          ? null
                          : predefinedCategories
                              .firstWhere(
                                (cat) => cat.id == _selectedCategory,
                                orElse: () => Category(
                                  id: _selectedCategory!,
                                  name: 'Filtered Deals',
                                ),
                              )
                              .name,
                    ),
                    icon: const Icon(Icons.grid_view_rounded),
                    label: const Text('Browse all deals'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Content Sections ──────────────────────────────────────────────────────
  Widget _buildContent() {
    if (_filteredDeals.isEmpty) {
      return _buildNoDealsState();
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        // Flash Sales Section
        if (_flashSales.isNotEmpty) ...[
          SectionHeader(
            title: '⚡ Flash Sales',
            subtitle: 'Ending soon - Hurry up!',
            icon: Icons.flash_on,
            onSeeAll: () => _openAllDeals(
              sectionPreset: 'flash_sales',
              sortBy: 'ending_soon',
              contextTitle: 'Flash Sales',
            ),
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
                              color: Colors.black.withValues(alpha: 0.1),
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
          SectionHeader(
            title: '⏰ Ending Soon',
            subtitle: _endingSoonSectionSubtitle,
            icon: Icons.access_time,
            onSeeAll: () => _openAllDeals(
              sectionPreset: 'ending_soon',
              sortBy: 'ending_soon',
              contextTitle: 'Ending Soon',
            ),
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
                              color: Colors.black.withValues(alpha: 0.1),
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
            subtitle: _locationName == 'Near You'
                ? 'Deals around your location'
                : 'Deals around $_locationName',
            icon: Icons.location_on,
            onSeeAll: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NearbyDealsScreen()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5FBF7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD7EEDD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2E7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.near_me,
                            color: Color(0xFF2E7D32), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Closest deals first',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF14213D),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _nearbyDeals.first.distance != null
                                  ? 'Closest deal is ${(_nearbyDeals.first.distance! < 1000 ? '${_nearbyDeals.first.distance!.round()}m' : '${(_nearbyDeals.first.distance! / 1000).toStringAsFixed(1)}km')} away. Open the map for directions and distance context.'
                                  : 'Open the nearby map view to compare distance, direction, and location context.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_nearbyDeals.length} nearby picks',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2E7D32),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NearbyDealsScreen()),
                        ),
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('Open map'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                          side: const BorderSide(color: Color(0xFFB7DFC2)),
                        ),
                      ),
                    ],
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
                    _locationIssue ??
                        'Allow location access to discover amazing deals near you',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _loadLocation();
                      if (!mounted) return;
                      if (_position != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Location enabled! Loading nearby deals...'),
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
          SectionHeader(
            title: '🆕 New This Week',
            subtitle: 'Fresh deals just added',
            icon: Icons.fiber_new,
            onSeeAll: () => _openAllDeals(
              sectionPreset: 'new_this_week',
              sortBy: 'recent',
              contextTitle: 'New This Week',
            ),
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
                              color: Colors.black.withValues(alpha: 0.1),
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
          onSeeAll: () => _openAllDeals(
            contextTitle: _selectedCategory == null
                ? null
                : predefinedCategories
                    .firstWhere(
                      (cat) => cat.id == _selectedCategory,
                      orElse: () => Category(
                        id: _selectedCategory!,
                        name: 'Filtered Deals',
                      ),
                    )
                    .name,
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
              onPressed: () => _openAllDeals(
                contextTitle: _selectedCategory == null
                    ? null
                    : predefinedCategories
                        .firstWhere(
                          (cat) => cat.id == _selectedCategory,
                          orElse: () => Category(
                            id: _selectedCategory!,
                            name: 'Filtered Deals',
                          ),
                        )
                        .name,
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 2),
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
