import '../utils/offer_presentation.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/map_marker_icon.dart';
import 'package:geolocator/geolocator.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../config/app_theme.dart';
import '../models/promotion.dart';
import '../models/category.dart';
import '../services/browsing_area.dart';
import '../services/api_service.dart';
import '../services/nearby_discovery_controller.dart';
import '../services/location_service.dart';
import '../widgets/stitch_discover_components.dart';
import '../widgets/nearby_offer_row.dart';
import '../widgets/discovery_offer_card.dart';
import '../widgets/sign_in_gate.dart';
import 'deal_detail_screen.dart';
import 'notifications_screen.dart';
import 'user_profile_screen.dart';

class NearbyDealsScreen extends StatelessWidget {
  const NearbyDealsScreen(
      {super.key, this.onNavigateAccount, this.api, this.mapBuilder});
  final ApiService? api;
  final Widget Function(GoogleMap map)? mapBuilder;
  final VoidCallback? onNavigateAccount;
  @override
  Widget build(BuildContext context) => Theme(
      data: stitchDiscoverTheme(Theme.of(context)),
      child: _NearbyDealsPage(
          api: api,
          mapBuilder: mapBuilder,
          onNavigateAccount: onNavigateAccount));
}

class _NearbyDealsPage extends StatefulWidget {
  const _NearbyDealsPage({this.api, this.mapBuilder, this.onNavigateAccount});
  final ApiService? api;
  final Widget Function(GoogleMap map)? mapBuilder;
  final VoidCallback? onNavigateAccount;
  @override
  State<_NearbyDealsPage> createState() => _NearbyDealsScreenState();
}

