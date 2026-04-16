import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'merchant_profile_screen.dart';
import '../widgets/merchant_card.dart';
import '../widgets/category_icon.dart';
import '../widgets/merchant_card_shimmer.dart';
import 'package:share_plus/share_plus.dart';

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
  final Set<String> _followingMerchants = {};

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'All', 'icon': 'all_inclusive'},
    {'id': 'fashion', 'name': 'Fashion', 'icon': 'checkroom'},
    {'id': 'electronics', 'name': 'Electronics', 'icon': 'devices'},
    {'id': 'food', 'name': 'Food', 'icon': 'restaurant'},
    {'id': 'travel', 'name': 'Travel', 'icon': 'flight'},
    {'id': 'health', 'name': 'Health', 'icon': 'spa'},
    {'id': 'entertainment', 'name': 'Entertainment', 'icon': 'movie'},
    {'id': 'home', 'name': 'Home', 'icon': 'home'},
    {'id': 'pets', 'name': 'Pets', 'icon': 'pets'},
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
      if (mounted) {
        setState(() {
          _allMerchants = merchants;
          _filteredMerchants = merchants;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
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

  void _toggleFollow(String merchantId) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_followingMerchants.contains(merchantId)) {
        _followingMerchants.remove(merchantId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Unfollowed store'),
              ],
            ),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _followingMerchants.add(merchantId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Following store'),
              ],
            ),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    });
  }

  void _shareMerchant(Map<String, dynamic> merchant) {
    HapticFeedback.mediumImpact();
    final name = merchant['name'] ?? 'Store';
    final url = merchant['profileUrl'] ?? '';
    Share.share('Check out $name on DealFinder! $url');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Stores', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? buildMerchantListShimmer(itemCount: 5)
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    _buildStatsHeader(),
                    _buildSearchBar(),
                    _buildCategoryFilter(),
                    Expanded(child: _buildMerchantList()),
                  ],
                ),
    );
  }

  Widget _buildStatsHeader() {
    final followingCount = _followingMerchants.length;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.store, '${_allMerchants.length}', 'Total Stores'),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildStatItem(Icons.favorite, '$followingCount', 'Following'),
        ],
      ),
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
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search stores...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF9E9E9E)),
            suffixIcon: _searchTerm.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFF9E9E9E)),
                    onPressed: () {
                      setState(() { _searchTerm = ''; });
                      _filterMerchants();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) {
            setState(() { _searchTerm = value; });
            _filterMerchants();
          },
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final selected = _selectedCategory == cat['id'];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() { _selectedCategory = cat['id']!; });
              _filterMerchants();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CategoryIcon(
                    category: cat['id']!,
                    size: 16,
                    color: selected ? Colors.white : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['name']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMerchantList() {
    if (_filteredMerchants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No stores found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchTerm.isNotEmpty
                  ? 'Try a different search term'
                  : 'Try selecting a different category',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await _fetchMerchants();
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _filteredMerchants.length,
        itemBuilder: (context, index) {
          final merchant = _filteredMerchants[index];
          final merchantId = merchant['id'] ?? merchant['_id'] ?? '';
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50)),
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
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MerchantCard(
                merchant: merchant,
                isFollowing: _followingMerchants.contains(merchantId),
                onFollowToggle: () => _toggleFollow(merchantId),
                onShare: () => _shareMerchant(merchant),
                onVisit: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MerchantProfileScreen(
                        merchantId: merchantId,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 64),
            const SizedBox(height: 16),
            Text(
              'Failed to load stores',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchMerchants,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
