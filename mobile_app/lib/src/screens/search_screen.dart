import 'dart:async';

import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/promotion.dart';
import '../services/search_service.dart';
import '../utils/bank_card_promotion_support.dart';
import '../utils/deal_filter_support.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/modern_deal_card.dart';
import 'deal_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<String> _history = [];
  List<String> _suggestions = [];
  bool _loadingHistory = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await SearchService.getSearchHistory();
    if (!mounted) return;
    setState(() {
      _history = history;
      _loadingHistory = false;
    });
  }

  Future<void> _submitSearch(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return;

    await SearchService.addToSearchHistory(query);
    if (!mounted) return;

    setState(() {
      _searchController.text = query;
      _suggestions = [];
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(query: query),
      ),
    );

    _loadHistory();
  }

  void _handleQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();

    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final suggestions = await SearchService.getSuggestions(query);
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() => _suggestions = suggestions);
    });
  }

  Future<void> _clearHistory() async {
    await SearchService.clearSearchHistory();
    if (!mounted) return;
    setState(() => _history = []);
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find deals faster',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF14213D),
                ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Search by product, store, category, card offer, or Sinhala keywords.',
            style: TextStyle(
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _handleQueryChanged,
            onSubmitted: _submitSearch,
            decoration: InputDecoration(
              hintText: 'Try burgers, phones, fashion, කෑම...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _suggestions = [];
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTopicSection() {
    return _SectionCard(
      title: 'Browse by delivery and budget',
      subtitle: 'Jump straight into the deal types people act on fastest.',
      trailing: const Icon(Icons.trending_up, color: Color(0xFF1E88E5)),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: dealCapabilityPresets
            .map(
              (preset) => ActionChip(
                label: Text(preset.label),
                avatar: Icon(preset.icon, size: 16),
                tooltip: preset.description,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchResultsScreen(
                        query: '',
                        initialCapabilityPresetId: preset.id,
                      ),
                    ),
                  );
                },
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSuggestionSection() {
    return _SectionCard(
      title: 'Suggestions',
      subtitle: 'Live matches based on current deals and store names.',
      trailing: const Icon(Icons.auto_awesome, color: Color(0xFF7C3AED)),
      child: Column(
        children: _suggestions
            .map(
              (suggestion) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFE8F1FF),
                  child: Icon(
                    Icons.search,
                    size: 18,
                    color: Color(0xFF1E88E5),
                  ),
                ),
                title: Text(suggestion),
                trailing: const Icon(Icons.north_west_rounded, size: 18),
                onTap: () => _submitSearch(suggestion),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildHistorySection() {
    return _SectionCard(
      title: 'Recent searches',
      subtitle: _history.isEmpty
          ? 'Your last searches will appear here for quick reuse.'
          : 'Pick up where you left off.',
      trailing: _history.isEmpty
          ? const Icon(Icons.history, color: Color(0xFF94A3B8))
          : TextButton(
              onPressed: _clearHistory,
              child: const Text('Clear'),
            ),
      child: _loadingHistory
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          : _history.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Searches for deals, stores, and categories will be saved here.',
                    style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                  ),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _history
                      .take(8)
                      .map(
                        (query) => InputChip(
                          avatar: const Icon(Icons.history, size: 16),
                          label: Text(query),
                          onPressed: () => _submitSearch(query),
                        ),
                      )
                      .toList(),
                ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(title: const Text('Search Deals')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDFF1FF),
              Color(0xFFF4F8FF),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSearchField(),
            const SizedBox(height: 16),
            if (_suggestions.isNotEmpty) ...[
              _buildSuggestionSection(),
              const SizedBox(height: 16),
            ] else ...[
              _buildQuickTopicSection(),
              const SizedBox(height: 16),
              _buildHistorySection(),
            ],
          ],
        ),
      ),
    );
  }
}

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String? initialCapabilityPresetId;

  const SearchResultsScreen({
    super.key,
    required this.query,
    this.initialCapabilityPresetId,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late Future<List<Promotion>> _futureResults;
  List<Promotion> _results = [];
  String _selectedSort = 'relevance';
  String? _selectedCategory;
  String? _selectedCapabilityPresetId;

  @override
  void initState() {
    super.initState();
    _selectedCapabilityPresetId = widget.initialCapabilityPresetId;
    _futureResults = _loadResults();
  }

  Future<List<Promotion>> _loadResults() async {
    final data = await SearchService.performAdvancedSearch(query: widget.query);
    if (mounted) {
      setState(() => _results = data);
    }
    return data;
  }

  List<Promotion> get _sortedResults {
    final sorted = List<Promotion>.from(_results);
    switch (_selectedSort) {
      case 'latest':
        sorted.sort(
          (a, b) => (b.startDate ?? DateTime(1970))
              .compareTo(a.startDate ?? DateTime(1970)),
        );
        break;
      case 'price_low':
        sorted.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
        break;
      case 'price_high':
        sorted.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
    }
    return sorted;
  }

  List<Promotion> get _visibleResults {
    final sorted = _sortedResults;
    return sorted.where(
      (promotion) {
        final categoryMatches = _selectedCategory == null ||
            BankCardPromotionSupport.effectiveCategoryId(promotion) ==
                _selectedCategory;
        final capabilityMatches = _selectedCapabilityPresetId == null ||
            matchesDealCapabilityPreset(
              promotion,
              _selectedCapabilityPresetId!,
            );
        return categoryMatches && capabilityMatches;
      },
    ).toList();
  }

  int get _activeFilterCount {
    var count = 0;
    if (_selectedCategory != null) count += 1;
    if (_selectedCapabilityPresetId != null) count += 1;
    return count;
  }

  Future<void> _refreshResults() async {
    final refreshed = SearchService.performAdvancedSearch(query: widget.query);
    setState(() => _futureResults = refreshed);
    final data = await refreshed;
    if (!mounted) return;
    setState(() => _results = data);
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use quick presets or narrow by category.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Quick presets',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
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
                      title: const Text(
                        'Categories',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        _selectedCategory == null
                            ? 'Optional'
                            : getCategoryLabel(_selectedCategory!),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 8),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ChoiceChip(
                                label: const Text('All'),
                                selected: _selectedCategory == null,
                                onSelected: (_) {
                                  setState(() => _selectedCategory = null);
                                  setSheetState(() {});
                                },
                              ),
                              ...predefinedCategories
                                  .where((category) => category.id != 'other')
                                  .map(
                                    (category) => ChoiceChip(
                                      label: Text(category.name),
                                      selected:
                                          _selectedCategory == category.id,
                                      onSelected: (_) {
                                        setState(
                                          () => _selectedCategory = category.id,
                                        );
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = null;
                                _selectedCapabilityPresetId = null;
                              });
                              setSheetState(() {});
                            },
                            child: const Text('Clear'),
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
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSortChip(String value, String label, IconData icon) {
    final selected = _selectedSort == value;
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? Colors.white : const Color(0xFF54606E),
      ),
      label: Text(label),
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : const Color(0xFF243447),
      ),
      onSelected: (_) => setState(() => _selectedSort = value),
    );
  }

  Widget _buildResultHeader(int resultCount) {
    final activeCapability =
        findDealCapabilityPreset(_selectedCapabilityPresetId);
    final activeCategory = _selectedCategory == null
        ? 'All categories'
        : getCategoryLabel(_selectedCategory!);
    final headline = widget.query.trim().isNotEmpty
        ? widget.query
        : (activeCapability?.label ?? 'All deals');
    final summaryParts = <String>[
      '$resultCount matches',
      activeCategory,
      if (activeCapability != null) activeCapability.label,
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF14213D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summaryParts.join(' • '),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _openFilterSheet,
                icon: const Icon(Icons.tune_rounded),
                label: Text(
                  _activeFilterCount > 0
                      ? 'Filter ($_activeFilterCount)'
                      : 'Filter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: dealCapabilityPresets.map((preset) {
                final selected = _selectedCapabilityPresetId == preset.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      preset.icon,
                      size: 16,
                      color: selected ? Colors.white : const Color(0xFF54606E),
                    ),
                    label: Text(preset.label),
                    selected: selected,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF243447),
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (value) {
                      setState(() {
                        _selectedCapabilityPresetId = value ? preset.id : null;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortChip('relevance', 'Relevance', Icons.auto_awesome),
                const SizedBox(width: 8),
                _buildSortChip('latest', 'Latest', Icons.access_time_rounded),
                const SizedBox(width: 8),
                _buildSortChip(
                  'price_low',
                  'Lowest Price',
                  Icons.south_rounded,
                ),
                const SizedBox(width: 8),
                _buildSortChip(
                  'price_high',
                  'Highest Price',
                  Icons.north_rounded,
                ),
              ],
            ),
          ),
          if (_selectedCategory != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                InputChip(
                  label: Text(getCategoryLabel(_selectedCategory!)),
                  avatar: const Icon(Icons.category_outlined, size: 16),
                  onDeleted: () => setState(() => _selectedCategory = null),
                ),
              ],
            ),
          ],
          if (_selectedCapabilityPresetId != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                InputChip(
                  avatar: Icon(
                    activeCapability?.icon ?? Icons.tune_rounded,
                    size: 16,
                  ),
                  label: Text(activeCapability?.label ?? 'Preset'),
                  onDeleted: () =>
                      setState(() => _selectedCapabilityPresetId = null),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return AppEmptyState(
      icon: Icons.search_off_rounded,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedCapabilityPresetId = null;
    });
  }

  Widget _buildResultsGrid(List<Promotion> visibleResults) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 900
            ? 4
            : width >= 680
                ? 3
                : 2;

        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.56,
          ),
          itemCount: visibleResults.length,
          itemBuilder: (context, index) {
            final promotion = visibleResults[index];
            return ModernDealCard(
              promotion: promotion,
              showCountdown: promotion.endDate != null,
              prioritizeDistance: promotion.distance != null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DealDetailScreen(
                      promotion: promotion,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: Text(
          widget.query.trim().isNotEmpty
              ? 'Results for "${widget.query}"'
              : 'Browse Deals',
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDFF1FF),
              Color(0xFFF4F8FF),
            ],
          ),
        ),
        child: FutureBuilder<List<Promotion>>(
          future: _futureResults,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _results.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildEmptyState(
                title: 'Search is having trouble',
                message: 'We could not load the latest results right now.',
                actionLabel: 'Retry',
                onAction: _refreshResults,
              );
            }

            if (!snapshot.hasData || _results.isEmpty) {
              return _buildEmptyState(
                title: widget.query.trim().isNotEmpty
                    ? 'No results for "${widget.query}"'
                    : 'No deals found',
                message: widget.query.trim().isNotEmpty
                    ? 'Try a broader keyword, a store name, or one of the popular topics from the search page.'
                    : 'Try a different quick preset or clear the active filters to see more deals.',
              );
            }

            final visibleResults = _visibleResults;

            return RefreshIndicator(
              onRefresh: _refreshResults,
              child: Column(
                children: [
                  _buildResultHeader(visibleResults.length),
                  Expanded(
                    child: visibleResults.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.55,
                                child: _buildEmptyState(
                                  title: 'No matches in this filter',
                                  message:
                                      'Try another category or clear the active filter to see more deals.',
                                  actionLabel: 'Clear filters',
                                  onAction: _clearAllFilters,
                                ),
                              ),
                            ],
                          )
                        : _buildResultsGrid(visibleResults),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF14213D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
