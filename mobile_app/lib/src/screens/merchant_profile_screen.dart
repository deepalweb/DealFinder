import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../services/merchant_following_manager.dart';

class MerchantProfileScreen extends StatefulWidget {
  final String merchantId;

  const MerchantProfileScreen({
    super.key,
    required this.merchantId,
  });

  @override
  State<MerchantProfileScreen> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends State<MerchantProfileScreen> {
  Map<String, dynamic>? _merchant;
  List<Map<String, dynamic>> _deals = [];
  bool _loading = true;
  bool _followBusy = false;
  bool _isFollowing = false;
  String? _error;
  String _activeTab = 'active';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      _fetchMerchant(),
      _loadFollowStatus(),
    ]);
  }

  Future<void> _fetchMerchant() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final merchant = await ApiService().fetchMerchantById(widget.merchantId);
      final deals = await ApiService().fetchPromotionsByMerchant(widget.merchantId);

      if (!mounted) return;
      setState(() {
        _merchant = merchant;
        _deals = deals;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadFollowStatus() async {
    final isFollowing =
        await MerchantFollowingManager.isFollowing(widget.merchantId);
    if (!mounted) return;
    setState(() {
      _isFollowing = isFollowing;
    });
  }

  Future<void> _toggleFollow() async {
    if (_followBusy) return;
    setState(() => _followBusy = true);

    try {
      final followerCount = _isFollowing
          ? await MerchantFollowingManager.unfollowMerchant(widget.merchantId)
          : await MerchantFollowingManager.followMerchant(widget.merchantId);

      if (!mounted) return;
      setState(() {
        _isFollowing = !_isFollowing;
        if (_merchant != null) {
          final current =
              (_merchant!['followers'] as num?)?.toInt() ?? 0;
          _merchant = {
            ..._merchant!,
            'followers': followerCount ??
                (_isFollowing ? current + 1 : (current - 1).clamp(0, 1 << 30)),
          };
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFollowing ? 'Following store' : 'Unfollowed store',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _followBusy = false);
      }
    }
  }

  String _merchantText(String primaryKey, {String? fallbackKey}) {
    final primary = (_merchant?[primaryKey] ?? '').toString().trim();
    if (primary.isNotEmpty) return primary;
    if (fallbackKey == null) return '';
    return (_merchant?[fallbackKey] ?? '').toString().trim();
  }

  double? get _merchantLatitude {
    final direct = _merchant?['latitude'];
    if (direct is num) return direct.toDouble();
    final coords = _merchant?['location']?['coordinates'];
    if (coords is List && coords.length >= 2 && coords[1] is num) {
      return (coords[1] as num).toDouble();
    }
    return null;
  }

  double? get _merchantLongitude {
    final direct = _merchant?['longitude'];
    if (direct is num) return direct.toDouble();
    final coords = _merchant?['location']?['coordinates'];
    if (coords is List && coords.length >= 2 && coords[0] is num) {
      return (coords[0] as num).toDouble();
    }
    return null;
  }

  String _normalizeSocialHandle(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return '';
    if (text.startsWith('http://') || text.startsWith('https://')) return text;
    return text.replaceFirst(RegExp(r'^@+'), '');
  }

  String _buildSocialUrl(String platform, dynamic value) {
    final normalized = _normalizeSocialHandle(value);
    if (normalized.isEmpty) return '';
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }

    switch (platform) {
      case 'facebook':
        return 'https://facebook.com/$normalized';
      case 'instagram':
        return 'https://instagram.com/$normalized';
      case 'twitter':
        return 'https://twitter.com/$normalized';
      case 'tiktok':
        return 'https://tiktok.com/@$normalized';
      default:
        return normalized;
    }
  }

  String _normalizeWebsite(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return '';
    if (text.startsWith('http://') || text.startsWith('https://')) return text;
    return 'https://$text';
  }

  Widget _buildImageWidget(
    String? imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.storefront, color: Colors.white, size: 40),
      );
    }

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
            child: const Icon(Icons.storefront, color: Colors.white, size: 40),
          ),
        );
      } catch (_) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.storefront, color: Colors.white, size: 40),
        );
      }
    }

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
          child: const Icon(Icons.storefront, color: Colors.white, size: 40),
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
      child: const Icon(Icons.storefront, color: Colors.white, size: 40),
    );
  }

  List<Map<String, dynamic>> get _filteredDeals {
    final now = DateTime.now();
    if (_activeTab == 'active') {
      return _deals.where((deal) {
        final end = DateTime.tryParse((deal['endDate'] ?? '').toString());
        return end == null || !end.isBefore(now);
      }).toList();
    }
    return _deals.where((deal) {
      final end = DateTime.tryParse((deal['endDate'] ?? '').toString());
      return end != null && end.isBefore(now);
    }).toList();
  }

  String? _countdownText(Map<String, dynamic> deal) {
    final end = DateTime.tryParse((deal['endDate'] ?? '').toString());
    if (end == null) return null;
    final diff = end.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h left';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m left';
    return '${diff.inMinutes}m ${diff.inSeconds % 60}s left';
  }

  String _dateRange(Map<String, dynamic> deal) {
    final start = (deal['startDate'] ?? '').toString();
    final end = (deal['endDate'] ?? '').toString();
    if (start.isEmpty && end.isEmpty) return 'Dates unavailable';
    return '$start - $end';
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildSocialLinks(Map? social) {
    if (social == null) return const SizedBox.shrink();
    final links = <Widget>[];

    final facebook = _buildSocialUrl('facebook', social['facebook']);
    if (facebook.isNotEmpty) {
      links.add(_socialIcon('facebook', facebook, Colors.blue[800]!));
    }

    final instagram = _buildSocialUrl('instagram', social['instagram']);
    if (instagram.isNotEmpty) {
      links.add(_socialIcon('instagram', instagram, Colors.purple));
    }

    final twitter = _buildSocialUrl('twitter', social['twitter']);
    if (twitter.isNotEmpty) {
      links.add(_socialIcon('twitter', twitter, Colors.blue));
    }

    final tiktok = _buildSocialUrl('tiktok', social['tiktok']);
    if (tiktok.isNotEmpty) {
      links.add(_socialIcon('tiktok', tiktok, Colors.black));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: links,
    );
  }

  Widget _socialIcon(String type, String url, Color color) {
    IconData icon;
    switch (type) {
      case 'facebook':
        icon = Icons.facebook;
        break;
      case 'instagram':
        icon = Icons.camera_alt;
        break;
      case 'twitter':
        icon = Icons.alternate_email;
        break;
      case 'tiktok':
        icon = Icons.music_note;
        break;
      default:
        icon = Icons.link;
    }

    return InkWell(
      onTap: () => _openExternalUrl(url),
      child: CircleAvatar(
        backgroundColor: color,
        radius: 16,
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1E88E5)),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF14213D),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF607080)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final merchantDescription = _merchantText(
      'description',
      fallbackKey: 'profile',
    );
    final merchantPhone = _merchantText(
      'phone',
      fallbackKey: 'contactNumber',
    );
    final merchantWebsite = _normalizeWebsite(_merchant?['website']);
    final latitude = _merchantLatitude;
    final longitude = _merchantLongitude;
    final followerCount = (_merchant?['followers'] as num?)?.toInt() ?? 0;
    final activeDeals = (_merchant?['activeDeals'] as num?)?.toInt() ??
        _deals.where((deal) => _countdownText(deal) != 'Expired').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Profile'),
        actions: [
          if (_merchant != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                final url = _merchant!['website'] ?? '';
                Share.share(
                  'Check out ${_merchant!['name']} on DealFinder!'
                  '${url.toString().isNotEmpty ? '\n$url' : ''}',
                );
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _merchant == null
                  ? const Center(child: Text('Merchant not found'))
                  : RefreshIndicator(
                      onRefresh: _fetchMerchant,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          SizedBox(
                            height: 220,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _buildImageWidget(
                                  _merchant!['banner']?.toString().isNotEmpty == true
                                      ? _merchant!['banner'] as String
                                      : null,
                                  height: 220,
                                ),
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Color(0xAA14213D),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -34),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipOval(
                                          child: _buildImageWidget(
                                            _merchant!['logo'] as String?,
                                            width: 78,
                                            height: 78,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (_merchant!['name'] ?? '').toString(),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                (_merchant!['category'] ?? 'Other')
                                                    .toString(),
                                                style: const TextStyle(
                                                  color: Color(0xFF6D7B8A),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  _buildStatChip(
                                                    icon: Icons.people_alt_outlined,
                                                    label: 'followers',
                                                    value: '$followerCount',
                                                  ),
                                                  _buildStatChip(
                                                    icon: Icons.local_offer_outlined,
                                                    label: 'active deals',
                                                    value: '$activeDeals',
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (merchantDescription.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        merchantDescription,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: const Color(0xFF425466),
                                              height: 1.45,
                                            ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: _followBusy ? null : _toggleFollow,
                                          icon: Icon(
                                            _isFollowing
                                                ? Icons.check_circle
                                                : Icons.person_add_alt_1,
                                          ),
                                          label: Text(
                                            _isFollowing ? 'Following' : 'Follow',
                                          ),
                                        ),
                                        if (merchantWebsite.isNotEmpty)
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _openExternalUrl(merchantWebsite),
                                            icon: const Icon(Icons.language),
                                            label: const Text('Website'),
                                          ),
                                        if (merchantPhone.isNotEmpty)
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _openExternalUrl('tel:$merchantPhone'),
                                            icon: const Icon(Icons.call_outlined),
                                            label: const Text('Contact'),
                                          ),
                                      ],
                                    ),
                                    if ((_merchant!['address'] ?? '')
                                        .toString()
                                        .trim()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF7F9FC),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Icon(
                                                  Icons.location_on_outlined,
                                                  color: Color(0xFF1E88E5),
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _merchant!['address']
                                                        .toString(),
                                                    style: const TextStyle(
                                                      color: Color(0xFF425466),
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (latitude != null &&
                                                longitude != null) ...[
                                              const SizedBox(height: 10),
                                              TextButton.icon(
                                                onPressed: () => _openExternalUrl(
                                                  'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
                                                ),
                                                icon: const Icon(Icons.directions),
                                                label:
                                                    const Text('Get Directions'),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (_merchant!['socialMedia'] != null) ...[
                                      const SizedBox(height: 16),
                                      _buildSocialLinks(
                                        _merchant!['socialMedia'] as Map?,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (latitude != null && longitude != null)
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: SizedBox(
                                height: 190,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: FlutterMap(
                                    options: MapOptions(
                                      initialCenter: latlng.LatLng(
                                        latitude,
                                        longitude,
                                      ),
                                      initialZoom: 15,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName:
                                            'com.dealfinder.mobile',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: latlng.LatLng(
                                              latitude,
                                              longitude,
                                            ),
                                            width: 44,
                                            height: 44,
                                            child: Icon(
                                              Icons.location_on,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
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
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                _buildTabButton('active', 'Active Deals'),
                                const SizedBox(width: 8),
                                _buildTabButton('expired', 'Expired Deals'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: _filteredDeals.isEmpty
                                ? Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 32),
                                    child: Center(
                                      child: Text(
                                        'No ${_activeTab == 'active' ? 'active' : 'expired'} deals available.',
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: _filteredDeals.map((deal) {
                                      final countdown = _countdownText(deal);
                                      return Card(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: _buildImageWidget(
                                                  (deal['image'] ??
                                                          deal['imageUrl'])
                                                      ?.toString(),
                                                  width: 84,
                                                  height: 84,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      (deal['title'] ?? '')
                                                          .toString(),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    if ((deal['description'] ?? '')
                                                        .toString()
                                                        .isNotEmpty)
                                                      Text(
                                                        deal['description']
                                                            .toString(),
                                                        maxLines: 2,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      _dateRange(deal),
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Color(0xFF6D7B8A),
                                                      ),
                                                    ),
                                                    if (countdown != null) ...[
                                                      const SizedBox(height: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: countdown ==
                                                                  'Expired'
                                                              ? Colors.red
                                                                  .shade50
                                                              : const Color(
                                                                  0xFFFFF4E5),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(999),
                                                        ),
                                                        child: Text(
                                                          countdown ==
                                                                  'Expired'
                                                              ? countdown
                                                              : 'Ends in $countdown',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: countdown ==
                                                                    'Expired'
                                                                ? Colors.red
                                                                    .shade700
                                                                : const Color(
                                                                    0xFFB26A00),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildTabButton(String value, String label) {
    final selected = _activeTab == value;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _activeTab = value),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.white,
          foregroundColor: selected ? Colors.white : const Color(0xFF425466),
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : const Color(0xFFD7E0EA),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
