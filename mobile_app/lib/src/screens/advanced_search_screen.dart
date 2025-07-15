import 'package:flutter/material.dart';
import '../models/promotion.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../services/search_service.dart';
import '../widgets/deal_card.dart';
import 'deal_detail_screen.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final _searchController = TextEditingController();
  List<Promotion> _searchResults = [];
  List<String> _searchSuggestions = [];
  List<String> _searchHistory = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  
  // Filter options
  RangeValues _priceRange = const RangeValues(0, 1000);
  String? _selectedCategory;
  String? _selectedMerchant;
  String _sortBy = 'relevance';
  double _maxDistance = 50;
  bool _hasDiscountOnly = false;
  DateTime? _expiresAfter;
  
  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSearchHistory() async {
    final history = await SearchService.getSearchHistory();
    setState(() {
      _searchHistory = history;
    });
  }
  
  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.length >= 2) {
      _getSuggestions(query);
    } else {
      setState(() {
        _searchSuggestions = [];
        _showSuggestions = false;
      });
    }
  }
  
  Future<void> _getSuggestions(String query) async {
    final suggestions = await SearchService.getSuggestions(query);
    setState(() {
      _searchSuggestions = suggestions;
      _showSuggestions = true;
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _showSuggestions = false;
    });
    
    try {
      await SearchService.addToSearchHistory(query);
      
      final results = await SearchService.performAdvancedSearch(
        query: query,
        category: _selectedCategory,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
        merchant: _selectedMerchant,
        hasDiscount: _hasDiscountOnly,
        expiresAfter: _expiresAfter,
        sortBy: _sortBy,
      );
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    }
  }

  void _showSearchHistory() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Search History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () async {
                    await SearchService.clearSearchHistory();
                    _loadSearchHistory();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_searchHistory.isEmpty)
              const Text('No search history')
            else
              ..._searchHistory.take(10).map((query) => ListTile(
                leading: const Icon(Icons.history),
                title: Text(query),
                onTap: () {
                  _searchController.text = query;
                  Navigator.pop(context);
                  _performSearch();
                },
              )).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Search'),
      ),
      body: Column(
        children: [
          // Search bar with suggestions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search deals, merchants, categories...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchSuggestions = [];
                                _showSuggestions = false;
                              });
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.history),
                          onPressed: () => _showSearchHistory(),
                        ),
                      ],
                    ),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
                
                // Search suggestions
                if (_showSuggestions && _searchSuggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _searchSuggestions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.search, size: 16),
                          title: Text(suggestion),
                          onTap: () {
                            _searchController.text = suggestion;
                            setState(() => _showSuggestions = false);
                            _performSearch();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          
          // Filters
          ExpansionTile(
            title: const Text('Filters'),
            children: [
              // Price range
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Price Range: Rs.${_priceRange.start.round()} - Rs.${_priceRange.end.round()}'),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 1000,
                      divisions: 20,
                      onChanged: (values) => setState(() => _priceRange = values),
                    ),
                  ],
                ),
              ),
              
              // Category filter
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Categories')),
                    ...predefinedCategories.map((cat) => 
                      DropdownMenuItem(value: cat.id, child: Text(cat.name))
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedCategory = value),
                ),
              ),
              
              // Merchant filter
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Merchant Name',
                    prefixIcon: Icon(Icons.store),
                  ),
                  onChanged: (value) => _selectedMerchant = value.isEmpty ? null : value,
                ),
              ),
              
              // Discount filter
              Padding(
                padding: const EdgeInsets.all(16),
                child: CheckboxListTile(
                  title: const Text('Deals with discount only'),
                  value: _hasDiscountOnly,
                  onChanged: (value) => setState(() => _hasDiscountOnly = value ?? false),
                ),
              ),
              
              // Expiry filter
              Padding(
                padding: const EdgeInsets.all(16),
                child: ListTile(
                  title: const Text('Expires after'),
                  subtitle: Text(_expiresAfter?.toString().split(' ')[0] ?? 'Any time'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _expiresAfter = date);
                    }
                  },
                ),
              ),
              
              // Sort by
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: const InputDecoration(labelText: 'Sort By'),
                  items: const [
                    DropdownMenuItem(value: 'relevance', child: Text('Relevance')),
                    DropdownMenuItem(value: 'newest', child: Text('Newest First')),
                    DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
                    DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
                    DropdownMenuItem(value: 'discount', child: Text('Best Discount')),
                    DropdownMenuItem(value: 'expiry', child: Text('Expiring Soon')),
                  ],
                  onChanged: (value) => setState(() => _sortBy = value!),
                ),
              ),
              
              // Apply filters button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _performSearch,
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
          
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No results found'),
                            Text('Try different keywords or adjust filters'),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _performSearch,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final deal = _searchResults[index];
                            return InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DealDetailScreen(promotion: deal),
                                ),
                              ),
                              child: DealCard(promotion: deal),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}