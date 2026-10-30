import '../widgets/hybrid_offer_layout.dart';
import '../widgets/stitch_discover_components.dart';
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
import '../widgets/discover_filter_sheet.dart';
import 'categories_screen.dart';
import '../utils/offer_presentation.dart';
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
      this.now,
      this.onNavigateToFavorites,
      this.onNavigateNearby,
      this.onNavigateAccount,
      this.onNavigateBankOffers});
  final ApiService? api;
  final DateTime Function()? now;
  final VoidCallback? onNavigateToFavorites;
  final VoidCallback? onNavigateNearby;
  final VoidCallback? onNavigateAccount;
  final ValueChanged<String?>? onNavigateBankOffers;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime get _now => widget.now?.call() ?? DateTime.now();
  late final _api = widget.api ?? ApiService();
  List<Promotion> _offers = [];
  CuratedHomeSectionsResponse? _curated;
  bool _curatedFailed = false;
  int _curatedGeneration = 0;
  Position? _position;
  int _locationRequest = 0;
  String? _area;
  String? _category;
  String? _fulfillment;
  bool _bankOnly = false;
  String _sort = 'default';
  bool _endingOnly = false;
  bool _loading = true;
  bool _offline = false;
  int _unread = 0;
  Timer? _ticker;
  int _pageOffset = 50, _bankOffset = 50;
  bool _morePromotionPages = false, _moreBankPages = false;
  int _feedGeneration = 0;
  bool _moreAvailable = false;
  bool _loadingMore = false;
  bool _pageError = false;
  Future<void> _loadMore() async {
    if (_loadingMore) return;
    final generation = _feedGeneration;
    setState(() => _loadingMore = true);
    try {
      final promotionPage = _morePromotionPages
          ? await _api.fetchPromotionPage(skip: _pageOffset)
          : <Promotion>[];
      final bankPage = _moreBankPages
          ? await _api.fetchBankOfferPage(skip: _bankOffset)
          : <Promotion>[];
      final page = [...promotionPage, ...bankPage];
      if (!mounted || generation != _feedGeneration) return;
      final ids = _offers.map((p) => OfferPresentation(p).identity).toSet();
      setState(() {
        _offers = [
          ..._offers,
          ...page.where((p) => ids.add(OfferPresentation(p).identity))
        ];
        _pageOffset += promotionPage.length;
        _bankOffset += bankPage.length;
        _morePromotionPages = _morePromotionPages && promotionPage.length == 50;
        _moreBankPages = _moreBankPages && bankPage.length == 50;
        _moreAvailable = _morePromotionPages || _moreBankPages;
        _pageError = false;
      });
    } catch (_) {
      if (mounted && generation == _feedGeneration) {
        setState(() => _pageError = true);
      }
    } finally {
      if (mounted && generation == _feedGeneration) {
        setState(() => _loadingMore = false);
      }
    }
  }

  void _categories() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => CategoriesScreen(api: widget.api)));

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
      _unread = 0;
    });
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
    await Future.wait(
        [_loadOffers(), _loadLocation(), _loadNotifications(), _loadCurated()]);
  }

  Future<void> _loadCurated() async {
    final generation = ++_curatedGeneration;
    try {
      final response = await _api.fetchCuratedHomeSections();
      if (!mounted || generation != _curatedGeneration) return;
      setState(() {
        _curated = response;
        _curatedFailed = false;
      });
    } catch (_) {
      if (mounted && generation == _curatedGeneration) {
        setState(() => _curatedFailed = true);
      }
    }
  }

  Future<void> _loadOffers() async {
    final generation = ++_feedGeneration;
    _loadingMore = false;
    try {
      final offers = await _api.fetchPromotions(forceRefresh: true);
      if (mounted && generation == _feedGeneration) {
        setState(() {
          _offers = offers;
          _pageOffset = 50;
          _bankOffset = 50;
          _morePromotionPages = _api.lastPromotionPageHasMore ??
              (offers
                      .where((p) => !OfferPresentation(p).standaloneBank)
                      .length >=
                  50);
          _moreBankPages = _api.lastBankOfferPageHasMore ??
              (offers
                      .where((p) => OfferPresentation(p).standaloneBank)
                      .length >=
                  50);
          _moreAvailable = _morePromotionPages || _moreBankPages;
          _pageError = false;
          _loading = false;
          _offline = _api.lastPromotionsFromCache;
        });
      }
    } catch (_) {
      if (mounted && generation == _feedGeneration) {
        setState(() {
          _loading = false;
          _offline = true;
        });
      }
    }
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
    _locationRequest++;
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
    final request = ++_locationRequest;
    try {
      final saved = await BrowsingArea.read();
      if (!mounted || request != _locationRequest) return;
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
      if (!requestPermission) return;
      final result = await LocationService.resolveCurrentLocation(
          requestPermission: requestPermission);
      if (!mounted || request != _locationRequest) return;
      if (result.position == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_t(
                'Location unavailable. Choose an area manually.',
                'ස්ථානය නොලැබේ. ප්‍රදේශයක් තෝරන්න.',
                'இருப்பிடம் கிடைக்கவில்லை. பகுதியைத் தேர்ந்தெடுக்கவும்.'))));
        return;
      }
      setState(() => _position = result.position);
      final area = await LocationService.getLocationName(
          _position!.latitude, _position!.longitude);
      if (mounted && request == _locationRequest) {
        await BrowsingArea.select(BrowsingArea(
            latitude: result.position!.latitude,
            longitude: result.position!.longitude,
            label: area ??
                _t('Selected location', 'තෝරාගත් ස්ථානය', 'தேர்ந்தெடுத்த இடம்'),
            source: 'gps',
            approximate: result.position!.accuracy > 100));
      }
    } catch (_) {}
  }

  bool _matchesFilters(Promotion p) =>
      (_fulfillment == null ||
          switch (_fulfillment) {
            'delivery' => p.supportsDelivery,
            'pickup' => p.supportsPickup,
            'online' => OfferPresentation(p).onlineOnly,
            _ => p.supportsVisit,
          }) &&
      (!_bankOnly || BankCardPromotionSupport.isBankCardPromotion(p)) &&
      (!_endingOnly ||
          (p.endDate != null && p.endDate!.difference(_now).inHours <= 72));

  List<Promotion> get _visible => _sortOffers(_offers
      .where((p) =>
          OfferPresentation(p).public &&
          (_category == null ||
              BankCardPromotionSupport.matchesCategory(p, _category!)) &&
          _matchesFilters(p))
      .toList());

  List<Promotion> _sortOffers(List<Promotion> offers) {
    int dateCompare(Promotion a, Promotion b) =>
        (a.endDate ?? DateTime(9999)).compareTo(b.endDate ?? DateTime(9999));
    if (_sort == 'ending_soon') offers.sort(dateCompare);
    if (_sort == 'recent') {
      offers.sort((a, b) => (b.createdAt ?? DateTime(1970))
          .compareTo(a.createdAt ?? DateTime(1970)));
    }
    if (_sort == 'discount') {
      offers.sort((a, b) => OfferPresentation(b)
          .percentage
          .compareTo(OfferPresentation(a).percentage));
    }
    if (_sort == 'distance' && _position != null) {
      offers.sort((a, b) => (_distance(a) ?? double.infinity)
          .compareTo(_distance(b) ?? double.infinity));
    }
    return offers;
  }

  double? _distance(Promotion p) => OfferPresentation(p).onlineOnly ||
          _position == null ||
          p.latitude == null ||
          p.longitude == null
      ? null
      : LocationService.calculateDistance(_position!.latitude,
              _position!.longitude, p.latitude!, p.longitude!) *
          1000;

  void _open(Promotion offer) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => DealDetailScreen(promotion: offer, api: widget.api)));
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

  void _clearFilters() => setState(() {
        _category = null;
        _fulfillment = null;
        _bankOnly = false;
        _endingOnly = false;
        _sort = 'default';
      });

  Future<void> _showFilters() async {
    final selected = await showModalBottomSheet<DiscoverFilterSelection>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => DiscoverFilterSheet(
            initial: DiscoverFilterSelection(
                category: _category,
                fulfillment: _fulfillment,
                bankOnly: _bankOnly,
                sort: _sort,
                endingOnly: _endingOnly),
            allowDistance: _position != null,
            categories: predefinedCategories));
    if (!mounted || selected == null) return;
    setState(() {
      _category = selected.category;
      _fulfillment = selected.fulfillment;
      _bankOnly = selected.bankOnly;
      _sort = selected.sort;
      _endingOnly = selected.endingOnly;
    });
  }

  void _all() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AllDealsScreen(
              api: widget.api,
              initialCategoryId: _category,
              initialCapabilityPresetId: _fulfillment,
              bankOffersOnly: _bankOnly,
              initialPrimaryFilter: _endingOnly ? 'ending_soon' : null,
              initialSortBy: _sort == 'default' ? null : _sort)));
  void _stores() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const StoresScreen()));

  int get _filterCount =>
      (_category == null ? 0 : 1) +
      (_fulfillment == null ? 0 : 1) +
      (_bankOnly ? 1 : 0) +
      (_endingOnly ? 1 : 0) +
      (_sort == 'default' ? 0 : 1);

  Future<void> _chooseArea() async {
    final l10n = AppLocalizations.of(context)!;
    final areas = [
      BrowsingArea.initial,
      const BrowsingArea(
          latitude: 6.895,
          longitude: 79.858,
          label: 'Colombo 04',
          source: 'preset'),
      const BrowsingArea(
          latitude: 6.906,
          longitude: 79.869,
          label: 'Colombo 07',
          source: 'preset')
    ];
    String query = '';
    final selected = await showModalBottomSheet<BrowsingArea>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => StatefulBuilder(
            builder: (context, update) => SafeArea(
                child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16,
                        16 + MediaQuery.viewInsetsOf(context).bottom),
                    child: SizedBox(
                        height: MediaQuery.sizeOf(context).height * .65,
                        child: Column(children: [
                          Row(children: [
                            Expanded(
                                child: Text(l10n.chooseAreaLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge)),
                            const CloseButton()
                          ]),
                          TextField(
                              decoration: InputDecoration(
                                  labelText: l10n.chooseAreaLabel,
                                  prefixIcon: const Icon(Icons.search)),
                              onChanged: (value) =>
                                  update(() => query = value.toLowerCase())),
                          Expanded(
                              child: ListView(children: [
                            for (final area in areas.where(
                                (a) => a.label.toLowerCase().contains(query)))
                              ListTile(
                                  title: Text(area.label),
                                  leading: const Icon(Icons.place_outlined),
                                  onTap: () =>
                                      Navigator.pop(sheetContext, area))
                          ])),
                          TextButton.icon(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                _loadLocation(requestPermission: true);
                              },
                              icon: const Icon(Icons.my_location),
                              label: Text(_t(
                                  'Use my location',
                                  'මගේ ස්ථානය භාවිත කරන්න',
                                  'என் இருப்பிடத்தைப் பயன்படுத்து'))),
                          TextButton.icon(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                _nearbyTab();
                              },
                              icon: const Icon(Icons.map_outlined),
                              label: Text(l10n.nearbyTab)),
                        ]))))));
    if (selected != null) await BrowsingArea.select(selected);
  }

  Widget _sectionTitle(BuildContext context, String title,
      {String? subtitle,
      VoidCallback? action,
      String? actionLabel,
      IconData? icon}) {
    final colors = Theme.of(context).colorScheme;
    final large = MediaQuery.textScalerOf(context).scale(16) > 24;
    final heading =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (icon != null) Icon(icon, size: 18, color: colors.primary),
            stitchText(context, title, size: 15, weight: FontWeight.w700),
          ]),
      if (subtitle != null) ...[
        const SizedBox(height: 3),
        stitchText(context, subtitle, size: 11, color: colors.onSurfaceVariant)
      ],
    ]);
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 12, 10),
        child: Flex(
            direction: large ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment:
                large ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              if (large) heading else Expanded(child: heading),
              if (action != null)
                TextButton(
                    onPressed: action,
                    child: Text(
                        actionLabel ?? AppLocalizations.of(context)!.viewAll))
            ]));
  }

  Widget _rail(BuildContext context, List<Promotion> offers,
      {bool nearby = false}) {
    Widget card(Promotion offer) => nearby
        ? StitchNearbyOfferCard(
            key: ValueKey('nearby:${OfferPresentation(offer).identity}'),
            offer: offer,
            onOpen: () => _open(offer))
        : StitchHorizontalOfferCard(
            key: ValueKey(OfferPresentation(offer).identity),
            offer: offer,
            onOpen: () => _open(offer));
    if (MediaQuery.textScalerOf(context).scale(16) > 24) {
      return Column(
          children: offers
              .map((offer) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: card(offer)))
              .toList());
    }
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 4),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: offers
                .map((offer) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(
                        width: nearby
                            ? ((MediaQuery.sizeOf(context).width - 44) / 2)
                                .clamp(160.0, 210.0)
                            : (MediaQuery.sizeOf(context).width * .66)
                                .clamp(228.0, 350.0),
                        child: card(offer))))
                .toList()));
  }

  Promotion _withDistance(Promotion p) =>
      p.copyWith(distance: _distance(p), clearDistance: _distance(p) == null);

  bool _eligible(Promotion p) =>
      OfferPresentation(p).public &&
      (_category == null ||
          BankCardPromotionSupport.matchesCategory(p, _category!)) &&
      _matchesFilters(p);

  @override
  Widget build(BuildContext context) => Theme(
      data: stitchDiscoverTheme(Theme.of(context)),
      child: Builder(builder: _buildDiscover));

  Widget _buildDiscover(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final large = MediaQuery.textScalerOf(context).scale(16) > 24;
    final seen = <String>{};
    final visible = _visible
        .where((p) => seen.add(OfferPresentation(p).identity))
        .map(_withDistance)
        .toList();
    if (_position != null && _sort == 'default') {
      visible.sort((a, b) => (OfferPresentation(a).distance ?? double.infinity)
          .compareTo(OfferPresentation(b).distance ?? double.infinity));
    }
    final used = <String>{};
    List<Promotion> remaining(Iterable<Promotion> source) => source
        .where(_eligible)
        .where((p) => !used.contains(OfferPresentation(p).identity))
        .map(_withDistance)
        .toList();
    final banners =
        remaining(_curated?.banner ?? visible.where((p) => p.featured == true));
    final banner = banners.isEmpty ? null : banners.first;
    if (banner != null) used.add(OfferPresentation(banner).identity);
    final expiryCandidates = remaining([...visible, ...?_curated?.flashSales])
        .where((p) =>
            p.endDate != null &&
            p.endDate!.isAfter(_now) &&
            p.endDate!.difference(_now).inHours <= 72)
        .toList()
      ..sort((a, b) => a.endDate!.compareTo(b.endDate!));
    final expiring = expiryCandidates.isEmpty ? null : expiryCandidates.first;
    if (expiring != null) used.add(OfferPresentation(expiring).identity);
    final banks = remaining(visible)
        .where(BankCardPromotionSupport.isBankCardPromotion)
        .take(4)
        .toList();
    final bankIds = banks.map((p) => OfferPresentation(p).identity).toSet();
    final railSeen = <String>{};
    final lead = remaining(
            _sort == 'default' ? [...?_curated?.hotDeals, ...visible] : visible)
        .where((p) =>
            !bankIds.contains(OfferPresentation(p).identity) &&
            railSeen.add(OfferPresentation(p).identity))
        .take(2)
        .toList();
    used.addAll([...lead, ...banks].map((p) => OfferPresentation(p).identity));
    final more = remaining(visible);
    // Independent geographic preview: keep every existing collection unchanged.
    final nearby = visible.where((p) {
      final distance = OfferPresentation(p).distance;
      return !OfferPresentation(p).onlineOnly &&
          distance != null &&
          distance <= 3000 &&
          p.latitude != null &&
          p.longitude != null &&
          p.latitude!.abs() <= 90 &&
          p.longitude!.abs() <= 180;
    }).toList()
      ..sort((a, b) => a.distance!.compareTo(b.distance!));
    final bankNames = banks
        .map((p) => p.bankName)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toSet();
    Widget box(Widget child) => SliverToBoxAdapter(child: child);
    Widget inset(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16), child: child);
    return Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
                onRefresh: _load,
                child: CustomScrollView(
                    key: const PageStorageKey('discover-visual-feed'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      box(StitchLocationHeader(
                          area: _area ?? l10n.chooseAreaLabel,
                          unread: _unread,
                          onArea: _chooseArea,
                          onNotifications: _notifications,
                          onStores: _stores)),
                      box(StitchFulfillmentSegments(
                          selected: ['visit', 'online'].contains(_fulfillment)
                              ? _fulfillment
                              : null,
                          onSelected: (value) =>
                              setState(() => _fulfillment = value))),
                      SliverPersistentHeader(
                          pinned: true,
                          delegate: HybridSearchHeader(
                              height: large ? 66 : 56,
                              child: ColoredBox(
                                  color: colors.surface,
                                  child: StitchDiscoverSearchBar(
                                      count: _filterCount,
                                      onSearch: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const SearchScreen())),
                                      onFilters: _showFilters)))),
                      box(StitchQuickFilters(
                          categoryLabel: _category == null
                              ? null
                              : getCategoryLabel(_category!),
                          ending: _endingOnly,
                          bankOnly: _bankOnly,
                          filtered: _filterCount > 0,
                          onReset: _clearFilters,
                          onEnding: () =>
                              setState(() => _endingOnly = !_endingOnly),
                          onBank: () => setState(() => _bankOnly = !_bankOnly),
                          onCategories: _showFilters)),
                      if (_filterCount > 0)
                        box(inset(Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                                onPressed: _clearFilters,
                                child: Text(l10n.clearFilters))))),
                      if (_loading)
                        box(const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()))),
                      if (_offline)
                        box(inset(Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              stitchText(
                                  context,
                                  _offers.isEmpty
                                      ? _t(
                                          'Could not load offers.',
                                          'දීමනා පූරණය කළ නොහැකි විය.',
                                          'சலுகைகளை ஏற்ற முடியவில்லை.')
                                      : _api.lastPromotionsFromCache
                                          ? l10n.offlineShowingCachedDeals
                                          : _t(
                                              'Could not refresh. Showing previously loaded offers.',
                                              'යාවත්කාලීන කළ නොහැක. පෙර පූරණය කළ දීමනා පෙන්වයි.',
                                              'புதுப்பிக்க முடியவில்லை. முன்பு ஏற்றப்பட்ட சலுகைகள் காட்டப்படுகின்றன.')),
                              TextButton(
                                  onPressed: _load, child: Text(l10n.retry)),
                            ]))),
                      if (!_loading && !_offline && visible.isEmpty)
                        box(Padding(
                            padding: const EdgeInsets.all(16),
                            child: stitchText(
                                context,
                                _offers.isEmpty && !_moreAvailable
                                    ? _t(
                                        'No offers returned by the service.',
                                        'සේවාවෙන් දීමනා ලැබී නැත.',
                                        'சேவையிலிருந்து சலுகைகள் வரவில்லை.')
                                    : _t(
                                        'No matches in loaded results. Clear filters or load another page.',
                                        'පූරණය කළ ප්‍රතිඵලවල ගැළපීම් නැත. පෙරහන් ඉවත් කරන්න හෝ තවත් පිටුවක් පූරණය කරන්න.',
                                        'ஏற்றப்பட்ட முடிவுகளில் பொருத்தங்கள் இல்லை. வடிகட்டிகளை அகற்றவும் அல்லது மேலும் ஏற்றவும்.')))),
                      box(_sectionTitle(context, l10n.nearbyDeals,
                          subtitle: _position == null
                              ? _t(
                                  'Choose an area to find nearby offers',
                                  'අවට දීමනා සඳහා ප්‍රදේශයක් තෝරන්න',
                                  'அருகிலுள்ள சலுகைகளுக்கு பகுதியைத் தேர்ந்தெடுக்கவும்')
                              : _t(
                                  'Within 3 km · matching offers loaded so far',
                                  'කි.මී. 3 ඇතුළත · පූරණය කළ ගැළපෙන දීමනා',
                                  '3 கி.மீ.க்குள் · இதுவரை ஏற்றப்பட்ட பொருத்தங்கள்'),
                          icon: Icons.near_me_outlined,
                          action: _nearbyTab)),
                      if (nearby.isNotEmpty)
                        box(_rail(context, nearby.take(6).toList(),
                            nearby: true))
                      else
                        box(inset(Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_position != null)
                                stitchText(
                                    context,
                                    _t(
                                        'No nearby matches in loaded offers. Try another area or load more offers.',
                                        'පූරණය කළ දීමනාවල අවට ගැළපීම් නැත. වෙනත් ප්‍රදේශයක් හෝ තවත් දීමනා බලන්න.',
                                        'ஏற்றப்பட்ட சலுகைகளில் அருகிலுள்ள பொருத்தங்கள் இல்லை. வேறு பகுதியைத் தேர்ந்தெடுக்கவும் அல்லது மேலும் ஏற்றவும்.'),
                                    size: 12,
                                    color: colors.onSurfaceVariant),
                              TextButton(
                                  onPressed: _chooseArea,
                                  child: Text(l10n.chooseAreaLabel)),
                            ]))),
                      if (banner != null)
                        box(Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: StitchFeaturedBanner(
                                offer: banner, onOpen: () => _open(banner)))),
                      if (_curatedFailed)
                        box(inset(TextButton(
                            onPressed: _loadCurated,
                            child: Text(_t(
                                'Featured offers could not be refreshed. Retry',
                                'විශේෂ දීමනා යාවත්කාලීන කළ නොහැක. නැවත උත්සාහ කරන්න',
                                'சிறப்புச் சலுகைகளைப் புதுப்பிக்க முடியவில்லை. மீண்டும் முயலவும்'))))),
                      if (expiring != null)
                        box(Padding(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                            child: StitchExpiringOfferStrip(
                                offer: expiring,
                                now: _now,
                                onOpen: () => _open(expiring)))),
                      if (lead.isNotEmpty) ...[
                        box(_sectionTitle(
                            context,
                            _t('Featured offers', 'විශේෂ දීමනා',
                                'சிறப்புச் சலுகைகள்'),
                            subtitle: _t(
                                'Matching offers loaded so far',
                                'මෙතෙක් පූරණය කළ ගැළපෙන දීමනා',
                                'இதுவரை ஏற்றப்பட்ட பொருந்தும் சலுகைகள்'),
                            action: _all)),
                        box(_rail(context, lead)),
                      ],
                      if (banks.isNotEmpty || _api.lastBankOffersFailed)
                        box(_sectionTitle(
                            context,
                            _t('Bank Perks', 'බැංකු ප්‍රතිලාභ',
                                'வங்கிச் சலுகைகள்'),
                            icon: Icons.credit_card,
                            subtitle: _t(
                                'Check bank and card conditions',
                                'බැංකු සහ කාඩ්පත් කොන්දේසි බලන්න',
                                'வங்கி மற்றும் அட்டை விதிகளைச் சரிபாருங்கள்'),
                            action: () => _bank(null),
                            actionLabel: bankNames.isEmpty
                                ? l10n.viewAll
                                : _t(
                                    '${bankNames.length} banks',
                                    'බැංකු ${bankNames.length}',
                                    '${bankNames.length} வங்கிகள்'))),
                      if (_api.lastBankOffersFailed)
                        box(inset(TextButton(
                            onPressed: _load,
                            child: Text(_t(
                                'Bank offers could not be refreshed. Retry',
                                'බැංකු දීමනා යාවත්කාලීන කළ නොහැක. නැවත උත්සාහ කරන්න',
                                'வங்கிச் சலுகைகளைப் புதுப்பிக்க முடியவில்லை. மீண்டும் முயலவும்'))))),
                      if (banks.isNotEmpty)
                        SliverList.builder(
                            itemCount: large
                                ? banks.length
                                : (banks.length / 2).ceil(),
                            itemBuilder: (_, row) => Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: large
                                    ? StitchBankGridCard(
                                        offer: banks[row],
                                        onOpen: () => _open(banks[row]))
                                    : Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                            for (var col = 0;
                                                col < 2;
                                                col++) ...[
                                              if (col > 0)
                                                const SizedBox(width: 12),
                                              Expanded(
                                                  child: row * 2 + col <
                                                          banks.length
                                                      ? StitchBankGridCard(
                                                          key: ValueKey(
                                                              OfferPresentation(
                                                                      banks[row *
                                                                              2 +
                                                                          col])
                                                                  .identity),
                                                          offer: banks[
                                                              row * 2 + col],
                                                          onOpen: () => _open(
                                                              banks[row * 2 +
                                                                  col]))
                                                      : const SizedBox.shrink()),
                                            ],
                                          ]))),
                      if (banks.isEmpty && !_api.lastBankOffersFailed)
                        box(inset(Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                                onPressed: () => _bank(null),
                                child: Text(l10n.bankOffersTab))))),
                      if (more.isNotEmpty)
                        box(_sectionTitle(
                            context,
                            _t(
                                'More deals to explore',
                                'තවත් දීමනා ගවේෂණය කරන්න',
                                'மேலும் சலுகைகளை ஆராயுங்கள்'),
                            subtitle: _t(
                                'Matching offers loaded so far',
                                'මෙතෙක් පූරණය කළ ගැළපෙන දීමනා',
                                'இதுவரை ஏற்றப்பட்ட பொருந்தும் சலுகைகள்'),
                            action: _showFilters,
                            actionLabel: l10n.sortByTitle)),
                      SliverList.builder(
                          itemCount: more.length,
                          itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: StitchFullWidthOfferCard(
                                  key: ValueKey(
                                      OfferPresentation(more[i]).identity),
                                  offer: more[i],
                                  onOpen: () => _open(more[i])))),
                      if (_moreAvailable || _pageError)
                        box(Padding(
                            padding: const EdgeInsets.all(16),
                            child: OutlinedButton(
                                onPressed: _loadingMore ? null : _loadMore,
                                child: Text(_loadingMore
                                    ? '…'
                                    : _pageError
                                        ? l10n.retry
                                        : _t(
                                            'Load more offers',
                                            'තවත් දීමනා පූරණය කරන්න',
                                            'மேலும் சலுகைகளை ஏற்று'))))),
                      box(Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          child: Wrap(spacing: 12, children: [
                            TextButton(
                                onPressed: _categories,
                                child: Text(l10n.allCategories)),
                            TextButton(
                                onPressed: _stores,
                                child: Text(l10n.browseStores)),
                            OutlinedButton(
                                onPressed: _all, child: Text(l10n.allDeals))
                          ]))),
                    ]))));
  }
}
