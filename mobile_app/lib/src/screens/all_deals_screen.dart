import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/promotion.dart';
import '../models/category.dart';
import '../widgets/modern_deal_card.dart';
import 'deals_list_screen.dart';
import 'deal_detail_screen.dart';
import 'package:shimmer/shimmer.dart';

class AllDealsScreen extends StatefulWidget {
  const AllDealsScreen({super.key});

  @override
  State<AllDealsScreen> createState() => _AllDealsScreenState();
}

class _AllDealsScreenState extends State<AllDealsScreen> {
  late Future<List<Promotion>> _promotionsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  void _loadPromotions() {
    setState(() {
      _promotionsFuture = _apiService.fetchPromotions(forceRefresh: false);
    });
  }

  Future<void> _refreshPromotions() async {
    setState(() {
      _promotionsFuture = _apiService.fetchPromotions(forceRefresh: true);
    });
  }

  Map<String, List<Promotion>> _groupByCategory(List<Promotion> promotions) {
    final Map<String, List<Promotion>> grouped = {};
    
    // Sort promotions by createdAt (most recent first)
    promotions.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    
    for (var promo in promotions) {
      final category = promo.category ?? 'other';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(promo);
    }
    
    return grouped;
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
      'food_bev': Icons.restaurant,
      'electronics': Icons.devices,
      'fashion': Icons.checkroom,
      'travel': Icons.flight,
      'home_garden': Icons.home,
      'beauty_health': Icons.spa,
      'entertainment': Icons.movie,
      'services': Icons.build,
      'other': Icons.category,
    };
    return iconMap[categoryId] ?? Icons.category;
  }

  Color _getCategoryColor(String categoryId) {
    const colorMap = {
      'food_bev': Color(0xFFFF6B6B),
      'electronics': Color(0xFF4ECDC4),
      'fashion': Color(0xFFFFBE0B),
      'travel': Color(0xFF95E1D3),
      'home_garden': Color(0xFF38A3A5),
      'beauty_health': Color(0xFFFF6B9D),
      'entertainment': Color(0xFF9B59B6),
      'services': Color(0xFF3498DB),
      'other': Color(0xFF95A5A6),
    };
    return colorMap[categoryId] ?? const Color(0xFF95A5A6);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('All Deals', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
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
            final totalDeals = snapshot.data!.length;
            return _buildCategoryList(groupedDeals, totalDeals);
          },
        ),
      ),
    );
  }

  Widget _buildCategoryList(Map<String, List<Promotion>> groupedDeals, int totalDeals) {
    final sortedCategories = groupedDeals.keys.toList()
      ..sort((a, b) => groupedDeals[b]!.length.compareTo(groupedDeals[a]!.length));

    return CustomScrollView(
      slivers: [
        // Stats header
        SliverToBoxAdapter(
          child: Container(
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
                _buildStatItem(Icons.local_offer, '$totalDeals', 'Total Deals'),
                Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                _buildStatItem(Icons.category, '${sortedCategories.length}', 'Categories'),
              ],
            ),
          ),
        ),
        // Category sections
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final categoryId = sortedCategories[index];
                final deals = groupedDeals[categoryId]!;
                final categoryName = _getCategoryName(categoryId);
                return _buildCategorySection(categoryId, categoryName, deals, index);
              },
              childCount: sortedCategories.length,
            ),
          ),
        ),
      ],
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

  Widget _buildCategorySection(String categoryId, String categoryName, List<Promotion> deals, int index) {
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
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    categoryColor.withOpacity(0.1),
                    categoryColor.withOpacity(0.05),
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
                      color: categoryColor.withOpacity(0.2),
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${deals.length} deals available',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (deals.length > 4)
                    Material(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          final category = predefinedCategories.firstWhere(
                            (cat) => cat.id == categoryId,
                            orElse: () => Category(id: categoryId, name: categoryName),
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'See All',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
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
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                itemCount: displayDeals.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 160,
                    margin: EdgeInsets.only(
                      right: index < displayDeals.length - 1 ? 12 : 0,
                    ),
                    child: ModernDealCard(
                      promotion: displayDeals[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DealDetailScreen(promotion: displayDeals[index]),
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
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Container(
                    width: 160,
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
              label: const Text('Try Again'),
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
}