class _NearbyDealsScreenState extends State<_NearbyDealsPage> {
  late final NearbyDiscoveryController _data;
  GoogleMapController? _map;
  bool _movingCamera = false;
  final _icons = <String, BitmapDescriptor>{};
  final _pendingIcons = <String>{};
  final _sheet = DraggableScrollableController();
  bool _mapReady = false;
  bool _dirty = false;
  bool _expanded = false;
  double _sheetExtent = .46;
  bool _locating = false;
  LatLng _draftCenter = const LatLng(6.911, 79.854);
  double _zoom = 13;
  Timer? _clock;
  @override
  void initState() {
    super.initState();
    _data = NearbyDiscoveryController(api: widget.api);
    _data.addListener(_changed);
    _data.initialize();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _changed() {
    if (!mounted) return;
    final area = LatLng(_data.area.latitude, _data.area.longitude);
    if (_data.loading &&
        (_draftCenter.latitude != area.latitude ||
            _draftCenter.longitude != area.longitude)) {
      _draftCenter = area;
      _dirty = false;
      if (_mapReady) _move(area, 13);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _clock?.cancel();
    _data.removeListener(_changed);
    _data.dispose();
    _map?.dispose();
    _sheet.dispose();
    super.dispose();
  }

  Future<void> _move(LatLng center, double zoom) async {
    _movingCamera = true;
    _zoom = zoom;
    await _map?.moveCamera(CameraUpdate.newLatLngZoom(center, zoom));
  }

  Future<void> _resize(bool expanded) async {
    if (!_sheet.isAttached) return;
    final extent = expanded ? .92 : .46;
    final duration = AppMotion.duration(context, 240);
    if (duration == Duration.zero) {
      _sheet.jumpTo(extent);
    } else {
      await _sheet.animateTo(extent,
          duration: duration, curve: Curves.easeOutCubic);
    }
  }

  void _select(Promotion offer, {bool fromMap = false}) {
    _data.select(offer.id);
    if (_mapReady) {
      _move(LatLng(offer.latitude!, offer.longitude!), math.max(_zoom, 14));
    }
    if (fromMap) _resize(false);
  }

  Future<void> _searchMap() async {
    if (!_dirty) {
      await _data.search(_data.area);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final area = BrowsingArea(
        latitude: _draftCenter.latitude,
        longitude: _draftCenter.longitude,
        label: l10n.selectedMapAreaLabel,
        source: 'map');
    setState(() => _dirty = false);
    await _data.search(area);
  }

  Future<void> _useLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final result =
          await LocationService.resolveCurrentLocation(requestPermission: true);
      if (!mounted) return;
      if (result.position == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.locationUnavailableHint),
            action: SnackBarAction(
                label: l10n.openSettings,
                onPressed: result.status == LocationFetchStatus.serviceDisabled
                    ? Geolocator.openLocationSettings
                    : Geolocator.openAppSettings)));
        return;
      }
      final position = result.position!;
      final accuracy = await Geolocator.getLocationAccuracy();
      if (!mounted) return;
      final area = BrowsingArea(
          latitude: position.latitude,
          longitude: position.longitude,
          label: l10n.deviceLocationLabel,
          source: 'gps',
          approximate: accuracy == LocationAccuracyStatus.reduced ||
              result.usedLastKnownPosition);
      _draftCenter = LatLng(area.latitude, area.longitude);
      if (_mapReady) _move(_draftCenter, 14);
      setState(() => _dirty = false);
      await _data.search(area);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.locationUnavailableHint)));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _chooseArea() async {
    final l10n = AppLocalizations.of(context)!;
    final presets = <BrowsingArea>[
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
          source: 'preset'),
    ];
    for (final merchant in _data.merchants) {
      final location = merchant['location'];
      final coordinates = location is Map ? location['coordinates'] : null;
      if (coordinates is! List ||
          coordinates.length < 2 ||
          coordinates[0] is! num ||
          coordinates[1] is! num) {
        continue;
      }
      final label = (merchant['address'] ?? merchant['name'] ?? '').toString();
      if (label.isEmpty || presets.any((a) => a.label == label)) continue;
      presets.add(BrowsingArea(
          latitude: (coordinates[1] as num).toDouble(),
          longitude: (coordinates[0] as num).toDouble(),
          label: label));
    }
    String query = '';
    final area = await showModalBottomSheet<BrowsingArea>(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => SafeArea(
                child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16,
                        16 + MediaQuery.viewInsetsOf(context).bottom),
                    child: SizedBox(
                        height: (MediaQuery.sizeOf(context).height -
                                MediaQuery.viewInsetsOf(context).bottom) *
                            .65,
                        child: Column(children: [
                          Row(children: [
                            Expanded(
                                child: Text(l10n.chooseAreaLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge)),
                            IconButton(
                                tooltip: l10n.closeDialogLabel,
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close))
                          ]),
                          Text(l10n.chooseAreaMapHint),
                          const SizedBox(height: 12),
                          TextField(
                              onChanged: (value) => update(() => query = value),
                              decoration: InputDecoration(
                                  labelText: l10n.searchAreasLabel,
                                  prefixIcon: const Icon(Icons.search))),
                          Expanded(
                              child: ListView(
                                  children: presets
                                      .where((a) => a.label
                                          .toLowerCase()
                                          .contains(query.toLowerCase()))
                                      .map((a) => ListTile(
                                          leading: const Icon(
                                              Icons.location_on_outlined),
                                          title: Text(a.label),
                                          onTap: () =>
                                              Navigator.pop(context, a)))
                                      .toList())),
                        ]))))));
    if (!mounted || area == null) return;
    _draftCenter = LatLng(area.latitude, area.longitude);
    if (_mapReady) _move(_draftCenter, 13);
    setState(() => _dirty = false);
    await _data.search(area);
  }

  Future<void> _filters() async {
    final l10n = AppLocalizations.of(context)!;
    final query = TextEditingController(text: _data.query);
    bool onlyOpen = _data.openOnly;
    bool resetAll = false;
    final apply = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => SafeArea(
                child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20,
                        20 + MediaQuery.viewInsetsOf(context).bottom),
                    child: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(l10n.filterOffersLabel,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextField(
                          controller: query,
                          decoration:
                              InputDecoration(labelText: l10n.searchHint)),
                      SwitchListTile(
                          title: Text(l10n.openNowLabel),
                          subtitle: Text(l10n.storeHoursHint),
                          value: onlyOpen,
                          onChanged: (value) => update(() => onlyOpen = value)),
                      Wrap(spacing: 8, children: [
                        TextButton(
                            onPressed: () {
                              query.clear();
                              update(() {
                                onlyOpen = false;
                                resetAll = true;
                              });
                            },
                            child: Text(l10n.clearAll)),
                        OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.cancelDialogLabel)),
                        FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(l10n.applyFilterLabel)),
                      ]),
                    ]))))));
    if (mounted && apply == true) {
      _data.filter(
          onlyOpen: onlyOpen,
          searchQuery: query.text.trim(),
          clearCategory: resetAll);
      if (resetAll) await _data.setRadius(3);
    }
    query.dispose();
  }

  Future<void> _notifications() async {
    if (!await requireSignIn(context) || !mounted) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()));
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

  Widget _mapButton(String label, IconData icon, VoidCallback? onTap) =>
      Material(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          shape: const CircleBorder(),
          elevation: 2,
          child:
              IconButton(tooltip: label, onPressed: onTap, icon: Icon(icon)));

  List<List<Promotion>> _groups(List<Promotion> offers) {
    final groups = <List<Promotion>>[];
    final threshold = 90 *
        156543.03392 *
        math.cos(_data.area.latitude * math.pi / 180) /
        math.pow(2, _zoom);
    for (final offer in offers) {
      final index = groups.indexWhere((g) =>
          LocationService.calculateDistance(g.first.latitude!,
                  g.first.longitude!, offer.latitude!, offer.longitude!) *
              1000 <
          threshold);
      if (index == -1) {
        groups.add([offer]);
      } else {
        groups[index].add(offer);
      }
    }
    return groups;
  }

  Set<Marker> _markers(List<Promotion> offers) {
    final theme = Theme.of(context);
    return _groups(offers).map((group) {
      final first = group.first;
      final selected = group.any((p) => p.id == _data.selectedId);
      final label = group.length > 1
          ? '${group.length}'
          : (OfferPresentation(first).price != null &&
                  !OfferPresentation(first).useDiscountHeadline
              ? offerMoney(first, OfferPresentation(first).price!)
              : getCategoryLabel(first.category));
      final background =
          selected ? theme.colorScheme.primary : theme.colorScheme.surface;
      final foreground =
          selected ? theme.colorScheme.onPrimary : theme.colorScheme.primary;
      final key = '$label:${background.toARGB32()}:${foreground.toARGB32()}';
      if (!_icons.containsKey(key) && _pendingIcons.add(key)) {
        mapMarkerIcon(label, background, foreground).then((icon) {
          if (mounted) setState(() => _icons[key] = icon);
        }).catchError((Object _) {
          _pendingIcons.remove(key);
        });
      }
      return Marker(
        markerId: MarkerId(first.id),
        position: LatLng(first.latitude!, first.longitude!),
        icon: _icons[key] ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        zIndexInt: selected ? 2 : 1,
        consumeTapEvents: true,
        infoWindow: InfoWindow(
            title: group.length > 1
                ? AppLocalizations.of(context)!.nearbyOfferCount(group.length)
                : first.title),
        onTap: () {
          if (group.length == 1 || _zoom >= 17) {
            _select(first, fromMap: true);
          } else {
            _move(LatLng(first.latitude!, first.longitude!),
                math.min(18, _zoom + 2));
          }
        },
      );
    }).toSet();
  }

  Widget _mapView(ThemeData theme, List<Promotion> offers, double mapPadding) {
    final map = GoogleMap(
      initialCameraPosition: CameraPosition(
          target: LatLng(_data.area.latitude, _data.area.longitude), zoom: 13),
      minMaxZoomPreference: const MinMaxZoomPreference(5, 18),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      // Move Google's logo and attribution above the overlapping results sheet.
      padding: EdgeInsets.only(bottom: mapPadding, top: _expanded ? 0 : 64),
      style: theme.brightness == Brightness.dark ? googleMapDarkStyle : null,
      onMapCreated: (controller) {
        if (!mounted) {
          controller.dispose();
          return;
        }
        _map = controller;
        _mapReady = true;
        _move(LatLng(_data.area.latitude, _data.area.longitude), 13);
      },
      onCameraMove: (camera) {
        if (!mounted) return;
        setState(() {
          _zoom = camera.zoom;
          if (!_movingCamera) {
            _draftCenter = camera.target;
            _dirty = LocationService.calculateDistance(
                        _data.area.latitude,
                        _data.area.longitude,
                        camera.target.latitude,
                        camera.target.longitude) *
                    1000 >
                100;
          }
        });
      },
      onCameraIdle: () => _movingCamera = false,
      circles: {
        Circle(
          circleId: const CircleId('search-radius'),
          center: LatLng(_data.area.latitude, _data.area.longitude),
          radius: _data.radius * 1000,
          fillColor: theme.colorScheme.primary.withValues(alpha: .08),
          strokeColor: theme.colorScheme.primary,
          strokeWidth: 1,
        )
      },
      markers: {
        Marker(
            markerId: const MarkerId('search-center'),
            position: LatLng(_data.area.latitude, _data.area.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(
                title: AppLocalizations.of(context)!.searchCenterLabel)),
        ..._markers(offers),
      },
    );
    return widget.mapBuilder?.call(map) ?? map;
  }

  Widget _header(String areaLabel) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        child: Row(children: [
          Expanded(
              child: InkWell(
                  onTap: _chooseArea,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Row(children: [
                        Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                shape: BoxShape.circle),
                            child: Icon(Icons.location_on_outlined,
                                color: colors.primary, size: 19)),
                        const SizedBox(width: 9),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              stitchText(context, l10n.nearbyTab,
                                  size: 11,
                                  weight: FontWeight.w600,
                                  color: colors.onSurfaceVariant),
                              Row(children: [
                                Flexible(
                                    child: stitchText(context, areaLabel,
                                        size: 16, weight: FontWeight.w700)),
                                const Icon(Icons.expand_more, size: 18)
                              ]),
                            ])),
                      ])))),
          IconButton(
              tooltip: l10n.notifications,
              onPressed: _notifications,
              icon: const Icon(Icons.notifications_none, size: 21)),
          IconButton(
              tooltip: l10n.accountTab,
              onPressed: _account,
              icon: const Icon(Icons.account_circle_outlined, size: 23)),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final offers = _data.offers;
    final areaLabel = _data.area.source == 'map'
        ? l10n.selectedMapAreaLabel
        : _data.area.source == 'gps'
            ? l10n.deviceLocationLabel
            : _data.area.label;
    final selected = _data.selected;
    final ordered = [
      if (selected != null) selected,
      ...offers.where((p) => p.id != selected?.id)
    ];
    return Scaffold(
        body: SafeArea(
            child: Column(children: [
      _header(areaLabel),
      SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            PopupMenuButton<double>(
                tooltip: l10n.searchRadiusLabel,
                initialValue: _data.radius,
                onSelected: _data.setRadius,
                itemBuilder: (_) => [1.0, 3.0, 5.0, 10.0]
                    .map((r) => PopupMenuItem(
                        value: r,
                        child: Text(l10n.withinRadiusLabel(r.toInt()))))
                    .toList(),
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Chip(
                        side: BorderSide.none,
                        backgroundColor: theme.colorScheme.primary,
                        labelStyle: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onPrimary, fontSize: 12),
                        avatar: Icon(Icons.radar,
                            size: 17, color: theme.colorScheme.onPrimary),
                        label: Text(
                            l10n.withinRadiusLabel(_data.radius.toInt()))))),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
                tooltip: l10n.allCategories,
                onSelected: (id) => _data.filter(
                    categoryId: id == 'all' ? null : id,
                    clearCategory: id == 'all'),
                itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 'all', child: Text(l10n.allCategories)),
                      ...launchCategories.map((c) =>
                          PopupMenuItem(value: c.id, child: Text(c.name)))
                    ],
                child: Chip(
                    side: BorderSide.none,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 12, color: theme.colorScheme.onSurface),
                    avatar: const Icon(Icons.category_outlined),
                    label: Text(_data.category == null
                        ? l10n.allCategories
                        : getCategoryLabel(_data.category)))),
            const SizedBox(width: 8),
            FilterChip(
                side: BorderSide.none,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 12, color: theme.colorScheme.onSurface),
                avatar: const Icon(Icons.access_time, size: 16),
                label: Text(l10n.openNowLabel),
                selected: _data.openOnly,
                onSelected: (value) => _data.filter(onlyOpen: value)),
          ])),
      Expanded(
          child: LayoutBuilder(
              builder: (context, constraints) => Stack(children: [
                    Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: constraints.maxHeight,
                        child: _mapView(
                            theme,
                            offers,
                            math.max(
                                0, constraints.maxHeight * _sheetExtent + 8))),
                    if (!_expanded)
                      Positioned(
                          top: 12,
                          left: 16,
                          right: 76,
                          child: Align(
                              alignment: Alignment.center,
                              child: FilledButton.tonalIcon(
                                  style: FilledButton.styleFrom(
                                      backgroundColor: theme
                                          .colorScheme.surfaceContainerLowest,
                                      foregroundColor:
                                          theme.colorScheme.primary,
                                      elevation: 2),
                                  onPressed: _data.loading ? null : _searchMap,
                                  icon: const Icon(Icons.refresh),
                                  label: Text(_dirty
                                      ? l10n.searchThisAreaLabel
                                      : l10n.refreshAreaLabel)))),
                    if (!_expanded)
                      Positioned(
                          top: 12,
                          right: 12,
                          child: Column(children: [
                            _mapButton(l10n.useMyLocation, Icons.my_location,
                                _locating ? null : _useLocation),
                            const SizedBox(height: 8),
                            _mapButton(l10n.expandResultsLabel, Icons.list,
                                () => _resize(true)),
                          ])),
                    NotificationListener<DraggableScrollableNotification>(
                      onNotification: (notice) {
                        final expanded = notice.extent > .75;
                        if (_sheetExtent != notice.extent) {
                          setState(() {
                            _expanded = expanded;
                            _sheetExtent = notice.extent;
                          });
                        }
                        return false;
                      },
                      child: DraggableScrollableSheet(
                          controller: _sheet,
                          initialChildSize: .46,
                          minChildSize: .20,
                          maxChildSize: .92,
                          snap: true,
                          snapSizes: const [.20, .46, .92],
                          builder: (context, scroll) => Material(
                              color: theme.colorScheme.surfaceContainerLowest,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(28)),
                              elevation: 6,
                              child: ListView(
                                  controller: scroll,
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                  children: [
                                    Center(
                                        child: Container(
                                            width: 48,
                                            height: 4,
                                            decoration: BoxDecoration(
                                                color: theme
                                                    .colorScheme.outlineVariant,
                                                borderRadius:
                                                    BorderRadius.circular(4)))),
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      Expanded(
                                          child: Text(
                                              l10n.nearbyOfferCount(
                                                  offers.length),
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w700))),
                                      IconButton(
                                          tooltip: l10n.filterOffersLabel,
                                          onPressed: _filters,
                                          icon: const Icon(Icons.tune)),
                                      IconButton(
                                          tooltip: _expanded
                                              ? l10n.collapseResultsLabel
                                              : l10n.expandResultsLabel,
                                          onPressed: () => _resize(!_expanded),
                                          icon: Icon(_expanded
                                              ? Icons.expand_more
                                              : Icons.expand_less)),
                                    ]),
                                    Text(
                                        '$areaLabel · ${_data.radius.toInt()} km',
                                        style: theme.textTheme.bodySmall),
                                    const SizedBox(height: 12),
                                    Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                            color: theme.colorScheme
                                                .surfaceContainerLow,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Text(
                                            _data.area.approximate
                                                ? l10n.approximateAreaHint
                                                : l10n.areaDistanceHint,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(fontSize: 12))),
                                    if (_data.area.approximate)
                                      TextButton(
                                          onPressed: Geolocator.openAppSettings,
                                          child: Text(l10n.openSettings)),
                                    if (_data.openOnly)
                                      Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: Text(l10n.storeHoursHint)),
                                    if (_data.cached)
                                      Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: Text(
                                              l10n.offlineShowingCachedDeals)),
                                    if (_data.loading)
                                      const Padding(
                                          padding: EdgeInsets.all(24),
                                          child: Center(
                                              child:
                                                  CircularProgressIndicator())),
                                    if (_data.failed ||
                                        _data.cacheMismatch) ...[
                                      Text(_data.cacheMismatch
                                          ? l10n.cachedAreaMismatchHint
                                          : l10n.checkConnectionRetry),
                                      TextButton(
                                          onPressed: () =>
                                              _data.search(_data.area),
                                          child: Text(l10n.retry)),
                                    ] else if (!_data.loading &&
                                        offers.isEmpty) ...[
                                      Text(_data.openOnly
                                          ? l10n.noKnownOpenStoresHint
                                          : l10n.noNearbyDealsFound),
                                      TextButton(
                                          onPressed: () => _data.filter(
                                              clearCategory: true,
                                              onlyOpen: false,
                                              searchQuery: ''),
                                          child: Text(l10n.clearAll)),
                                    ],
                                    ...ordered.map((p) => Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: NearbyOfferRow(
                                            key: ValueKey(p.id),
                                            offer: p,
                                            selected: p.id == _data.selectedId,
                                            onSelect: () => _select(p),
                                            onOpen: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        DealDetailScreen(
                                                            promotion: p,
                                                            api: widget
                                                                .api)))))),
                                  ]))),
                    ),
                  ]))),
    ])));
  }
}
