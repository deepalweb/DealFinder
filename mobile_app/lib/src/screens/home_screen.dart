import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../models/promotion.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/location_service.dart';
import '../services/browsing_area.dart';
import '../services/app_session.dart';
import '../utils/bank_card_promotion_support.dart';
import '../widgets/discover_offer_surface.dart';
import '../widgets/discover_offer_tile.dart';
import '../widgets/sign_in_gate.dart';
import 'all_deals_screen.dart';
import 'nearby_deals_screen.dart';
import 'notifications_screen.dart';
import 'stores_screen.dart';
import 'search_screen.dart';
import 'deal_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen(
      {super.key,
      this.api,
      this.onNavigateToFavorites,
      this.onNavigateNearby,
      this.onNavigateAccount,
      this.onNavigateBankOffers});
  final ApiService? api;
  final VoidCallback? onNavigateToFavorites;
  final VoidCallback? onNavigateNearby;
  final VoidCallback? onNavigateAccount;
  final ValueChanged<String?>? onNavigateBankOffers;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final _api = widget.api ?? ApiService();
  List<Promotion> _offers = [];
  List<Promotion> _curated = [];
  List<Promotion> _recommended = [];
  Position? _position;
  String? _area;
  String? _category;
  String? _fulfillment;
  bool _bankOnly = false;
  bool _loading = true;
  bool _offline = false;
  bool _bannerManaged = false;
  int _unread = 0;
  String _recommendationUserId = '';
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    AppSession.changes.addListener(_sessionChanged);
    BrowsingArea.changes.addListener(_areaChanged);
    _load();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    AppSession.changes.removeListener(_sessionChanged);
    BrowsingArea.changes.removeListener(_areaChanged);
    _ticker?.cancel();
    super.dispose();
  }

  void _sessionChanged() {
    if (!mounted) return;
    setState(() {
      _recommended = [];
      _recommendationUserId = '';
      _unread = 0;
    });
    _loadRecommendations();
    _loadNotifications();
  }

  Future<void> _load() async {
    final cached = await CacheService.loadPromotions();
    if (!mounted) return;
    if (cached != null) {
      setState(() {
        _offers = cached;
        _loading = false;
      });
    }
    await Future.wait([
      _loadOffers(),
      _loadCurated(),
      _loadLocation(),
      _loadRecommendations(),
      _loadNotifications()
    ]);
  }

  Future<void> _loadOffers() async {
    try {
      final offers = await _api.fetchPromotions(forceRefresh: true);
      if (mounted) {
        setState(() {
          _offers = offers;
          _loading = false;
          _offline = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _offline = true;
        });
      }
    }
  }

  Future<void> _loadCurated() async {
    try {
      final sections = await _api.fetchCuratedHomeSections();
      if (mounted) {
        setState(() {
          _curated = sections.banner;
          _bannerManaged = sections.bannerManaged;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadRecommendations() async {
    try {
      final session = await AppSession.read();
      final offers = await _api.fetchRecommendedPromotions(limit: 6);
      final current = await AppSession.read();
      if (mounted && session.userId == current.userId) {
        setState(() {
          _recommended = offers;
          _recommendationUserId = session.userId;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadNotifications() async {
    if (!(await AppSession.read()).isSignedIn) return;
    try {
      final count = await _api.fetchUnreadNotificationCount();
      if (mounted) setState(() => _unread = count);
    } catch (_) {}
  }

  void _areaChanged() {
    final area = BrowsingArea.changes.value;
    if (!mounted || area == null) return;
    setState(() {
      _area = area.label;
      _position = Position(
          latitude: area.latitude,
          longitude: area.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0);
    });
  }

  Future<void> _loadLocation({bool requestPermission = false}) async {
    try {
      final saved = await BrowsingArea.read();
      if (!requestPermission && saved != null) {
        if (mounted) {
          setState(() {
            _area = saved.label;
            _position = Position(
                latitude: saved.latitude,
                longitude: saved.longitude,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                altitudeAccuracy: 0,
                heading: 0,
                headingAccuracy: 0,
                speed: 0,
                speedAccuracy: 0);
          });
        }
        return;
      }
      final result = await LocationService.resolveCurrentLocation(
          requestPermission: requestPermission);
      if (!mounted || result.position == null) return;
      setState(() => _position = result.position);
      final area = await LocationService.getLocationName(
          _position!.latitude, _position!.longitude);
      if (mounted) setState(() => _area = area);
    } catch (_) {}
  }

  bool _matchesFilters(Promotion p) =>
      (_fulfillment == null ||
          switch (_fulfillment) {
            'delivery' => p.supportsDelivery,
            'pickup' => p.supportsPickup,
            _ => p.supportsVisit,
          }) &&
      (!_bankOnly || BankCardPromotionSupport.isBankCardPromotion(p));

  List<Promotion> get _visible => _offers
      .where((p) =>
          (p.hasStarted && !p.isExpired) &&
          (_category == null || p.category == _category) &&
          _matchesFilters(p))
      .toList();
  List<Promotion> get _featured {
    final curated = _curated
        .where((p) =>
            (p.hasStarted && !p.isExpired) &&
            (_category == null || p.category == _category) &&
            _matchesFilters(p))
        .toList();
    return ((_bannerManaged || curated.isNotEmpty)
            ? curated
            : _visible.where((p) => p.featured == true).toList())
        .take(3)
        .toList();
  }

  List<Promotion> get _nearby {
    if (_position == null) return [];
    final nearby = _visible
        .where(
            (p) => p.latitude != null && p.longitude != null && p.supportsVisit)
        .map((p) => p.copyWith(
            distance: LocationService.calculateDistance(_position!.latitude,
                    _position!.longitude, p.latitude!, p.longitude!) *
                1000))
        .where((p) => p.distance! <= 3000)
        .toList();
    nearby.sort((a, b) => a.distance!.compareTo(b.distance!));
    return nearby;
  }

  List<Promotion> get _ending {
    final now =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final today = DateTime.utc(now.year, now.month, now.day);
    final ending = _visible.where((p) {
      if (p.endDate == null || p.isExpired) return false;
      final end = p.endDate!.toUtc().add(const Duration(hours: 5, minutes: 30));
      return DateTime.utc(end.year, end.month, end.day)
              .difference(today)
              .inDays <=
          3;
    }).toList();
    ending.sort((a, b) => a.endDate!.compareTo(b.endDate!));
    return ending.take(3).toList();
  }

  void _open(Promotion offer) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => DealDetailScreen(promotion: offer)));
  void _nearbyTab() {
    if (widget.onNavigateNearby != null) {
      widget.onNavigateNearby!();
      return;
    }
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const NearbyDealsScreen()));
  }

  void _bank(String? bank) {
    if (widget.onNavigateBankOffers != null) {
      widget.onNavigateBankOffers!(bank);
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                AllDealsScreen(bankOffersOnly: true, initialBankName: bank)));
  }

  Future<void> _notifications() async {
    if (!await requireSignIn(context) || !mounted) return;
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    _loadNotifications();
  }

  String _t(String en, String si, String ta) {
    return switch (Localizations.localeOf(context).languageCode) {
      'si' => si,
      'ta' => ta,
      _ => en,
    };
  }

  void _all({bool endingSoon = false}) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AllDealsScreen(
                initialCategoryId: _category,
                initialCapabilityPresetId: _fulfillment,
                bankOffersOnly: _bankOnly,
                initialPrimaryFilter: endingSoon ? 'ending_soon' : null,
                initialSortBy: endingSoon ? 'ending_soon' : null,
              )));

  void _stores() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const StoresScreen()));

  Widget _section(String title, {String? subtitle, VoidCallback? onAll}) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 16)),
                if (subtitle != null)
                  Text(subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 11)),
              ])),
          if (onAll != null)
            TextButton(
                onPressed: onAll,
                child: Text(AppLocalizations.of(context)!.viewAll)),
        ]),
      );

  Widget _card(Promotion offer, {bool editorial = false}) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DiscoverOfferSurface(
          offer: offer,
          layout: editorial
              ? DiscoverSurfaceLayout.editorial
              : DiscoverSurfaceLayout.detail,
          onOpen: () => _open(offer)));

  Widget _rail(List<Promotion> offers) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: offers
              .take(6)
              .map((offer) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                      width: 240,
                      child: DiscoverOfferTile(
                          offer: offer, onOpen: () => _open(offer)))))
              .toList()));

  Widget _fulfillmentControls() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
        child: Row(children: [
          for (final mode in [
            ('delivery', l10n.deliveryLabel, Icons.delivery_dining),
            ('visit_store', l10n.inStoreLabel, Icons.restaurant_outlined),
            ('pickup', l10n.pickupLabel, Icons.shopping_bag_outlined),
          ])
            Padding(
                padding: const EdgeInsets.only(right: 4),
                child: FilterChip(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    labelPadding: EdgeInsets.zero,
                    shape: const StadiumBorder(),
                    label: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(mode.$3, size: 12),
                      const SizedBox(width: 4),
                      Text(mode.$2, style: const TextStyle(fontSize: 11)),
                    ]),
                    selected: _fulfillment == mode.$1,
                    onSelected: (selected) => setState(
                        () => _fulfillment = selected ? mode.$1 : null))),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final visible = _visible;
    final featured = _featured;
    final nearby = _nearby;
    final ending = _ending;
    final bankOffers = visible
        .where(BankCardPromotionSupport.isBankCardPromotion)
        .where((p) => p.bankName?.isNotEmpty == true)
        .toList();
    final nearbyBankOffers =
        nearby.where(BankCardPromotionSupport.isBankCardPromotion).toList();
    final bankGrid =
        nearbyBankOffers.isNotEmpty ? nearbyBankOffers : bankOffers;
    final topDeals = nearby.isNotEmpty ? nearby : visible;
    final shown = <String>{
      if (featured.isNotEmpty) featured.first.id,
      ...topDeals.take(4).map((p) => p.id),
      ...bankGrid.take(4).map((p) => p.id),
      if (ending.isNotEmpty) ending.first.id,
    };
    final explore = <Promotion>[];
    final explored = <String>{};
    for (final offer in [..._recommended, ...visible]) {
      if (offer.hasStarted &&
          !offer.isExpired &&
          (_category == null || offer.category == _category) &&
          _matchesFilters(offer) &&
          !shown.contains(offer.id) &&
          explored.add(offer.id)) {
        explore.add(offer);
      }
    }
    final personalized = _recommendationUserId.isNotEmpty &&
        explore.take(4).any((p) => const {
              'Based on categories you view',
              'From stores you like',
              'Saved in your favorites',
              'From a store you follow'
            }.contains(p.recommendationReason));
    return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: nearby.isEmpty
            ? null
            : ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width - 32),
                child: Material(
                    color: theme.colorScheme.inverseSurface,
                    borderRadius: BorderRadius.circular(28),
                    elevation: 4,
                    child: InkWell(
                        onTap: _nearbyTab,
                        borderRadius: BorderRadius.circular(28),
                        child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                      _t(
                                          '${nearby.length} ${nearby.length == 1 ? 'offer' : 'offers'} within 3 km',
                                          'කි.මී. 3 තුළ දීමනා ${nearby.length}',
                                          '3 கி.மீ. தூரத்தில் ${nearby.length} சலுகைகள்'),
                                      style: TextStyle(
                                          color: theme
                                              .colorScheme.onInverseSurface,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  Text(_t('Map', 'සිතියම', 'வரைபடம்'),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: theme
                                              .colorScheme.onInverseSurface)),
                                  Icon(Icons.map_outlined,
                                      size: 16,
                                      color:
                                          theme.colorScheme.onInverseSurface),
                                ]))))),
        body: SafeArea(
            child: Padding(
                padding: EdgeInsets.only(
                    bottom: nearby.isEmpty
                        ? 0
                        : MediaQuery.textScalerOf(context).scale(12) * 4 + 32),
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
                    key: const PageStorageKey('discover-visual-feed'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      PinnedHeaderSliver(
                          child: Material(
                              color: theme.scaffoldBackgroundColor,
                              child: Column(children: [
                                Padding(
                                    padding:
                                        const EdgeInsets.only(top: 4, right: 8),
                                    child: Row(children: [
                                      Expanded(child: _fulfillmentControls()),
                                      IconButton(
                                          tooltip: l10n.bankOffersTab,
                                          onPressed: () => _bank(null),
                                          icon: const Icon(
                                              Icons.credit_card_outlined,
                                              size: 20)),
                                      IconButton(
                                          tooltip: l10n.notifications,
                                          onPressed: _notifications,
                                          icon: Badge(
                                              isLabelVisible: _unread > 0,
                                              label: Text('$_unread'),
                                              child: const Icon(
                                                  Icons.notifications_none,
                                                  size: 20))),
                                    ])),
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Row(children: [
                                      Expanded(
                                          child: InkWell(
                                              onTap: _nearbyTab,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 12),
                                                  child: Row(children: [
                                                    Icon(
                                                        Icons
                                                            .location_on_outlined,
                                                        size: 17,
                                                        color: theme.colorScheme
                                                            .primary),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                        child: Text(
                                                            _area ??
                                                                l10n
                                                                    .chooseAreaLabel,
                                                            style: theme
                                                                .textTheme
                                                                .labelLarge
                                                                ?.copyWith(
                                                                    fontSize:
                                                                        12,
                                                                    color: theme
                                                                        .colorScheme
                                                                        .onSurface),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis)),
                                                    const Icon(
                                                        Icons.expand_more,
                                                        size: 16),
                                                  ])))),
                                      TextButton(
                                          onPressed: () => _bank(null),
                                          style: TextButton.styleFrom(
                                              textStyle: theme
                                                  .textTheme.labelLarge
                                                  ?.copyWith(fontSize: 11)),
                                          child: Text(l10n.bankOffersTab)),
                                    ])),
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    child: Material(
                                        color: theme.colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(24),
                                        child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        const SearchScreen())),
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 12),
                                                child: Row(children: [
                                                  const Icon(Icons.search,
                                                      size: 18),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                      child: Text(
                                                          l10n.searchHint,
                                                          style: theme.textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                  fontSize:
                                                                      12))),
                                                  const Icon(Icons.tune,
                                                      size: 18)
                                                ]))))),
                                SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 8, 16, 12),
                                    child: Row(children: [
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: ChoiceChip(
                                              visualDensity:
                                                  const VisualDensity(
                                                      horizontal: -2,
                                                      vertical: -2),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6),
                                              shape: const StadiumBorder(),
                                              labelStyle:
                                                  const TextStyle(fontSize: 12),
                                              label: Text(
                                                  '${l10n.allLabel} (${_offers.where((p) => p.hasStarted && !p.isExpired).length})'),
                                              selected: _category == null &&
                                                  !_bankOnly,
                                              onSelected: (_) => setState(() {
                                                    _category = null;
                                                    _bankOnly = false;
                                                    _fulfillment = null;
                                                  }))),
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: FilterChip(
                                              visualDensity:
                                                  const VisualDensity(
                                                      horizontal: -2,
                                                      vertical: -2),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6),
                                              shape: const StadiumBorder(),
                                              labelStyle:
                                                  const TextStyle(fontSize: 12),
                                              avatar: const Icon(
                                                  Icons.credit_card,
                                                  size: 18),
                                              label: Text(l10n.bankOffersTab),
                                              selected: _bankOnly,
                                              onSelected: (value) => setState(
                                                  () => _bankOnly = value))),
                                      ...predefinedCategories
                                          .where((c) => _offers.any((p) =>
                                              p.hasStarted &&
                                              !p.isExpired &&
                                              p.category == c.id))
                                          .map((c) => Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8),
                                              child: ChoiceChip(
                                                  visualDensity:
                                                      const VisualDensity(
                                                          horizontal: -2,
                                                          vertical: -2),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 6),
                                                  shape: const StadiumBorder(),
                                                  labelStyle: const TextStyle(
                                                      fontSize: 12),
                                                  label:
                                                      Text(getCategoryLabel(c.id)),
                                                  selected: _category == c.id,
                                                  onSelected: (_) => setState(() => _category = c.id)))),
                                    ])),
                              ]))),
                      if (_offline)
                        SliverToBoxAdapter(
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(_offers.isEmpty
                                          ? _t(
                                              'Could not load offers.',
                                              'දීමනා පූරණය කළ නොහැකි විය.',
                                              'சலுகைகளை ஏற்ற முடியவில்லை.')
                                          : l10n.offlineShowingCachedDeals),
                                      TextButton.icon(
                                          onPressed: _load,
                                          icon: const Icon(Icons.refresh),
                                          label: Text(l10n.retry)),
                                    ]))),
                      if (_loading)
                        const SliverToBoxAdapter(
                            child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                    child: CircularProgressIndicator()))),
                      if (featured.isNotEmpty)
                        SliverToBoxAdapter(
                            child: _card(featured.first, editorial: true)),
                      if (bankOffers.isNotEmpty)
                        SliverToBoxAdapter(
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 0),
                                child: Material(
                                    color: theme.colorScheme.surface,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                            color: theme
                                                .colorScheme.outlineVariant)),
                                    child: InkWell(
                                        onTap: () => _bank(null),
                                        child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            child: Row(children: [
                                              Icon(Icons.verified_user_outlined,
                                                  size: 24,
                                                  color: theme
                                                      .colorScheme.primary),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                    Text(l10n.bankOffersTab,
                                                        style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700)),
                                                    Text(
                                                        _t(
                                                            'Check card requirements for each offer.',
                                                            'එක් එක් දීමනාවේ කාඩ්පත් අවශ්‍යතා බලන්න.',
                                                            'ஒவ்வொரு சலுகையின் அட்டை நிபந்தனைகளைப் பார்க்கவும்.'),
                                                        style: theme
                                                            .textTheme.bodySmall
                                                            ?.copyWith(
                                                                fontSize: 11)),
                                                  ])),
                                              IconButton(
                                                  tooltip: l10n.viewAll,
                                                  onPressed: () => _bank(null),
                                                  icon: const Icon(
                                                      Icons.chevron_right,
                                                      size: 18)),
                                            ])))))),
                      SliverToBoxAdapter(
                          child: _section(
                              _t("Today's offers", 'අද දීමනා',
                                  'இன்றைய சலுகைகள்'),
                              subtitle: nearby.isEmpty
                                  ? null
                                  : '${_area ?? l10n.nearbyTab} · 3 km',
                              onAll: _all)),
                      if (topDeals.isNotEmpty)
                        SliverToBoxAdapter(child: _rail(topDeals)),
                      if (_position == null)
                        SliverToBoxAdapter(
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Wrap(spacing: 8, children: [
                                  TextButton(
                                      onPressed: _nearbyTab,
                                      child: Text(l10n.chooseAreaLabel)),
                                  TextButton.icon(
                                      onPressed: () => _loadLocation(
                                          requestPermission: true),
                                      icon: const Icon(Icons.my_location),
                                      label: Text(l10n.useMyLocation)),
                                ]))),
                      if (bankGrid.isNotEmpty) ...[
                        SliverToBoxAdapter(
                            child: _section(
                                nearbyBankOffers.isNotEmpty
                                    ? _t(
                                        'Bank offers near you',
                                        'ඔබ අසල බැංකු දීමනා',
                                        'அருகிலுள்ள வங்கிச் சலுகைகள்')
                                    : l10n.bankOffersTab,
                                subtitle: nearbyBankOffers.isNotEmpty
                                    ? '${_area ?? l10n.nearbyTab} · 3 km'
                                    : null,
                                onAll: () => _bank(null))),
                        SliverToBoxAdapter(
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: DiscoverOfferGrid(
                                    offers: bankGrid.take(4).toList(),
                                    onOpen: _open))),
                      ],
                      if (ending.isNotEmpty)
                        SliverToBoxAdapter(
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 24, 16, 0),
                                child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: theme.colorScheme.error,
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Icon(Icons.timer_outlined,
                                                color:
                                                    theme.colorScheme.onError),
                                            const SizedBox(width: 8),
                                            Expanded(
                                                child: Text(
                                                    l10n.endingSoonLabel,
                                                    style: theme
                                                        .textTheme.titleMedium
                                                        ?.copyWith(
                                                            fontSize: 13,
                                                            color: theme
                                                                .colorScheme
                                                                .onError))),
                                            IconButton(
                                                tooltip: l10n.viewAll,
                                                onPressed: () =>
                                                    _all(endingSoon: true),
                                                icon: Icon(Icons.arrow_forward,
                                                    color: theme
                                                        .colorScheme.onError)),
                                          ]),
                                          DiscoverOfferSurface(
                                              layout:
                                                  DiscoverSurfaceLayout.expiry,
                                              offer: ending.first,
                                              onOpen: () =>
                                                  _open(ending.first)),
                                        ])))),
                      if (explore.isNotEmpty) ...[
                        SliverToBoxAdapter(
                            child: _section(
                                personalized
                                    ? l10n.recommendedForYouTitle
                                    : _t('More offers', 'තවත් දීමනා',
                                        'மேலும் சலுகைகள்'),
                                onAll: _all)),
                        SliverList.list(
                            children:
                                explore.take(4).map((p) => _card(p)).toList()),
                      ],
                      SliverToBoxAdapter(
                          child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: OutlinedButton.icon(
                                  onPressed: _all,
                                  icon: const Icon(Icons.grid_view_outlined),
                                  label: Text(_t(
                                      'Browse all offers',
                                      'සියලු දීමනා බලන්න',
                                      'அனைத்து சலுகைகளையும் காண்க'))))),
                      SliverToBoxAdapter(
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: TextButton.icon(
                                  onPressed: _stores,
                                  icon: const Icon(Icons.storefront_outlined,
                                      size: 18),
                                  label: Text(l10n.browseStores)))),
                      if (!_loading && !_offline && visible.isEmpty)
                        SliverToBoxAdapter(
                            child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(l10n.noDealsAvailable))),
                      const SliverToBoxAdapter(child: SizedBox(height: 88)),
                    ],
                  ),
                ))));
  }
}
