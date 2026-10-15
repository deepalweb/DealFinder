import '../config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../models/promotion.dart';
import '../models/category.dart';
import '../utils/bank_card_promotion_support.dart';
import '../utils/deal_filter_support.dart';
import '../widgets/discover_marketplace_card.dart';
import '../utils/offer_presentation.dart';
import '../services/browsing_area.dart';
import 'deal_detail_screen.dart';
import 'package:shimmer/shimmer.dart';

class AllDealsScreen extends StatefulWidget {
  final String? initialCapabilityPresetId;
  final String? initialSortBy;
  final String? initialCategoryId;
  final String? initialSectionPreset;
  final String? initialContextTitle;
  final String? initialPrimaryFilter;
  final double? initialMinDiscount;
  final bool bankOffersOnly;
  final String? initialBankName;
  final ApiService? api;

  const AllDealsScreen({
    super.key,
    this.initialCapabilityPresetId,
    this.initialSortBy,
    this.initialCategoryId,
    this.initialSectionPreset,
    this.initialContextTitle,
    this.initialPrimaryFilter,
    this.initialMinDiscount,
    this.bankOffersOnly = false,
    this.initialBankName,
    this.api,
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
  late final ApiService _apiService = widget.api ?? ApiService();
  List<Promotion> _loaded = [];
  bool _hasMore = false, _paging = false, _pageError = false;
  int _offset = 50, _bankOffset = 50;
  bool _morePromotions = false, _moreBanks = false;
  String? _bank, _card;
  int _request = 0;
  Future<void> _nextPage() async {
    if (_paging) return;
    final request = _request;
    setState(() => _paging = true);
    try {
      final promotionRows = _morePromotions
          ? await _apiService.fetchPromotionPage(skip: _offset)
          : <Promotion>[];
      final bankRows = _moreBanks
          ? await _apiService.fetchBankOfferPage(skip: _bankOffset)
          : <Promotion>[];
      final rows = [...promotionRows, ...bankRows];
      if (!mounted || request != _request) return;
      final known = _loaded.map((p) => OfferPresentation(p).identity).toSet();
      final area = await BrowsingArea.read();
      if (!mounted || request != _request) return;
      setState(() {
        _loaded.addAll(rows
            .where((p) => known.add(OfferPresentation(p).identity))
            .map((p) => area == null ||
                    p.latitude == null ||
                    p.longitude == null ||
                    OfferPresentation(p).onlineOnly
                ? p
                : p.copyWith(
                    distance: LocationService.calculateDistance(area.latitude,
                            area.longitude, p.latitude!, p.longitude!) *
                        1000)));
        _offset += promotionRows.length;
        _bankOffset += bankRows.length;
        _morePromotions = _morePromotions && promotionRows.length == 50;
        _moreBanks = _moreBanks && bankRows.length == 50;
        _hasMore = _morePromotions || _moreBanks;
        _pageError = false;
        _promotionsFuture = Future.value(List.of(_loaded));
      });
    } catch (_) {
      if (mounted && request == _request) setState(() => _pageError = true);
    } finally {
      if (mounted && request == _request) setState(() => _paging = false);
    }
  }

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

  String _t(String en, String si, String ta) {
    final code = Localizations.localeOf(context).languageCode;
    if (code == 'si') return si;
    if (code == 'ta') return ta;
    return en;
  }

  @override
  void initState() {
    super.initState();
    _sortBy = widget.initialSortBy ?? _sortBy;
    _selectedCategory = widget.initialCategoryId;
    _bank = widget.initialBankName;
    _selectedCapabilityPresetId = widget.initialCapabilityPresetId;
    _activeSectionPreset = widget.initialSectionPreset;
    _activePrimaryFilter = widget.initialPrimaryFilter;
    _minDiscount = widget.initialMinDiscount ?? _minDiscount;
    _loadPromotions();
  }

  void _loadPromotions() {
    _promotionsFuture = _fetchPromotionsWithDistance(forceRefresh: false);
  }

  Future<void> _refreshPromotions() async {
    final future = _fetchPromotionsWithDistance(forceRefresh: true);
    setState(() => _promotionsFuture = future);
    await future;
  }

  Future<List<Promotion>> _fetchPromotionsWithDistance({
    required bool forceRefresh,
  }) async {
    final request = ++_request;
    final fetched =
        await _apiService.fetchPromotions(forceRefresh: forceRefresh);
    if (request == _request) {
      _loaded = List.of(fetched);
      _offset = 50;
      _morePromotions = _apiService.lastPromotionPageHasMore ??
          (fetched.where((p) => !OfferPresentation(p).standaloneBank).length >=
              50);
      _moreBanks = _apiService.lastBankOfferPageHasMore ??
          (fetched.where((p) => OfferPresentation(p).standaloneBank).length >=
              50);
      _bankOffset = 50;
      _hasMore = _morePromotions || _moreBanks;
      _paging = false;
    }

    final promotions = fetched;
    final area = await BrowsingArea.read();
    final result = promotions.map((promotion) {
      if (area == null ||
          promotion.latitude == null ||
          promotion.longitude == null ||
          OfferPresentation(promotion).onlineOnly) {
        return promotion;
      }
      return promotion.copyWith(
          distance: LocationService.calculateDistance(area.latitude,
                  area.longitude, promotion.latitude!, promotion.longitude!) *
              1000);
    }).toList();
    if (request == _request) _loaded = List.of(result);
    return result;
  }

  String _effectiveCategory(Promotion promotion) {
    return BankCardPromotionSupport.effectiveCategoryId(promotion);
  }

  bool get _hasMaxPriceFilter => _maxPrice.isFinite;

  List<Promotion> _filteredPromotions(List<Promotion> promotions) {
    final filtered = promotions.where((promo) {
      if (!OfferPresentation(promo).public) return false;
      if (widget.bankOffersOnly &&
          !BankCardPromotionSupport.isBankCardPromotion(promo)) {
        return false;
      }
      if (widget.bankOffersOnly && _bank != null && promo.bankName != _bank) {
        return false;
      }
      if (widget.bankOffersOnly &&
          _card != null &&
          !promo.cardTypes.contains(_card)) {
        return false;
      }
      if (_selectedCategory != null &&
          !BankCardPromotionSupport.matchesCategory(
              promo, _selectedCategory!)) {
        return false;
      }

      if (_selectedCapabilityPresetId != null &&
          !matchesDealCapabilityPreset(promo, _selectedCapabilityPresetId!)) {
        return false;
      }

      final price = OfferPresentation(promo).price;
      if ((_minPrice > 0 || _hasMaxPriceFilter) &&
          (price == null || price < _minPrice || price > _maxPrice)) {
        return false;
      }

      if (OfferPresentation(promo).percentage < _minDiscount) return false;

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
          return b.latestActivityAt.compareTo(a.latestActivityAt);
        case 'discount':
          return OfferPresentation(b)
              .percentage
              .compareTo(OfferPresentation(a).percentage);
        case 'highest_rated':
          final ratingCompare =
              (b.averageRating ?? 0).compareTo(a.averageRating ?? 0);
          if (ratingCompare != 0) return ratingCompare;
          return b.ratingsCount.compareTo(a.ratingsCount);
        case 'price_low':
          return (OfferPresentation(a).price ?? double.infinity)
              .compareTo(OfferPresentation(b).price ?? double.infinity);
        case 'price_high':
          return (OfferPresentation(b).price ?? -1)
              .compareTo(OfferPresentation(a).price ?? -1);
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
    final match =
        RegExp(r'^(?:up to\s+)?(\d+(?:\.\d+)?)\s*%', caseSensitive: false)
            .firstMatch(discount.trim());
    return match != null ? double.parse(match.group(1)!) : 0;
  }

  double _discountSignal(Promotion promo) {
    final structured = promo.discountPercentage;
    if (structured != null) return structured.toDouble();
    return _extractDiscount(promo.discount);
  }

  String _getCategoryName(String categoryId) {
    final category = predefinedCategories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => Category(id: 'other', name: 'Other'),
    );
    return category.name;
  }

  String get _screenTitle {
    if (widget.bankOffersOnly) {
      return widget.initialBankName ??
          AppLocalizations.of(context)!.bankOffersTab;
    }
    if (_activeSectionPreset != null && widget.initialContextTitle != null) {
      return widget.initialContextTitle!;
    }
    if (_selectedCategory != null) {
      return _getCategoryName(_selectedCategory!);
    }
    return _t('All Deals', 'සියලු ඩීල්', 'அனைத்து சலுகைகள்');
  }

  String? get _contextSubtitle {
    switch (_activeSectionPreset) {
      case 'flash_sales':
        return _t(
            'Showing quick-turn deals closing within the next day.',
            'ඊළඟ දවස ඇතුළත අවසන් වන ඉක්මන් ඩීල් පෙන්වයි.',
            'அடுத்த நாளுக்குள் முடியும் விரைவு சலுகைகள் காட்டப்படுகின்றன.');
      case 'ending_soon':
        return _t(
            'Showing the deals that are most likely to expire today.',
            'අද කල් ඉකුත් වීමට වැඩි ඉඩක් ඇති ඩීල් පෙන්වයි.',
            'இன்று காலாவதியாக அதிக வாய்ப்புள்ள சலுகைகள் காட்டப்படுகின்றன.');
      case 'new_this_week':
        return _t(
            'Showing recently added deals so fresh offers stay easy to find.',
            'අලුතින් එක් කළ ඩීල් පෙන්වමින් නව දීමනා පහසුවෙන් සොයාගත හැක.',
            'புதிய சலுகைகளை எளிதாக காண சமீபத்தில் சேர்க்கப்பட்ட சலுகைகள் காட்டப்படுகின்றன.');
      default:
        if (_selectedCategory == BankCardPromotionSupport.categoryId ||
            _activePrimaryFilter == primaryBankCards) {
          return _t(
              'Showing bank card promotions, cashback offers, and installment deals.',
              'බැංකු කාඩ් ප්‍රවර්ධන, මුදල් ආපසු දීමනා සහ වාරික ඩීල් පෙන්වයි.',
              'வங்கி அட்டை சலுகைகள், கேஷ்பேக் சலுகைகள், மற்றும் தவணை ஒப்பந்தங்கள் காட்டப்படுகின்றன.');
        }
        return null;
    }
  }

  void _resetFilters({bool clearEntryContext = false}) {
    setState(() {
      _selectedCategory = clearEntryContext ? null : widget.initialCategoryId;
      _selectedCapabilityPresetId = null;
      _bank = null;
      _card = null;
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
                      Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use quick filters or narrow the price range to refine what you see.',
                        style: TextStyle(
                          color: AppColors.muted(context),
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
    final l10n = AppLocalizations.of(context)!;
    final activeFilterChips = _buildActiveFilterChips();
    return Scaffold(
      backgroundColor: AppColors.canvas(context),
      appBar: AppBar(
        title: Text(_screenTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: AppColors.card(context),
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        actions: [
          IconButton(
            icon: Icon(
              _hasActiveUserFilters
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
            onPressed: _openFilterSheet,
            tooltip: l10n.filtersTitle,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: l10n.sortByTitle,
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
                    Text(l10n.mostRecent,
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
                    Text(l10n.highestDiscount,
                        style: TextStyle(
                            fontWeight: _sortBy == 'discount'
                                ? FontWeight.bold
                                : null)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'highest_rated',
                child: Row(
                  children: [
                    Icon(Icons.star_rounded,
                        size: 20,
                        color: _sortBy == 'highest_rated'
                            ? Theme.of(context).colorScheme.primary
                            : null),
                    const SizedBox(width: 8),
                    Text('Top Rated',
                        style: TextStyle(
                            fontWeight: _sortBy == 'highest_rated'
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
                    Text(l10n.priceLowToHigh,
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
                    Text(l10n.priceHighToLow,
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
                    Text(l10n.endingSoonLabel,
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
                    Text(l10n.nearest,
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
          if (!widget.bankOffersOnly) _buildPrimaryFilterBar(),
          if (_hasActiveUserFilters)
            Container(
              width: double.infinity,
              color: AppColors.card(context),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.filter_alt_outlined,
                        size: 18,
                        color: AppColors.muted(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.activeFiltersLabel(activeFilterChips.length),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.text(context),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _resetFilters,
                        child: Text(l10n.clearAll),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: activeFilterChips,
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
                  } else if ((!snapshot.hasData || snapshot.data!.isEmpty) &&
                      !_hasMore) {
                    return _buildEmpty();
                  }

                  final groupedDeals = _groupByCategory(snapshot.data!);
                  final totalDeals = groupedDeals.values
                      .fold<int>(0, (sum, list) => sum + list.length);

                  if (totalDeals == 0) {
                    return ListView(children: [
                      _buildNoMatchesState(),
                      if (_hasMore || _pageError)
                        Padding(
                            padding: const EdgeInsets.all(16),
                            child: OutlinedButton(
                                onPressed: _paging ? null : _nextPage,
                                child: Text(_paging
                                    ? '…'
                                    : _pageError
                                        ? AppLocalizations.of(context)!.retry
                                        : AppLocalizations.of(context)!
                                            .allDeals)))
                    ]);
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
      color: AppColors.card(context),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildPrimaryFilterChip(
              id: primaryEndingSoon,
              label: _t('Ending Soon', 'ඉක්මනින් අවසන්', 'விரைவில் முடியும்'),
              icon: Icons.hourglass_bottom_rounded,
            ),
            const SizedBox(width: 8),
            _buildPrimaryFilterChip(
              id: primaryUnder1km,
              label: _t('Under 1km', 'කි.මී. 1ට අඩු', '1 கி.மீ.க்குள்'),
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(width: 8),
            _buildPrimaryFilterChip(
              id: primaryHalfOff,
              label: _t('50%+ OFF', '50%+ වට්ටම්', '50%+ தள்ளுபடி'),
              icon: Icons.local_offer_outlined,
            ),
            const SizedBox(width: 8),
            _buildPrimaryFilterChip(
              id: primaryBankCards,
              label: _t('Bank Cards', 'බැංකු කාඩ්', 'வங்கி அட்டைகள்'),
              icon: Icons.credit_card_rounded,
            ),
            const SizedBox(width: 8),
            _buildPrimaryFilterChip(
              id: primaryNewDeals,
              label: _t('New Deals', 'නව ඩීල්', 'புதிய சலுகைகள்'),
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
        color: selected ? Colors.white : AppColors.accent(context),
      ),
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.text(context),
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: const Color(0xFFF3F7FF),
      selectedColor: AppColors.accent(context),
      side: BorderSide(
        color: selected ? AppColors.accent(context) : const Color(0xFFD8E4FB),
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
        return _t('Under 1km', 'කි.මී. 1ට අඩු', '1 கி.மீ.க்குள்');
      case primaryHalfOff:
        return _t('50%+ OFF', '50%+ වට්ටම්', '50%+ தள்ளுபடி');
      case primaryBankCards:
        return _t('Bank Cards', 'බැංකු කාඩ්', 'வங்கி அட்டைகள்');
      case primaryEndingSoon:
        return _t('Ending Soon', 'ඉක්මනින් අවසන්', 'விரைவில் முடியும்');
      case primaryNewDeals:
        return _t('New Deals', 'නව ඩීල්', 'புதிய சலுகைகள்');
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
        border: Border.all(color: AppColors.border(context)),
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
                      ? '${widget.initialContextTitle ?? _screenTitle} ${_t('view', 'දසුන', 'காட்சி')}'
                      : _t('Category filter applied', 'ප්‍රවර්ග පෙරහන යොදා ඇත',
                          'வகை வடிகட்டி பயன்படுத்தப்பட்டுள்ளது'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
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

  Widget _bankFilters() {
    final l10n = AppLocalizations.of(context)!;
    final banks = _loaded
        .map((p) => p.bankName)
        .whereType<String>()
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final cards = _loaded.expand((p) => p.cardTypes).toSet().toList()..sort();
    return Padding(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_t(
              'Filter loaded offers by bank and card type',
              'බැංකුව සහ කාඩ් වර්ගය අනුව පූරණය කළ දීමනා පෙරන්න',
              'வங்கி மற்றும் அட்டை வகைப்படி ஏற்றப்பட்ட சலுகைகளை வடிகட்டு')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
              key: ValueKey(_bank),
              initialValue: banks.contains(_bank) ? _bank : null,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.bankOffersTab),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.allLabel)),
                ...banks.map((b) => DropdownMenuItem(value: b, child: Text(b)))
              ],
              onChanged: (bank) => setState(() => _bank = bank)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(
                label: Text(l10n.allLabel),
                selected: _card == null,
                onSelected: (_) => setState(() => _card = null)),
            for (final card in cards)
              ChoiceChip(
                  label: Text(switch (card) {
                    'credit' => l10n.creditCardLabel,
                    'debit' => l10n.debitCardLabel,
                    'prepaid' => l10n.prepaidCardLabel,
                    _ => card
                  }),
                  selected: _card == card,
                  onSelected: (_) => setState(() => _card = card))
          ])
        ]));
  }

  Widget _buildCategoryList(
      Map<String, List<Promotion>> groupedDeals, int totalDeals) {
    final offers =
        _filteredPromotions(groupedDeals.values.expand((p) => p).toList());
    final l10n = AppLocalizations.of(context)!;
    return CustomScrollView(
        key: const PageStorageKey('marketplace-results'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (widget.bankOffersOnly) SliverToBoxAdapter(child: _bankFilters()),
          if (_apiService.lastPromotionsFromCache)
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.offlineShowingCachedDeals))),
          if (_apiService.lastBankOffersFailed)
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                        onPressed: _refreshPromotions,
                        child: Text(_t(
                            'Bank offers could not be refreshed. Retry',
                            'බැංකු දීමනා යාවත්කාලීන කළ නොහැකි විය. නැවත උත්සාහ කරන්න',
                            'வங்கிச் சலுகைகளைப் புதுப்பிக்க முடியவில்லை. மீண்டும் முயலவும்'))))),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Text(
                      '$totalDeals ${_t('loaded offers', 'පූරණය කළ දීමනා', 'ஏற்றப்பட்ட சலுகைகள்')}',
                      style: Theme.of(context).textTheme.bodyLarge))),
          SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                  itemCount: offers.length,
                  itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: DiscoverMarketplaceCard(
                          offer: offers[i],
                          onOpen: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => DealDetailScreen(
                                      promotion: offers[i]))))))),
          if (_hasMore || _pageError)
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton(
                        onPressed: _paging ? null : _nextPage,
                        child: Text(_paging
                            ? '…'
                            : _pageError
                                ? l10n.retry
                                : _t(
                                    'Load more offers',
                                    'තවත් දීමනා පූරණය කරන්න',
                                    'மேலும் சலுகைகளை ஏற்று'))))),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ]);
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
                enabled: !MediaQuery.disableAnimationsOf(context),
                baseColor: AppColors.border(context),
                highlightColor: AppColors.canvas(context),
                child: Container(
                  width: 150,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            SizedBox(
              height:
                  314 + (MediaQuery.textScalerOf(context).scale(16) - 16) * 6,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Container(
                    width: 184,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Shimmer.fromColors(
                      enabled: !MediaQuery.disableAnimationsOf(context),
                      baseColor: AppColors.border(context),
                      highlightColor: AppColors.canvas(context),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 50),
            const SizedBox(height: 10),
            Text(
              l10n.failedToLoadDeals,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
              onPressed: _refreshPromotions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sentiment_dissatisfied,
              color: AppColors.muted(context), size: 50),
          const SizedBox(height: 10),
          Text(
            l10n.noDealsAvailable,
            style: TextStyle(fontSize: 16, color: AppColors.muted(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMatchesState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.bankOffersOnly) _bankFilters(),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.canvas(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 42,
                color: AppColors.muted(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noDealsMatchView,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noDealsMatchSubtitle,
              style: TextStyle(
                color: AppColors.muted(context),
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
                  label: Text(l10n.clearFilters),
                ),
                OutlinedButton.icon(
                  onPressed: _refreshPromotions,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
