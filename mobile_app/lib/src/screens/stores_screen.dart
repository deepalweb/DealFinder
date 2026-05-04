import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../services/api_service.dart';
import '../services/merchant_following_manager.dart';
import '../widgets/category_icon.dart';
import '../widgets/merchant_card.dart';
import '../widgets/merchant_card_shimmer.dart';
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
  String _sortMode = 'popular';
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
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadFollowingMerchants();
    await _fetchMerchants();
  }

  Future<void> _loadFollowingMerchants() async {
    final followed =
        await MerchantFollowingManager.getFollowingMerchants();
    if (!mounted) return;
    setState(() {
      _followingMerchants
        ..clear()
        ..addAll(followed);
    });
  }

  Future<void> _fetchMerchants({bool forceRefresh = false}) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final merchants =
          await ApiService().fetchMerchants(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _allMerchants = merchants;
        _loading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    final term = _searchTerm.trim().toLowerCase();
    var results = [..._allMerchants];

    if (term.isNotEmpty) {
      results = results.where((merchant) {
        final name = (merchant['name'] ?? '').toString().toLowerCase();
        final description =
            (merchant['description'] ?? merchant['profile'] ?? '')
                .toString()
                .toLowerCase();
        final category =
            (merchant['category'] ?? '').toString().toLowerCase();
        return name.contains(term) ||
            description.contains(term) ||
            category.contains(term);
      }).toList();
    }

    if (_selectedCategory != 'all') {
      results = results
          .where((merchant) => merchant['category'] == _selectedCategory)
          .toList();
    }

    results.sort((a, b) {
      final aId = _merchantIdOf(a);
      final bId = _merchantIdOf(b);
      switch (_sortMode) {
        case 'following':
          final aFollowing = _followingMerchants.contains(aId);
          final bFollowing = _followingMerchants.contains(bId);
          if (aFollowing != bFollowing) {
            return bFollowing ? 1 : -1;
          }
          return _compareByPopularity(a, b);
        case 'a_z':
          return (a['name'] ?? '')
              .toString()
              .toLowerCase()
              .compareTo((b['name'] ?? '').toString().toLowerCase());
        case 'new':
          return (b['createdAt'] ?? '')
              .toString()
              .compareTo((a['createdAt'] ?? '').toString());
        case 'popular':
        default:
          return _compareByPopularity(a, b);
      }
    });

    if (!mounted) return;
    setState(() {
      _filteredMerchants = results;
    });
  }

  int _compareByPopularity(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final bScore = _merchantScore(b);
    final aScore = _merchantScore(a);
    return bScore.compareTo(aScore);
  }

  int _merchantScore(Map<String, dynamic> merchant) {
    final followers = (merchant['followers'] as num?)?.toInt() ?? 0;
    final deals = ((merchant['activeDeals'] ?? merchant['deals']) as num?)
            ?.toInt() ??
        0;
    return (followers * 3) + (deals * 5);
  }

  String _merchantIdOf(Map<String, dynamic> merchant) =>
      (merchant['id'] ?? merchant['_id'] ?? '').toString();

  List<Map<String, dynamic>> get _featuredMerchants {
    final ranked = [..._allMerchants];
    ranked.sort(_compareByPopularity);
    return ranked.take(5).toList();
  }

  int get _activeCategoryCount =>
      _selectedCategory == 'all'
          ? _allMerchants.length
          : _allMerchants
              .where((merchant) => merchant['category'] == _selectedCategory)
              .length;

  Future<void> _toggleFollow(String merchantId) async {
    HapticFeedback.lightImpact();
    final isFollowing = _followingMerchants.contains(merchantId);

    if (isFollowing) {
      await MerchantFollowingManager.unfollowMerchant(merchantId);
    } else {
      await MerchantFollowingManager.followMerchant(merchantId);
    }

    if (!mounted) return;
    setState(() {
      if (isFollowing) {
        _followingMerchants.remove(merchantId);
      } else {
        _followingMerchants.add(merchantId);
      }
    });
    _applyFilters();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isFollowing ? Icons.check_circle : Icons.favorite,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(isFollowing ? 'Unfollowed store' : 'Following store'),
          ],
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isFollowing ? const Color(0xFF455A64) : const Color(0xFF2E7D32),
      ),
    );
  }

  void _shareMerchant(Map<String, dynamic> merchant) {
    HapticFeedback.mediumImpact();
    final name = merchant['name'] ?? 'Store';
    final category = merchant['category'] ?? 'store';
    Share.share(
      'Check out $name on DealFinder.\nGreat $category deals and local offers await.',
    );
  }

  void _openMerchant(Map<String, dynamic> merchant) {
    final merchantId = _merchantIdOf(merchant);
    if (merchantId.isEmpty) return;
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MerchantProfileScreen(merchantId: merchantId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text(
          'Stores',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? buildMerchantListShimmer(itemCount: 5)
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: () async {
                    HapticFeedback.mediumImpact();
                    await _fetchMerchants(forceRefresh: true);
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeroPanel(),
                              const SizedBox(height: 16),
                              _buildSearchBar(),
                              const SizedBox(height: 14),
                              _buildQuickStatsRow(),
                              const SizedBox(height: 16),
                              _buildCategoryFilter(),
                              const SizedBox(height: 18),
                              if (_featuredMerchants.isNotEmpty &&
                                  _searchTerm.isEmpty &&
                                  _selectedCategory == 'all') ...[
                                _buildSectionHeader(
                                  title: 'Top Picks',
                                  subtitle:
                                      'Popular stores worth checking first',
                                ),
                                const SizedBox(height: 12),
                                _buildFeaturedScroller(),
                                const SizedBox(height: 22),
                              ],
                              _buildSectionHeader(
                                title: 'Browse All Stores',
                                subtitle:
                                    '${_filteredMerchants.length} results${_searchTerm.isNotEmpty ? ' for "${_searchTerm.trim()}"' : ''}',
                                trailing: _buildSortMenu(),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                      if (_filteredMerchants.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverList.builder(
                            itemCount: _filteredMerchants.length,
                            itemBuilder: (context, index) {
                              final merchant = _filteredMerchants[index];
                              final merchantId = _merchantIdOf(merchant);
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration:
                                    Duration(milliseconds: 260 + (index * 35)),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 18 * (1 - value)),
                                    child: Opacity(opacity: value, child: child),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: MerchantCard(
                                    merchant: merchant,
                                    isFollowing:
                                        _followingMerchants.contains(merchantId),
                                    onFollowToggle: () =>
                                        _toggleFollow(merchantId),
                                    onShare: () => _shareMerchant(merchant),
                                    onVisit: () => _openMerchant(merchant),
                                    compact: false,
                                  ),
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

  Widget _buildHeroPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F4C81),
            Color(0xFF1572A1),
            Color(0xFF36A2B8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1572A1).withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Discover stores near your style',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Follow standout merchants, compare categories, and jump straight into the best local deals.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeroChip(
                icon: Icons.local_offer_outlined,
                value: '${_allMerchants.length}',
                label: 'Stores live',
              ),
              _buildHeroChip(
                icon: Icons.favorite_border,
                value: '${_followingMerchants.length}',
                label: 'Following',
              ),
              _buildHeroChip(
                icon: Icons.grid_view_rounded,
                value: '${_categories.length - 1}',
                label: 'Categories',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search stores, categories, or vibes',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF8B97A8)),
          suffixIcon: _searchTerm.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFF8B97A8)),
                  onPressed: () {
                    setState(() => _searchTerm = '');
                    _applyFilters();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        onChanged: (value) {
          setState(() => _searchTerm = value);
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    final allCount = _allMerchants.length;
    final followingCount = _followingMerchants.length;
    final visibleCount = _filteredMerchants.length;

    return Row(
      children: [
        Expanded(
          child: _buildQuickStatCard(
            label: 'Visible Now',
            value: '$visibleCount',
            icon: Icons.visibility_outlined,
            tone: const Color(0xFF1E88E5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickStatCard(
            label: 'Following',
            value: '$followingCount',
            icon: Icons.favorite_outline,
            tone: const Color(0xFFE53935),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildQuickStatCard(
            label: 'In Category',
            value: '$_activeCategoryCount',
            icon: Icons.category_outlined,
            tone: const Color(0xFF00897B),
            helper: allCount > 0 ? 'of $allCount' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color tone,
    String? helper,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: tone.withValues(alpha: 0.1),
            child: Icon(icon, size: 18, color: tone),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF14213D),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          if (helper != null)
            Text(
              helper,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = _selectedCategory == category['id'];
          return InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = category['id']!);
              _applyFilters();
            },
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF14213D) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF14213D)
                      : const Color(0xFFE6EBF2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CategoryIcon(
                    category: category['id']!,
                    size: 16,
                    color: selected ? Colors.white : const Color(0xFF1E88E5),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    category['name']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : const Color(0xFF243447),
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

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF14213D),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<String>(
      initialValue: _sortMode,
      onSelected: (value) {
        setState(() => _sortMode = value);
        _applyFilters();
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'popular', child: Text('Most Popular')),
        PopupMenuItem(value: 'following', child: Text('Following First')),
        PopupMenuItem(value: 'a_z', child: Text('A to Z')),
        PopupMenuItem(value: 'new', child: Text('Newest')),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5EAF1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded,
                size: 16, color: Color(0xFF5C6B7A)),
            const SizedBox(width: 6),
            Text(
              _sortLabel(_sortMode),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF243447),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sortLabel(String mode) {
    switch (mode) {
      case 'following':
        return 'Following';
      case 'a_z':
        return 'A-Z';
      case 'new':
        return 'Newest';
      case 'popular':
      default:
        return 'Popular';
    }
  }

  Widget _buildFeaturedScroller() {
    return SizedBox(
      height: 268,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _featuredMerchants.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final merchant = _featuredMerchants[index];
          final merchantId = _merchantIdOf(merchant);
          return SizedBox(
            width: 288,
            child: MerchantCard(
              merchant: merchant,
              isFollowing: _followingMerchants.contains(merchantId),
              onFollowToggle: () => _toggleFollow(merchantId),
              onShare: () => _shareMerchant(merchant),
              onVisit: () => _openMerchant(merchant),
              compact: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching =
        _searchTerm.trim().isNotEmpty || _selectedCategory != 'all';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EEF6),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                isSearching ? Icons.travel_explore : Icons.storefront_outlined,
                size: 44,
                color: const Color(0xFF718096),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No stores match this view',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF14213D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isSearching
                  ? 'Try a broader search, switch category, or clear your filters to explore more merchants.'
                  : 'Stores will show up here as soon as merchants start publishing their profiles.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            if (isSearching)
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchTerm = '';
                    _selectedCategory = 'all';
                    _sortMode = 'popular';
                  });
                  _applyFilters();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Clear Filters'),
              ),
          ],
        ),
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
            Icon(Icons.wifi_off_rounded, color: Colors.red[400], size: 64),
            const SizedBox(height: 16),
            Text(
              'Failed to load stores',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _fetchMerchants(forceRefresh: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
