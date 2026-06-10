import 'dart:convert';

import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../services/merchant_following_manager.dart';
import '../utils/deal_expiry_helper.dart';
import '../widgets/rating_widget.dart';

String _merchantLocalizedText(
    BuildContext context, String en, String si, String ta) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'si':
      return si;
    case 'ta':
      return ta;
    default:
      return en;
  }
}

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
  bool _loadingRatings = true;
  bool _loadingReviews = true;
  bool _submittingRating = false;
  bool _submittingReview = false;
  String? _error;
  String _activeTab = 'active';
  final ApiService _apiService = ApiService();
  final TextEditingController _reviewController = TextEditingController();
  List<Map<String, dynamic>> _ratings = [];
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0;
  double _userRating = 0;
  int _ratingsCount = 0;
  String? _userToken;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadUserAuth();
    await Future.wait([
      _fetchMerchant(),
      _loadFollowStatus(),
      _fetchMerchantRatings(),
      _fetchMerchantReviews(),
    ]);
  }

  Future<void> _loadUserAuth() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userToken = prefs.getString('userToken');
      _userId = prefs.getString('userId');
      _userRating = _findUserRating(_ratings);
    });
  }

  Future<void> _fetchMerchant() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final merchant = await _apiService.fetchMerchantById(widget.merchantId);
      final deals = await _apiService.fetchPromotionsByMerchant(
        widget.merchantId,
      );

      if (!mounted) return;
      setState(() {
        _merchant = merchant;
        _deals = deals;
        _averageRating =
            (merchant['averageRating'] as num?)?.toDouble() ?? _averageRating;
        _ratingsCount =
            (merchant['ratingsCount'] as num?)?.toInt() ?? _ratingsCount;
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

  Future<void> _fetchMerchantRatings() async {
    if (mounted) {
      setState(() => _loadingRatings = true);
    }

    try {
      final ratings = await _apiService.fetchMerchantRatings(widget.merchantId);
      final ratingValues = ratings
          .map((rating) => (rating['value'] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      if (!mounted) return;
      setState(() {
        _ratings = ratings;
        _ratingsCount = ratings.length;
        _averageRating = ratingValues.isNotEmpty
            ? ratingValues.reduce((a, b) => a + b) / ratingValues.length
            : 0;
        _userRating = _findUserRating(ratings);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ratings = [];
        _userRating = 0;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingRatings = false);
      }
    }
  }

  Future<void> _fetchMerchantReviews() async {
    if (mounted) {
      setState(() => _loadingReviews = true);
    }

    try {
      final reviews = await _apiService.fetchMerchantReviews(widget.merchantId);
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reviews = [];
      });
    } finally {
      if (mounted) {
        setState(() => _loadingReviews = false);
      }
    }
  }

  String _normalizeId(dynamic value) {
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      final nestedId = value['_id'] ?? value['id'];
      if (nestedId is String) return nestedId;
    }
    return '';
  }

  double _findUserRating(List<Map<String, dynamic>> ratings) {
    if (_userId == null || _userId!.isEmpty) return 0;

    for (final rating in ratings) {
      if (_normalizeId(rating['user']) == _userId) {
        return (rating['value'] as num?)?.toDouble() ?? 0;
      }
    }

    return 0;
  }

  Future<void> _submitRating(double rating) async {
    if (_userToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_merchantLocalizedText(
            context,
            'Please log in to rate this store.',
            'මෙම store එකට rating දීමට කරුණාකර log in වෙන්න.',
            'இந்த store-க்கு rating அளிக்க log in செய்யவும்.',
          )),
        ),
      );
      return;
    }

    setState(() => _submittingRating = true);
    try {
      final ratings = await _apiService.postMerchantRating(
        widget.merchantId,
        rating,
        _userToken!,
      );
      final ratingValues = ratings
          .map((entry) => (entry['value'] as num?)?.toDouble())
          .whereType<double>()
          .toList();

      if (!mounted) return;
      setState(() {
        _ratings = ratings;
        _userRating = rating;
        _ratingsCount = ratings.length;
        _averageRating = ratingValues.isNotEmpty
            ? ratingValues.reduce((a, b) => a + b) / ratingValues.length
            : 0;
        if (_merchant != null) {
          _merchant = {
            ..._merchant!,
            'averageRating': _averageRating,
            'ratingsCount': _ratingsCount,
          };
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_merchantLocalizedText(
            context,
            'Store rating saved!',
            'Store rating save කළා!',
            'Store rating save செய்யப்பட்டது!',
          )),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_merchantLocalizedText(context, 'Failed to save store rating', 'Store rating save කිරීමට අසමත් විය', 'Store rating save செய்ய முடியவில்லை')}: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submittingRating = false);
      }
    }
  }

  Future<void> _submitReview() async {
    final text = _reviewController.text.trim();
    if (text.isEmpty) return;
    if (_userToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_merchantLocalizedText(
            context,
            'Please log in to review this store.',
            'මෙම store එක review කිරීමට කරුණාකර log in වෙන්න.',
            'இந்த store-ஐ review செய்ய log in செய்யவும்.',
          )),
        ),
      );
      return;
    }

    setState(() => _submittingReview = true);
    try {
      final review = await _apiService.postMerchantReview(
        widget.merchantId,
        text,
        _userToken!,
      );
      if (!mounted) return;
      setState(() {
        _reviews = [..._reviews, review];
        _reviewController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_merchantLocalizedText(
            context,
            'Store review posted!',
            'Store review එක පළ කළා!',
            'Store review பதிவுசெய்யப்பட்டது!',
          )),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_merchantLocalizedText(context, 'Failed to post store review', 'Store review පළ කිරීමට අසමත් විය', 'Store review பதிவிட முடியவில்லை')}: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submittingReview = false);
      }
    }
  }

  Future<void> _showReportStoreDialog() async {
    if (_userToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_merchantLocalizedText(
            context,
            'Please log in to report this store.',
            'මෙම store එක report කිරීමට කරුණාකර log in වෙන්න.',
            'இந்த store-ஐ report செய்ய log in செய்யவும்.',
          )),
        ),
      );
      return;
    }

    var reason = 'wrong_information';
    final detailsController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_merchantLocalizedText(
            context,
            'Report store',
            'Store report කරන්න',
            'Store report செய்யவும்',
          )),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: const [
                  DropdownMenuItem(
                    value: 'wrong_information',
                    child: Text('Wrong information'),
                  ),
                  DropdownMenuItem(
                    value: 'fake_or_misleading',
                    child: Text('Fake or misleading'),
                  ),
                  DropdownMenuItem(
                    value: 'inappropriate',
                    child: Text('Inappropriate'),
                  ),
                  DropdownMenuItem(value: 'spam', child: Text('Spam')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) =>
                    setDialogState(() => reason = value ?? reason),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Details',
                  hintText: 'Tell us what looks wrong',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    final description = detailsController.text.trim();
    detailsController.dispose();
    if (submitted != true) return;

    try {
      await _apiService.reportMerchant(
          widget.merchantId,
          {
            'reason': reason,
            'description': description,
          },
          _userToken!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_merchantLocalizedText(
            context,
            'Thanks, we sent this store report to admin.',
            'ස්තුතියි, මෙම store report එක admin වෙත යැව්වා.',
            'நன்றி, இந்த store report admin-க்கு அனுப்பப்பட்டது.',
          )),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to report store: $e')),
      );
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
          final current = (_merchant!['followers'] as num?)?.toInt() ?? 0;
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
            _isFollowing
                ? _merchantLocalizedText(
                    context,
                    'Store added to your follows',
                    'Store එක follow list එකට එකතු විය',
                    'Store உங்கள் follows இல் சேர்க்கப்பட்டது')
                : _merchantLocalizedText(
                    context,
                    'Store removed from your follows',
                    'Store එක follow list එකෙන් ඉවත් කරන ලදී',
                    'Store உங்கள் follows இலிருந்து அகற்றப்பட்டது'),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              _isFollowing ? const Color(0xFF2E7D32) : const Color(0xFF455A64),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _merchantLocalizedText(
                context,
                'Could not update store follow right now',
                'Store follow එක දැන් update කළ නොහැක',
                'Store follow ஐ இப்போது update செய்ய முடியவில்லை'),
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

  String get _merchantType {
    final raw = (_merchant?['merchantType'] ?? 'offline').toString().trim();
    if (raw == 'online' || raw == 'hybrid' || raw == 'offline') {
      return raw;
    }
    return 'offline';
  }

  bool get _merchantDeliveryAvailable =>
      _merchant?['deliveryAvailable'] == true;

  bool get _merchantPickupAvailable => _merchant?['pickupAvailable'] == true;

  String get _merchantOrderLink =>
      _normalizeWebsite(_merchant?['orderLink'] ?? _merchant?['website']);

  String get _todayKey {
    switch (DateTime.now().weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      default:
        return 'sunday';
    }
  }

  Map<String, dynamic>? get _todayOpeningHours {
    final hours = _merchant?['openingHours'];
    if (hours is! Map) return null;
    final today = hours[_todayKey];
    return today is Map<String, dynamic>
        ? today
        : (today is Map ? Map<String, dynamic>.from(today) : null);
  }

  bool? get _isOpenNow {
    final today = _todayOpeningHours;
    if (today == null || today['closed'] == true) return false;
    final open = _parseClock(today['open']);
    final close = _parseClock(today['close']);
    if (open == null || close == null) return null;
    final now = DateTime.now();
    final current = now.hour * 60 + now.minute;
    if (close < open) return current >= open || current <= close;
    return current >= open && current <= close;
  }

  int? _parseClock(dynamic value) {
    final text = value?.toString().trim() ?? '';
    final parts = text.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }

  String get _hoursLabel {
    final today = _todayOpeningHours;
    if (today == null) {
      return _merchantLocalizedText(
        context,
        'Hours unavailable',
        'Hours නොමැත',
        'Hours இல்லை',
      );
    }
    if (today['closed'] == true) {
      return _merchantLocalizedText(
          context, 'Closed today', 'අද වසා ඇත', 'இன்று மூடப்பட்டுள்ளது');
    }
    final open = (today['open'] ?? '').toString();
    final close = (today['close'] ?? '').toString();
    if (open.isEmpty || close.isEmpty) {
      return _merchantLocalizedText(
        context,
        'Hours unavailable',
        'Hours නොමැත',
        'Hours இல்லை',
      );
    }
    return '$open - $close';
  }

  String _merchantTypeLabel(String merchantType) {
    switch (merchantType) {
      case 'online':
        return _merchantLocalizedText(context, 'Online', 'Online', 'Online');
      case 'hybrid':
        return _merchantLocalizedText(context, 'Visit or Order',
            'පැමිණෙන්න හෝ Order කරන්න', 'வருகை அல்லது Order');
      default:
        return _merchantLocalizedText(context, 'In-store', 'ගබඩාවේ', 'கடையில்');
    }
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
        final bytes =
            base64Decode(imageUrl.substring(imageUrl.indexOf(',') + 1));
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
        final end = _parseDealDate(deal['endDate']);
        return end == null || !end.isBefore(now);
      }).toList();
    }
    return _deals.where((deal) {
      final end = _parseDealDate(deal['endDate']);
      return end != null && end.isBefore(now);
    }).toList();
  }

  int get _activeDealsCount {
    final now = DateTime.now();
    return _deals.where((deal) {
      final end = _parseDealDate(deal['endDate']);
      return end == null || !end.isBefore(now);
    }).length;
  }

  int get _expiredDealsCount {
    final now = DateTime.now();
    return _deals.where((deal) {
      final end = _parseDealDate(deal['endDate']);
      return end != null && end.isBefore(now);
    }).length;
  }

  String? _countdownText(Map<String, dynamic> deal) {
    final end = _parseDealDate(deal['endDate']);
    return DealExpiryHelper.formatCompact(end);
  }

  DateTime? _parseDealDate(dynamic value) {
    final raw = (value ?? '').toString();
    if (raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  String _dateRange(Map<String, dynamic> deal) {
    final start = (deal['startDate'] ?? '').toString();
    final end = (deal['endDate'] ?? '').toString();
    if (start.isEmpty && end.isEmpty) {
      return _merchantLocalizedText(context, 'Dates unavailable',
          'දින ලබා නොමැත', 'தேதிகள் கிடைக்கவில்லை');
    }
    return '$start - $end';
  }

  String _formatReviewDate(dynamic value) {
    final raw = (value ?? '').toString();
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    final local = parsed.isUtc ? parsed.toLocal() : parsed;
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
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

  Widget _buildModeChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1E88E5)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF14213D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreRatingCard() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE3A3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _merchantLocalizedText(
                    context,
                    'Store Ratings',
                    'Store Ratings',
                    'Store Ratings',
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF14213D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingRatings)
            const LinearProgressIndicator(minHeight: 2)
          else if (_ratingsCount > 0)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                RatingWidget(
                  rating: _averageRating,
                  size: 24,
                  allowHalfRating: true,
                ),
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF14213D),
                  ),
                ),
                Text(
                  '($_ratingsCount ${_ratingsCount == 1 ? 'rating' : 'ratings'})',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF607080),
                  ),
                ),
              ],
            )
          else
            Text(
              _merchantLocalizedText(
                context,
                'No store ratings yet.',
                'තවම store ratings නැහැ.',
                'இன்னும் store ratings இல்லை.',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF607080),
              ),
            ),
          const SizedBox(height: 14),
          Text(
            _merchantLocalizedText(
              context,
              'Rate this store',
              'මෙම store එකට rating දෙන්න',
              'இந்த store-ஐ rate செய்யவும்',
            ),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          InteractiveRatingWidget(
            initialRating: _userRating,
            onRatingChanged: _submitRating,
            size: 32,
            enabled: _userToken != null && !_submittingRating,
          ),
          if (_userRating > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${_merchantLocalizedText(context, 'Your rating:', 'ඔබගේ rating:', 'உங்கள் rating:')} ${_userRating.toStringAsFixed(0)}/5',
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (_submittingRating) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (_userToken == null) ...[
            const SizedBox(height: 8),
            Text(
              _merchantLocalizedText(
                context,
                'Log in to rate this store.',
                'මෙම store එකට rating දීමට log in වෙන්න.',
                'இந்த store-க்கு rating அளிக்க log in செய்யவும்.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoreReviewsCard() {
    final theme = Theme.of(context);

    String reviewerName(Map<String, dynamic> review) {
      final user = review['user'];
      if (user is Map<String, dynamic>) {
        return (user['name'] ?? user['email'] ?? 'DealFinder user').toString();
      }
      return _merchantLocalizedText(
        context,
        'DealFinder user',
        'DealFinder user',
        'DealFinder user',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.rate_review_outlined,
                color: Color(0xFF1E88E5),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_merchantLocalizedText(context, 'Store Reviews', 'Store Reviews', 'Store Reviews')} (${_reviews.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF14213D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewController,
            enabled: _userToken != null && !_submittingReview,
            minLines: 2,
            maxLines: 4,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: _userToken == null
                  ? _merchantLocalizedText(
                      context,
                      'Log in to write a store review',
                      'Store review එකක් ලිවීමට log in වෙන්න',
                      'Store review எழுத log in செய்யவும்',
                    )
                  : _merchantLocalizedText(
                      context,
                      'Share your experience with this store',
                      'මෙම store එක ගැන ඔබගේ අත්දැකීම ලියන්න',
                      'இந்த store பற்றிய உங்கள் அனுபவத்தை பகிரவும்',
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              counterText: '',
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _userToken == null || _submittingReview
                  ? null
                  : _submitReview,
              icon: _submittingReview
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_merchantLocalizedText(
                context,
                'Post Review',
                'Review පළ කරන්න',
                'Review பதிவிடவும்',
              )),
            ),
          ),
          const SizedBox(height: 14),
          if (_loadingReviews)
            const LinearProgressIndicator(minHeight: 2)
          else if (_reviews.isEmpty)
            Text(
              _merchantLocalizedText(
                context,
                'No store reviews yet.',
                'තවම store reviews නැහැ.',
                'இன்னும் store reviews இல்லை.',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF607080),
              ),
            )
          else
            Column(
              children: _reviews.reversed.take(5).map((review) {
                final date = _formatReviewDate(review['createdAt']);
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              reviewerName(review),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF14213D),
                              ),
                            ),
                          ),
                          if (date.isNotEmpty)
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7C8896),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (review['text'] ?? '').toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF425466),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final merchantDescription = _merchantText(
      'description',
      fallbackKey: 'profile',
    );
    final merchantPhone = _merchantText(
      'phone',
      fallbackKey: 'contactNumber',
    );
    final merchantWebsite = _normalizeWebsite(_merchant?['website']);
    final merchantOrderLink = _merchantOrderLink;
    final merchantType = _merchantType;
    final latitude = _merchantLatitude;
    final longitude = _merchantLongitude;
    final followerCount = (_merchant?['followers'] as num?)?.toInt() ?? 0;
    final activeDeals =
        (_merchant?['activeDeals'] as num?)?.toInt() ?? _activeDealsCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(_merchantLocalizedText(
            context, 'Store Profile', 'Store පැතිකඩ', 'Store சுயவிவரம்')),
        actions: [
          if (_merchant != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                final url = _merchant!['website'] ?? '';
                Share.share(
                  '${_merchantLocalizedText(context, 'Check out', 'බලන්න', 'பாருங்கள்')} ${_merchant!['name']} ${_merchantLocalizedText(context, 'on Deal Finder!', 'Deal Finder හි!', 'Deal Finder இல்!')}'
                  '${url.toString().isNotEmpty ? '\n$url' : ''}',
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: _merchantLocalizedText(
              context,
              'Report store',
              'Store report කරන්න',
              'Store report செய்யவும்',
            ),
            onPressed: _showReportStoreDialog,
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
                  ? Center(
                      child: Text(_merchantLocalizedText(
                          context,
                          'Merchant not found',
                          'Merchant හමු නොවීය',
                          'Merchant கிடைக்கவில்லை')))
                  : RefreshIndicator(
                      onRefresh: () async {
                        await Future.wait([
                          _fetchMerchant(),
                          _fetchMerchantRatings(),
                          _fetchMerchantReviews(),
                        ]);
                      },
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          SizedBox(
                            height: 220,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _buildImageWidget(
                                  _merchant!['banner']?.toString().isNotEmpty ==
                                          true
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (_merchant!['name'] ?? '')
                                                    .toString(),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                (_merchant!['category'] ??
                                                        'Other')
                                                    .toString(),
                                                style: const TextStyle(
                                                  color: Color(0xFF6D7B8A),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  _buildModeChip(
                                                    icon: merchantType ==
                                                            'online'
                                                        ? Icons.public
                                                        : Icons
                                                            .storefront_outlined,
                                                    label: _merchantTypeLabel(
                                                        merchantType),
                                                  ),
                                                  _buildModeChip(
                                                    icon: _isOpenNow == true
                                                        ? Icons
                                                            .check_circle_outline
                                                        : Icons
                                                            .schedule_outlined,
                                                    label: _isOpenNow == true
                                                        ? _merchantLocalizedText(
                                                            context,
                                                            'Open now • $_hoursLabel',
                                                            'දැන් විවෘතයි • $_hoursLabel',
                                                            'இப்போது திறந்திருக்கும் • $_hoursLabel')
                                                        : _hoursLabel,
                                                  ),
                                                  if (_merchantDeliveryAvailable)
                                                    _buildModeChip(
                                                      icon:
                                                          Icons.delivery_dining,
                                                      label:
                                                          _merchantLocalizedText(
                                                              context,
                                                              'delivery',
                                                              'delivery',
                                                              'delivery'),
                                                    ),
                                                  if (_merchantPickupAvailable)
                                                    _buildModeChip(
                                                      icon: Icons
                                                          .shopping_bag_outlined,
                                                      label:
                                                          _merchantLocalizedText(
                                                              context,
                                                              'pickup',
                                                              'pickup',
                                                              'pickup'),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              AnimatedSwitcher(
                                                duration: const Duration(
                                                  milliseconds: 220,
                                                ),
                                                child: Wrap(
                                                  key: ValueKey(
                                                    '$followerCount-$activeDeals-$_ratingsCount-$_isFollowing',
                                                  ),
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    _buildStatChip(
                                                      icon: Icons
                                                          .people_alt_outlined,
                                                      label: _isFollowing
                                                          ? _merchantLocalizedText(
                                                              context,
                                                              'followers • you follow',
                                                              'followers • ඔබ follow කරයි',
                                                              'followers • நீங்கள் follow செய்கிறீர்கள்')
                                                          : _merchantLocalizedText(
                                                              context,
                                                              'followers',
                                                              'followers',
                                                              'followers'),
                                                      value: '$followerCount',
                                                    ),
                                                    _buildStatChip(
                                                      icon: Icons
                                                          .local_offer_outlined,
                                                      label:
                                                          _merchantLocalizedText(
                                                              context,
                                                              'active deals',
                                                              'සක්‍රිය deals',
                                                              'active deals'),
                                                      value: '$activeDeals',
                                                    ),
                                                    if (_ratingsCount > 0)
                                                      _buildStatChip(
                                                        icon: Icons
                                                            .star_rate_rounded,
                                                        label:
                                                            _merchantLocalizedText(
                                                                context,
                                                                'rating',
                                                                'rating',
                                                                'rating'),
                                                        value: _averageRating
                                                            .toStringAsFixed(1),
                                                      ),
                                                  ],
                                                ),
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
                                    _buildStoreRatingCard(),
                                    const SizedBox(height: 16),
                                    _buildStoreReviewsCard(),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          child: ElevatedButton.icon(
                                            key: ValueKey(
                                              'follow-${_isFollowing ? 'on' : 'off'}-${_followBusy ? 'busy' : 'idle'}',
                                            ),
                                            onPressed: _followBusy
                                                ? null
                                                : _toggleFollow,
                                            icon: _followBusy
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Icon(
                                                    _isFollowing
                                                        ? Icons.check_circle
                                                        : Icons
                                                            .person_add_alt_1,
                                                  ),
                                            label: Text(
                                              _followBusy
                                                  ? (_isFollowing
                                                      ? _merchantLocalizedText(
                                                          context,
                                                          'Updating...',
                                                          'යාවත්කාලීන වෙමින්...',
                                                          'புதுப்பிக்கப்படுகிறது...')
                                                      : _merchantLocalizedText(
                                                          context,
                                                          'Saving...',
                                                          'සුරකිමින්...',
                                                          'சேமிக்கப்படுகிறது...'))
                                                  : (_isFollowing
                                                      ? _merchantLocalizedText(
                                                          context,
                                                          'Following store',
                                                          'Follow කරන store',
                                                          'Following store')
                                                      : _merchantLocalizedText(
                                                          context,
                                                          'Follow store',
                                                          'Store follow කරන්න',
                                                          'Store follow செய்யவும்')),
                                            ),
                                          ),
                                        ),
                                        if (merchantWebsite.isNotEmpty)
                                          OutlinedButton.icon(
                                            onPressed: () => _openExternalUrl(
                                                merchantWebsite),
                                            icon: const Icon(Icons.language),
                                            label: Text(l10n.websiteLabel),
                                          ),
                                        if ((_merchantDeliveryAvailable ||
                                                _merchantPickupAvailable ||
                                                merchantType == 'online' ||
                                                merchantType == 'hybrid') &&
                                            merchantOrderLink.isNotEmpty)
                                          ElevatedButton.icon(
                                            onPressed: () => _openExternalUrl(
                                                merchantOrderLink),
                                            icon: const Icon(
                                                Icons.delivery_dining),
                                            label: Text(
                                              _merchantDeliveryAvailable
                                                  ? _merchantLocalizedText(
                                                      context,
                                                      'Order Now',
                                                      'දැන් Order කරන්න',
                                                      'இப்போது Order செய்யவும்')
                                                  : _merchantLocalizedText(
                                                      context,
                                                      'Order',
                                                      'Order',
                                                      'Order'),
                                            ),
                                          ),
                                        if (merchantPhone.isNotEmpty)
                                          OutlinedButton.icon(
                                            onPressed: () => _openExternalUrl(
                                                'tel:$merchantPhone'),
                                            icon:
                                                const Icon(Icons.call_outlined),
                                            label: Text(_merchantLocalizedText(
                                                context,
                                                'Contact',
                                                'සම්බන්ධ වන්න',
                                                'தொடர்பு')),
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
                                          borderRadius:
                                              BorderRadius.circular(16),
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
                                                onPressed: () =>
                                                    _openExternalUrl(
                                                  'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
                                                ),
                                                icon: const Icon(
                                                    Icons.directions),
                                                label: Text(l10n.getDirections),
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
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                _buildTabButton(
                                  'active',
                                  _merchantLocalizedText(
                                      context,
                                      'Active Deals',
                                      'සක්‍රිය Deals',
                                      'Active Deals'),
                                  _activeDealsCount,
                                ),
                                const SizedBox(width: 8),
                                _buildTabButton(
                                  'expired',
                                  _merchantLocalizedText(
                                      context,
                                      'Expired Deals',
                                      'කල් ඉකුත් Deals',
                                      'Expired Deals'),
                                  _expiredDealsCount,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _filteredDeals.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 32),
                                    child: Center(
                                      child: Text(
                                        _activeTab == 'active'
                                            ? _merchantLocalizedText(
                                                context,
                                                'No active deals available.',
                                                'සක්‍රිය deals නොමැත.',
                                                'Active deals எதுவும் இல்லை.')
                                            : _merchantLocalizedText(
                                                context,
                                                'No expired deals available.',
                                                'කල් ඉකුත් deals නොමැත.',
                                                'Expired deals எதுவும் இல்லை.'),
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
                                                    if ((deal['description'] ??
                                                            '')
                                                        .toString()
                                                        .isNotEmpty)
                                                      Text(
                                                        deal['description']
                                                            .toString(),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
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
                                                    if (DealExpiryHelper
                                                        .isEndingToday(
                                                      _parseDealDate(
                                                          deal['endDate']),
                                                    )) ...[
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
                                                          color: const Color(
                                                              0xFFFFF4ED),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      999),
                                                          border: Border.all(
                                                            color: const Color(
                                                              0xFFF9B189,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          _merchantLocalizedText(
                                                              context,
                                                              'Ending today',
                                                              'අද අවසන්',
                                                              'இன்று முடியும்'),
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: Color(
                                                                0xFF9A3412),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                    if (countdown != null) ...[
                                                      const SizedBox(height: 8),
                                                      Builder(
                                                        builder: (context) {
                                                          final urgencyDate =
                                                              countdown ==
                                                                      'Expired'
                                                                  ? DateTime
                                                                          .now()
                                                                      .subtract(
                                                                      const Duration(
                                                                        minutes:
                                                                            1,
                                                                      ),
                                                                    )
                                                                  : _parseDealDate(
                                                                      deal[
                                                                          'endDate'],
                                                                    );
                                                          final foreground =
                                                              DealExpiryHelper
                                                                  .urgencyColor(
                                                            context,
                                                            urgencyDate,
                                                          );
                                                          return Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 10,
                                                              vertical: 6,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: DealExpiryHelper
                                                                  .urgencyBackgroundColor(
                                                                urgencyDate,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                999,
                                                              ),
                                                              border:
                                                                  Border.all(
                                                                color: DealExpiryHelper
                                                                    .urgencyBorderColor(
                                                                  urgencyDate,
                                                                ),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              countdown ==
                                                                      'Expired'
                                                                  ? countdown
                                                                  : '${_merchantLocalizedText(context, 'Ends in', 'අවසන් වීමට', 'முடிவதற்கு')} $countdown',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color:
                                                                    foreground,
                                                              ),
                                                            ),
                                                          );
                                                        },
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

  Widget _buildTabButton(String value, String label, int count) {
    final selected = _activeTab == value;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _activeTab = value),
        style: OutlinedButton.styleFrom(
          backgroundColor:
              selected ? Theme.of(context).colorScheme.primary : Colors.white,
          foregroundColor: selected ? Colors.white : const Color(0xFF425466),
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : const Color(0xFFD7E0EA),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.18)
                    : const Color(0xFFF3F6FA),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : const Color(0xFF425466),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
