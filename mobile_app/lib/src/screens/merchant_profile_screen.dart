import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';

class MerchantProfileScreen extends StatefulWidget {
  final String merchantId;
  const MerchantProfileScreen({Key? key, required this.merchantId}) : super(key: key);

  @override
  State<MerchantProfileScreen> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends State<MerchantProfileScreen> {
  Map<String, dynamic>? _merchant;
  List<Map<String, dynamic>> _deals = [];
  bool _loading = true;
  String? _error;
  bool _isFollowing = false;
  String _activeTab = 'active';

  @override
  void initState() {
    super.initState();
    _fetchMerchant();
    _loadFollowStatus();
  }

  String _previewValue(dynamic value, {int maxLength = 50}) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Future<void> _fetchMerchant() async {
    setState(() { _loading = true; _error = null; });
    try {
      final merchant = await ApiService().fetchMerchantById(widget.merchantId);
      final deals = await ApiService().fetchPromotionsByMerchant(widget.merchantId);
      
      // Debug logging
      if (kDebugMode) {
        print('=== MERCHANT DATA ===');
        print('Name: ${merchant['name']}');
        print('Logo: ${_previewValue(merchant['logo'])}');
        print('Banner: ${_previewValue(merchant['banner'])}');
        print('Has logo: ${merchant['logo'] != null}');
        print('Has banner: ${merchant['banner'] != null}');
      }
      
      setState(() {
        _merchant = merchant;
        _deals = deals;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadFollowStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final followed = prefs.getStringList('dealFinderFollowing') ?? [];
    setState(() {
      _isFollowing = followed.contains(widget.merchantId);
    });
  }

  Future<void> _toggleFollow() async {
    final prefs = await SharedPreferences.getInstance();
    final followed = prefs.getStringList('dealFinderFollowing') ?? [];
    if (_isFollowing) {
      followed.remove(widget.merchantId);
    } else {
      followed.add(widget.merchantId);
    }
    await prefs.setStringList('dealFinderFollowing', followed);
    setState(() { _isFollowing = !_isFollowing; });
  }

  Widget _buildImageWidget(String? imageUrl, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.image, color: Colors.white, size: 48),
      );
    }
    
    // Handle base64 data URI
    if (imageUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(imageUrl.substring(imageUrl.indexOf(',') + 1));
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.image, color: Colors.white, size: 48),
          ),
        );
      } catch (e) {
        if (kDebugMode) print('Error decoding base64 image: $e');
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.image, color: Colors.white, size: 48),
        );
      }
    }
    
    // Handle HTTP/HTTPS URL
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.image, color: Colors.white, size: 48),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      );
    }
    
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.image, color: Colors.white, size: 48),
    );
  }

  List<Map<String, dynamic>> get _filteredDeals {
    final now = DateTime.now();
    if (_activeTab == 'active') {
      return _deals.where((d) {
        final end = DateTime.tryParse(d['endDate'] ?? '') ?? now;
        return end.isAfter(now) || end.isAtSameMomentAs(now);
      }).toList();
    } else {
      return _deals.where((d) {
        final end = DateTime.tryParse(d['endDate'] ?? '') ?? now;
        return end.isBefore(now);
      }).toList();
    }
  }

  Widget _buildSocialLinks(Map? social) {
    if (social == null) return const SizedBox.shrink();
    final List<Widget> links = [];
    if (social['facebook'] != null && social['facebook'].toString().isNotEmpty) {
      links.add(_socialIcon('facebook', 'https://facebook.com/${social['facebook']}', Colors.blue[800]!));
    }
    if (social['instagram'] != null && social['instagram'].toString().isNotEmpty) {
      links.add(_socialIcon('instagram', 'https://instagram.com/${social['instagram']}', Colors.purple));
    }
    if (social['twitter'] != null && social['twitter'].toString().isNotEmpty) {
      links.add(_socialIcon('twitter', 'https://twitter.com/${social['twitter']}', Colors.blue));
    }
    if (social['tiktok'] != null && social['tiktok'].toString().isNotEmpty) {
      links.add(_socialIcon('tiktok', 'https://tiktok.com/@${social['tiktok']}', Colors.black));
    }
    return Row(children: links.map((w) => Padding(padding: const EdgeInsets.only(right: 8), child: w)).toList());
  }

  Widget _socialIcon(String type, String url, Color color) {
    IconData icon;
    switch (type) {
      case 'facebook': icon = Icons.facebook; break;
      case 'instagram': icon = Icons.camera_alt; break;
      case 'twitter': icon = Icons.alternate_email; break;
      case 'tiktok': icon = Icons.music_note; break;
      default: icon = Icons.link;
    }
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url)),
      child: CircleAvatar(
        backgroundColor: color,
        radius: 16,
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bannerUrl = _merchant?['banner'];
    final hasBanner = bannerUrl != null && bannerUrl.toString().isNotEmpty;
    
    if (kDebugMode && _merchant != null) {
      debugPrint('Building merchant profile:');
      debugPrint('Banner URL: $bannerUrl');
      debugPrint('Has banner: $hasBanner');
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Profile'),
        actions: [
          if (_merchant != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                final url = _merchant!['website'] ?? '';
                Share.share('Check out ${_merchant!['name']} on DealFinder!${url.isNotEmpty ? '\n$url' : ''}');
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _merchant == null
                  ? const Center(child: Text('Merchant not found'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Banner / Cover Photo
                          if (hasBanner)
                            SizedBox(
                              width: double.infinity,
                              height: 200,
                              child: _buildImageWidget(
                                bannerUrl,
                                width: double.infinity,
                                height: 200,
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              height: 80,
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            ),
                          // Merchant Card
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipOval(
                                      child: _buildImageWidget(
                                        _merchant!['logo'],
                                        width: 72,
                                        height: 72,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_merchant!['name'] ?? '', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(_merchant!['category'] ?? 'Other', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          Text('${_merchant!['followers'] ?? 0} followers', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                          if ((_merchant!['description'] ?? '').isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text(_merchant!['description'], style: Theme.of(context).textTheme.bodyMedium),
                                            ),
                                          if ((_merchant!['address'] ?? '').isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 18),
                                                  const SizedBox(width: 6),
                                                  Expanded(child: Text(_merchant!['address'], style: const TextStyle(fontSize: 14))),
                                                  if (_merchant!['latitude'] != null && _merchant!['longitude'] != null)
                                                    TextButton.icon(
                                                      icon: const Icon(Icons.directions),
                                                      label: const Text('Get Directions'),
                                                      onPressed: () async {
                                                        final lat = _merchant!['latitude'];
                                                        final lng = _merchant!['longitude'];
                                                        final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                                                        if (await canLaunchUrl(Uri.parse(url))) {
                                                          await launchUrl(Uri.parse(url));
                                                        } else if (context.mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Maps.')));
                                                        }
                                                      },
                                                    ),
                                                ],
                                              ),
                                            ),
                                          if ((_merchant!['website'] ?? '').isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: InkWell(
                                                onTap: () => launchUrl(Uri.parse(_merchant!['website'])),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.link, color: Theme.of(context).colorScheme.primary, size: 18),
                                                    const SizedBox(width: 6),
                                                    Text('Visit Website', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          if (_merchant!['socialMedia'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: _buildSocialLinks(_merchant!['socialMedia']),
                                            ),
                                          if ((_merchant!['phone'] ?? '').isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: TextButton.icon(
                                                icon: const Icon(Icons.phone),
                                                label: const Text('Contact'),
                                                onPressed: () => launchUrl(Uri.parse('tel:${_merchant!['phone']}')),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      children: [
                                        ElevatedButton.icon(
                                          icon: Icon(_isFollowing ? Icons.check : Icons.person_add),
                                          label: Text(_isFollowing ? 'Following' : 'Follow'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _isFollowing ? Colors.grey[200] : Theme.of(context).colorScheme.primary,
                                            foregroundColor: _isFollowing ? Colors.black : Colors.white,
                                          ),
                                          onPressed: _toggleFollow,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Map
                          if (_merchant!['latitude'] != null &&
                              _merchant!['longitude'] != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: SizedBox(
                                height: 180,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: FlutterMap(
                                    options: MapOptions(
                                      initialCenter: latlng.LatLng(
                                        _merchant!['latitude'],
                                        _merchant!['longitude'],
                                      ),
                                      initialZoom: 15,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.example.deal_finder_mobile',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: latlng.LatLng(
                                              _merchant!['latitude'],
                                              _merchant!['longitude'],
                                            ),
                                            width: 44,
                                            height: 44,
                                            child: Icon(
                                              Icons.location_on,
                                              color: Theme.of(context).colorScheme.primary,
                                              size: 36,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          // Deals Tabs
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              children: [
                                TextButton(
                                  onPressed: () => setState(() => _activeTab = 'active'),
                                  child: Text('Active Deals', style: TextStyle(fontWeight: _activeTab == 'active' ? FontWeight.bold : FontWeight.normal)),
                                ),
                                TextButton(
                                  onPressed: () => setState(() => _activeTab = 'expired'),
                                  child: Text('Expired Deals', style: TextStyle(fontWeight: _activeTab == 'expired' ? FontWeight.bold : FontWeight.normal)),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: _filteredDeals.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                                    child: Center(child: Text('No ${_activeTab == 'active' ? 'active' : 'expired'} deals available.')),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _filteredDeals.length,
                                    itemBuilder: (context, idx) {
                                      final deal = _filteredDeals[idx];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 6),
                                        child: ListTile(
                                          leading: deal['image'] != null && deal['image'].toString().isNotEmpty
                                              ? SizedBox(
                                                  width: 48,
                                                  height: 48,
                                                  child: _buildImageWidget(
                                                    deal['image'],
                                                    width: 48,
                                                    height: 48,
                                                  ),
                                                )
                                              : null,
                                          title: Row(
                                            children: [
                                              Expanded(child: Text(deal['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                                              if (deal['featured'] == true)
                                                const Padding(
                                                  padding: EdgeInsets.only(left: 6.0),
                                                  child: Icon(Icons.star, color: Colors.amber, size: 18),
                                                ),
                                            ],
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if ((deal['description'] ?? '').isNotEmpty)
                                                Text(deal['description'], maxLines: 2, overflow: TextOverflow.ellipsis),
                                              Row(
                                                children: [
                                                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Text('${deal['startDate'] ?? ''} - ${deal['endDate'] ?? ''}', style: const TextStyle(fontSize: 12)),
                                                ],
                                              ),
                                              if ((deal['code'] ?? '').isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2.0),
                                                  child: Text('Code: ${deal['code']}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                                                ),
                                              if ((deal['discount'] ?? '').isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2.0),
                                                  child: Text('Discount: ${deal['discount']}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }
}
