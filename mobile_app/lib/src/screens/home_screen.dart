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
import '../utils/bank_card_promotion_support.dart';
import '../widgets/section_header.dart';
import '../widgets/home_shimmer.dart';
import '../widgets/modern_deal_card.dart';
import '../widgets/category_icon.dart';
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
      final nearbyResult = await _api.fetchNearbyPromotionsWithCache(
        lat,
        lng,
        radiusKm: 5,
        locationName: _locationName,
      );
      if (mounted) {
        setState(() {
          _nearbyDealsFromLocation =
              nearbyResult.fromCache && nearbyResult.locationChanged
                  ? []
                  : nearbyResult.promotions;
          if (nearbyResult.fromCache && nearbyResult.locationChanged) {
            _locationIssue =
                'Nearby deals need internet because you moved away from the last saved area.';
          }
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

  int _discountSignal(Promotion promotion) {
    final percentage = promotion.discountPercentage;
    if (percentage != null) return percentage;

    final rawDiscount = promotion.discount;
    if (rawDiscount == null) return 0;

    final percentMatch = RegExp(r'(\d+)\s*%').firstMatch(rawDiscount);
    if (percentMatch != null) {
      return int.tryParse(percentMatch.group(1) ?? '') ?? 0;
    }

    return 0;
  }

  List<Promotion> get _filteredDeals {
    final now = DateTime.now();
    final filtered = _allDeals
        .where((p) =>
            (p.endDate == null || p.endDate!.isAfter(now)) &&
            (_selectedCategory == null ||
                BankCardPromotionSupport.effectiveCategoryId(p) ==
                    _selectedCategory))
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
    final cutoff = now.add(const Duration(hours: 48));
    final localEndingSoon = _filteredDeals
        .where((p) =>
            p.endDate != null &&
            p.endDate!.isAfter(now) &&
            p.endDate!.isBefore(cutoff))
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
              p.endDate!.isBefore(cutoff))
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
    if (duration == null) return 'Deals ending within 48 hours';
    if (duration == Duration.zero) return 'Last chance deals';
    return 'Closest expiry in the next 48 hours';
  }

  List<Promotion> get _newDeals {
    if (_newThisWeekDeals.isNotEmpty || _newThisWeekManaged) {
      return _newThisWeekDeals.take(10).toList();
    }
    return _filteredDeals.take(10).toList();
  }

  List<Promotion> get _trendingDeals {
    final source = _hotDeals.isNotEmpty ? _hotDeals : _filteredDeals;
    final now = DateTime.now();

    final deals = source
        .where((p) =>
            p.hasStarted &&
            (p.endDate == null || p.endDate!.isAfter(now)) &&
            (_selectedCategory == null ||
                BankCardPromotionSupport.effectiveCategoryId(p) ==
                    _selectedCategory))
        .toList()
      ..sort((a, b) {
        final featuredCompare =
            (b.featured == true ? 1 : 0).compareTo(a.featured == true ? 1 : 0);
        if (featuredCompare != 0) return featuredCompare;

        final discountCompare = _discountSignal(b).compareTo(
          _discountSignal(a),
        );
        if (discountCompare != 0) return discountCompare;

        final ratingsCompare = b.ratingsCount.compareTo(a.ratingsCount);
        if (ratingsCompare != 0) return ratingsCompare;

        return _compareByRecent(a, b);
      });

    return deals.take(8).toList();
  }

  List<Promotion> get _recommendedDeals {
    return _trendingDeals;
  }

  List<Promotion> get _bankCardDeals {
    final now = DateTime.now();
    final deals = _filteredDeals
        .where((p) =>
            BankCardPromotionSupport.isBankCardPromotion(p) &&
            (p.endDate == null || p.endDate!.isAfter(now)))
        .toList()
      ..sort((a, b) {
        final discountCompare = _discountSignal(b).compareTo(
          _discountSignal(a),
        );
        if (discountCompare != 0) return discountCompare;
        return _compareByRecent(a, b);
      });
    return deals.take(10).toList();
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
    String? categoryId,
    String? primaryFilter,
    double? minDiscount,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllDealsScreen(
          initialSectionPreset: sectionPreset,
          initialSortBy: sortBy,
          initialCategoryId: categoryId ?? _selectedCategory,
          initialContextTitle: contextTitle,
          initialPrimaryFilter: primaryFilter,
          initialMinDiscount: minDiscount,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB9E6FF),
              Color(0xFFD8F1FF),
              Color(0xFFE8F2FF),
              Color(0xFFF6F1FF),
            ],
            stops: [0.0, 0.24, 0.68, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: Theme.of(context).colorScheme.primary,
              child: CustomScrollView(
                slivers: [
                  _buildHeader(),
                  _buildDiscoveryHero(),
                  if (!_loading && _bannerSectionDeals.isNotEmpty)
                    _buildFeaturedBanner(),
                  _buildQuickPicksSection(),
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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE0F4FF),
                      Color(0xFFBFE8FF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF9FD2EE)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2A7DA8).withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/app_icon.png',
                        width: 26,
                        height: 26,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Deal Finder',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B3B53),
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
                    color: const Color(0xFFE8F7FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFB9DDF1)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4B93B8).withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Color(0xFF0E7490)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _locationName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0B3B53),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down,
                          size: 14, color: Color(0xFF4B7D96)),
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
                color: const Color(0xFFE2F4FF),
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _openNotifications,
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.notifications_outlined,
                          size: 26,
                          color: Color(0xFF0B5C7A),
                        ),
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

  Widget _buildQuickActionsCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final compactBottomRow = constraints.maxWidth < 340;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD7E5FA)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8EA6C9).withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildQuickBrowseCard(
                      emoji: '🔥',
                      title: 'Ending Soon',
                      accent: const Color(0xFFEF4444),
                      onTap: () => _openAllDeals(
                        sectionPreset: 'ending_soon',
                        sortBy: 'ending_soon',
                        primaryFilter: 'ending_soon',
                        contextTitle: 'Ending Soon',
                      ),
                    ),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: _buildQuickBrowseCard(
                      emoji: '📍',
                      title: 'Under 1km',
                      accent: const Color(0xFF0EA5E9),
                      onTap: () => _openAllDeals(
                        sortBy: 'distance',
                        primaryFilter: 'under_1km',
                        contextTitle: 'Under 1km',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: gap),
              if (!compactBottomRow)
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickBrowseCard(
                        emoji: '💳',
                        title: 'Bank Cards',
                        accent: const Color(0xFF0F4C81),
                        onTap: () => _openAllDeals(
                          categoryId: BankCardPromotionSupport.categoryId,
                          contextTitle: 'Bank Card Offers',
                        ),
                      ),
                    ),
                    const SizedBox(width: gap),
                    Expanded(
                      child: _buildQuickBrowseCard(
                        emoji: '💸',
                        title: '50%+ OFF',
                        accent: const Color(0xFF10B981),
                        onTap: () => _openAllDeals(
                          sortBy: 'discount',
                          primaryFilter: 'half_off',
                          minDiscount: 50,
                          contextTitle: '50%+ OFF',
                        ),
                      ),
                    ),
                    const SizedBox(width: gap),
                    Expanded(
                      child: _buildQuickBrowseCard(
                        emoji: '🆕',
                        title: 'New Deals',
                        accent: const Color(0xFF6366F1),
                        onTap: () => _openAllDeals(
                          sectionPreset: 'new_this_week',
                          sortBy: 'recent',
                          primaryFilter: 'new_deals',
                          contextTitle: 'New Deals',
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickBrowseCard(
                            emoji: '💳',
                            title: 'Bank Cards',
                            accent: const Color(0xFF0F4C81),
                            onTap: () => _openAllDeals(
                              categoryId: BankCardPromotionSupport.categoryId,
                              contextTitle: 'Bank Card Offers',
                            ),
                          ),
                        ),
                        const SizedBox(width: gap),
                        Expanded(
                          child: _buildQuickBrowseCard(
                            emoji: '💸',
                            title: '50%+ OFF',
                            accent: const Color(0xFF10B981),
                            onTap: () => _openAllDeals(
                              sortBy: 'discount',
                              primaryFilter: 'half_off',
                              minDiscount: 50,
                              contextTitle: '50%+ OFF',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: gap),
                    _buildQuickBrowseCard(
                      emoji: '🆕',
                      title: 'New Deals',
                      accent: const Color(0xFF6366F1),
                      onTap: () => _openAllDeals(
                        sectionPreset: 'new_this_week',
                        sortBy: 'recent',
                        primaryFilter: 'new_deals',
                        contextTitle: 'New Deals',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 112;

          return Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: EdgeInsets.symmetric(
              horizontal: narrow ? 8 : 10,
              vertical: narrow ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.22)),
            ),
            child: narrow
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildQuickBrowseIcon(accent, emoji),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildQuickBrowseIcon(accent, emoji),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildQuickBrowseIcon(Color accent, String emoji) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 13),
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF3F7FF),
                Color(0xFFE9F1FB),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFDCE7F5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8CA2C8).withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
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
                  color: const Color(0xFFDDEBFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.waving_hand_rounded,
                      size: 14,
                      color: Color(0xFF1D4ED8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Hello, $_userName',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF365314),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Find the Best Deals Near You',
                style: TextStyle(
                  fontSize: 24,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Discover savings around ${_locationName == 'Current Location' ? 'you' : _locationName} right now.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
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
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFCFDFF),
                              Color(0xFFF0F6FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFBCD2F4),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF87A4D8)
                                  .withValues(alpha: 0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDDEAFF),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Search deals near you',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Try: burgers, salons, repair',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2ECFF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFF1D4ED8),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPicksSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick picks near you',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            _buildQuickActionsCard(),
          ],
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
        // Top Deals Near You Section
        if (_nearbyDeals.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionHeader(
            title: '🔥 Top Deals Near You',
            subtitle: _locationName == 'Near You'
                ? 'Best nearby deals sorted by distance and value'
                : 'Best nearby deals around $_locationName',
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nearest live pick',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF14213D),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'See nearby deals sorted by distance.',
                              style: TextStyle(
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
                childAspectRatio: 0.54,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _nearbyDeals.length > 4 ? 4 : _nearbyDeals.length,
              itemBuilder: (_, i) => ModernDealCard(
                promotion: _nearbyDeals[i],
                prioritizeDistance: true,
                onTap: () => _openDeal(_nearbyDeals[i]),
              ),
            ),
          ),
        ] else if (_position == null) ...[
          const SizedBox(height: 8),
          const SectionHeader(
            title: '🔥 Top Deals Near You',
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

        // Ending Soon Section
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
                height: 340,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _featuredDeals.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => ModernDealCard(
                    promotion: _featuredDeals[i],
                    width: 184,
                    showCountdown: true,
                    onTap: () => _openDeal(_featuredDeals[i]),
                  ),
                ),
              ),
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

        // Recommended Section
        if (_recommendedDeals.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionHeader(
            title: '🎯 Recommended For You',
            subtitle: _nearbyDeals.isNotEmpty
                ? 'Popular picks based on what is working near you'
                : 'Popular picks while we learn your preferences',
            icon: Icons.auto_awesome,
            onSeeAll: () => _openAllDeals(
              sortBy: 'discount',
              contextTitle: 'Recommended For You',
            ),
          ),
          Stack(
            children: [
              SizedBox(
                height: 340,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recommendedDeals.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => ModernDealCard(
                    promotion: _recommendedDeals[i],
                    width: 184,
                    onTap: () => _openDeal(_recommendedDeals[i]),
                  ),
                ),
              ),
              if (_recommendedDeals.length > 2)
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

        if (_bankCardDeals.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionHeader(
            title: '💳 Bank Card Offers',
            subtitle: 'Credit and debit card promotions from your banks',
            icon: Icons.credit_card_rounded,
            onSeeAll: () => _openAllDeals(
              categoryId: BankCardPromotionSupport.categoryId,
              contextTitle: 'Bank Card Offers',
            ),
          ),
          Stack(
            children: [
              SizedBox(
                height: 340,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _bankCardDeals.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => ModernDealCard(
                    promotion: _bankCardDeals[i],
                    width: 184,
                    onTap: () => _openDeal(_bankCardDeals[i]),
                  ),
                ),
              ),
              if (_bankCardDeals.length > 2)
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

        // Categories Section
        const SizedBox(height: 8),
        SectionHeader(
          title: '📂 Browse Categories',
          subtitle: 'Jump into the deal type you care about fastest',
          icon: Icons.grid_view_rounded,
          onSeeAll: () => _openAllDeals(contextTitle: 'All Categories'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.05,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount:
                launchCategories.length > 9 ? 9 : launchCategories.length,
            itemBuilder: (_, i) {
              final category = launchCategories[i];
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _openAllDeals(
                  contextTitle: category.name,
                  categoryId: category.id,
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CategoryIcon(
                        category: category.id,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        category.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Flash Sales Section
        if (_flashSales.isNotEmpty) ...[
          SectionHeader(
            title: '⚡ Flash Sales',
            subtitle: 'Time-sensitive promotions worth checking now',
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
                height: 360,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _flashSales.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => ModernDealCard(
                    promotion: _flashSales[i],
                    width: 184,
                    showCountdown: true,
                    onTap: () => _openDeal(_flashSales[i]),
                  ),
                ),
              ),
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

        // New Deals Section
        if (_newDeals.isNotEmpty) ...[
          const SizedBox(height: 8),
          SectionHeader(
            title: '🆕 New Deals',
            subtitle: 'Fresh deals just added',
            icon: Icons.fiber_new,
            onSeeAll: () => _openAllDeals(
              sectionPreset: 'new_this_week',
              sortBy: 'recent',
              contextTitle: 'New Deals',
            ),
          ),
          Stack(
            children: [
              SizedBox(
                height: 340,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _newDeals.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => ModernDealCard(
                    promotion: _newDeals[i],
                    width: 184,
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

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: OutlinedButton(
            onPressed: () => _openAllDeals(
              sortBy: 'discount',
              contextTitle: 'All Deals',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Browse All ${_filteredDeals.length} Deals',
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
