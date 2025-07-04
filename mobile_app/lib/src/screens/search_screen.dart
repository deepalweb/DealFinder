import 'package:flutter/material.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';
import 'deal_detail_screen.dart';
import '../widgets/deal_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Deals'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter product, category, or merchant...',
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchResultsScreen(query: value.trim()),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class SearchResultsScreen extends StatefulWidget {
  final String query;
  const SearchResultsScreen({Key? key, required this.query}) : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late Future<List<Promotion>> _futureResults;
  List<Promotion> _results = [];
  String _selectedSort = 'relevance';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _futureResults = ApiService().searchPromotions(widget.query);
    _futureResults.then((data) => setState(() => _results = data));
  }

  void _sortResults() {
    setState(() {
      if (_selectedSort == 'latest') {
        _results.sort((a, b) => (b.startDate ?? DateTime(1970)).compareTo(a.startDate ?? DateTime(1970)));
      } else if (_selectedSort == 'price_low') {
        _results.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
      } else if (_selectedSort == 'price_high') {
        _results.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
      }
      // Default is relevance (API order)
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter by Category'),
          content: DropdownButton<String>(
            value: _selectedCategory,
            isExpanded: true,
            items: <String?>[null, 'fashion', 'electronics', 'food', 'travel', 'health', 'entertainment', 'home', 'pets']
                .map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat == null ? 'All' : cat[0].toUpperCase() + cat.substring(1)),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() { _selectedCategory = value; });
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Results for "${widget.query}"')),
      body: FutureBuilder<List<Promotion>>(
        future: _futureResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text('Error: \\${snapshot.error}', style: const TextStyle(color: Colors.red)),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No results found.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          // Apply filter
          final filtered = _selectedCategory == null
              ? _results
              : _results.where((p) => p.category == _selectedCategory).toList();
          return RefreshIndicator(
            onRefresh: () async {
              setState(() { _futureResults = ApiService().searchPromotions(widget.query); });
              final data = await _futureResults;
              setState(() => _results = data);
            },
            child: Column(
              children: [
                // Add filter and sort row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedSort,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'relevance', child: Text('Relevance')),
                            DropdownMenuItem(value: 'latest', child: Text('Latest')),
                            DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
                            DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() { _selectedSort = value; });
                              _sortResults();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        tooltip: 'Filter',
                        onPressed: _showFilterDialog,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final promotion = filtered[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DealDetailScreen(promotion: promotion),
                            ),
                          );
                        },
                        child: DealCard(promotion: promotion),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
