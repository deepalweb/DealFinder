import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../models/promotion.dart';
import '../models/category.dart';
import '../utils/bank_card_promotion_support.dart';
import '../utils/deal_filter_support.dart';
import '../widgets/modern_deal_card.dart';
import 'deals_list_screen.dart';
import 'deal_detail_screen.dart';
import 'search_screen.dart';
import 'package:shimmer/shimmer.dart';

class AllDealsScreen extends StatefulWidget {
  final String? initialSortBy;
  final String? initialCategoryId;
  final String? initialSectionPreset;
  final String? initialContextTitle;
  final String? initialPrimaryFilter;
  final double? initialMinDiscount;

  const AllDealsScreen({
    super.key,
    this.initialSortBy,
    this.initialCategoryId,
    this.initialSectionPreset,
    this.initialContextTitle,
    this.initialPrimaryFilter,
    this.initialMinDiscount,
  });

  @override
  State<AllDealsScreen> createState() => _AllDealsScreenState();
}

class _AllDealsScreenState extends State<AllDealsScreen> {
  static const String primaryUnder1km = 'under_1km';
  static const String primaryHalfOff = 'half_off';
  static const String primaryEndingSoon = 'ending_soon';
  static const String primaryNewDeals = 'new_deals';
  static const String primaryBankCards = 'bank_cards';
  static const double _defaultMaxPrice = double.infinity;

  late Future<List<Promotion>> _promotionsFuture;
  final ApiService _apiService = ApiService();

