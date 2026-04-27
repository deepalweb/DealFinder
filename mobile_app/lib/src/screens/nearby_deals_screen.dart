import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/promotion.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/background_location_service.dart';
import 'deal_detail_screen.dart';

class NearbyDealsScreen extends StatefulWidget {
  const NearbyDealsScreen({super.key});

  @override
  State<NearbyDealsScreen> createState() => _NearbyDealsScreenState();
}

class _NearbyDealsScreenState extends State<NearbyDealsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Promotion> _nearbyDeals = [];
  bool _isLoading = false;
  String? _error;
  Position? _currentPosition;
  double _selectedRadius = 10.0;
  String _locationName = 'Detecting location';
  String _sortBy = 'distance';
  String _viewMode = 'list';
  String _activeFilter = 'all';
  Promotion? _selectedMapDeal;

  @override
  void initState() {
    super.initState();
    _loadCachedPreferences();
    _checkLocationPermission();
    BackgroundLocationService.startLocationChecking();
  }

  @override
  void dispose() {
    _searchController.dispose();
    BackgroundLocationService.stopLocationChecking();
    super.dispose();
  }

  Future<void> _loadCachedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedRadius = prefs.getDouble('nearby_radius');
    final cachedView = prefs.getString('nearby_view_mode');
    final cachedSort = prefs.getString('nearby_sort_mode');

    if (!mounted) return;

    setState(() {
      if (cachedRadius != null) _selectedRadius = cachedRadius;
      if (cachedView != null) _viewMode = cachedView;
      if (cachedSort != null) _sortBy = cachedSort;
    });
  }

  Future<void> _persistPreference(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _checkLocationPermission() async {
    final hasPermission = await LocationService.hasLocationPermission();
    if (hasPermission) {
      await _getCurrentLocationAndFetchDeals();
    } else {
      setState(() {
        _locationName = 'Location permission needed';
      });
    }
  }

  Future<void> _getCurrentLocationAndFetchDeals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final position = await LocationService.getCurrentLocation();

      if (position == null) {
        setState(() {
          _error = 'Location access denied. Enable location to discover nearby deals.';
          _isLoading = false;
          _locationName = 'Location unavailable';
        });
        return;
      }

      setState(() => _currentPosition = position);

      final locationName = await LocationService.getLocationName(position.latitude, position.longitude);
      if (mounted) {
        setState(() => _locationName = locationName ?? 'Current location');
      }

      await _fetchNearbyDeals(position);
    } catch (e) {
      setState(() {
        _error = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNearbyDeals(Position position, {double? radius}) async {
    final searchRadius = radius ?? _selectedRadius;

    try {
      final nearbyDeals = await _apiService.fetchNearbyPromotions(
        position.latitude,
        position.longitude,
        radiusKm: searchRadius,
      );

      if (!mounted) return;

      setState(() {
        _nearbyDeals = nearbyDeals;
        _sortDeals(_nearbyDeals);
        _selectedMapDeal = _filteredDeals.isNotEmpty ? _filteredDeals.first : null;
        _isLoading = false;
        _error = null;
      });
    } on TimeoutException {
      setState(() {
        _error = 'Nearby search timed out. Try a smaller radius or a quick refresh.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load nearby deals. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _sortDeals(List<Promotion> deals) {
    switch (_sortBy) {
      case 'best':
        deals.sort((a, b) => _dealScore(b).compareTo(_dealScore(a)));
        break;
      case 'ending':
        deals.sort((a, b) => _timeToExpiry(a).compareTo(_timeToExpiry(b)));
        break;
      default:
        deals.sort((a, b) => (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));
    }
  }

  double _dealScore(Promotion promotion) {
    final discount = _extractDiscount(promotion.discount);
    final distanceBoost = promotion.distance == null ? 0 : (5000 - promotion.distance!).clamp(0, 5000) / 150;
    return discount + distanceBoost;
  }

  int _timeToExpiry(Promotion promotion) {
    if (promotion.endDate == null) return 1 << 30;
    return promotion.endDate!.difference(DateTime.now()).inMinutes;
  }

  double _extractDiscount(String? discount) {
    if (discount == null) return 0;
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(discount);
    return match != null ? double.tryParse(match.group(1)!) ?? 0 : 0;
  }

  String _formatDistance(double? distanceInMeters) {
    if (distanceInMeters == null) return '';
    if (distanceInMeters < 1000) return '${distanceInMeters.round()} m away';
    return '${(distanceInMeters / 1000).toStringAsFixed(1)} km away';
  }

  String _expiryLabel(Promotion promotion) {
    if (promotion.endDate == null) return 'Limited time';
    final now = DateTime.now();
    final hours = promotion.endDate!.difference(now).inHours;
    if (hours <= 0) return 'Ends today';
    if (hours < 24) return 'Ends in ${hours}h';
    final days = promotion.endDate!.difference(now).inDays;
    if (days == 0) return 'Ends today';
    return 'Ends in ${days + 1}d';
  }

  Future<void> _changeRadius(double newRadius) async {
    setState(() => _selectedRadius = newRadius);
    await _persistPreference('nearby_radius', newRadius);

    if (_currentPosition != null) {
      setState(() => _isLoading = true);
      await _fetchNearbyDeals(_currentPosition!, radius: newRadius);
    }
  }

  Future<void> _setViewMode(String mode) async {
    setState(() => _viewMode = mode);
    await _persistPreference('nearby_view_mode', mode);
  }

  Future<void> _setSortMode(String mode) async {
    setState(() {
      _sortBy = mode;
      _sortDeals(_nearbyDeals);
      _selectedMapDeal = _filteredDeals.isNotEmpty ? _filteredDeals.first : null;
    });
    await _persistPreference('nearby_sort_mode', mode);
  }

  List<Promotion> get _filteredDeals {
    final term = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();

    final filtered = _nearbyDeals.where((deal) {
      final category = deal.category?.toLowerCase() ?? '';
      final title = deal.title.toLowerCase();
      final merchant = (deal.merchantName ?? '').toLowerCase();

      final matchesSearch = term.isEmpty ||
          title.contains(term) ||
          merchant.contains(term) ||
          category.contains(term);

      final matchesFilter = switch (_activeFilter) {
        'food' => category.contains('food'),
        'electronics' => category.contains('electronic'),
        'fashion' => category.contains('fashion'),
        'discount50' => _extractDiscount(deal.discount) >= 50,
        'ending' => deal.endDate != null && deal.endDate!.difference(now).inHours <= 24,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();

    _sortDeals(filtered);
    return filtered;
  }

  List<Promotion> get _popularNearby {
    final deals = [..._filteredDeals]..sort((a, b) => _dealScore(b).compareTo(_dealScore(a)));
    return deals.take(5).toList();
  }

  List<Promotion> get _endingTodayNearby {
    final now = DateTime.now();
    return _filteredDeals
        .where((deal) => deal.endDate != null && deal.endDate!.difference(now).inHours <= 24)
        .take(5)
        .toList();
  }

  Set<Marker> get _markers {
    return _filteredDeals
        .where((deal) => deal.latitude != null && deal.longitude != null)
        .map(
          (deal) => Marker(
            markerId: MarkerId(deal.id),
            position: LatLng(deal.latitude!, deal.longitude!),
            infoWindow: InfoWindow(
              title: deal.merchantName ?? deal.title,
              snippet: deal.discount ?? _formatDistance(deal.distance),
            ),
            onTap: () {
              setState(() => _selectedMapDeal = deal);
            },
          ),
        )
        .toSet();
  }

  Future<void> _openDirections(Promotion deal) async {
    final hasCoordinates = deal.latitude != null && deal.longitude != null;
    final query = hasCoordinates
        ? 'https://www.google.com/maps/search/?api=1&query=${deal.latitude},${deal.longitude}'
        : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${deal.merchantName ?? deal.title} ${deal.location ?? ''}') }';

    final uri = Uri.parse(query);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  Future<void> _showLocationDialog() async {
    final latController = TextEditingController(
      text: _currentPosition?.latitude.toStringAsFixed(6) ?? '',
    );
    final lngController = TextEditingController(
      text: _currentPosition?.longitude.toStringAsFixed(6) ?? '',
    );
    final labelController = TextEditingController(text: _locationName);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Change location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use your current GPS position or enter coordinates manually for testing nearby results.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _getCurrentLocationAndFetchDeals();
                },
                icon: const Icon(Icons.my_location),
                label: const Text('Use Current Location'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: labelController,
                decoration: const InputDecoration(labelText: 'Location label'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: latController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'Latitude'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lngController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'Longitude'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final lat = double.tryParse(latController.text.trim());
                        final lng = double.tryParse(lngController.text.trim());
                        if (lat == null || lng == null) return;

                        final manualPosition = Position(
                          longitude: lng,
                          latitude: lat,
                          timestamp: DateTime.now(),
                          accuracy: 0,
                          altitude: 0,
                          altitudeAccuracy: 0,
                          heading: 0,
                          headingAccuracy: 0,
                          speed: 0,
                          speedAccuracy: 0,
                        );

                        Navigator.pop(context);
                        setState(() {
                          _currentPosition = manualPosition;
                          _locationName = labelController.text.trim().isEmpty ? 'Custom location' : labelController.text.trim();
                          _isLoading = true;
                          _error = null;
                        });
                        await _fetchNearbyDeals(manualPosition);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    latController.dispose();
    lngController.dispose();
    labelController.dispose();
  }

  Widget _buildFilterChip({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final selected = _activeFilter == id;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggleButton({
    required String mode,
    required IconData icon,
    required String label,
  }) {
    final selected = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setViewMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextStrip(String title, List<Promotion> deals) {
    if (deals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: deals.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              final deal = deals[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DealDetailScreen(promotion: deal)),
                ),
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              deal.discount ?? 'Deal',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDistance(deal.distance),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        deal.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Spacer(),
                      Text(
                        deal.merchantName ?? 'Nearby store',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyDealCard(Promotion deal) {
    final hasPrice = deal.originalPrice != null || deal.discountedPrice != null || deal.price != null;
    final displayPrice = deal.discountedPrice ?? deal.price ?? deal.originalPrice;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (deal.imageDataString != null && deal.imageDataString!.isNotEmpty)
                  Image.network(
                    deal.imageDataString!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEAF2FF)),
                  )
                else
                  Container(color: const Color(0xFFEAF2FF)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.08),
                        Colors.black.withOpacity(0.35),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: [
                      if ((deal.discount ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            deal.discount!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _expiryLabel(deal),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Color(0xFF1E88E5)),
                        const SizedBox(width: 4),
                        Text(
                          _formatDistance(deal.distance),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deal.merchantName ?? 'Nearby store',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  deal.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.25),
                ),
                const SizedBox(height: 10),
                if (hasPrice && displayPrice != null)
                  Wrap(
                    spacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (deal.originalPrice != null && deal.discountedPrice != null)
                        Text(
                          'Rs. ${deal.originalPrice!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        'Rs. ${displayPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Text(
                  deal.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.45),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DealDetailScreen(promotion: deal)),
                        ),
                        child: const Text('Get Deal'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openDirections(deal),
                        icon: const Icon(Icons.directions),
                        label: const Text('Directions'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    if (_currentPosition == null) {
      return _buildEmptyLocationState();
    }

    if (_markers.isEmpty) {
      return _buildEmptyDealsState();
    }

    final initialTarget = _selectedMapDeal?.latitude != null && _selectedMapDeal?.longitude != null
        ? LatLng(_selectedMapDeal!.latitude!, _selectedMapDeal!.longitude!)
        : LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialTarget,
            zoom: 13.5,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          markers: _markers,
          onTap: (_) => setState(() => _selectedMapDeal = null),
        ),
        if (_selectedMapDeal != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DealDetailScreen(promotion: _selectedMapDeal!)),
              ),
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _selectedMapDeal!.discount ?? 'Nearby deal',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDistance(_selectedMapDeal!.distance),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _selectedMapDeal!.merchantName ?? _selectedMapDeal!.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedMapDeal!.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => DealDetailScreen(promotion: _selectedMapDeal!)),
                              ),
                              child: const Text('Get Deal'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _openDirections(_selectedMapDeal!),
                              child: const Text('Directions'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListView() {
    final deals = _filteredDeals;

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('Finding deals near you...'),
          ],
        ),
      );
    }

    if (_currentPosition == null) {
      return _buildEmptyLocationState();
    }

    if (deals.isEmpty) {
      return _buildEmptyDealsState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await _getCurrentLocationAndFetchDeals();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildContextStrip('Popular near you', _popularNearby),
          _buildContextStrip('Ending today nearby', _endingTodayNearby),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Nearby deals',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${deals.length} results',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          ...deals.map(_buildNearbyDealCard),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyLocationState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_disabled, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Location Required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Turn on location to see nearby deals, distance, and directions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _getCurrentLocationAndFetchDeals,
              icon: const Icon(Icons.my_location),
              label: const Text('Enable Location'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDealsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_searching, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No nearby deals found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try increasing the radius or changing filters to widen the search.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              children: [
                OutlinedButton(onPressed: () => _changeRadius(20), child: const Text('20 km')),
                OutlinedButton(onPressed: () => _changeRadius(50), child: const Text('50 km')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeDeals = _filteredDeals;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nearby',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Color(0xFFE53935)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _locationName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showLocationDialog,
                        icon: const Icon(Icons.edit_location_alt_outlined),
                        label: const Text('Change Location'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() => _selectedMapDeal = _filteredDeals.isNotEmpty ? _filteredDeals.first : null),
                    decoration: InputDecoration(
                      hintText: 'Search nearby deals...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _selectedMapDeal = _filteredDeals.isNotEmpty ? _filteredDeals.first : null);
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 46,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip(id: 'all', label: 'All', icon: Icons.grid_view_rounded),
                        const SizedBox(width: 8),
                        _buildFilterChip(id: 'food', label: 'Food', icon: Icons.fastfood_outlined),
                        const SizedBox(width: 8),
                        _buildFilterChip(id: 'electronics', label: 'Electronics', icon: Icons.devices_outlined),
                        const SizedBox(width: 8),
                        _buildFilterChip(id: 'fashion', label: 'Fashion', icon: Icons.checkroom_outlined),
                        const SizedBox(width: 8),
                        _buildFilterChip(id: 'discount50', label: '50%+', icon: Icons.percent),
                        const SizedBox(width: 8),
                        _buildFilterChip(id: 'ending', label: 'Ending Soon', icon: Icons.timelapse_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _buildViewToggleButton(mode: 'list', icon: Icons.view_agenda_outlined, label: 'List View'),
                        _buildViewToggleButton(mode: 'map', icon: Icons.map_outlined, label: 'Map View'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activeDeals.isEmpty
                              ? 'No active nearby deals'
                              : '${activeDeals.length} active nearby deal${activeDeals.length == 1 ? '' : 's'}',
                          style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: _setSortMode,
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'distance', child: Text('Closest first')),
                          PopupMenuItem(value: 'best', child: Text('Best deal nearby')),
                          PopupMenuItem(value: 'ending', child: Text('Ending soon')),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.swap_vert, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                switch (_sortBy) {
                                  'best' => 'Best Nearby',
                                  'ending' => 'Ending Soon',
                                  _ => 'Closest',
                                },
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _selectedRadius,
                          min: 1,
                          max: 50,
                          divisions: 49,
                          label: '${_selectedRadius.round()} km',
                          onChanged: (value) => _changeRadius(value),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedRadius.round()} km',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _viewMode == 'map' ? _buildMapView() : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }
}
