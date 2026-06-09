import 'package:flutter/material.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';
import '../services/favorites_manager.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/deal_card.dart';

class FavoritesScreen extends StatefulWidget {
  final String userId;
  final String token;
  const FavoritesScreen({Key? key, required this.userId, required this.token})
      : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Promotion>> _favoritesFuture;

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
    final api = ApiService();
    try {
      final favorites = await api.fetchFavorites(widget.userId, widget.token);
      final remoteIds = favorites.map((promotion) => promotion.id).toSet();
      final localIds = await FavoritesManager.getFavorites();

      for (final id in localIds.where((id) => !remoteIds.contains(id))) {
        try {
          await api.addFavorite(widget.userId, id, widget.token);
        } catch (_) {}
      }

      final mergedIds = {...remoteIds, ...localIds};
      final merged = <Promotion>[
        ...favorites,
      ];

      if (localIds.any((id) => !remoteIds.contains(id))) {
        final knownIds = merged.map((promotion) => promotion.id).toSet();
        merged.addAll(
          await api.resolveFavoritePromotionsByIds(
            mergedIds.where((id) => !knownIds.contains(id)),
          ),
        );
      }

      await _syncLocalFavorites(merged.map((promotion) => promotion.id));
      return _sortFavorites(merged);
    } catch (_) {
      final ids = await FavoritesManager.getFavorites();
      if (ids.isEmpty) return [];

      return _sortFavorites(await api.resolveFavoritePromotionsByIds(ids));
    }
  }

  List<Promotion> _sortFavorites(List<Promotion> favorites) {
    favorites.sort((a, b) => b.latestActivityAt.compareTo(a.latestActivityAt));
    return favorites;
  }

  Future<void> _syncLocalFavorites(Iterable<String> ids) async {
    for (final id in ids) {
      await FavoritesManager.addFavorite(id);
    }
  }

  Future<void> _removeFavorite(String id, String title) async {
    try {
      await ApiService().removeFavorite(widget.userId, id, widget.token);
    } catch (_) {}
    await FavoritesManager.removeFavorite(id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$title" removed from favorites'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              try {
                await ApiService().addFavorite(widget.userId, id, widget.token);
              } catch (_) {}
              await FavoritesManager.addFavorite(id);
              _loadFavorites();
            },
          ),
        ),
      );
    }

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
            return AppEmptyState(
              icon: Icons.error_outline,
              title: 'Could not load favorites',
              message: 'Please try again in a moment.',
              actionLabel: 'Retry',
              onAction: _loadFavorites,
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _loadFavorites(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: AppEmptyState(
                    icon: Icons.favorite_border,
                    title: 'No favorite deals yet',
                    message:
                        'Start saving deals you love and they will appear here.',
                    actionLabel: 'Refresh',
                    onAction: _loadFavorites,
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
                  onDismissed: (_) =>
                      _removeFavorite(promotion.id, promotion.title),
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
