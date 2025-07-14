import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/promotion.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/background_location_service.dart';
import '../widgets/deal_card.dart';
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
  double _selectedRadius = 10.0;
  String _locationStatus = 'Tap "Find Nearby Deals" to discover promotions in your area';

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    BackgroundLocationService.startLocationChecking();
  }
  
  @override
  void dispose() {
    BackgroundLocationService.stopLocationChecking();
    super.dispose();
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
      _locationStatus = 'Getting your location...';
    });

    try {
      final position = await LocationService.getCurrentLocation();
      
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _locationStatus = 'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        });
        
        await _fetchNearbyDeals(position);
      } else {
        setState(() {
          _error = 'Location access denied. Please enable location services and try again.';
          _locationStatus = 'Location not available';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error getting location: $e';
        _locationStatus = 'Location error';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNearbyDeals(Position position) async {
    try {
      setState(() {
        _locationStatus = 'Finding deals near you...';
      });

      final nearbyDeals = await _apiService.fetchNearbyPromotions(
        position.latitude,
        position.longitude,
        radiusKm: _selectedRadius,
      );

      setState(() {
        _nearbyDeals = nearbyDeals;
        _locationStatus = nearbyDeals.isEmpty 
          ? 'No deals found within ${_selectedRadius.round()}km'
          : 'Found ${nearbyDeals.length} deals within ${_selectedRadius.round()}km';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load nearby deals: $e';
        _isLoading = false;
      });
    }
  }

  void _changeRadius(double newRadius) {
    setState(() {
      _selectedRadius = newRadius;
    });
    
    if (_currentPosition != null) {
      _fetchNearbyDeals(_currentPosition!);
    }
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
      appBar: AppBar(
        title: const Text('📍 Nearby Deals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocationAndFetchDeals,
            tooltip: 'Refresh Location',
          ),
        ],
      ),
      body: Column(
        children: [
          // Location and Controls Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              children: [
                // Location Status
                Row(
                  children: [
                    Icon(
                      _currentPosition != null ? Icons.location_on : Icons.location_off,
                      color: _currentPosition != null ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationStatus,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Find Deals Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _getCurrentLocationAndFetchDeals,
                    icon: _isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.near_me),
                    label: Text(_isLoading ? 'Finding Deals...' : 'Find Nearby Deals'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Radius Selector
                Row(
                  children: [
                    const Text('Search Radius: '),
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
                    Text('${_selectedRadius.round()} km'),
                  ],
                ),
              ],
            ),
          ),

          // Error Display
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red[50],
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red[700]),
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
            Text('🔄 Finding deals near you...'),
          ],
        ),
      );
    }

    if (_nearbyDeals.isEmpty && _currentPosition != null && _error == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_searching, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              '😔 No deals found nearby',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try increasing the search radius or check back later',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _changeRadius(20),
              child: const Text('Search 20km radius'),
            ),
          ],
        ),
      );
    }

    if (_nearbyDeals.isEmpty && _currentPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_disabled, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              '📍 Location Required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'We need your location to show you relevant deals nearby',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _getCurrentLocationAndFetchDeals,
              icon: const Icon(Icons.location_on),
              label: const Text('Enable Location'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_currentPosition != null) {
          await _fetchNearbyDeals(_currentPosition!);
        } else {
          await _getCurrentLocationAndFetchDeals();
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _nearbyDeals.length,
        itemBuilder: (context, index) {
          final deal = _nearbyDeals[index];
          
          return Stack(
            children: [
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DealDetailScreen(promotion: deal),
                  ),
                ),
                child: DealCard(promotion: deal),
              ),
              
              // Distance Badge
              if (deal.distance != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          _formatDistance(deal.distance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}