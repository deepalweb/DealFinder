import '../widgets/storefront_theme.dart';
import '../widgets/stitch_discover_components.dart'
    show StitchFullWidthOfferCard;
import '../utils/offer_presentation.dart';
import '../widgets/sign_in_gate.dart';
import '../widgets/profile_section.dart';
import '../models/promotion.dart';
import '../utils/merchant_hours.dart';
import '../utils/map_marker_icon.dart';
import '../config/app_config.dart';
import 'deal_detail_screen.dart';
import '../config/app_theme.dart';
import 'dart:convert';

import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../services/merchant_following_manager.dart';
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

class MerchantProfileScreen extends StatelessWidget {
  const MerchantProfileScreen(
      {super.key, required this.merchantId, this.api, this.mapBuilder});
  final String merchantId;
  final ApiService? api;
  final Widget Function(GoogleMap map)? mapBuilder;
  @override
  Widget build(BuildContext context) => Theme(
      data: storefrontTheme(Theme.of(context)),
      child: _MerchantProfilePage(
          merchantId: merchantId, api: api, mapBuilder: mapBuilder));
}

class _MerchantProfilePage extends StatefulWidget {
  const _MerchantProfilePage(
      {required this.merchantId, this.api, this.mapBuilder});
  final String merchantId;
  final ApiService? api;
  final Widget Function(GoogleMap map)? mapBuilder;
  @override
  State<_MerchantProfilePage> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends State<_MerchantProfilePage> {
  Map<String, dynamic>? _merchant;
  List<Map<String, dynamic>> _deals = [];
  bool _loading = true;
  bool _loadingOffers = false;
  bool _offersFailed = false;
  bool _followBusy = false;
  bool _isFollowing = false;
  bool _loadingRatings = true;
  bool _loadingReviews = true;
  bool _submittingRating = false;
  bool _submittingReview = false;
  String? _error;
  String _activeTab = 'active';
  late final ApiService _apiService = widget.api ?? ApiService();
  String _profileSection = 'offers';
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
      if (!mounted) return;
      setState(() {
        _merchant = merchant;
        _averageRating =
            (merchant['averageRating'] as num?)?.toDouble() ?? _averageRating;
        _ratingsCount =
            (merchant['ratingsCount'] as num?)?.toInt() ?? _ratingsCount;
        _loading = false;
      });
      await _fetchOffers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is MerchantRequestException && e.statusCode == 404
            ? 'not_found'
            : 'request_failed';
        _loading = false;
      });
    }
  }

  Future<void> _fetchOffers() async {
    if (!mounted) return;
    setState(() {
      _loadingOffers = true;
      _offersFailed = false;
    });
    try {
      final deals =
          await _apiService.fetchPromotionsByMerchant(widget.merchantId);
      if (!mounted) return;
      setState(() => _deals = deals);
    } catch (_) {
      if (!mounted) return;
      setState(() => _offersFailed = true);
    } finally {
      if (mounted) setState(() => _loadingOffers = false);
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
    if (!await requireSignIn(context) || !mounted) return;
    await _loadUserAuth();
    if (!mounted) return;
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
    switch (DateTime.now()
        .toUtc()
        .add(const Duration(hours: 5, minutes: 30))
        .weekday) {
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

  bool? get _isOpenNow => MerchantHours.isOpen(_merchant?['openingHours']);

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
        color: AppColors.border(context),
        child: const Icon(Icons.storefront, color: Colors.white, size: 40),
      );
    }

    if (imageUrl.startsWith('assets/')) {
      return Image.asset(imageUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => SizedBox(
              width: width,
              height: height,
              child: const Icon(Icons.storefront_outlined)));
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
            color: AppColors.border(context),
            child: const Icon(Icons.storefront, color: Colors.white, size: 40),
          ),
        );
      } catch (_) {
        return Container(
          width: width,
          height: height,
          color: AppColors.border(context),
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
          color: AppColors.border(context),
          child: const Icon(Icons.storefront, color: Colors.white, size: 40),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppColors.border(context),
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      );
    }

    return Container(
      width: width,
      height: height,
      color: AppColors.border(context),
      child: const Icon(Icons.storefront, color: Colors.white, size: 40),
    );
  }

  List<Promotion> get _profileOffers => _deals
      .map((deal) => Promotion.fromJson({...deal, 'merchant': _merchant}))
      .toList();
  List<Promotion> get _activeOffers =>
      _profileOffers.where((offer) => OfferPresentation(offer).public).toList();
  List<Promotion> get _expiredOffers => _profileOffers
      .where((offer) =>
          offer.isExpired &&
          (offer.status == null ||
              ['active', 'approved', 'scheduled'].contains(offer.status)))
      .toList();

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

    return IconButton(
      tooltip: type,
      onPressed: () => _openExternalUrl(url),
      icon: CircleAvatar(
        backgroundColor: color,
        radius: 16,
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildStatChip(
          {required IconData icon,
          required String label,
          required String value}) =>
      Chip(avatar: Icon(icon, size: 18), label: Text('$value $label'));

  Widget _buildModeChip({required IconData icon, required String label}) =>
      Chip(avatar: Icon(icon, size: 18), label: Text(label));

  Widget _buildStoreRatingCard() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                    fontWeight: FontWeight.w700,
                    color: AppColors.text(context),
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
                    color: AppColors.text(context),
                  ),
                ),
                Text(
                  '($_ratingsCount ${_ratingsCount == 1 ? 'rating' : 'ratings'})',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rate_review_outlined,
                color: AppColors.accent(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_merchantLocalizedText(context, 'Store Reviews', 'Store Reviews', 'Store Reviews')} (${_reviews.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text(context),
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
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
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.text(context),
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
                          color: Theme.of(context).colorScheme.onSurface,
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

  void _directions() => _openExternalUrl(
      'https://www.google.com/maps/dir/?api=1&destination=$_merchantLatitude,$_merchantLongitude');

  Widget _merchantHero() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final banner = _merchantText('banner');
    final logo = _merchantText('logo');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (banner.isNotEmpty) ...[
        ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
                aspectRatio: 2.6,
                child: _buildImageWidget(banner, width: double.infinity))),
        const SizedBox(height: 20),
      ],
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _buildImageWidget(logo.isEmpty ? null : logo,
                width: 56, height: 56)),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(
              header: true,
              child: Text(_merchantText('name'),
                  style: theme.textTheme.headlineSmall)),
          if (_merchantText('address').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_merchantText('address'), style: theme.textTheme.bodyMedium),
          ],
        ])),
      ]),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _buildModeChip(
            icon: _merchantType == 'online'
                ? Icons.language
                : Icons.storefront_outlined,
            label: _merchantTypeLabel(_merchantType)),
        if (_merchantDeliveryAvailable)
          _buildModeChip(
              icon: Icons.delivery_dining, label: l10n.deliveryLabel),
        if (_merchantPickupAvailable)
          _buildModeChip(
              icon: Icons.shopping_bag_outlined, label: l10n.pickupLabel),
        if (_isOpenNow != null && _merchantType != 'online')
          _buildModeChip(
              icon: Icons.schedule,
              label: _isOpenNow! ? l10n.openNowLabel : l10n.profileClosedLabel),
        if (!_loadingOffers && !_offersFailed)
          _buildStatChip(
              icon: Icons.local_offer_outlined,
              label: l10n.profileOffersLabel,
              value: '${_activeOffers.length}'),
        if (_ratingsCount > 0)
          _buildStatChip(
              icon: Icons.star_outline,
              label: '($_ratingsCount)',
              value: _averageRating.toStringAsFixed(1)),
        if (_merchant!['followers'] is num)
          _buildStatChip(
              icon: Icons.people_outline,
              label: l10n.profileFollowersLabel,
              value: '${_merchant!['followers']}'),
      ]),
      const SizedBox(height: 18),
      Wrap(spacing: 10, runSpacing: 10, children: [
        FilledButton.icon(
            onPressed: _followBusy ? null : _toggleFollow,
            icon: _followBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_isFollowing ? Icons.check : Icons.add),
            label: Text(_isFollowing ? l10n.following : l10n.followStoreLabel)),
        if (_merchantType != 'online' &&
            _merchantLatitude != null &&
            _merchantLongitude != null)
          OutlinedButton.icon(
              onPressed: _directions,
              icon: const Icon(Icons.near_me_outlined),
              label: Text(l10n.getDirections)),
        if (_merchantType != 'offline' && _merchantOrderLink.isNotEmpty)
          OutlinedButton.icon(
              onPressed: () => _openExternalUrl(_merchantOrderLink),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(l10n.visitWebsite)),
      ]),
    ]);
  }

  Widget _merchantAbout() {
    final l10n = AppLocalizations.of(context)!;
    final description = _merchantText('description', fallbackKey: 'profile');
    final phone = _merchantText('phone', fallbackKey: 'contactNumber');
    final website = _normalizeWebsite(_merchant?['website']);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (description.isNotEmpty)
        Text(description, style: Theme.of(context).textTheme.bodyLarge),
      ProfileSection(title: l10n.contact, children: [
        if (_merchantText('address').isNotEmpty)
          ProfileActionTile(
              icon: Icons.location_on_outlined,
              title: _merchantText('address'),
              subtitle: l10n.profileVisitLabel,
              onTap: _merchantLatitude != null && _merchantLongitude != null
                  ? _directions
                  : null),
        if (phone.isNotEmpty)
          ProfileActionTile(
              icon: Icons.call_outlined,
              title: l10n.profileCallStoreLabel,
              subtitle: phone,
              onTap: () => _openExternalUrl('tel:$phone')),
        if (website.isNotEmpty)
          ProfileActionTile(
              icon: Icons.language,
              title: l10n.visitWebsite,
              subtitle: website,
              onTap: () => _openExternalUrl(website)),
        if (phone.isEmpty &&
            website.isEmpty &&
            _merchantText('address').isEmpty)
          ProfileActionTile(
              icon: Icons.info_outline, title: l10n.noContactInfo),
      ]),
      ProfileSection(title: l10n.profileHoursLabel, children: [
        ProfileActionTile(
            icon: Icons.schedule,
            title: _hoursLabel,
            subtitle: _isOpenNow == null
                ? l10n.profileHoursUnknownLabel
                : _isOpenNow!
                    ? l10n.openNowLabel
                    : l10n.profileClosedLabel),
      ]),
      if (_merchantLatitude != null && _merchantLongitude != null) ...[
        const SizedBox(height: 20),
        ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(height: 200, child: _locationMap())),
      ],
      if (_merchant?['socialMedia'] is Map) ...[
        const SizedBox(height: 16),
        _buildSocialLinks(_merchant!['socialMedia'] as Map)
      ],
    ]);
  }

  Widget _locationMap() {
    final map = GoogleMap(
        initialCameraPosition: CameraPosition(
            target: LatLng(_merchantLatitude!, _merchantLongitude!), zoom: 15),
        style: Theme.of(context).brightness == Brightness.dark
            ? googleMapDarkStyle
            : null,
        myLocationButtonEnabled: false,
        mapToolbarEnabled: false,
        markers: {
          Marker(
              markerId: const MarkerId('merchant'),
              position: LatLng(_merchantLatitude!, _merchantLongitude!))
        });
    return widget.mapBuilder?.call(map) ?? map;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offers = _activeTab == 'active' ? _activeOffers : _expiredOffers;
    return Scaffold(
      appBar: AppBar(
          title: Text(l10n.merchantProfileTitle),
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700),
          actions: [
            if (_merchant != null)
              IconButton(
                  tooltip: l10n.profileShareStoreLabel,
                  icon: const Icon(Icons.ios_share),
                  onPressed: () => Share.share(
                      '${_merchantText('name')}\n${AppConfig.publicBaseUrl}/merchants/${widget.merchantId}')),
            IconButton(
                tooltip: _merchantLocalizedText(context, 'Report store',
                    'ගබඩාව වාර්තා කරන්න', 'கடையைப் புகாரளிக்கவும்'),
                icon: const Icon(Icons.flag_outlined),
                onPressed: _showReportStoreDialog),
          ]),
      body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null || _merchant == null
                      ? Center(
                          child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.storefront_outlined,
                                        size: 48),
                                    const SizedBox(height: 16),
                                    Text(
                                        _error == 'not_found'
                                            ? _merchantLocalizedText(
                                                context,
                                                'This store is no longer available.',
                                                'මෙම වෙළඳසැල තවදුරටත් නොමැත.',
                                                'இந்தக் கடை இனி கிடைக்காது.')
                                            : l10n
                                                .merchantProfileUnavailableLabel,
                                        textAlign: TextAlign.center),
                                    const SizedBox(height: 16),
                                    FilledButton.icon(
                                        onPressed: _bootstrap,
                                        icon: const Icon(Icons.refresh),
                                        label: Text(l10n.retry)),
                                  ])))
                      : RefreshIndicator(
                          onRefresh: _bootstrap,
                          child: ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 32),
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                _merchantHero(),
                                const SizedBox(height: 24),
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  for (final entry in {
                                    'offers': l10n.profileOffersLabel,
                                    'about': l10n.about,
                                    'reviews': l10n.profileReviewsLabel
                                  }.entries)
                                    ChoiceChip(
                                        label: Text(entry.value),
                                        selected: _profileSection == entry.key,
                                        onSelected: (_) => setState(
                                            () => _profileSection = entry.key)),
                                ]),
                                const SizedBox(height: 20),
                                if (_profileSection == 'offers') ...[
                                  if (_loadingOffers)
                                    const LinearProgressIndicator(),
                                  if (_offersFailed)
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(_merchantLocalizedText(
                                                  context,
                                                  'Offers could not be loaded. Store details are still available.',
                                                  'දීමනා පූරණය කළ නොහැක. වෙළඳසැල් විස්තර තවමත් තිබේ.',
                                                  'சலுகைகளை ஏற்ற முடியவில்லை. கடை விவரங்கள் இன்னும் உள்ளன.')),
                                              TextButton.icon(
                                                  onPressed: _fetchOffers,
                                                  icon:
                                                      const Icon(Icons.refresh),
                                                  label: Text(l10n.retry)),
                                            ])),
                                  if (!_loadingOffers && !_offersFailed)
                                    Wrap(spacing: 8, runSpacing: 8, children: [
                                      ChoiceChip(
                                          label: Text(
                                              '${l10n.profileActiveOffersLabel} (${_activeOffers.length})'),
                                          selected: _activeTab == 'active',
                                          onSelected: (_) => setState(
                                              () => _activeTab = 'active')),
                                      ChoiceChip(
                                          label: Text(
                                              '${l10n.profileExpiredOffersLabel} (${_expiredOffers.length})'),
                                          selected: _activeTab == 'expired',
                                          onSelected: (_) => setState(
                                              () => _activeTab = 'expired')),
                                    ]),
                                  const SizedBox(height: 16),
                                  if (!_loadingOffers &&
                                      !_offersFailed &&
                                      offers.isEmpty)
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 28),
                                        child: Text(l10n.profileNoOffersLabel,
                                            textAlign: TextAlign.center)),
                                  for (final offer
                                      in (_loadingOffers || _offersFailed
                                          ? <Promotion>[]
                                          : offers))
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
                                        child: StitchFullWidthOfferCard(
                                            offer: offer,
                                            onOpen: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        DealDetailScreen(
                                                            promotion: offer,
                                                            api:
                                                                _apiService))))),
                                ],
                                if (_profileSection == 'about')
                                  _merchantAbout(),
                                if (_profileSection == 'reviews') ...[
                                  _buildStoreRatingCard(),
                                  const SizedBox(height: 16),
                                  _buildStoreReviewsCard()
                                ],
                              ])))),
    );
  }
}
