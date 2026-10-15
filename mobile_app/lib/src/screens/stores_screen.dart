import '../widgets/storefront_theme.dart';
import '../widgets/stitch_discover_components.dart' show stitchLabel;
import '../widgets/sign_in_gate.dart';
import '../config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

import '../models/category.dart';
import '../services/api_service.dart';
import '../services/merchant_following_manager.dart';
import '../services/search_matcher.dart';
import '../widgets/merchant_card.dart';
import '../widgets/merchant_card_shimmer.dart';
import 'merchant_profile_screen.dart';

class StoresScreen extends StatelessWidget {
  const StoresScreen({super.key, this.initialQuery = '', this.api});
  final String initialQuery;
  final ApiService? api;
  @override
  Widget build(BuildContext context) => Theme(
      data: storefrontTheme(Theme.of(context)),
      child: _StoresPage(initialQuery: initialQuery, api: api));
}

class _StoresPage extends StatefulWidget {
  const _StoresPage({required this.initialQuery, this.api});
  final String initialQuery;
  final ApiService? api;
  @override
  State<_StoresPage> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<_StoresPage> {
  late final ApiService _api = widget.api ?? ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allMerchants = [];
  List<Map<String, dynamic>> _filteredMerchants = [];
  bool _loading = true;
  String _searchTerm = '';
  String _selectedCategory = 'all';
  String _sortMode = 'popular';
  String? _error;
  final Set<String> _followingMerchants = {};
  final Set<String> _followLoadingMerchants = {};

  late final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'All', 'icon': 'all_inclusive'},
    ...predefinedCategories
        .where((category) => category.id != 'other')
        .map((category) => {
              'id': category.id,
              'name': category.name,
              'icon': category.id,
            }),
  ];

  @override
  void initState() {
    super.initState();
    _searchTerm = widget.initialQuery;
    _searchController.text = widget.initialQuery;
    _bootstrap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadFollowingMerchants();
    await _fetchMerchants();
  }

  Future<void> _loadFollowingMerchants() async {
    final followed = await MerchantFollowingManager.getFollowingMerchants();
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
      final merchants = await _api.fetchMerchants(forceRefresh: forceRefresh);
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
    final term = _searchTerm.trim();
    var results = [..._allMerchants];

    if (term.isNotEmpty) {
      results = results
          .where((merchant) => SearchMatcher.matchesMerchant(merchant, term))
          .toList();
    }

    if (_selectedCategory != 'all') {
      results = results
          .where((merchant) =>
              _normalizedMerchantCategory(merchant) == _selectedCategory)
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
    final deals =
        ((merchant['activeDeals'] ?? merchant['deals']) as num?)?.toInt() ?? 0;
    final averageRating = (merchant['averageRating'] as num?)?.toDouble() ?? 0;
    final ratingsCount = (merchant['ratingsCount'] as num?)?.toInt() ?? 0;
    final ratingScore =
        averageRating > 0 ? (averageRating * 8).round() + ratingsCount : 0;
    return (followers * 3) + (deals * 5) + ratingScore;
  }

  String _merchantIdOf(Map<String, dynamic> merchant) =>
      (merchant['id'] ?? merchant['_id'] ?? '').toString();

  String _normalizedMerchantCategory(Map<String, dynamic> merchant) =>
      SearchMatcher.normalizeCategory((merchant['category'] ?? '').toString());

  Future<void> _toggleFollow(String merchantId) async {
    if (_followLoadingMerchants.contains(merchantId)) return;
    if (!await requireSignIn(context) || !mounted) return;
    HapticFeedback.lightImpact();
    final isFollowing = _followingMerchants.contains(merchantId);
    final previousFollowerCount = _merchantFollowerCount(merchantId);
    setState(() {
      _followLoadingMerchants.add(merchantId);
      _setMerchantFollowState(
        merchantId: merchantId,
        isFollowing: !isFollowing,
        followers:
            (previousFollowerCount + (isFollowing ? -1 : 1)).clamp(0, 1 << 30),
      );
    });
    _applyFilters();

    try {
      final followers = isFollowing
          ? await MerchantFollowingManager.unfollowMerchant(merchantId)
          : await MerchantFollowingManager.followMerchant(merchantId);
      if (!mounted) return;
      setState(() {
        _followLoadingMerchants.remove(merchantId);
        if (followers != null) {
          _setMerchantFollowState(
            merchantId: merchantId,
            isFollowing: !isFollowing,
            followers: followers,
          );
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
              Text(
                isFollowing
                    ? 'Store removed from your follows'
                    : 'Store added to your follows',
              ),
            ],
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isFollowing ? const Color(0xFF455A64) : const Color(0xFF2E7D32),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _followLoadingMerchants.remove(merchantId);
        _setMerchantFollowState(
          merchantId: merchantId,
          isFollowing: isFollowing,
          followers: previousFollowerCount,
        );
      });
      _applyFilters();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update store follow right now'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _shareMerchant(Map<String, dynamic> merchant) {
    HapticFeedback.mediumImpact();
    final name = merchant['name'] ?? 'Store';
    final category = merchant['category'] ?? 'store';
    Share.share(
      'Check out $name on Deal Finder.\nGreat $category deals and local offers await.',
    );
  }

  Future<void> _openMerchant(Map<String, dynamic> merchant) async {
    final merchantId = _merchantIdOf(merchant);
    if (merchantId.isEmpty) return;
    HapticFeedback.lightImpact();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MerchantProfileScreen(merchantId: merchantId, api: _api),
      ),
    );
    if (!mounted) return;
    await _loadFollowingMerchants();
    _applyFilters();
  }

  int _merchantFollowerCount(String merchantId) {
    final merchant = _allMerchants.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item != null && _merchantIdOf(item) == merchantId,
          orElse: () => null,
        );
    return (merchant?['followers'] as num?)?.toInt() ?? 0;
  }

  void _setMerchantFollowState({
    required String merchantId,
    required bool isFollowing,
    required int followers,
  }) {
    if (isFollowing) {
      _followingMerchants.add(merchantId);
    } else {
      _followingMerchants.remove(merchantId);
    }
    _allMerchants = _allMerchants.map((merchant) {
      if (_merchantIdOf(merchant) != merchantId) return merchant;
      return {
        ...merchant,
        'followers': followers,
      };
    }).toList();
  }

  bool get _hasActiveFilters =>
      _searchTerm.trim().isNotEmpty ||
      _selectedCategory != 'all' ||
      _sortMode != 'popular';

  int get _activeFilterCount {
    var count = 0;
    if (_searchTerm.trim().isNotEmpty) count++;
    if (_selectedCategory != 'all') count++;
    if (_sortMode != 'popular') count++;
    return count;
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchTerm = '';
      _selectedCategory = 'all';
      _sortMode = 'popular';
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
            title: Text(l10n.stores),
            backgroundColor: colors.surface,
            foregroundColor: colors.onSurface,
            titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.onSurface, fontWeight: FontWeight.w700)),
        body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: _loading
                    ? buildMerchantListShimmer(itemCount: 5)
                    : _error != null
                        ? _buildError()
                        : RefreshIndicator(
                            onRefresh: () =>
                                _fetchMerchants(forceRefresh: true),
                            child: CustomScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                slivers: [
                                  SliverPadding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 8, 16, 16),
                                      sliver: SliverToBoxAdapter(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(
                                                stitchLabel(
                                                    context,
                                                    'Find stores and explore their offers.',
                                                    'වෙළඳසැල් සහ ඒවායේ දීමනා සොයන්න.',
                                                    'கடைகளையும் அவற்றின் சலுகைகளையும் கண்டறியுங்கள்.'),
                                                style: TextStyle(
                                                    color: colors
                                                        .onSurfaceVariant)),
                                            const SizedBox(height: 12),
                                            _buildSearchBar(),
                                            const SizedBox(height: 12),
                                            _buildCategoryFilter(),
                                            if (_hasActiveFilters) ...[
                                              const SizedBox(height: 12),
                                              _buildActiveFilterBar()
                                            ],
                                            const SizedBox(height: 16),
                                            _buildSectionHeader(
                                                title: l10n.browseAllStores,
                                                subtitle: l10n.storesSummary(
                                                    _filteredMerchants.length,
                                                    _followingMerchants.length,
                                                    _allMerchants.length),
                                                trailing: _buildSortMenu()),
                                          ]))),
                                  if (_filteredMerchants.isEmpty)
                                    SliverFillRemaining(
                                        hasScrollBody: false,
                                        child: _buildEmptyState())
                                  else
                                    SliverPadding(
                                        padding: EdgeInsets.fromLTRB(
                                            16,
                                            0,
                                            16,
                                            24 +
                                                MediaQuery.paddingOf(context)
                                                    .bottom),
                                        sliver: SliverList.builder(
                                            itemCount:
                                                _filteredMerchants.length,
                                            itemBuilder: (_, index) {
                                              final merchant =
                                                  _filteredMerchants[index];
                                              final id =
                                                  _merchantIdOf(merchant);
                                              return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 12),
                                                  child: MerchantCard(
                                                      merchant: merchant,
                                                      isFollowing:
                                                          _followingMerchants
                                                              .contains(id),
                                                      isFollowUpdating:
                                                          _followLoadingMerchants
                                                              .contains(id),
                                                      onFollowToggle: () =>
                                                          _toggleFollow(id),
                                                      onShare: () =>
                                                          _shareMerchant(
                                                              merchant),
                                                      onVisit: () =>
                                                          _openMerchant(
                                                              merchant)));
                                            })),
                                ])))));
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
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
          hintText: stitchLabel(
              context,
              'Search stores or categories',
              'වෙළඳසැල් හෝ ප්‍රවර්ග සොයන්න',
              'கடைகள் அல்லது வகைகளைத் தேடுங்கள்'),
          labelText: l10n.stores,
          hintStyle: TextStyle(color: AppColors.muted(context)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF8B97A8)),
          suffixIcon: _searchTerm.isNotEmpty
              ? IconButton(
                  tooltip:
                      MaterialLocalizations.of(context).deleteButtonTooltip,
                  icon:
                      const Icon(Icons.close_rounded, color: Color(0xFF8B97A8)),
                  onPressed: () {
                    _searchController.clear();
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
        controller: _searchController,
      ),
    );
  }

  Widget _buildCategoryFilter() => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final category in _categories)
          Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                  label: Text(category['name']!),
                  selected: _selectedCategory == category['id'],
                  onSelected: (_) {
                    setState(() => _selectedCategory = category['id']!);
                    _applyFilters();
                  })),
      ]));

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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text(context),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.muted(context),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildActiveFilterBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 18,
                color: Color(0xFF4F5D75),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.activeFiltersLabel(_activeFilterCount),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text(context),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearFilters,
                child: Text(l10n.clearAll),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_searchTerm.trim().isNotEmpty)
                _buildActiveFilterChip(
                  icon: Icons.search_rounded,
                  label: l10n.searchFilterLabel(_searchTerm.trim()),
                  onRemoved: () {
                    _searchController.clear();
                    _searchController.clear();
                    setState(() => _searchTerm = '');
                    _applyFilters();
                  },
                ),
              if (_selectedCategory != 'all')
                _buildActiveFilterChip(
                  icon: Icons.category_outlined,
                  label: l10n.categoryFilterLabel(
                    _categories.firstWhere(
                        (item) => item['id'] == _selectedCategory)['name']!,
                  ),
                  onRemoved: () {
                    setState(() => _selectedCategory = 'all');
                    _applyFilters();
                  },
                ),
              if (_sortMode != 'popular')
                _buildActiveFilterChip(
                  icon: Icons.sort_rounded,
                  label: l10n.sortFilterLabel(_sortLabel(_sortMode)),
                  onRemoved: () {
                    setState(() => _sortMode = 'popular');
                    _applyFilters();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onRemoved,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4F5D75)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF243447),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemoved,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.muted(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortMenu() {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      initialValue: _sortMode,
      onSelected: (value) {
        setState(() => _sortMode = value);
        _applyFilters();
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'popular', child: Text(l10n.mostPopular)),
        PopupMenuItem(value: 'following', child: Text(l10n.followingFirst)),
        PopupMenuItem(value: 'a_z', child: Text(l10n.aToZ)),
        PopupMenuItem(value: 'new', child: Text(l10n.newest)),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5EAF1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF5C6B7A)),
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
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case 'following':
        return l10n.following;
      case 'a_z':
        return l10n.aToZ;
      case 'new':
        return l10n.newest;
      case 'popular':
      default:
        return l10n.popular;
    }
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
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
            Text(
              l10n.noStoresMatchView,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isSearching
                  ? l10n.noStoresMatchSubtitle
                  : l10n.storesWillAppearSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.muted(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                if (isSearching)
                  OutlinedButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_rounded),
                    label: Text(l10n.clearFilters),
                  ),
                FilledButton.tonalIcon(
                  onPressed: () => _fetchMerchants(forceRefresh: true),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                ),
                if (_followingMerchants.isNotEmpty)
                  FilledButton.tonalIcon(
                    onPressed: () {
                      setState(() => _sortMode = 'following');
                      _applyFilters();
                    },
                    icon: const Icon(Icons.favorite_outline),
                    label: Text(l10n.showFollowed),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.red[400], size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.failedToLoadStores,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.muted(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? l10n.unknownError,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted(context), height: 1.4),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _fetchMerchants(forceRefresh: true),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.tryAgain),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: Text(l10n.resetView),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
