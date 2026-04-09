import 'package:flutter/material.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import '../widgets/deal_card_shimmer.dart';
import '../models/category.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/notification_alert_service.dart';
import '../services/cache_service.dart';
import '../widgets/deal_card.dart';
import 'deal_detail_screen.dart';
import 'deals_list_screen.dart';
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
  late Future<List<Promotion>> _allPromotionsFuture;
  late Future<List<Promotion>> _nearbyDealsPreviewFuture;
  final ApiService _apiService = ApiService();
  String? _profilePicture;
  String _userName = 'User';
  String _userId = '';
  String _token = '';
  int _notificationCount = 0;
  String? _selectedCategoryId;
  final TextEditingController _searchController = TextEditingController();
  List<Promotion> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  List<Promotion> _allPromotionsCache = [];
  bool _locationAvailable = false;
  bool _locationChecked = false;
  bool _isOffline = false;
  static Position? _cachedPosition;
  final int _latestCount = 10;
  List<Promotion> _latestDeals = [];
  static const int _homePageLatestDealsLimit = 6; // Show only 6 on home page

  @override
  void initState() {
    super.initState();
    _allPromotionsFuture = _apiService.fetchPromotions().then((promos) {
      _allPromotionsCache = promos;
      final now = DateTime.now();
      final sorted = ([...promos]
        .where((p) => p.endDate == null || p.endDate!.isAfter(now))
        .toList()
        ..sort((a, b) => (b.startDate ?? DateTime(0)).compareTo(a.startDate ?? DateTime(0))));
      if (mounted) setState(() { _isOffline = false; _latestDeals = sorted; });
      return promos;
    }).catchError((e) async {
      if (mounted) setState(() => _isOffline = true);
      final cached = await CacheService.loadPromotions(forceStale: true);
      if (cached != null) {
        _allPromotionsCache = cached;
        final now = DateTime.now();
        final sorted = ([...cached]
          .where((p) => p.endDate == null || p.endDate!.isAfter(now))
          .toList()
          ..sort((a, b) => (b.startDate ?? DateTime(0)).compareTo(a.startDate ?? DateTime(0))));
        if (mounted) setState(() => _latestDeals = sorted);
        return cached;
      }
      throw e;
    });
    _nearbyDealsPreviewFuture = _fetchNearbyDealsPreview();
    _loadUserData();
    _checkAlerts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() { _isSearching = false; _searchResults = []; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final q = query.toLowerCase();
      final results = _allPromotionsCache.where((p) =>
        p.title.toLowerCase().contains(q) ||
        p.description.toLowerCase().contains(q) ||
        (p.merchantName?.toLowerCase().contains(q) ?? false) ||
        (p.category?.toLowerCase().contains(q) ?? false)
      ).take(8).toList();
      setState(() { _isSearching = true; _searchResults = results; });
    });
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
      final notifications = await _apiService.fetchNotifications(_userId, _token);
      if (mounted) setState(() => _notificationCount = notifications.length);
    } catch (_) {}
  }

  Future<void> _refresh() async {
    final newFuture = _apiService.fetchPromotions().then((promos) {
      _allPromotionsCache = promos;
      final now = DateTime.now();
      final sorted = ([...promos]
        .where((p) => p.endDate == null || p.endDate!.isAfter(now))
        .toList()
        ..sort((a, b) => (b.startDate ?? DateTime(0)).compareTo(a.startDate ?? DateTime(0))));
      if (mounted) setState(() { _isOffline = false; _latestDeals = sorted; });
      return promos;
    }).catchError((e) async {
      if (mounted) setState(() => _isOffline = true);
      return <Promotion>[];
    });
    setState(() {
      _allPromotionsFuture = newFuture;
      _nearbyDealsPreviewFuture = _fetchNearbyDealsPreview(useCache: true);
    });
    await Future.wait([_allPromotionsFuture, _nearbyDealsPreviewFuture]);
  }

  Future<List<Promotion>> _fetchNearbyDealsPreview({bool useCache = false}) async {
    try {
      Position? position;
      if (useCache && _cachedPosition != null) {
        position = _cachedPosition;
      } else {
        position = await LocationService.getCurrentLocation();
        if (position != null) _cachedPosition = position;
      }
      if (position == null) {
        if (mounted) setState(() { _locationAvailable = false; _locationChecked = true; });
        return [];
      }
      if (mounted) setState(() { _locationAvailable = true; _locationChecked = true; });
      try {
        final nearbyDeals = await _apiService.fetchNearbyPromotions(
          position.latitude,
          position.longitude,
          radiusKm: 50,
        );
        return nearbyDeals.take(3).toList();
      } catch (_) {
        // location available but API failed — return empty, don't hide section
        return [];
      }
    } catch (e) {
      if (mounted) setState(() { _locationAvailable = false; _locationChecked = true; });
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen())),
          ),
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
                      _notificationCount > 99 ? '99+' : '$_notificationCount',
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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
        slivers: <Widget>[
          // Offline banner
          if (_isOffline) SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange[800], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You\'re offline. Showing last saved data.',
                      style: TextStyle(color: Colors.orange[900], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Welcome section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: _profilePicture != null && _profilePicture!.contains(',')
                          ? MemoryImage(base64Decode(_profilePicture!.split(',')[1]))
                          : null,
                      child: (_profilePicture == null || !_profilePicture!.contains(','))
                          ? const Icon(Icons.person, color: Colors.white, size: 28)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.welcomeBack(_userName),
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Text(
                          AppLocalizations.of(context)!.findBestDeals,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FutureBuilder<List<Promotion>>(
                    future: _allPromotionsFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${snapshot.data!.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Text('Deals', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(() { _isSearching = false; _searchResults = []; });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                  if (_isSearching) ...[
                    const SizedBox(height: 8),
                    _searchResults.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text('No results found', style: TextStyle(color: Colors.grey[600])),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final p = _searchResults[index];
                              return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: p.imageDataString != null && p.imageDataString!.isNotEmpty
                                      ? (p.imageDataString!.startsWith('http')
                                          ? Image.network(p.imageDataString!, width: 48, height: 48, fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => _searchResultPlaceholder())
                                          : (p.imageDataString!.startsWith('data:image')
                                              ? Image.memory(
                                                  base64Decode(p.imageDataString!.substring(p.imageDataString!.indexOf(',') + 1)),
                                                  width: 48, height: 48, fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => _searchResultPlaceholder())
                                              : _searchResultPlaceholder()))
                                      : _searchResultPlaceholder(),
                                ),
                                title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(p.merchantName ?? p.category ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: p.discount != null ? Text(p.discount!, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)) : null,
                                onTap: () {
                                  _searchController.clear();
                                  setState(() { _isSearching = false; _searchResults = []; });
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => DealDetailScreen(promotion: p)));
                                },
                              );
                            },
                          ),
                  ],
                ],
              ),
            ),
          ),

          // Category chips — hidden while searching
          if (!_isSearching) SliverToBoxAdapter(
            child: Container(
              height: 48,
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: predefinedCategories.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isSelected = _selectedCategoryId == null;
                    return ChoiceChip(
                      avatar: Icon(Icons.all_inclusive, size: 18, color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary),
                      label: const Text('All', style: TextStyle(fontSize: 13)),
                      selected: isSelected,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                      onSelected: (_) => setState(() => _selectedCategoryId = null),
                    );
                  }
                  final category = predefinedCategories[index - 1];
                  final isSelected = _selectedCategoryId == category.id;
                  return ChoiceChip(
                    avatar: Icon(_getIconForCategory(category.id), size: 18, color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary),
                    label: Text(category.name, style: const TextStyle(fontSize: 13)),
                    selected: isSelected,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                    onSelected: (_) => setState(() => _selectedCategoryId = isSelected ? null : category.id),
                  );
                },
              ),
            ),
          ),

          // Featured Deals — hidden while searching
          if (!_isSearching) SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.featuredDeals,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => _allPromotionsFuture.then((promos) {
                            final now = DateTime.now();
                            final featured = promos.where((p) =>
                              (p.endDate == null || p.endDate!.isAfter(now)) &&
                              (_selectedCategoryId == null || p.category == _selectedCategoryId)
                            ).toList();
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => DealsListScreen(promotions: featured, title: 'Featured Deals'),
                            ));
                          }),
                          child: Text(AppLocalizations.of(context)!.viewAll),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<Promotion>>(
                    future: _allPromotionsFuture,
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
                                Text(AppLocalizations.of(context)!.apiConnectionFailed, style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('${snapshot.error}', style: TextStyle(color: Colors.red[300], fontSize: 12), textAlign: TextAlign.center),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => setState(() => _allPromotionsFuture = _apiService.fetchPromotions()),
                                  child: Text(AppLocalizations.of(context)!.retry),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return SizedBox(
                          height: 220,
                          child: Center(child: Text(AppLocalizations.of(context)!.noFeaturedDeals, style: TextStyle(color: Colors.grey[600]))),
                        );
                      }
                      final now = DateTime.now();
                      final all = snapshot.data!
                          .where((p) => p.endDate == null || p.endDate!.isAfter(now))
                          .where((p) => _selectedCategoryId == null || p.category == _selectedCategoryId)
                          .toList();
                      final featuredDeals = (all.where((p) => p.featured == true).isNotEmpty
                          ? all.where((p) => p.featured == true).toList()
                          : all.toList())
                        ..sort((a, b) => (b.startDate ?? DateTime(0)).compareTo(a.startDate ?? DateTime(0)));
                      final featuredList = featuredDeals.take(5).toList();
                      return SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: featuredList.length,
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          itemBuilder: (context, index) {
                            final promotion = featuredList[index];
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

          // Nearby Deals — hidden while searching
          if (!_isSearching) SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.nearbyDeals,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NearbyDealsScreen()),
                          ),
                          child: Text(AppLocalizations.of(context)!.viewAll),
                        ),
                      ],
                    ),
                  ),
                  FutureBuilder<List<Promotion>>(
                    future: _nearbyDealsPreviewFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting || !_locationChecked) {
                        return _buildFeaturedDealsShimmer();
                      }
                      if (!_locationAvailable) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Card(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(Icons.location_off, size: 40, color: Colors.grey[500]),
                                  const SizedBox(height: 10),
                                  const Text('Location not available', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Enable location to see deals near you', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.location_on, size: 16),
                                    label: const Text('Enable Location'),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const NearbyDealsScreen()),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return SizedBox(
                          height: 80,
                          child: Center(child: Text(AppLocalizations.of(context)!.noNearbyDeals, style: TextStyle(color: Colors.grey[600]))),
                        );
                      }
                      final nearbyDeals = snapshot.data!;
                      return SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: nearbyDeals.length,
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          itemBuilder: (context, index) {
                            final promotion = nearbyDeals[index];
                            return Container(
                              width: MediaQuery.of(context).size.width * 0.75,
                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Stack(
                                children: [
                                  InkWell(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => DealDetailScreen(promotion: promotion)),
                                    ),
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
                                  if (promotion.distance != null)
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green[600],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 12, color: Colors.white),
                                            const SizedBox(width: 4),
                                            Text(
                                              promotion.distance! < 1000
                                                  ? '${promotion.distance!.round()}m'
                                                  : '${(promotion.distance! / 1000).toStringAsFixed(1)}km',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ],
                                        ),
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

          // Quick Actions
          if (!_isSearching) SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _QuickActionButton(icon: Icons.near_me, label: AppLocalizations.of(context)!.nearby, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyDealsScreen()))),
                      _QuickActionButton(icon: Icons.qr_code_scanner, label: AppLocalizations.of(context)!.scanQR, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScannerScreen()))),
                      _QuickActionButton(icon: Icons.favorite_border, label: AppLocalizations.of(context)!.favorites, onTap: () => widget.onNavigateToFavorites?.call()),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Latest Deals - show only 6 with View More button
          if (!_isSearching) SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary, size: 22),
                    const SizedBox(width: 6),
                    Text('Latest Deals', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ]),
                ],
              ),
            ),
          ),

          // Latest Deals Grid - show only 6 deals
          if (!_isSearching && _latestDeals.isEmpty)
            SliverToBoxAdapter(child: _buildGridShimmer()),

          if (!_isSearching && _latestDeals.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: (() {
                  final filtered = _latestDeals
                    .where((p) => _selectedCategoryId == null || p.category == _selectedCategoryId)
                    .take(_homePageLatestDealsLimit)
                    .toList();
                  return filtered.length;
                })(),
                itemBuilder: (context, index) {
                  final filtered = _latestDeals
                    .where((p) => _selectedCategoryId == null || p.category == _selectedCategoryId)
                    .take(_homePageLatestDealsLimit)
                    .toList();
                  final promotion = filtered[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DealDetailScreen(promotion: promotion))),
                    child: DealCard(promotion: promotion, compact: true),
                  );
                },
              ),
            ),

          // View More button - always show if there are deals
          if (!_isSearching && _latestDeals.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('View More Deals'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // Navigate to DealsListScreen without passing promotions (dynamic mode)
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DealsListScreen()),
                    );
                  },
                ),
              ),
            ),

                    if (!_isSearching) const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
      ),
    );
  }

  Widget _searchResultPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.local_offer_outlined, color: Colors.grey[400], size: 22),
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

  Widget _buildGridShimmer() {
    return SizedBox(
      height: 400,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 2, mainAxisSpacing: 2,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => const DealCardShimmer(),
      ),
    );
  }

  Widget _buildFeaturedDealsShimmer({double height = 200}) {
    return SizedBox(
      height: height,
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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
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

