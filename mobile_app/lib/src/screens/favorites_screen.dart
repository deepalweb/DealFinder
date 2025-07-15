import 'package:flutter/material.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';
import '../services/favorites_manager.dart';
import '../widgets/deal_card.dart';

class FavoritesScreen extends StatefulWidget {
  final String userId;
  final String token;
  const FavoritesScreen({Key? key, required this.userId, required this.token}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Promotion>> _favoritesFuture;
  String? _error;
  bool _isLocalFallback = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    setState(() {
      _favoritesFuture = _fetchFavoritesWithFallback();
    });
  }

  Future<List<Promotion>> _fetchFavoritesWithFallback() async {
    try {
      final ids = await FavoritesManager.getFavorites();
      if (ids.isEmpty) return [];
      
      final allPromos = await ApiService().fetchPromotions();
      final favorites = allPromos.where((promo) => ids.contains(promo.id)).toList();
      
      _error = null;
      return favorites;
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  Future<void> _removeFavorite(String id) async {
    await FavoritesManager.removeFavorite(id);
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadFavorites,
          ),
        ],
      ),
      body: FutureBuilder<List<Promotion>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _loadFavorites(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No favorite deals yet'),
                        Text('Start favoriting deals to see them here!'),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          final favorites = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadFavorites(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final promotion = favorites[index];
                return Dismissible(
                  key: ValueKey(promotion.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _removeFavorite(promotion.id),
                  child: DealCard(promotion: promotion),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
