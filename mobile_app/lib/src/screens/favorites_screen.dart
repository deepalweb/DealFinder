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
    final localRecords = await FavoritesManager.getFavoriteRecords();
    final localIds = localRecords.map((record) => record.id).toList();
    final snapshotFavorites = localRecords
        .map((record) => record.promotion)
        .whereType<Promotion>()
        .toList();
    final snapshotIds =
        snapshotFavorites.map((promotion) => promotion.id).toSet();
    final unresolvedLocalIds =
        localIds.where((id) => !snapshotIds.contains(id)).toList();
    final resolvedLocalFavorites =
        await api.resolveFavoritePromotionsByIds(unresolvedLocalIds).timeout(
              const Duration(seconds: 6),
              onTimeout: () => <Promotion>[],
            );
    final localFavorites = [
      ...snapshotFavorites,
      ...resolvedLocalFavorites,
    ];
    final merged = <Promotion>[...localFavorites];
    final knownIds = merged.map((promotion) => promotion.id).toSet();

    try {
      final remoteFavorites = await api
          .fetchFavorites(
            widget.userId,
            widget.token,
          )
          .timeout(
            const Duration(seconds: 6),
            onTimeout: () => <Promotion>[],
          );

      for (final promotion in remoteFavorites) {
        if (knownIds.add(promotion.id)) {
          merged.add(promotion);
        }
      }

      final remoteIds =
          remoteFavorites.map((promotion) => promotion.id).toSet();
      for (final id in localIds.where((id) => !remoteIds.contains(id))) {
        try {
          await api.addFavorite(widget.userId, id, widget.token);
        } catch (_) {}
      }
    } catch (_) {
      // Local favorites are still useful when the remote API is slow/offline.
    }

    await _syncLocalFavorites(merged);
    return _sortFavorites(merged);
  }

  List<Promotion> _sortFavorites(List<Promotion> favorites) {
    favorites.sort((a, b) => b.latestActivityAt.compareTo(a.latestActivityAt));
    return favorites;
  }

  Future<void> _syncLocalFavorites(Iterable<Promotion> promotions) async {
    for (final promotion in promotions) {
      await FavoritesManager.addFavoritePromotion(promotion);
    }
  }

  Future<void> _removeFavorite(Promotion promotion) async {
    try {
      await ApiService().removeFavorite(
        widget.userId,
        promotion.id,
        widget.token,
      );
    } catch (_) {}
    await FavoritesManager.removeFavorite(promotion.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${promotion.title}" removed from favorites'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              try {
                await ApiService().addFavorite(
                  widget.userId,
                  promotion.id,
                  widget.token,
                );
              } catch (_) {}
              await FavoritesManager.addFavoritePromotion(promotion);
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
                  onDismissed: (_) => _removeFavorite(promotion),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      height: 320,
                      child: DealCard(promotion: promotion),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
