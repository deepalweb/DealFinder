import 'package:flutter/material.dart';
import '../models/promotion.dart';
import '../services/search_service.dart';
import '../widgets/deal_card.dart';
import 'deal_detail_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;
  final Map<String, dynamic>? initialFilters;

  const SearchResultsScreen({
    super.key,
    required this.initialQuery,
    this.initialFilters,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Promotion> _results = [];
  bool _isLoading = false;
  String _sortBy = 'relevance';
  int _resultCount = 0;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);

    try {
      final results = await SearchService.performAdvancedSearch(
        query: widget.initialQuery,
        sortBy: _sortBy,
        // Add other filters from initialFilters if provided
      );

      setState(() {
        _results = results;
        _resultCount = results.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search Results'),
            Text(
              '$_resultCount results for "${widget.initialQuery}"',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() => _sortBy = value);
              _performSearch();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'relevance', child: Text('Relevance')),
              const PopupMenuItem(value: 'newest', child: Text('Newest First')),
              const PopupMenuItem(value: 'price_low', child: Text('Price: Low to High')),
              const PopupMenuItem(value: 'price_high', child: Text('Price: High to Low')),
              const PopupMenuItem(value: 'discount', child: Text('Best Discount')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('No results found for "${widget.initialQuery}"'),
                      const SizedBox(height: 8),
                      const Text('Try different keywords or filters'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _performSearch,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final deal = _results[index];
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open filter bottom sheet
          _showFilterBottomSheet();
        },
        child: const Icon(Icons.filter_list),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Add filter widgets here
                    const Text('Price Range'),
                    // Price range slider
                    const SizedBox(height: 16),
                    const Text('Category'),
                    // Category dropdown
                    const SizedBox(height: 16),
                    const Text('Merchant'),
                    // Merchant input
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _performSearch();
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}