  // Sort and Filter state
  String _sortBy =
      'recent'; // recent, discount, price_low, price_high, ending_soon, distance
  double _minPrice = 0;
  double _maxPrice = _defaultMaxPrice;
  double _minDiscount = 0;
  String? _selectedCategory;
  String? _selectedCapabilityPresetId;
  String? _activeSectionPreset;
  String? _activePrimaryFilter;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.initialSortBy ?? _sortBy;
    _selectedCategory = widget.initialCategoryId;
    _activeSectionPreset = widget.initialSectionPreset;
    _activePrimaryFilter = widget.initialPrimaryFilter;
    _minDiscount = widget.initialMinDiscount ?? _minDiscount;
    _loadPromotions();
  }

  void _loadPromotions() {
    setState(() {
      _promotionsFuture =
          _fetchPromotionsWithDistance(forceRefresh: false).then((promotions) {
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

  String _effectiveCategory(Promotion promotion) {
    return BankCardPromotionSupport.effectiveCategoryId(promotion);
  }

  bool get _hasMaxPriceFilter => _maxPrice.isFinite;

  List<Promotion> _filteredPromotions(List<Promotion> promotions) {
    final filtered = promotions.where((promo) {
      final normalizedCategory = _effectiveCategory(promo);
      if (_selectedCategory != null &&
          normalizedCategory != _selectedCategory) {
        return false;
      }

      if (_selectedCapabilityPresetId != null &&
          !matchesDealCapabilityPreset(promo, _selectedCapabilityPresetId!)) {
        return false;
      }

      final price =
          promo.discountedPrice ?? promo.price ?? promo.originalPrice ?? 0;
      if (price < _minPrice || price > _maxPrice) {
        return false;
      }

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

      if (!_matchesPrimaryFilter(promo)) {
        return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      final primaryCompare = _comparePrimaryFilterOrder(a, b);
      if (primaryCompare != 0) return primaryCompare;

      switch (_sortBy) {
        case 'recent':
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        case 'discount':
          return _extractDiscount(b.discount).compareTo(
            _extractDiscount(a.discount),
          );
        case 'price_low':
          final aPrice = a.discountedPrice ??
              a.price ??
              a.originalPrice ??
              double.infinity;
          final bPrice = b.discountedPrice ??
              b.price ??
              b.originalPrice ??
              double.infinity;
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
          return (a.distance ?? double.infinity).compareTo(
            b.distance ?? double.infinity,
          );
        default:
          return 0;
      }
    });

    return filtered;
  }

  Map<String, List<Promotion>> _groupByCategory(List<Promotion> promotions) {
    final Map<String, List<Promotion>> grouped = {};
    final filtered = _filteredPromotions(promotions);

    // Group by category - only add categories that have deals
    for (var promo in filtered) {
      final category = _effectiveCategory(promo);
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

  bool _matchesPrimaryFilter(Promotion promo) {
    final now = DateTime.now();

    switch (_activePrimaryFilter) {
      case primaryUnder1km:
        return promo.distance != null && promo.distance! <= 1000;
      case primaryHalfOff:
        return _discountSignal(promo) >= 50;
      case primaryBankCards:
        return BankCardPromotionSupport.isBankCardPromotion(promo);
      case primaryEndingSoon:
        final cutoff = now.add(const Duration(hours: 48));
        return promo.endDate != null &&
            promo.endDate!.isAfter(now) &&
            promo.endDate!.isBefore(cutoff);
      case primaryNewDeals:
        final recentCutoff = now.subtract(const Duration(days: 7));
        final publishedAt = promo.createdAt ?? promo.startDate;
        return publishedAt != null && publishedAt.isAfter(recentCutoff);
      default:
        return true;
    }
  }

  int _comparePrimaryFilterOrder(Promotion a, Promotion b) {
    switch (_activePrimaryFilter) {
      case primaryUnder1km:
        return (a.distance ?? double.infinity).compareTo(
          b.distance ?? double.infinity,
        );
      case primaryHalfOff:
        return _discountSignal(b).compareTo(_discountSignal(a));
      case primaryBankCards:
        final bankCompare =
            (BankCardPromotionSupport.bankName(a) ?? '').compareTo(
          BankCardPromotionSupport.bankName(b) ?? '',
        );
        if (bankCompare != 0) return bankCompare;
        return _discountSignal(b).compareTo(_discountSignal(a));
      case primaryEndingSoon:
        if (a.endDate == null && b.endDate == null) return 0;
        if (a.endDate == null) return 1;
        if (b.endDate == null) return -1;
        return a.endDate!.compareTo(b.endDate!);
      case primaryNewDeals:
        final aDate = a.createdAt ?? a.startDate;
        final bDate = b.createdAt ?? b.startDate;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      default:
        return 0;
    }
  }

  double _extractDiscount(String? discount) {
    if (discount == null) return 0;
    final match = RegExp(r'(\d+)').firstMatch(discount);
    return match != null ? double.parse(match.group(1)!) : 0;
  }

  double _discountSignal(Promotion promo) {
    final structured = promo.discountPercentage;
    if (structured != null) return structured.toDouble();
    return _extractDiscount(promo.discount);
  }

  bool _hasDirections(Promotion promotion) {
    return (promotion.latitude != null && promotion.longitude != null) ||
        (promotion.location?.trim().isNotEmpty ?? false);
  }

  Future<void> _openDirectionsFor(Promotion promotion) async {
    String? url;
    if (promotion.latitude != null && promotion.longitude != null) {
      url =
          'https://www.google.com/maps/dir/?api=1&destination=${promotion.latitude},${promotion.longitude}';
    } else if (promotion.location != null &&
        promotion.location!.trim().isNotEmpty) {
      final query = Uri.encodeComponent(promotion.location!.trim());
      url = 'https://www.google.com/maps/dir/?api=1&destination=$query';
    }

    if (url == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location available for this deal.')),
      );
      return;
    }

    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
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
      'food_dining': Icons.restaurant,
      'beauty_salon': Icons.content_cut,
      'repairs_services': Icons.build,
      'electronics': Icons.devices_rounded,
      'bank_cards': Icons.credit_card_rounded,
      'shopping_retail': Icons.shopping_bag,
      'health_wellness': Icons.favorite,
      'daily_essentials': Icons.local_grocery_store,
      'auto_services': Icons.directions_car,
      'education_courses': Icons.school,
      'entertainment_activities': Icons.movie,
      'other': Icons.category,
    };
    return iconMap[categoryId] ?? Icons.category;
  }

  Color _getCategoryColor(String categoryId) {
    const colorMap = {
      'food_dining': Color(0xFFFF6B6B),
      'beauty_salon': Color(0xFFFF6B9D),
      'repairs_services': Color(0xFF3498DB),
      'electronics': Color(0xFF06B6D4),
      'bank_cards': Color(0xFF0F4C81),
      'shopping_retail': Color(0xFFFFBE0B),
      'health_wellness': Color(0xFF10B981),
      'daily_essentials': Color(0xFF38A3A5),
      'auto_services': Color(0xFF6366F1),
      'education_courses': Color(0xFF8B5CF6),
      'entertainment_activities': Color(0xFF9B59B6),
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
        if (_selectedCategory == BankCardPromotionSupport.categoryId ||
            _activePrimaryFilter == primaryBankCards) {
          return 'Showing bank card promotions, cashback offers, and installment deals.';
        }
        return null;
    }
  }

  void _resetFilters({bool clearEntryContext = false}) {
    setState(() {
      _selectedCategory = clearEntryContext ? null : widget.initialCategoryId;
      _selectedCapabilityPresetId = null;
      _activePrimaryFilter = null;
      _minPrice = 0;
      _maxPrice = _defaultMaxPrice;
      _minDiscount = 0;
      _activeSectionPreset =
          clearEntryContext ? null : widget.initialSectionPreset;
      _sortBy = widget.initialSortBy ?? 'recent';
    });
  }

  Future<void> _openFilterSheet() async {
    final minController = TextEditingController(
      text: _minPrice > 0 ? _minPrice.toInt().toString() : '',
    );
    final maxController = TextEditingController(
      text: _hasMaxPriceFilter ? _maxPrice.toInt().toString() : '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_activeSectionPreset != null ||
                          widget.initialCategoryId != null)
                        _buildContextBanner(),
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF14213D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Use quick filters or narrow the price range to refine what you see.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Quick filters',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: dealCapabilityPresets
                            .map(
                              (preset) => FilterChip(
                                avatar: Icon(preset.icon, size: 18),
                                label: Text(preset.label),
                                selected:
                                    _selectedCapabilityPresetId == preset.id,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCapabilityPresetId =
                                        selected ? preset.id : null;
                                  });
                                  setSheetState(() {});
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 18),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 12),
                        title: const Text(
                          'Categories',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          _selectedCategory == null
                              ? 'Optional'
                              : _getCategoryName(_selectedCategory!),
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilterChip(
                                  label: const Text('All'),
                                  selected: _selectedCategory == null,
                                  onSelected: (_) {
                                    setState(() => _selectedCategory = null);
                                    setSheetState(() {});
                                  },
                                ),
                                ...predefinedCategories.map(
                                  (cat) => FilterChip(
                                    label: Text(cat.name),
                                    selected: _selectedCategory == cat.id,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCategory =
                                            selected ? cat.id : null;
                                      });
                                      setSheetState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Price range',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minController,
                              decoration: const InputDecoration(
                                labelText: 'Min',
                                prefixText: 'Rs. ',
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  _minPrice = double.tryParse(value) ?? 0;
                                });
                                setSheetState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: maxController,
                              decoration: const InputDecoration(
                                labelText: 'Max',
                                prefixText: 'Rs. ',
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  _maxPrice = double.tryParse(value) ??
                                      _defaultMaxPrice;
                                });
                                setSheetState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Minimum Discount: ${_minDiscount.toInt()}%',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Slider(
                        value: _minDiscount,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        label: '${_minDiscount.toInt()}%',
                        onChanged: (value) {
                          setState(() => _minDiscount = value);
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Clear filters'),
                              onPressed: () {
                                _resetFilters();
                                minController.clear();
                                maxController.clear();
                                setSheetState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Done'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    minController.dispose();
    maxController.dispose();
  }

  bool get _hasActiveUserFilters {
    return _selectedCategory != widget.initialCategoryId ||
        _selectedCapabilityPresetId != null ||
        _activePrimaryFilter != null ||
        _minPrice > 0 ||
        _hasMaxPriceFilter ||
        _minDiscount > 0 ||
        _sortBy != (widget.initialSortBy ?? 'recent');
  }

  List<Widget> _buildActiveFilterChips() {
    final chips = <Widget>[];
    final selectedCapability =
        findDealCapabilityPreset(_selectedCapabilityPresetId);

    if (_selectedCategory != null) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.category_outlined, size: 16),
          label: Text(_getCategoryName(_selectedCategory!)),
          onDeleted: () => setState(() => _selectedCategory = null),
        ),
      );
    }

    if (selectedCapability != null) {
      chips.add(
        InputChip(
          avatar: Icon(selectedCapability.icon, size: 16),
          label: Text(selectedCapability.label),
          onDeleted: () => setState(() => _selectedCapabilityPresetId = null),
        ),
      );
    }

    if (_activePrimaryFilter != null) {
      chips.add(
        InputChip(
          avatar: Icon(_primaryFilterIcon(_activePrimaryFilter!), size: 16),
          label: Text(_primaryFilterLabel(_activePrimaryFilter!)),
          onDeleted: () => setState(() => _activePrimaryFilter = null),
        ),
      );
    }

    if (_minPrice > 0 || _hasMaxPriceFilter) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.payments_outlined, size: 16),
          label: Text(_hasMaxPriceFilter
              ? 'Rs. ${_minPrice.toInt()} - Rs. ${_maxPrice.toInt()}'
              : 'Rs. ${_minPrice.toInt()}+'),
          onDeleted: () {
            setState(() {
              _minPrice = 0;
              _maxPrice = _defaultMaxPrice;
            });
          },
        ),
      );
    }

    if (_minDiscount > 0) {
      chips.add(
        InputChip(
          avatar: const Icon(Icons.percent_rounded, size: 16),
          label: Text('${_minDiscount.toInt()}%+ off'),
          onDeleted: () => setState(() => _minDiscount = 0),
        ),
      );
    }

    return chips;
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
            icon: Icon(
              _hasActiveUserFilters
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
            onPressed: _openFilterSheet,
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
                    Icon(Icons.access_time,
                        size: 20,
                        color: _sortBy == 'recent'
                            ? Theme.of(context).colorScheme.primary
                            : null),
                    const SizedBox(width: 8),
                    Text('Most Recent',
                        style: TextStyle(
                            fontWeight:
                                _sortBy == 'recent' ? FontWeight.bold : null)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'discount',
                child: Row(
                  children: [
                    Icon(Icons.percent,
                        size: 20,
                        color: _sortBy == 'discount'
                            ? Theme.of(context).colorScheme.primary
                            : null),
                    const SizedBox(width: 8),
                    Text('Highest Discount',
                        style: TextStyle(
                            fontWeight: _sortBy == 'discount'
                                ? FontWeight.bold
                                : null)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'price_low',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward,
                        size: 20,
                        color: _sortBy == 'price_low'
                            ? Theme.of(context).colorScheme.primary
                            : null),
                    const SizedBox(width: 8),
                    Text('Price: Low to High',
                        style: TextStyle(
                            fontWeight: _sortBy == 'price_low'
                                ? FontWeight.bold
                                : null)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'price_high',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward,
                        size: 20,
                        color: _sortBy == 'price_high'
                            ? Theme.of(context).colorScheme.primary
                            : null),
                    const SizedBox(width: 8),
                    Text('Price: High to Low',
                        style: TextStyle(
                            fontWeight: _sortBy == 'price_high'
                                ? FontWeight.bold
                                : null)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'ending_soon',
                child: Row(
                  children: [
                    Icon(Icons.schedule,
                        size: 20,
                        color: _sortBy == 'ending_soon'
                            ? Theme.of(context).colorScheme.primary
                            : null),
                    const SizedBox(width: 8),
                    Text('Ending Soon',
                        style: TextStyle(
                            fontWeight: _sortBy == 'ending_soon'
                                ? FontWeight.bold
                                : null)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'distance',
                child: Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 20,
                        color: _sortBy == 'distance'
                            ? Theme.of(context).colorScheme.primary
                            : null),
                    const SizedBox(width: 8),
                    Text('Nearest',
                        style: TextStyle(
                            fontWeight: _sortBy == 'distance'
                                ? FontWeight.bold
                                : null)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPrimaryFilterBar(),
          if (_hasActiveUserFilters)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.filter_alt_outlined,
                        size: 18,
                        color: Color(0xFF475569),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Active filters',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _resetFilters,
                        child: const Text('Clear all'),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _buildActiveFilterChips(),
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
                  final totalDeals = groupedDeals.values
                      .fold<int>(0, (sum, list) => sum + list.length);

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

  Widget _buildPrimaryFilterBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildPrimaryFilterChip(
              id: primaryEndingSoon,
              label: 'Ending Soon',
              icon: Icons.hourglass_bottom_rounded,
            ),
            const SizedBox(width: 8),
            _buildPrimaryFilterChip(
              id: primaryUnder1km,
              label: 'Under 1km',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(width: 8),
            _buildPrimaryFilterChip(
              id: primaryHalfOff,
              label: '50%+ OFF',
              icon: Icons.local_offer_outlined,
            ),
            const SizedBox(width: 8),
            _buildPrimaryFilterChip(
              id: primaryBankCards,
              label: 'Bank Cards',
              icon: Icons.credit_card_rounded,
            ),
            const SizedBox(width: 8),
            _buildPrimaryFilterChip(
              id: primaryNewDeals,
              label: 'New Deals',
              icon: Icons.auto_awesome_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryFilterChip({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final selected = _activePrimaryFilter == id;
    return FilterChip(
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? Colors.white : const Color(0xFF2563EB),
      ),
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF0F172A),
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: const Color(0xFFF3F7FF),
      selectedColor: const Color(0xFF2563EB),
      side: BorderSide(
        color: selected ? const Color(0xFF2563EB) : const Color(0xFFD8E4FB),
      ),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _activePrimaryFilter = selected ? null : id;
        });
      },
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }

  String _primaryFilterLabel(String id) {
    switch (id) {
      case primaryUnder1km:
        return 'Under 1km';
      case primaryHalfOff:
        return '50%+ OFF';
      case primaryBankCards:
        return 'Bank Cards';
      case primaryEndingSoon:
        return 'Ending Soon';
      case primaryNewDeals:
        return 'New Deals';
      default:
        return id;
    }
  }

  IconData _primaryFilterIcon(String id) {
    switch (id) {
      case primaryUnder1km:
        return Icons.location_on_outlined;
      case primaryHalfOff:
        return Icons.local_offer_outlined;
      case primaryBankCards:
        return Icons.credit_card_rounded;
      case primaryEndingSoon:
        return Icons.hourglass_bottom_rounded;
      case primaryNewDeals:
        return Icons.auto_awesome_outlined;
      default:
        return Icons.filter_alt_outlined;
    }
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

  Widget _buildCategoryList(
      Map<String, List<Promotion>> groupedDeals, int totalDeals) {
    final sortedCategories = groupedDeals.keys.toList()
      ..sort(
          (a, b) => groupedDeals[b]!.length.compareTo(groupedDeals[a]!.length));
    final curatedSections = _buildCuratedSections(groupedDeals);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildExploreHero(totalDeals, sortedCategories.length),
              if (curatedSections.isNotEmpty)
                ...curatedSections
                    .map(
                      (section) => _buildCuratedSection(
                        title: section.title,
                        subtitle: section.subtitle,
                        icon: section.icon,
                        promotions: section.promotions,
                      ),
                    )
                    .toList(),
              _buildCompactSummary(totalDeals, sortedCategories.length),
            ],
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 112 + bottomInset),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final categoryId = sortedCategories[index];
                final deals = groupedDeals[categoryId]!;
                final categoryName = _getCategoryName(categoryId);
                return _buildCategorySection(
                    categoryId, categoryName, deals, index);
              },
              childCount: sortedCategories.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExploreHero(int totalDeals, int totalCategories) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F4C81),
            Color(0xFF2563EB),
            Color(0xFF5EA6FF),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.explore_rounded, color: Colors.white, size: 15),
                    SizedBox(width: 6),
                    Text(
                      'Explore smarter',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '$totalDeals deals',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Discover what is worth opening first',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jump into urgent deals, nearby offers, and popular categories without digging through every section.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: Color(0xFF2563EB)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search products, stores, food, or card offers',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeroShortcut(
                label: 'Ending Soon',
                icon: Icons.hourglass_bottom_rounded,
                onTap: () => setState(() => _activePrimaryFilter =
                    _activePrimaryFilter == primaryEndingSoon
                        ? null
                        : primaryEndingSoon),
              ),
              _buildHeroShortcut(
                label: 'Under 1km',
                icon: Icons.near_me_rounded,
                onTap: () => setState(() => _activePrimaryFilter =
                    _activePrimaryFilter == primaryUnder1km
                        ? null
                        : primaryUnder1km),
              ),
              _buildHeroShortcut(
                label: '50%+ Off',
                icon: Icons.local_offer_outlined,
                onTap: () => setState(() => _activePrimaryFilter =
                    _activePrimaryFilter == primaryHalfOff
                        ? null
                        : primaryHalfOff),
              ),
              _buildHeroShortcut(
                label: '$totalCategories categories',
                icon: Icons.grid_view_rounded,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroShortcut({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSummary(int totalDeals, int totalCategories) {
    final topLabel = _selectedCategory != null
        ? _getCategoryName(_selectedCategory!)
        : 'All categories';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.insights_rounded,
            color: Color(0xFF2563EB),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$totalDeals deals across $totalCategories categories • $topLabel',
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!_hasActiveUserFilters)
            const Text(
              'Live',
              style: TextStyle(
                color: Color(0xFF0F766E),
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }

  List<_CuratedSectionData> _buildCuratedSections(
      Map<String, List<Promotion>> groupedDeals) {
    final allDeals = groupedDeals.values.expand((deals) => deals).toList();
    final sections = <_CuratedSectionData>[];

    final now = DateTime.now();
    final endingSoon = List<Promotion>.from(allDeals)
      ..retainWhere((p) {
        final cutoff = now.add(const Duration(hours: 48));
        return p.endDate != null &&
            p.endDate!.isAfter(now) &&
            p.endDate!.isBefore(cutoff);
      })
      ..sort((a, b) => (a.endDate ?? DateTime(9999))
          .compareTo(b.endDate ?? DateTime(9999)));

    final nearby = List<Promotion>.from(allDeals)
      ..retainWhere((p) => p.distance != null)
      ..sort((a, b) => (a.distance ?? double.infinity)
          .compareTo(b.distance ?? double.infinity));

    final bigDiscounts = List<Promotion>.from(allDeals)
      ..retainWhere((p) => _discountSignal(p) >= 40)
      ..sort((a, b) => _discountSignal(b).compareTo(_discountSignal(a)));

    void addSection(
      String title,
      String subtitle,
      IconData icon,
      List<Promotion> promotions,
    ) {
      final top = promotions.take(6).toList();
      if (top.length >= 2) {
        sections.add(
          _CuratedSectionData(
            title: title,
            subtitle: subtitle,
            icon: icon,
            promotions: top,
          ),
        );
      }
    }

    addSection(
      'Ending Soon',
      'Catch expiring deals before they disappear.',
      Icons.schedule_rounded,
      endingSoon,
    );
    addSection(
      'Near You',
      'Closest deals first when distance is available.',
      Icons.near_me_rounded,
      nearby,
    );
    addSection(
      'Big Savings',
      'The strongest discounts right now.',
      Icons.local_fire_department_outlined,
      bigDiscounts,
    );

    return sections.take(2).toList();
  }

  Widget _buildCuratedSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Promotion> promotions,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF14213D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 308,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: promotions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final promotion = promotions[index];
                return SizedBox(
                  width: 184,
                  child: ModernDealCard(
                    promotion: promotion,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DealDetailScreen(promotion: promotion),
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
    );
  }

  Widget _buildCategorySection(String categoryId, String categoryName,
      List<Promotion> deals, int index) {
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
          margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${deals.length} deals available',
                          style: TextStyle(
                            fontSize: 12.5,
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
                            orElse: () =>
                                Category(id: categoryId, name: categoryName),
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
                          padding:
                              EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                              Icon(Icons.arrow_forward,
                                  color: Colors.white, size: 16),
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
              height: 308,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                itemCount: displayDeals.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 184,
                    margin: EdgeInsets.only(
                      right: index < displayDeals.length - 1 ? 12 : 0,
                    ),
                    child: ModernDealCard(
                      promotion: displayDeals[index],
                      onPrimaryAction: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DealDetailScreen(
                                promotion: displayDeals[index]),
                          ),
                        );
                      },
                      onSecondaryAction: _hasDirections(displayDeals[index])
                          ? () => _openDirectionsFor(displayDeals[index])
                          : null,
                      secondaryActionLabel: _hasDirections(displayDeals[index])
                          ? 'Directions'
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DealDetailScreen(
                                promotion: displayDeals[index]),
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
              height: 308,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Container(
                    width: 184,
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

class _CuratedSectionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Promotion> promotions;

  const _CuratedSectionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.promotions,
  });
}
