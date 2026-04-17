import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/promotion.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/background_location_service.dart';
import '../widgets/modern_deal_card.dart';
import 'deal_detail_screen.dart';

class NearbyDealsScreen extends StatefulWidget {
  const NearbyDealsScreen({super.key});

  @override
  State<NearbyDealsScreen> createState() => _NearbyDealsScreenState();
}

class _NearbyDealsScreenState extends State<NearbyDealsScreen> {
  List<Promotion> _nearbyDeals = [];
  bool _isLoading = false;
  String? _error;
  Position? _currentPosition;
  double _selectedRadius = 10.0; // Default 10km
  String _locationName = 'Getting location...';
  String? _sortBy = 'distance'; // distance, discount, recent

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _checkLocationPermission();
    BackgroundLocationService.startLocationChecking();
  }
  
  @override
  void dispose() {
    BackgroundLocationService.stopLocationChecking();
    super.dispose();
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedRadius = prefs.getDouble('nearby_radius');
    if (cachedRadius != null) {
      setState(() => _selectedRadius = cachedRadius);
    }
  }

  Future<void> _saveRadius(double radius) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('nearby_radius', radius);
  }

  Future<void> _checkLocationPermission() async {
    final hasPermission = await LocationService.hasLocationPermission();
    if (hasPermission) {
      _getCurrentLocationAndFetchDeals();
    }
  }

  Future<void> _getCurrentLocationAndFetchDeals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final position = await LocationService.getCurrentLocation();
      
      if (position != null) {
        setState(() => _currentPosition = position);
        
        // Get location name
        final locationName = await LocationService.getLocationName(
          position.latitude,
          position.longitude,
        );
        if (mounted) {
          setState(() => _locationName = locationName ?? 'Current Location');
        }
        
        await _fetchNearbyDeals(position);
      } else {
        setState(() {
          _error = 'Location access denied. Please enable location services.';
          _isLoading = false;
        });
      }
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
      setState(() => _error = null);

      final nearbyDeals = await _apiService.fetchNearbyPromotions(
        position.latitude,
        position.longitude,
        radiusKm: searchRadius,
      );

      _sortDeals(nearbyDeals);

      setState(() {
        _nearbyDeals = nearbyDeals;
        _isLoading = false;
        _error = null;
      });
    } on TimeoutException {
      setState(() {
        _error = 'Request timed out. Try a smaller radius or check your connection.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().contains('timeout') 
            ? 'Request timed out. Try a smaller radius.'
            : 'Failed to load nearby deals. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _sortDeals(List<Promotion> deals) {
    switch (_sortBy) {
      case 'distance':
        deals.sort((a, b) => (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));
        break;
      case 'discount':
        deals.sort((a, b) {
          final aDiscount = _extractDiscount(a.discount);
          final bDiscount = _extractDiscount(b.discount);
          return bDiscount.compareTo(aDiscount);
        });
        break;
      case 'recent':
        deals.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        break;
    }
  }

  double _extractDiscount(String? discount) {
    if (discount == null) return 0;
    final match = RegExp(r'(\d+)').firstMatch(discount);
    return match != null ? double.parse(match.group(1)!) : 0;
  }

  void _changeRadius(double newRadius) {
    setState(() => _selectedRadius = newRadius);
    _saveRadius(newRadius);
    
    if (_currentPosition != null) {
      setState(() => _isLoading = true);
      _fetchNearbyDeals(_currentPosition!, radius: newRadius);
    }
  }

  void _changeSorting(String? newSort) {
    if (newSort == null) return;
    setState(() => _sortBy = newSort);
    _sortDeals(_nearbyDeals);
    setState(() {});
  }

  String _formatDistance(double? distanceInMeters) {
    if (distanceInMeters == null) return '';
    
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Nearby Deals', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: _changeSorting,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'distance',
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 20, color: _sortBy == 'distance' ? Theme.of(context).colorScheme.primary : null),
                    const SizedBox(width: 8),
                    Text('Nearest First', style: TextStyle(fontWeight: _sortBy == 'distance' ? FontWeight.bold : null)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'discount',
                child: Row(
                  children: [
                    Icon(Icons.percent, size: 20, color: _sortBy == 'discount' ? Theme.of(context).colorScheme.primary : null),
                    const SizedBox(width: 8),
                    Text('Highest Discount', style: TextStyle(fontWeight: _sortBy == 'discount' ? FontWeight.bold : null)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'recent',
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 20, color: _sortBy == 'recent' ? Theme.of(context).colorScheme.primary : null),
                    const SizedBox(width: 8),
                    Text('Most Recent', style: TextStyle(fontWeight: _sortBy == 'recent' ? FontWeight.bold : null)),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocationAndFetchDeals,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Location and Controls Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Location Display
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _currentPosition != null 
                            ? const Color(0xFF4CAF50).withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _currentPosition != null ? Icons.location_on : Icons.location_off,
                        color: _currentPosition != null ? const Color(0xFF4CAF50) : Colors.grey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _locationName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (_nearbyDeals.isNotEmpty)
                            Text(
                              '${_nearbyDeals.length} deals within ${_selectedRadius.round()}km',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Radius Slider
                Row(
                  children: [
                    Icon(Icons.radar, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Radius:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Expanded(
                      child: Slider(
                        value: _selectedRadius,
                        min: 1,
                        max: 50,
                        divisions: 49,
                        label: '${_selectedRadius.round()} km',
                        onChanged: _changeRadius,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_selectedRadius.round()} km',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Error Display
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Deals List
          Expanded(
            child: _buildDealsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDealsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Finding deals near you...', style: TextStyle(fontSize: 14)),
          ],
        ),
      );
    }

    if (_nearbyDeals.isEmpty && _currentPosition != null && _error == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_searching, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No deals found nearby',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Try increasing the search radius',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => _changeRadius(20),
                    child: const Text('20km'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => _changeRadius(50),
                    child: const Text('50km'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_nearbyDeals.isEmpty && _currentPosition == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_disabled, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Location Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Enable location to discover deals near you',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _getCurrentLocationAndFetchDeals,
                icon: const Icon(Icons.location_on),
                label: const Text('Enable Location'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        if (_currentPosition != null) {
          await _fetchNearbyDeals(_currentPosition!);
        } else {
          await _getCurrentLocationAndFetchDeals();
        }
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _nearbyDeals.length,
        itemBuilder: (context, index) {
          final deal = _nearbyDeals[index];
          return ModernDealCard(
            promotion: deal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DealDetailScreen(promotion: deal),
              ),
            ),
          );
        },
      ),
    );
  }
}