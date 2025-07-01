import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'deals_list_screen.dart';
import 'merchant_profile_screen.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({Key? key}) : super(key: key);

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  List<Map<String, dynamic>> _allMerchants = [];
  List<Map<String, dynamic>> _filteredMerchants = [];
  bool _loading = true;
  String _searchTerm = '';
  String _selectedCategory = 'all';
  String? _error;

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'All'},
    {'id': 'fashion', 'name': 'Fashion'},
    {'id': 'electronics', 'name': 'Electronics'},
    {'id': 'food', 'name': 'Food'},
    {'id': 'travel', 'name': 'Travel'},
    {'id': 'health', 'name': 'Health'},
    {'id': 'entertainment', 'name': 'Entertainment'},
    {'id': 'home', 'name': 'Home'},
    {'id': 'pets', 'name': 'Pets'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchMerchants();
  }

  Future<void> _fetchMerchants() async {
    setState(() { _loading = true; _error = null; });
    try {
      final merchants = await ApiService().fetchMerchants();
      setState(() {
        _allMerchants = merchants;
        _filteredMerchants = merchants;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _filterMerchants() {
    List<Map<String, dynamic>> results = [..._allMerchants];
    if (_searchTerm.isNotEmpty) {
      final term = _searchTerm.toLowerCase();
      results = results.where((m) =>
        (m['name'] ?? '').toLowerCase().contains(term) ||
        (m['description'] ?? '').toLowerCase().contains(term)
      ).toList();
    }
    if (_selectedCategory != 'all') {
      results = results.where((m) => m['category'] == _selectedCategory).toList();
    }
    setState(() { _filteredMerchants = results; });
  }

  String _getSafeLogo(dynamic logo, String name) {
    if (logo is String && logo.startsWith('data:image')) return logo;
    if (logo is String && logo.startsWith('http')) return logo;
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&size=300';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stores')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchMerchants,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search for stores...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        onChanged: (value) {
                          setState(() { _searchTerm = value; });
                          _filterMerchants();
                        },
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final selected = _selectedCategory == cat['id'];
                          return ChoiceChip(
                            label: Text(cat['name']!),
                            selected: selected,
                            onSelected: (_) {
                              setState(() { _selectedCategory = cat['id']!; });
                              _filterMerchants();
                            },
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: _filteredMerchants.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.store, size: 60, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text('No merchants found', style: TextStyle(color: Colors.grey)),
                                  SizedBox(height: 4),
                                  Text('Try a different search term or category', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _filteredMerchants.length,
                              itemBuilder: (context, index) {
                                final merchant = _filteredMerchants[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipOval(
                                          child: Image.network(
                                            _getSafeLogo(merchant['logo'], merchant['name'] ?? 'M'),
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              width: 56,
                                              height: 56,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.store, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                merchant['name'] ?? 'Unnamed Store',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                merchant['description'] ?? '',
                                                style: Theme.of(context).textTheme.bodySmall,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    merchant['category'] ?? 'Other',
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${merchant['followers'] ?? 0} followers',
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => MerchantProfileScreen(
                                                  merchantId: merchant['id'] ?? merchant['_id'],
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('Visit Store'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
