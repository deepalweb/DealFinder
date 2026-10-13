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
import '../services/image_helper.dart';
import '../services/app_session.dart';
import '../utils/bank_card_promotion_support.dart';
import '../widgets/dealfinder_mark.dart';
import '../widgets/discovery_offer_card.dart';
import '../widgets/offer_save_button.dart';
import '../widgets/sign_in_gate.dart';
import 'all_deals_screen.dart';
import 'nearby_deals_screen.dart';
import 'notifications_screen.dart';
import 'stores_screen.dart';
import 'search_screen.dart';
import 'deal_detail_screen.dart';
import 'user_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen(
      {super.key,
      this.onNavigateToFavorites,
      this.onNavigateNearby,
      this.onNavigateAccount,
      this.onNavigateBankOffers});
  final VoidCallback? onNavigateToFavorites;
  final VoidCallback? onNavigateNearby;
  final VoidCallback? onNavigateAccount;
  final ValueChanged<String?>? onNavigateBankOffers;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  List<Promotion> _offers = [];
  List<Promotion> _curated = [];
  List<Promotion> _recommended = [];
  Position? _position;
  String? _area;
  String? _category;
  bool _loading = true;
  bool _offline = false;
  bool _bannerManaged = false;
  int _featuredIndex = 0;
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

  List<Promotion> get _visible => _offers
      .where((p) =>
          (p.hasStarted && !p.isExpired) &&
          (_category == null || p.category == _category))
      .toList();
  List<Promotion> get _featured {
    final curated = _curated
        .where((p) =>
            (p.hasStarted && !p.isExpired) &&
            (_category == null || p.category == _category))
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
        .where((p) => p.distance! <= 5000)
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

  Future<void> _account() async {
    if (widget.onNavigateAccount != null) {
      widget.onNavigateAccount!();
      return;
    }
    if (!await requireSignIn(context) || !mounted) return;
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const UserProfileScreen()));
  }

  Widget _section(String title, {VoidCallback? onAll}) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(children: [
        Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (onAll != null)
          TextButton(
              onPressed: onAll,
              child: Text(AppLocalizations.of(context)!.viewAll))
      ]));
  Widget _rail(List<Promotion> offers) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: offers
              .take(6)
              .map((p) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                      width: 290,
                      child: DiscoveryOfferCard(
                          offer: p, onOpen: () => _open(p)))))
              .toList()));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final featured = _featured;
    final nearby = _nearby;
    final banks = _offers
        .where((p) => p.hasStarted && !p.isExpired)
        .where(BankCardPromotionSupport.isBankCardPromotion)
        .where((p) => p.bankName?.isNotEmpty == true)
        .map((p) => p.bankName!)
        .toSet()
        .toList()
      ..sort();
    final popular = (_recommended.isNotEmpty ? _recommended : _visible)
        .where((p) =>
            (p.hasStarted && !p.isExpired) &&
            (_category == null || p.category == _category))
        .take(6)
        .toList();
    final personalized = _recommendationUserId.isNotEmpty &&
        popular.any((p) => const {
              'Based on categories you view',
              'From stores you like',
              'Saved in your favorites',
              'From a store you follow'
            }.contains(p.recommendationReason));
    return Scaffold(
        body: SafeArea(
            child: RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(children: [
                  const DealFinderMark(size: 34),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextButton.icon(
                          onPressed: _nearbyTab,
                          icon: const Icon(Icons.expand_more),
                          iconAlignment: IconAlignment.end,
                          label: Text(_area ?? l10n.chooseAreaLabel,
                              maxLines: 1, overflow: TextOverflow.ellipsis))),
                  IconButton(
                      tooltip: l10n.notifications,
                      onPressed: _notifications,
                      icon: Badge(
                          isLabelVisible: _unread > 0,
                          label: Text('$_unread'),
                          child: const Icon(Icons.notifications_none))),
                  IconButton(
                      tooltip: l10n.accountTab,
                      onPressed: _account,
                      icon: const Icon(Icons.account_circle_outlined)),
                ])),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(l10n.discoverTab,
                    style: theme.textTheme.headlineLarge)),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SearchScreen())),
                        child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              const Icon(Icons.search),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(l10n.searchHint,
                                      style: theme.textTheme.bodyMedium))
                            ]))))),
            const SizedBox(height: 12),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                          label: Text(
                              '${l10n.allLabel} (${_offers.where((p) => (p.hasStarted && !p.isExpired)).length})'),
                          selected: _category == null,
                          onSelected: (_) => setState(() {
                                _category = null;
                                _featuredIndex = 0;
                              }))),
                  ...predefinedCategories
                      .where((c) => _offers.any((p) =>
                          (p.hasStarted && !p.isExpired) && p.category == c.id))
                      .map((c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                              label: Text(getCategoryLabel(c.id)),
                              selected: _category == c.id,
                              onSelected: (_) => setState(() {
                                    _category = c.id;
                                    _featuredIndex = 0;
                                  })))),
                ])),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const StoresScreen())),
                    icon: const Icon(Icons.storefront_outlined),
                    label: Text(l10n.browseStores))),
            if (_offline)
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.offlineShowingCachedDeals)),
            if (_loading)
              const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator())),
            if (featured.isNotEmpty) ...[
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DiscoveryOfferCard(
                      offer: featured[_featuredIndex % featured.length],
                      featured: true,
                      onOpen: () =>
                          _open(featured[_featuredIndex % featured.length]))),
              if (featured.length > 1)
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton(
                      tooltip: l10n.previousOfferLabel,
                      onPressed: () => setState(() => _featuredIndex =
                          (_featuredIndex - 1) % featured.length),
                      icon: const Icon(Icons.chevron_left)),
                  ...List.generate(
                      featured.length,
                      (i) => IconButton(
                          tooltip:
                              l10n.featuredPageLabel(i + 1, featured.length),
                          onPressed: () => setState(() => _featuredIndex = i),
                          icon: Icon(
                              i == _featuredIndex % featured.length
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 12,
                              color: theme.colorScheme.primary))),
                  IconButton(
                      tooltip: l10n.nextOfferLabel,
                      onPressed: () => setState(() => _featuredIndex =
                          (_featuredIndex + 1) % featured.length),
                      icon: const Icon(Icons.chevron_right)),
                ]),
            ],
            _section(l10n.nearbyTab, onAll: _nearbyTab),
            if (nearby.isNotEmpty)
              _rail(nearby)
            else
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_position == null
                                    ? l10n.chooseAreaHint
                                    : l10n.noNearbyDealsFound),
                                const SizedBox(height: 8),
                                Wrap(spacing: 8, children: [
                                  OutlinedButton(
                                      onPressed: _nearbyTab,
                                      child: Text(l10n.chooseAreaLabel)),
                                  TextButton.icon(
                                      onPressed: () => _loadLocation(
                                          requestPermission: true),
                                      icon: const Icon(Icons.my_location),
                                      label: Text(l10n.useMyLocation)),
                                ]),
                              ])))),
            _section(l10n.bankSpotlightLabel, onAll: () => _bank(null)),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.bankSpotlightHint,
                                  style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 12),
                              if (banks.isEmpty)
                                Text(l10n.noBankOffersLabel)
                              else
                                Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: banks
                                        .take(6)
                                        .map((bank) => OutlinedButton.icon(
                                            onPressed: () => _bank(bank),
                                            icon: const Icon(Icons.credit_card),
                                            label: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(bank),
                                                  Text(
                                                      _offers
                                                              .firstWhere((p) =>
                                                                  p.bankName ==
                                                                      bank &&
                                                                  BankCardPromotionSupport
                                                                      .isBankCardPromotion(
                                                                          p))
                                                              .discount ??
                                                          l10n.viewOfferLabel,
                                                      style: theme.textTheme
                                                          .labelMedium),
                                                ])))
                                        .toList()),
                            ])))),
            if (_ending.isNotEmpty) ...[
              _section(l10n.endingSoonLabel),
              ..._ending.map((p) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(
                                      child: Text(p.merchantName ?? '',
                                          style: theme.textTheme.bodySmall)),
                                  OfferSaveButton(offer: p)
                                ]),
                                Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: SizedBox(
                                              width: 88,
                                              height: 88,
                                              child: ImageHelper
                                                  .buildOptimizedImage(
                                                      p.imageDataString,
                                                      fit: BoxFit.cover))),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Text(p.title,
                                              style:
                                                  theme.textTheme.titleMedium)),
                                    ]),
                                const SizedBox(height: 10),
                                OfferConditions(offer: p),
                                const SizedBox(height: 10),
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton(
                                        onPressed: () => _open(p),
                                        child: Text(l10n.viewOfferLabel))),
                              ]))))),
            ],
            if (popular.isNotEmpty) ...[
              _section(
                  personalized
                      ? l10n.recommendedForYouTitle
                      : l10n.popularTitle,
                  onAll: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AllDealsScreen()))),
              _rail(popular),
            ],
            if (!_loading && _visible.isEmpty)
              Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.noDealsAvailable)),
            const SizedBox(height: 32),
          ],
        ))
      ]),
    )));
  }
}
