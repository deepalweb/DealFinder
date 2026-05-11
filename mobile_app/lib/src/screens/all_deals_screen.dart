import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../models/promotion.dart';
import '../models/category.dart';
import '../widgets/modern_deal_card.dart';
import 'deals_list_screen.dart';
import 'deal_detail_screen.dart';
import 'package:shimmer/shimmer.dart';

class AllDealsScreen extends StatefulWidget {
  final String? initialSortBy;
  final String? initialCategoryId;
  final String? initialSectionPreset;
  final String? initialContextTitle;

  const AllDealsScreen({
    super.key,
    this.initialSortBy,
    this.initialCategoryId,
    this.initialSectionPreset,
    this.initialContextTitle,
  });

  @override
  State<AllDealsScreen> createState() => _AllDealsScreenState();
}

class _AllDealsScreenState extends State<AllDealsScreen> {
  late Future<List<Promotion>> _promotionsFuture;
  final ApiService _apiService = ApiService();
  
  // Sort and Filter state
  String _sortBy = 'recent'; // recent, discount, price_low, price_high, ending_soon, distance
  double _minPrice = 0;
  double _maxPrice = 10000;
  double _minDiscount = 0;
  String? _selectedCategory;
  bool _showFilters = false;
  String? _activeSectionPreset;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.initialSortBy ?? _sortBy;
    _selectedCategory = widget.initialCategoryId;
    _activeSectionPreset = widget.initialSectionPreset;
    _loadPromotions();
  }

  void _loadPromotions() {
    setState(() {
      _promotionsFuture = _fetchPromotionsWithDistance(forceRefresh: false).then((promotions) {
        // Show cached data immediately, then refresh in background
        _fetchPromotionsWithDistance(forceRefresh: true).then((fresh) {
          if (mounted) {
            setState(() {
              _promotionsFuture = Future.value(fresh);
            });
          }
        }).catchError((_) {});
        return promotions;
      });
    });
  }

  Future<void> _refreshPromotions() async {
    setState(() {
      _promotionsFuture = _fetchPromotionsWithDistance(forceRefresh: true);
    });
  }

  Future<List<Promotion>> _fetchPromotionsWithDistance({
    required bool forceRefresh,
  }) async {
    final promotions =
        await _apiService.fetchPromotions(forceRefresh: forceRefresh);
    final locationResult = await LocationService.resolveCurrentLocation(
      requestPermission: false,
      allowLastKnownFallback: true,
    );
    final position = locationResult.position;
    if (position == null) return promotions;

    return promotions.map((promotion) {
      if (promotion.distance != null) return promotion;
      if (promotion.latitude == null || promotion.longitude == null) {
        return promotion;
      }

      final distanceKm = LocationService.calculateDistance(
        position.latitude,
        position.longitude,
        promotion.latitude!,
        promotion.longitude!,
      );

      return promotion.copyWith(distance: distanceKm * 1000);
    }).toList();
  }

  String _normalizeCategory(String? category) {
    if (category == null) return 'other';
    // Handle legacy 'food' category
    if (category == 'food') return 'food_bev';
    return category;
  }

  Map<String, List<Promotion>> _groupByCategory(List<Promotion> promotions) {
    final Map<String, List<Promotion>> grouped = {};
    
    // Apply filters
    var filtered = promotions.where((promo) {
      // Category filter
      final normalizedCategory = _normalizeCategory(promo.category);
      if (_selectedCategory != null && normalizedCategory != _selectedCategory) {
        return false;
      }
      
      // Price filter
      final price = promo.discountedPrice ?? promo.price ?? promo.originalPrice ?? 0;
      if (price < _minPrice || price > _maxPrice) {
        return false;
      }
      
      // Discount filter
      if (promo.discount != null) {
        final discountMatch = RegExp(r'(\d+)').firstMatch(promo.discount!);
        if (discountMatch != null) {
          final discountValue = double.parse(discountMatch.group(1)!);
          if (discountValue < _minDiscount) {
            return false;
          }
        }
      } else if (_minDiscount > 0) {
        return false;
      }

      if (!_matchesEntryPreset(promo)) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Apply sorting
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'recent':
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        
        case 'discount':
          final aDiscount = _extractDiscount(a.discount);
          final bDiscount = _extractDiscount(b.discount);
          return bDiscount.compareTo(aDiscount);
        
        case 'price_low':
          final aPrice = a.discountedPrice ?? a.price ?? a.originalPrice ?? double.infinity;
          final bPrice = b.discountedPrice ?? b.price ?? b.originalPrice ?? double.infinity;
          return aPrice.compareTo(bPrice);
        
        case 'price_high':
          final aPrice = a.discountedPrice ?? a.price ?? a.originalPrice ?? 0;
          final bPrice = b.discountedPrice ?? b.price ?? b.originalPrice ?? 0;
          return bPrice.compareTo(aPrice);
        
        case 'ending_soon':
          if (a.endDate == null && b.endDate == null) return 0;
          if (a.endDate == null) return 1;
          if (b.endDate == null) return -1;
          return a.endDate!.compareTo(b.endDate!);
        
        case 'distance':
          final aDist = a.distance ?? double.infinity;
          final bDist = b.distance ?? double.infinity;
          return aDist.compareTo(bDist);
        
        default:
          return 0;
      }
    });
    
    // Group by category - only add categories that have deals
    for (var promo in filtered) {
      final category = _normalizeCategory(promo.category);
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(promo);
    }
    
    // Remove empty categories (shouldn't happen but just in case)
    grouped.removeWhere((key, value) => value.isEmpty);
    
    return grouped;
  }

  bool _matchesEntryPreset(Promotion promo) {
    if (_activeSectionPreset == null) return true;

    final now = DateTime.now();
    switch (_activeSectionPreset) {
      case 'flash_sales':
        final cutoff = now.add(const Duration(hours: 24));
        return promo.endDate != null &&
            promo.endDate!.isAfter(now) &&
            promo.endDate!.isBefore(cutoff);
      case 'ending_soon':
        final endOfToday = DateTime(now.year, now.month, now.day + 1);
        return promo.endDate != null &&
            promo.endDate!.isAfter(now) &&
            promo.endDate!.isBefore(endOfToday);
      case 'new_this_week':
        final recentCutoff = now.subtract(const Duration(days: 7));
        final publishedAt = promo.createdAt ?? promo.startDate;
        return publishedAt != null && publishedAt.isAfter(recentCutoff);
      default:
        return true;
    }
  }
  
  double _extractDiscount(String? discount) {
    if (discount == null) return 0;
    final match = RegExp(r'(\d+)').firstMatch(discount);
    return match != null ? double.parse(match.group(1)!) : 0;
  }

  String _getCategoryName(String categoryId) {
    final category = predefinedCategories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => Category(id: 'other', name: 'Other'),
    );
    return category.name;
  }

  IconData _getCategoryIcon(String categoryId) {
    const iconMap = {
      'food_bev': Icons.restaurant,
      'electronics': Icons.devices,
      'fashion': Icons.checkroom,
      'travel': Icons.flight,
      'home_garden': Icons.home,
      'beauty_health': Icons.spa,
      'entertainment': Icons.movie,
      'services': Icons.build,
      'other': Icons.category,
    };
    return iconMap[categoryId] ?? Icons.category;
  }

  Color _getCategoryColor(String categoryId) {
    const colorMap = {
      'food_bev': Color(0xFFFF6B6B),
      'electronics': Color(0xFF4ECDC4),
      'fashion': Color(0xFFFFBE0B),
      'travel': Color(0xFF95E1D3),
      'home_garden': Color(0xFF38A3A5),
      'beauty_health': Color(0xFFFF6B9D),
      'entertainment': Color(0xFF9B59B6),
      'services': Color(0xFF3498DB),
      'other': Color(0xFF95A5A6),
    };
    return colorMap[categoryId] ?? const Color(0xFF95A5A6);
  }

  String get _screenTitle {
    if (_activeSectionPreset != null && widget.initialContextTitle != null) {
      return widget.initialContextTitle!;
    }
    if (_selectedCategory != null) {
      return _getCategoryName(_selectedCategory!);
    }
    return 'All Deals';
  }

  String? get _contextSubtitle {
    switch (_activeSectionPreset) {
      case 'flash_sales':
        return 'Showing quick-turn deals closing within the next day.';
      case 'ending_soon':
        return 'Showing the deals that are most likely to expire today.';
      case 'new_this_week':
        return 'Showing recently added deals so fresh offers stay easy to find.';
      default:
        return null;
    }
  }

  void _resetFilters({bool clearEntryContext = false}) {
    setState(() {
      _selectedCategory = clearEntryContext ? null : widget.initialCategoryId;
      _minPrice = 0;
      _maxPrice = 10000;
      _minDiscount = 0;
      _activeSectionPreset =
          clearEntryContext ? null : widget.initialSectionPreset;
      _sortBy = widget.initialSortBy ?? 'recent';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(_screenTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
            tooltip: 'Filters',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (value) {
              setState(() => _sortBy = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'recent',
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 20, color: _sortBy == 'recent' ? Theme.of(context).colorScheme.primary : null),
                    const SizedBox(width: 8),
                    Text('Most Recent', style: TextStyle(fontWeight: _sortBy == 'recent' ? FontWeight.bold : null)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'discount',
                child: Row(
                  children: [
                    Icon(Icons.percent, size: 20, color: _sortBy == 'discount' ? Theme.of(context).colorScheme.primary : null),
                    const SizedBox(width: 8),
                    Text('Highest Discount', style: TextStyle(fontWeight: _sortBy == 'discount' ? FontWeight.bold : null)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'price_low',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 20, color: _sortBy == 'price_low' ? Theme.of(context).colorScheme.primary : null),
                    const SizedBox(width: 8),
                    Text('Price: Low to High', style: TextStyle(fontWeight: _sortBy == 'price_low' ? FontWeight.bold : null)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'price_high',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 20, color: _sortBy == 'price_high' ? Theme.of(context).colorScheme.primary : null),
                    const SizedBox(width: 8),
                    Text('Price: High to Low', style: TextStyle(fontWeight: _sortBy == 'price_high' ? FontWeight.bold : null)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'ending_soon',
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 20, color: _sortBy == 'ending_soon' ? Theme.of(context).colorScheme.primary : null),
                    const SizedBox(width: 8),
                    Text('Ending Soon', style: TextStyle(fontWeight: _sortBy == 'ending_soon' ? FontWeight.bold : null)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'distance',
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 20, color: _sortBy == 'distance' ? Theme.of(context).colorScheme.primary : null),
                    const SizedBox(width: 8),
                    Text('Nearest', style: TextStyle(fontWeight: _sortBy == 'distance' ? FontWeight.bold : null)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Panel
          if (_showFilters)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_activeSectionPreset != null || widget.initialCategoryId != null)
                    _buildContextBanner(),
                  const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Category Filter
                  const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedCategory == null,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = null);
                        },
                      ),
                      ...predefinedCategories.map((cat) => FilterChip(
                        label: Text(cat.name),
                        selected: _selectedCategory == cat.id,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = selected ? cat.id : null);
                        },
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Price Range Filter
                  const Text('Price Range', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Min',
                            prefixText: 'Rs. ',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() => _minPrice = double.tryParse(value) ?? 0);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Max',
                            prefixText: 'Rs. ',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() => _maxPrice = double.tryParse(value) ?? 10000);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Discount Filter
                  Text('Minimum Discount: ${_minDiscount.toInt()}%', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Slider(
                    value: _minDiscount,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${_minDiscount.toInt()}%',
                    onChanged: (value) {
                      setState(() => _minDiscount = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  // Reset Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Clear filters'),
                      onPressed: () {
                        _resetFilters();
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          // Deals List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                await _refreshPromotions();
              },
              child: FutureBuilder<List<Promotion>>(
                future: _promotionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildShimmer();
                  } else if (snapshot.hasError) {
                    return _buildError();
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmpty();
                  }

                  final groupedDeals = _groupByCategory(snapshot.data!);
                  final totalDeals = groupedDeals.values.fold<int>(0, (sum, list) => sum + list.length);
                  
                  if (totalDeals == 0) {
                    return _buildNoMatchesState();
                  }
                  
                  return _buildCategoryList(groupedDeals, totalDeals);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextBanner() {
    final subtitle = _contextSubtitle;
    final hasPreset = _activeSectionPreset != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E4FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.auto_awesome_rounded,
                color: Color(0xFF1E5AA8), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPreset
                      ? '${widget.initialContextTitle ?? _screenTitle} view'
                      : 'Category filter applied',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF163A70),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF35537A),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => _resetFilters(clearEntryContext: true),
            child: Text(hasPreset ? 'Show all' : 'Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(Map<String, List<Promotion>> groupedDeals, int totalDeals) {
    final sortedCategories = groupedDeals.keys.toList()
      ..sort((a, b) => groupedDeals[b]!.length.compareTo(groupedDeals[a]!.length));

    return CustomScrollView(
      slivers: [
        // Stats header
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.local_offer, '$totalDeals', 'Total Deals'),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                _buildStatItem(Icons.category, '${sortedCategories.length}', 'Categories'),
              ],
            ),
          ),
        ),
        // Category sections
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final categoryId = sortedCategories[index];
                final deals = groupedDeals[categoryId]!;
                final categoryName = _getCategoryName(categoryId);
                return _buildCategorySection(categoryId, categoryName, deals, index);
              },
              childCount: sortedCategories.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(String categoryId, String categoryName, List<Promotion> deals, int index) {
    final displayDeals = deals.take(4).toList();
    final categoryColor = _getCategoryColor(categoryId);
    final categoryIcon = _getCategoryIcon(categoryId);
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    categoryColor.withValues(alpha: 0.1),
                    categoryColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(categoryIcon, color: categoryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${deals.length} deals available',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (deals.length > 2)
                    Material(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          final category = predefinedCategories.firstWhere(
                            (cat) => cat.id == categoryId,
                            orElse: () => Category(id: categoryId, name: categoryName),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DealsListScreen(
                                categoryFilter: category,
                                promotions: deals,
                                title: categoryName,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View More',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Deals List
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                itemCount: displayDeals.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 160,
                    margin: EdgeInsets.only(
                      right: index < displayDeals.length - 1 ? 12 : 0,
                    ),
                    child: ModernDealCard(
                      promotion: displayDeals[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DealDetailScreen(promotion: displayDeals[index]),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 150,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 50),
            const SizedBox(height: 10),
            const Text(
              'Failed to load deals',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _refreshPromotions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sentiment_dissatisfied, color: Colors.grey[600], size: 50),
          const SizedBox(height: 10),
          Text(
            'No deals available',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMatchesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              'No deals match this view',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF14213D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a broader category, adjust your price or discount filters, or clear filters to explore more deals.',
              style: TextStyle(
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
                FilledButton.tonalIcon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: const Text('Clear filters'),
                ),
                OutlinedButton.icon(
                  onPressed: _refreshPromotions,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
