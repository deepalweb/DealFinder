import 'followed_merchants_screen.dart';
import 'deal_comparison_screen.dart';
import '../services/deal_comparison_service.dart';
import '../services/saved_offer_service.dart';
import '../utils/offer_presentation.dart';
import 'package:flutter/material.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';
import '../services/favorites_manager.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/discover_marketplace_card.dart';
import 'deal_detail_screen.dart';

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
  final _scrollController = ScrollController();
  bool _cached = false;
  String _filter = 'active';
  final _comparison = <String>{};
  String _t(String en, String si, String ta) =>
      switch (Localizations.localeOf(context).languageCode) {
        'si' => si,
        'ta' => ta,
        _ => en
      };

  @override
  void initState() {
    super.initState();
    FavoritesManager.changes.addListener(_loadFavorites);
    _loadFavorites();
    DealComparisonService.getComparisonIds().then((ids) {
      if (mounted) setState(() => _comparison.addAll(ids));
    });
  }

  @override
  void dispose() {
    FavoritesManager.changes.removeListener(_loadFavorites);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadFavorites() {
    if (!mounted) return;
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
    final resolvedLocalFavorites = await api
        .resolveFavoritePromotionsByIds(unresolvedLocalIds)
        .timeout(
          const Duration(seconds: 6),
          onTimeout: () => <Promotion>[],
        )
        .catchError((_) => <Promotion>[]);
    final localFavorites = [
      ...snapshotFavorites,
      ...resolvedLocalFavorites,
    ];
    try {
      final remote = await api
          .fetchFavorites(widget.userId, widget.token)
          .timeout(const Duration(seconds: 6));
      await FavoritesManager.replaceAll(remote);
      _cached = false;
      return _sortFavorites(remote);
    } catch (_) {
      _cached = true;
      return _sortFavorites(localFavorites);
    }
  }

  List<Promotion> _sortFavorites(List<Promotion> favorites) {
    favorites.sort((a, b) => b.latestActivityAt.compareTo(a.latestActivityAt));
    return favorites;
  }

  Future<bool> _removeFavorite(Promotion promotion) async {
    try {
      await SavedOfferService.setSaved(promotion, false);
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.saveOfferFailed)));
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.savedTab),
        actions: [
          IconButton(
              tooltip: AppLocalizations.of(context)!.following,
              icon: const Icon(Icons.storefront_outlined),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          FollowedMerchantsScreen(userId: widget.userId)))),
          IconButton(
              tooltip: _t('Compare up to five offers',
                  'දීමනා පහක් දක්වා සසඳන්න', 'ஐந்து சலுகைகள் வரை ஒப்பிடு'),
              icon: const Icon(Icons.compare_arrows),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DealComparisonScreen()))),
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
          final all = snapshot.data!;
          final favorites = all
              .where((p) =>
                  _filter == 'all' ||
                  (_filter == 'expired'
                      ? p.isExpired
                      : !p.isExpired && p.hasStarted))
              .toList();
          return RefreshIndicator(
            onRefresh: () async => _loadFavorites(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Wrap(spacing: 8, runSpacing: 8, children: [
                        if (_cached)
                          Text(_t(
                              'Saved copy · reconnect to refresh',
                              'සුරැකි පිටපත · යාවත්කාලීන කිරීමට නැවත සම්බන්ධ වන්න',
                              'சேமித்த நகல் · புதுப்பிக்க மீண்டும் இணையவும்')),
                        for (final entry in {
                          'active': _t('Active', 'සක්‍රිය', 'செயலில்'),
                          'expired': AppLocalizations.of(context)!.expired,
                          'all': AppLocalizations.of(context)!.allLabel
                        }.entries)
                          ChoiceChip(
                              label: Text(
                                  '${entry.value} (${all.where((p) => entry.key == 'all' || (entry.key == 'expired' ? p.isExpired : !p.isExpired && p.hasStarted)).length})'),
                              selected: _filter == entry.key,
                              onSelected: (_) =>
                                  setState(() => _filter = entry.key))
                      ]));
                }
                final promotion = favorites[index - 1];
                return Dismissible(
                  key: ValueKey(promotion.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _removeFavorite(promotion),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: DiscoverMarketplaceCard(
                        offer: promotion,
                        trailing: OfferPresentation(promotion).standaloneBank
                            ? null
                            : CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(_t('Compare', 'සසඳන්න', 'ஒப்பிடு')),
                                value: _comparison.contains(promotion.id),
                                onChanged: (value) async {
                                  if (value == true &&
                                      _comparison.length >= 5) {
                                    return;
                                  }
                                  if (value == true) {
                                    await DealComparisonService.addToComparison(
                                        promotion.id);
                                  } else {
                                    await DealComparisonService
                                        .removeFromComparison(promotion.id);
                                  }
                                  if (mounted) {
                                    setState(() => value == true
                                        ? _comparison.add(promotion.id)
                                        : _comparison.remove(promotion.id));
                                  }
                                }),
                        onOpen: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    DealDetailScreen(promotion: promotion)))),
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
