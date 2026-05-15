import 'dart:convert'; // For base64Decode
import 'dart:async';
// For Uint8List
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:intl/intl.dart'; // For date formatting
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:shimmer/shimmer.dart';
import '../models/promotion.dart';
import '../services/favorites_manager.dart';
import '../services/api_service.dart';
import '../services/recommendation_service.dart';
import '../services/deal_history_service.dart';
import '../services/location_service.dart';
import '../config/app_config.dart';
import '../screens/merchant_profile_screen.dart';
import '../utils/deal_expiry_helper.dart';
import '../widgets/deal_verification_badge.dart';
import '../widgets/rating_widget.dart';

class DealDetailScreen extends StatefulWidget {
  final Promotion promotion;
  const DealDetailScreen({super.key, required this.promotion});

  @override
  State<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends State<DealDetailScreen> {
  bool _isFavorite = false;
  bool _showTerms = false;
  List<Map<String, dynamic>> _comments = [];
  List<Map<String, dynamic>> _ratings = [];
  bool _loadingComments = true;
  bool _submittingComment = false;
  bool _submittingRating = false;
  double _averageRating = 0;
  double _userRating = 0;
  int _reviewCount = 0;
  final ApiService _apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  String? _userToken;
  String? _userId;

  Map<String, dynamic>? _merchantData;
  double? _liveDistanceMeters;
  int _viewCount = 0;
  int _favoriteCount = 0;
  int _commentCount = 0;
  int _clickCount = 0;
  int _directionCount = 0;
  bool _loadingStats = true;
  Timer? _countdownTimer;

  late Future<List<Promotion>> _recommendedDealsFuture;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
    _loadReviewsAndStats();
    _loadUserAuth();
    _fetchMerchantData();
    _refreshDistanceFromCurrentLocation();
    _recommendedDealsFuture = _fetchRecommendedDeals();
    _trackView();
    _startCountdownTicker();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  String? _resolveMerchantLogoUrl(String? rawUrl) {
    final trimmed = rawUrl?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    if (trimmed.startsWith('data:image')) return trimmed;

    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      if (parsed.scheme == 'http' || parsed.scheme == 'https') {
        return parsed.toString();
      }
      return null;
    }

    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }

    final base = AppConfig.publicBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$path';
  }

  ImageProvider<Object>? _buildMerchantLogoProvider(String? rawUrl) {
    final resolved = _resolveMerchantLogoUrl(rawUrl);
    if (resolved == null) return null;

    if (resolved.startsWith('data:image')) {
      try {
        final bytes =
            base64Decode(resolved.substring(resolved.indexOf(',') + 1));
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }

    return NetworkImage(resolved);
  }

  void _startCountdownTicker() {
    if (widget.promotion.endDate == null) return;
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _trackView() async {
    await DealHistoryService.addToHistory(widget.promotion.id);
    await RecommendationService.trackView(
        widget.promotion.id, widget.promotion.category);
    try {
      await _apiService.recordPromotionClick(widget.promotion.id, type: 'view');
      await _fetchPromotionStats();
    } catch (_) {}
  }

  Future<void> _loadUserAuth() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userToken = prefs.getString('userToken');
      _userId = prefs.getString('userId');
      _userRating = _findUserRating(_ratings);
    });
  }

  Future<void> _loadFavoriteStatus() async {
    final isFav = await FavoritesManager.isFavorite(widget.promotion.id);
    setState(() {
      _isFavorite = isFav;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await FavoritesManager.removeFavorite(widget.promotion.id);
    } else {
      await FavoritesManager.addFavorite(widget.promotion.id);
    }
    setState(() {
      _isFavorite = !_isFavorite;
      _favoriteCount = _isFavorite
          ? _favoriteCount + 1
          : (_favoriteCount > 0 ? _favoriteCount - 1 : 0);
    });
  }

  Future<void> _fetchMerchantData() async {
    if (widget.promotion.merchantId == null) return;
    try {
      final data =
          await _apiService.fetchMerchantById(widget.promotion.merchantId!);
      if (!mounted) return;
      setState(() {
        _merchantData = data;
      });
      await _refreshDistanceFromCurrentLocation();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _merchantData = null;
      });
    }
  }

  (double, double)? _merchantCoordinates() {
    final coords = _merchantData?['location']?['coordinates'];
    if (coords is List && coords.length >= 2) {
      final lon = (coords[0] as num?)?.toDouble();
      final lat = (coords[1] as num?)?.toDouble();
      if (lat != null && lon != null) {
        return (lat, lon);
      }
    }

    final lat = widget.promotion.latitude;
    final lon = widget.promotion.longitude;
    if (lat != null && lon != null) {
      return (lat, lon);
    }

    return null;
  }

  Future<void> _refreshDistanceFromCurrentLocation() async {
    final coords = _merchantCoordinates();
    if (coords == null) return;

    final locationResult = await LocationService.resolveCurrentLocation(
      requestPermission: false,
      allowLastKnownFallback: true,
    );
    final position = locationResult.position;
    if (position == null || !mounted) return;

    final distanceKm = LocationService.calculateDistance(
      position.latitude,
      position.longitude,
      coords.$1,
      coords.$2,
    );

    setState(() {
      _liveDistanceMeters = distanceKm * 1000;
    });
  }

  Future<List<Promotion>> _fetchRecommendedDeals() async {
    try {
      // Fetch all promotions and filter out the current one
      final allPromos = await _apiService.fetchPromotions();
      return allPromos
          .where((p) => p.id != widget.promotion.id)
          .take(5)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Helper to launch URL - requires url_launcher package
  Future<void> _openDirections() async {
    String? url;
    final merchant = _merchantData;

    if (merchant != null) {
      final coords = merchant['location']?['coordinates'];
      if (coords != null && coords.length == 2) {
        final lng = coords[0];
        final lat = coords[1];
        url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
      } else if (merchant['address'] != null &&
          merchant['address'].toString().isNotEmpty) {
        final query = Uri.encodeComponent(merchant['address'].toString());
        url = 'https://www.google.com/maps/dir/?api=1&destination=$query';
      }
    }

    if (url == null &&
        widget.promotion.location != null &&
        widget.promotion.location!.isNotEmpty) {
      final query = Uri.encodeComponent(widget.promotion.location!);
      url = 'https://www.google.com/maps/dir/?api=1&destination=$query';
    }

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location available for this deal.')),
      );
      return;
    }

    try {
      await _apiService.recordPromotionClick(
        widget.promotion.id,
        type: 'direction',
        token: _userToken,
        userId: _userId,
      );
      if (mounted) {
        setState(() {
          _directionCount += 1;
          _clickCount += 1;
        });
      }
    } catch (_) {}

    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      await _apiService.recordPromotionClick(
        widget.promotion.id,
        type: 'outbound',
        token: _userToken,
        userId: _userId,
      );
      if (mounted) {
        setState(() => _clickCount += 1);
      }
    } catch (_) {}
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $urlString')),
      );
    }
  }

  String _merchantText(String primaryKey, {String? fallbackKey}) {
    final primary = (_merchantData?[primaryKey] ?? '').toString().trim();
    if (primary.isNotEmpty) return primary;
    if (fallbackKey == null) return '';
    return (_merchantData?[fallbackKey] ?? '').toString().trim();
  }

  String get _merchantPhoneNumber {
    final candidates = [
      _merchantText('phone', fallbackKey: 'contactNumber'),
      _merchantText('contactNumber'),
      _merchantText('contactInfo'),
    ];

    for (final value in candidates) {
      if (value.isEmpty) continue;
      final sanitized = value.replaceAll(RegExp(r'[^0-9+]'), '');
      final digitsOnly = sanitized.replaceAll('+', '');
      if (digitsOnly.length >= 7) {
        return sanitized;
      }
    }

    return '';
  }

  bool get _supportsVisit => widget.promotion.supportsVisit;

  bool get _supportsDelivery => widget.promotion.supportsDelivery;

  bool get _supportsPickup => widget.promotion.supportsPickup;

  String? get _effectiveOrderLink {
    final merchantLink = _merchantData?['orderLink']?.toString().trim();
    if (merchantLink != null && merchantLink.isNotEmpty) {
      return merchantLink;
    }
    return widget.promotion.effectiveOrderLink;
  }

  String? get _countdownText {
    return DealExpiryHelper.formatCompact(widget.promotion.endDate);
  }

  double? get _displayDistanceMeters {
    return _liveDistanceMeters ?? widget.promotion.distance;
  }

  String _formatDistance(double? distanceMeters) {
    if (distanceMeters == null) return '';
    if (distanceMeters < 1000) return '${distanceMeters.round()} m away';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km away';
  }

  String _displayTitle(Promotion promotion) {
    var title = promotion.title.trim();
    title = title
        .replaceFirst(
          RegExp(r'^[^\w\s]+', unicode: true),
          '',
        )
        .trim();

    final computedDiscount = promotion.discountPercentage;
    final titleDiscountMatch =
        RegExp(r'(\d+)\s*%\s*OFF', caseSensitive: false).firstMatch(title);
    if (computedDiscount != null && titleDiscountMatch != null) {
      final titleDiscount = int.tryParse(titleDiscountMatch.group(1) ?? '');
      if (titleDiscount != null && titleDiscount != computedDiscount) {
        title = title.replaceRange(
          titleDiscountMatch.start,
          titleDiscountMatch.end,
          '$computedDiscount% OFF',
        );
      }
    }

    return title;
  }

  String _displayHeaderTitle(Promotion promotion) {
    return promotion.featured == true ? 'Flash Deal' : 'Deal details';
  }

  String _formatCountdownInline(String countdownText) {
    if (countdownText == 'Expired') return 'Expired';
    return 'Ends in $countdownText';
  }

  Future<void> _launchPhoneCall() async {
    final phone = _merchantPhoneNumber;
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No merchant phone number available.')),
        );
      }
      return;
    }

    final uri = Uri.parse('tel:$phone');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start the phone call.')),
        );
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    final phone = _merchantPhoneNumber;
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No merchant phone number available.')),
        );
      }
      return;
    }

    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final message = Uri.encodeComponent(
      'Hi, I am contacting you about "${widget.promotion.title}" on Deal Finder.',
    );
    final uri = Uri.parse('https://wa.me/$digits?text=$message');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
      }
    }
  }

  void _shareDeal() {
    final promo = widget.promotion;
    final text =
        '${promo.title}\n${promo.description}\n${promo.websiteUrl ?? ''}';
    Share.share(text.trim());
  }

  Future<void> _loadReviewsAndStats() async {
    await Future.wait([
      _fetchCommentsAndRatings(),
      _fetchPromotionStats(),
    ]);
  }

  Future<void> _fetchCommentsAndRatings() async {
    setState(() {
      _loadingComments = true;
    });
    try {
      final results = await Future.wait<List<Map<String, dynamic>>>([
        _apiService.fetchPromotionComments(widget.promotion.id),
        _apiService.fetchPromotionRatings(widget.promotion.id),
      ]);
      final comments = results[0];
      final ratings = results[1];
      final ratingValues = ratings
          .map((rating) => (rating['value'] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      setState(() {
        _comments = comments;
        _ratings = ratings;
        _commentCount = comments.length;
        _reviewCount = ratings.length;
        _userRating = _findUserRating(ratings);
        _averageRating = ratingValues.isNotEmpty
            ? ratingValues.reduce((a, b) => a + b) / ratingValues.length
            : 0;
      });
    } catch (e) {
      setState(() {
        _comments = [];
        _ratings = [];
      });
    } finally {
      setState(() {
        _loadingComments = false;
      });
    }
  }

  Future<void> _fetchPromotionStats() async {
    setState(() => _loadingStats = true);
    try {
      final stats = await _apiService.fetchPromotionStats(widget.promotion.id);
      setState(() {
        _viewCount = (stats['viewCount'] as num?)?.toInt() ?? 0;
        _favoriteCount = (stats['favoriteCount'] as num?)?.toInt() ?? 0;
        _commentCount =
            (stats['commentCount'] as num?)?.toInt() ?? _comments.length;
        _clickCount = (stats['clickCount'] as num?)?.toInt() ?? 0;
        _directionCount = (stats['directionCount'] as num?)?.toInt() ?? 0;
        _reviewCount = (stats['ratingsCount'] as num?)?.toInt() ?? _reviewCount;
        _averageRating =
            (stats['averageRating'] as num?)?.toDouble() ?? _averageRating;
      });
    } catch (_) {
      setState(() {
        _commentCount = _comments.length;
        _reviewCount = _ratings.length;
      });
    } finally {
      setState(() => _loadingStats = false);
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
      final ratingUserId = _normalizeId(rating['user']);
      if (ratingUserId == _userId) {
        return (rating['value'] as num?)?.toDouble() ?? 0;
      }
    }

    return 0;
  }

  void _showAuthRequiredMessage(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please log in to $action.')),
    );
  }

  String _formatReviewDate(dynamic value) {
    if (value is! String || value.isEmpty) return '';
    try {
      return DateFormat.yMMMd().format(DateTime.parse(value).toLocal());
    } catch (_) {
      return '';
    }
  }

  Future<void> _submitRating(double rating) async {
    if (_userToken == null) {
      _showAuthRequiredMessage('rate this deal');
      return;
    }

    setState(() => _submittingRating = true);
    try {
      final ratings = await _apiService.postPromotionRating(
        widget.promotion.id,
        rating,
        _userToken!,
      );
      final ratingValues = ratings
          .map((entry) => (entry['value'] as num?)?.toDouble())
          .whereType<double>()
          .toList();

      setState(() {
        _ratings = ratings;
        _userRating = rating;
        _reviewCount = ratings.length;
        _averageRating = ratingValues.isNotEmpty
            ? ratingValues.reduce((a, b) => a + b) / ratingValues.length
            : 0;
      });

      await _fetchPromotionStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save rating: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submittingRating = false);
      }
    }
  }

  Future<void> _submitComment() async {
    if (_userToken == null) {
      _showAuthRequiredMessage('comment on this deal');
      return;
    }

    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _submittingComment = true);
    try {
      final comment = await _apiService.postPromotionComment(
        widget.promotion.id,
        text,
        _userToken!,
      );

      setState(() {
        _comments = [..._comments, comment];
        _commentCount = _comments.length;
      });
      _commentController.clear();

      await _fetchPromotionStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment posted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submittingComment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final promotion = widget.promotion;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final orderLink = _effectiveOrderLink;
    final deepLink = '${AppConfig.publicBaseUrl}/deal/${promotion.id}';
    final hasMerchant =
        promotion.merchantName != null && promotion.merchantName!.isNotEmpty;
    final hasPriceInfo = promotion.originalPrice != null ||
        promotion.discountedPrice != null ||
        promotion.price != null;
    final headlinePrice = _headlinePriceText(promotion);
    final originalPriceLabel = _originalPriceText(promotion);
    final savingsLabel = _savingsText(promotion);
    final distanceLabel = _formatDistance(_displayDistanceMeters);
    final displayTitle = _displayTitle(promotion);
    final displayHeaderTitle = _displayHeaderTitle(promotion);
    final merchantLogoProvider = _buildMerchantLogoProvider(
      (_merchantData?['logo'] ?? promotion.merchantLogoUrl)?.toString(),
    );
    final activityItems = [
      _DealStatItem(
        icon: Icons.visibility_outlined,
        label: 'Views',
        value: _viewCount,
      ),
      _DealStatItem(
        icon: Icons.favorite_border,
        label: 'Likes',
        value: _favoriteCount,
      ),
      _DealStatItem(
        icon: Icons.chat_bubble_outline,
        label: 'Comments',
        value: _commentCount,
      ),
      _DealStatItem(
        icon: Icons.ads_click_outlined,
        label: 'Clicks',
        value: _clickCount,
      ),
      _DealStatItem(
        icon: Icons.directions_outlined,
        label: 'Directions',
        value: _directionCount,
      ),
    ];
    final statusChips = <Widget>[
      if (promotion.featured == true)
        _buildInfoPill(
          icon: Icons.auto_awesome,
          label: 'Featured',
          backgroundColor: const Color(0xFFFFF3E0),
          foregroundColor: const Color(0xFFB45309),
        ),
      if (DealExpiryHelper.isEndingToday(promotion.endDate))
        _buildInfoPill(
          icon: Icons.schedule,
          label: 'Ending today',
          backgroundColor: const Color(0xFFFFF4ED),
          foregroundColor: const Color(0xFF9A3412),
        ),
      if (promotion.isVerifiedActiveDeal)
        const DealVerificationBadge(compact: false),
      if ((promotion.category ?? '').trim().isNotEmpty)
        _buildInfoPill(
          icon: Icons.sell_outlined,
          label: promotion.category!.trim(),
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
        ),
    ];
    final primaryActionButtons = <Widget>[
      if (_supportsVisit)
        Semantics(
          button: true,
          label: 'Get directions to merchant',
          child: ElevatedButton.icon(
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: const Text('Visit Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _openDirections,
          ),
        ),
      if ((_supportsDelivery || _supportsPickup) &&
          orderLink != null &&
          orderLink.isNotEmpty)
        Semantics(
          button: true,
          label: 'Open order link',
          child: ElevatedButton.icon(
            icon: const Icon(Icons.delivery_dining, size: 18),
            label: Text(_supportsDelivery ? 'Order Now' : 'Pickup Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _launchURL(orderLink),
          ),
        ),
    ];
    final callButton = _merchantPhoneNumber.isNotEmpty
        ? Semantics(
            button: true,
            label: 'Call merchant',
            child: ElevatedButton.icon(
              icon: const Icon(Icons.call_outlined, size: 18),
              label: const Text('Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _launchPhoneCall,
            ),
          )
        : null;
    final whatsappButton = _merchantPhoneNumber.isNotEmpty
        ? Semantics(
            button: true,
            label: 'Message merchant on WhatsApp',
            child: OutlinedButton.icon(
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: const Text('WhatsApp'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade700,
                backgroundColor: Colors.green.shade50,
                side: BorderSide(color: Colors.green.shade300),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _launchWhatsApp,
            ),
          )
        : null;
    final directionsButton = Semantics(
      button: true,
      label: 'Get directions to merchant',
      child: ElevatedButton.icon(
        icon: const Icon(Icons.directions, size: 18),
        label: const Text('Directions'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4285F4),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _openDirections,
      ),
    );
    final secondaryActionButtons = <Widget>[
      if ((!_supportsDelivery && !_supportsPickup) &&
          promotion.url != null &&
          promotion.url!.isNotEmpty)
        Semantics(
          button: true,
          label: 'Open deal link',
          child: ElevatedButton.icon(
            icon: const Icon(Icons.launch, size: 18),
            label: const Text('Go to Deal'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _launchURL(promotion.url!),
          ),
        ),
      if ((promotion.websiteUrl ?? '').isNotEmpty)
        Semantics(
          button: true,
          label: 'Open merchant website',
          child: OutlinedButton.icon(
            icon: const Icon(Icons.public, size: 18),
            label: const Text('Website'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _launchURL(promotion.websiteUrl!),
          ),
        ),
    ];
    final _StickyActionConfig? stickyPrimaryAction =
        (_supportsDelivery || _supportsPickup) &&
                orderLink != null &&
                orderLink.isNotEmpty
            ? _StickyActionConfig(
                label: _supportsDelivery ? 'Order now' : 'Pickup order',
                icon: Icons.delivery_dining,
                onPressed: () => _launchURL(orderLink),
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              )
            : _supportsVisit
                ? _StickyActionConfig(
                    label: 'Visit now',
                    icon: Icons.storefront_outlined,
                    onPressed: _openDirections,
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                  )
                : (promotion.url ?? '').isNotEmpty
                    ? _StickyActionConfig(
                        label: 'Open deal',
                        icon: Icons.launch,
                        onPressed: () => _launchURL(promotion.url!),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      )
                    : (promotion.websiteUrl ?? '').isNotEmpty
                        ? _StickyActionConfig(
                            label: 'Website',
                            icon: Icons.public,
                            onPressed: () => _launchURL(promotion.websiteUrl!),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          )
                        : null;
    final _StickyActionConfig? stickySecondaryAction =
        (!_supportsVisit || stickyPrimaryAction?.label != 'Visit now')
            ? _StickyActionConfig(
                label: 'Directions',
                icon: Icons.directions,
                onPressed: _openDirections,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: theme.colorScheme.onSurface,
              )
            : _merchantPhoneNumber.isNotEmpty
                ? _StickyActionConfig(
                    label: 'Call',
                    icon: Icons.call_outlined,
                    onPressed: _launchPhoneCall,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: theme.colorScheme.onSurface,
                  )
                : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(displayHeaderTitle, overflow: TextOverflow.ellipsis),
        actions: [
          Semantics(
            button: true,
            label: _isFavorite
                ? 'Remove deal from favorites'
                : 'Save deal to favorites',
            child: IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null,
              ),
              tooltip: 'Toggle Favorite',
              onPressed: _toggleFavorite,
            ),
          ),
          Semantics(
            button: true,
            label: 'Share deal',
            child: IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share Deal',
              onPressed: _shareDeal,
            ),
          ),
        ],
      ),
      bottomNavigationBar: stickyPrimaryAction == null
          ? null
          : _buildStickyActionBar(
              theme: theme,
              primaryAction: stickyPrimaryAction,
              secondaryAction: stickySecondaryAction,
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Promotion Image with Hero animation
            Hero(
              tag: 'dealImage_${promotion.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: _buildImageWidget(context, promotion.imageDataString),
              ),
            ),
            const SizedBox(height: 20.0),

            _DealSummarySection(
              title: displayTitle,
              merchantName: promotion.merchantName,
              merchantInitial: hasMerchant
                  ? (promotion.merchantName!.trim().isEmpty
                      ? 'M'
                      : promotion.merchantName!.trim()[0].toUpperCase())
                  : 'M',
              merchantLogoProvider: merchantLogoProvider,
              hasMerchant: hasMerchant,
              canOpenMerchant: promotion.merchantId != null,
              hasPriceInfo: hasPriceInfo && headlinePrice != null,
              headlinePrice: headlinePrice,
              originalPriceLabel: originalPriceLabel,
              savingsLabel: savingsLabel,
              countdownText: _countdownText == null
                  ? null
                  : _formatCountdownInline(_countdownText!),
              countdownExpired: _countdownText == 'Expired',
              distanceLabel: distanceLabel,
              statusChips: statusChips,
              onTapMerchant: promotion.merchantId == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MerchantProfileScreen(
                            merchantId: promotion.merchantId!,
                          ),
                        ),
                      );
                    },
              onCopyLink: () async {
                await Clipboard.setData(ClipboardData(text: deepLink));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deal link copied!')),
                );
              },
            ),
            const SizedBox(height: 16.0),
            _DealActivitySection(
              loading: _loadingStats,
              statBuilder: _buildStatChip,
              items: activityItems,
            ),
            const SizedBox(height: 16.0),
            _DealDetailsSection(
              description: promotion.description,
              startDate: promotion.startDate,
              endDate: promotion.endDate,
              dateFormat: dateFormat,
              termsAndConditions: promotion.termsAndConditions,
              showTerms: _showTerms,
              onToggleTerms: () {
                setState(() {
                  _showTerms = !_showTerms;
                });
              },
            ),
            const SizedBox(height: 20.0),
            const Divider(height: 32, thickness: 1.2),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 10.0;
                  final fullWidth = constraints.maxWidth;
                  final halfWidth = (fullWidth - gap) / 2;
                  final rows = <Widget>[];

                  for (var i = 0; i < primaryActionButtons.length; i += 2) {
                    final remaining = primaryActionButtons.length - i;
                    if (remaining == 1) {
                      rows.add(
                        _buildActionButtonShell(
                          width: fullWidth,
                          child: primaryActionButtons[i],
                        ),
                      );
                    } else {
                      rows.add(
                        Row(
                          children: [
                            _buildActionButtonShell(
                              width: halfWidth,
                              child: primaryActionButtons[i],
                            ),
                            const SizedBox(width: gap),
                            _buildActionButtonShell(
                              width: halfWidth,
                              child: primaryActionButtons[i + 1],
                            ),
                          ],
                        ),
                      );
                    }
                  }

                  if (callButton != null && whatsappButton != null) {
                    rows.add(
                      Row(
                        children: [
                          _buildActionButtonShell(
                            width: halfWidth,
                            child: callButton,
                          ),
                          const SizedBox(width: gap),
                          _buildActionButtonShell(
                            width: halfWidth,
                            child: whatsappButton,
                          ),
                        ],
                      ),
                    );
                  } else if (callButton != null || whatsappButton != null) {
                    rows.add(
                      _buildActionButtonShell(
                        width: fullWidth,
                        child: callButton ?? whatsappButton!,
                      ),
                    );
                  }

                  if (!_supportsVisit) {
                    rows.add(
                      _buildActionButtonShell(
                        width: fullWidth,
                        child: directionsButton,
                      ),
                    );
                  }

                  for (var i = 0; i < secondaryActionButtons.length; i += 2) {
                    final remaining = secondaryActionButtons.length - i;
                    if (remaining == 1) {
                      rows.add(
                        _buildActionButtonShell(
                          width: fullWidth,
                          child: secondaryActionButtons[i],
                        ),
                      );
                    } else {
                      rows.add(
                        Row(
                          children: [
                            _buildActionButtonShell(
                              width: halfWidth,
                              child: secondaryActionButtons[i],
                            ),
                            const SizedBox(width: gap),
                            _buildActionButtonShell(
                              width: halfWidth,
                              child: secondaryActionButtons[i + 1],
                            ),
                          ],
                        ),
                      );
                    }
                  }

                  return Column(
                    children: [
                      for (var i = 0; i < rows.length; i++) ...[
                        if (i > 0) const SizedBox(height: gap),
                        rows[i],
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20.0),
            const Divider(height: 32, thickness: 1.2),

            // Recommendations/Similar Deals
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: theme.colorScheme.surfaceContainerLowest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You might also like',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12.0),
                    FutureBuilder<List<Promotion>>(
                      future: _recommendedDealsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 180,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        } else if (snapshot.hasError) {
                          return const SizedBox(
                            height: 180,
                            child: Center(
                                child: Text('Error loading recommendations')),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const SizedBox(
                            height: 180,
                            child: Center(
                                child: Text('No recommendations available')),
                          );
                        } else {
                          final recommendedDeals = snapshot.data!;
                          return SizedBox(
                            height: 180,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: recommendedDeals.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final deal = recommendedDeals[index];
                                return Container(
                                  width: 140,
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 2))
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DealDetailScreen(
                                                      promotion: deal),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          height: 70,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: _buildRecommendationImage(
                                              deal.imageDataString),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        deal.title,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        deal.description,
                                        style: theme.textTheme.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            const Divider(height: 32, thickness: 1.2),

            // Ratings & Reviews Section
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: theme.colorScheme.surfaceContainerLowest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ratings & Reviews',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12.0),
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
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '($_reviewCount ${_reviewCount == 1 ? 'rating' : 'ratings'})',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Rate this deal',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8.0),
                    InteractiveRatingWidget(
                      initialRating: _userRating,
                      onRatingChanged: _submitRating,
                      size: 32,
                      enabled: _userToken != null && !_submittingRating,
                    ),
                    const SizedBox(height: 8.0),
                    if (_userRating > 0)
                      Text(
                        'Your rating: ${_userRating.toStringAsFixed(0)}/5',
                        style: theme.textTheme.bodyMedium,
                      ),
                    if (_submittingRating) ...[
                      const SizedBox(height: 8.0),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                    if (_userToken == null) ...[
                      const SizedBox(height: 8.0),
                      Text(
                        'Log in to rate this deal.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16.0),
                    Text(
                      'Comments ($_commentCount)',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8.0),
                    if (_loadingComments)
                      const Center(child: CircularProgressIndicator()),
                    if (!_loadingComments && _comments.isEmpty)
                      Text(
                        'No comments yet. Be the first to comment!',
                        style: theme.textTheme.bodyMedium,
                      ),
                    if (!_loadingComments && _comments.isNotEmpty)
                      Column(
                        children: _comments
                            .map((c) => Card(
                                  elevation: 0.5,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  child: ListTile(
                                    leading: c['user']?['profilePicture'] !=
                                                null &&
                                            c['user']!['profilePicture']
                                                .toString()
                                                .isNotEmpty
                                        ? CircleAvatar(
                                            backgroundImage: NetworkImage(
                                                c['user']!['profilePicture']),
                                            backgroundColor: Colors.grey[200],
                                          )
                                        : CircleAvatar(
                                            backgroundColor: theme
                                                .colorScheme.primaryContainer,
                                            child: Text(
                                              ((c['user']?['name'] ?? 'U')
                                                          .toString()
                                                          .trim()
                                                          .isNotEmpty
                                                      ? (c['user']?['name'] ??
                                                              'U')
                                                          .toString()
                                                          .trim()[0]
                                                      : 'U')
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: theme.colorScheme
                                                    .onPrimaryContainer,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            c['user']?['name'] ?? 'User',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        if (_formatReviewDate(c['createdAt'])
                                            .isNotEmpty)
                                          Text(
                                            _formatReviewDate(c['createdAt']),
                                            style: theme.textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        c['text'] ?? '',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    const SizedBox(height: 12.0),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stackActions = constraints.maxWidth < 420;
                        final composer = TextField(
                          controller: _commentController,
                          enabled: _userToken != null && !_submittingComment,
                          minLines: 1,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: _userToken == null
                                ? 'Log in to write a comment'
                                : 'Write a comment...',
                            border: const OutlineInputBorder(),
                          ),
                        );
                        final button = FilledButton(
                          onPressed: _submittingComment ? null : _submitComment,
                          child: _submittingComment
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Post'),
                        );

                        if (stackActions) {
                          return Column(
                            children: [
                              composer,
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: button,
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: composer),
                            const SizedBox(width: 12),
                            button,
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            const Divider(height: 32, thickness: 1.2),

            // Map/Location Section
            if (promotion.location != null && promotion.location!.isNotEmpty)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: theme.colorScheme.surfaceContainerLowest,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Location',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 8.0),
                          Expanded(child: Text(promotion.location!)),
                        ],
                      ),
                      if (distanceLabel.isNotEmpty) ...[
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            Icon(
                              Icons.near_me_outlined,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                '$distanceLabel from here',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8.0),
                      if (_merchantData != null &&
                          _merchantData!['latitude'] != null &&
                          _merchantData!['longitude'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: SizedBox(
                            height: 140,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: latlng.LatLng(
                                  (_merchantData!['latitude'] as num)
                                      .toDouble(),
                                  (_merchantData!['longitude'] as num)
                                      .toDouble(),
                                ),
                                initialZoom: 15,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.dealfinder.mobile',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: latlng.LatLng(
                                        (_merchantData!['latitude'] as num)
                                            .toDouble(),
                                        (_merchantData!['longitude'] as num)
                                            .toDouble(),
                                      ),
                                      width: 44,
                                      height: 44,
                                      child: Icon(
                                        Icons.location_on,
                                        color: theme.colorScheme.primary,
                                        size: 36,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.directions),
                        label: const Text('Get Directions'),
                        onPressed: _openDirections,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20.0),

            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }

  Widget _buildImageErrorPlaceholder(BuildContext context, {Object? error}) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child:
          Icon(Icons.broken_image_outlined, size: 60, color: Colors.grey[600]),
    );
  }

  Widget _buildImageWidget(BuildContext context, String? imageDataString) {
    void showFullScreenImage(Widget imageWidget) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(child: imageWidget),
          ),
        ),
      );
    }

    if (imageDataString == null || imageDataString.isEmpty) {
      return _buildImageErrorPlaceholder(context);
    }
    if (imageDataString.startsWith('data:image') &&
        imageDataString.contains(';base64,')) {
      try {
        final String base64Data =
            imageDataString.substring(imageDataString.indexOf(',') + 1);
        final Uint8List decodedBytes = base64Decode(base64Data);
        final image = Image.memory(
          decodedBytes,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _buildImageErrorPlaceholder(context, error: error),
        );
        return GestureDetector(
          onTap: () => showFullScreenImage(image),
          child: image,
        );
      } catch (e) {
        return _buildImageErrorPlaceholder(context, error: e);
      }
    } else if (imageDataString.startsWith('http')) {
      final image = Image.network(
        imageDataString,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _buildImageErrorPlaceholder(context, error: error),
      );
      return GestureDetector(
        onTap: () => showFullScreenImage(image),
        child: image,
      );
    }
    return _buildImageErrorPlaceholder(context);
  }

  Widget _buildRecommendationImage(String? imageDataString) {
    final shimmer = Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    );

    if (imageDataString == null || imageDataString.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.local_offer, size: 30, color: Colors.white70),
        ),
      );
    }

    if (imageDataString.startsWith('data:image')) {
      try {
        final bytes = base64Decode(
            imageDataString.substring(imageDataString.indexOf(',') + 1));
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => shimmer,
        );
      } catch (e) {
        return shimmer;
      }
    }

    if (imageDataString.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageDataString,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, __) => shimmer,
        errorWidget: (_, __, ___) => shimmer,
      );
    }

    return shimmer;
  }

  Widget _buildStatChip(IconData icon, String label, int value) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonShell({
    required Widget child,
    required double width,
  }) {
    return SizedBox(
      width: width,
      height: 52,
      child: child,
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: borderColor == null ? null : Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyActionBar({
    required ThemeData theme,
    required _StickyActionConfig primaryAction,
    _StickyActionConfig? secondaryAction,
  }) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (secondaryAction != null) ...[
              SizedBox(
                width: 52,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: secondaryAction.backgroundColor,
                    foregroundColor: secondaryAction.foregroundColor,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: secondaryAction.onPressed,
                  child: Icon(secondaryAction.icon, size: 22),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryAction.backgroundColor,
                    foregroundColor: primaryAction.foregroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: primaryAction.onPressed,
                  icon: Icon(primaryAction.icon, size: 20),
                  label: Text(
                    primaryAction.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 52,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: _isFavorite
                      ? Colors.red
                      : theme.colorScheme.onSurfaceVariant,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _toggleFavorite,
                child: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _headlinePriceText(Promotion promotion) {
    if (promotion.discountedPrice != null) {
      return 'Rs. ${promotion.discountedPrice!.toStringAsFixed(2)}';
    }
    if (promotion.price != null) {
      return 'Rs. ${promotion.price!.toStringAsFixed(2)}';
    }
    return null;
  }

  String? _originalPriceText(Promotion promotion) {
    if (promotion.originalPrice == null || promotion.discountedPrice == null) {
      return null;
    }
    return 'Rs. ${promotion.originalPrice!.toStringAsFixed(2)}';
  }

  String? _savingsText(Promotion promotion) {
    if (promotion.originalPrice == null || promotion.discountedPrice == null) {
      if ((promotion.discount ?? '').trim().isEmpty) return null;
      return promotion.discount!.trim();
    }

    final amount = promotion.originalPrice! - promotion.discountedPrice!;
    if (amount <= 0) return null;

    final percentage = promotion.discountPercentage;
    if (percentage == null) {
      return 'Save Rs. ${amount.toStringAsFixed(0)}';
    }
    return 'Save $percentage%';
  }
}

class _DealStatItem {
  final IconData icon;
  final String label;
  final int value;

  const _DealStatItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _DealSummarySection extends StatelessWidget {
  final String title;
  final String? merchantName;
  final String merchantInitial;
  final ImageProvider<Object>? merchantLogoProvider;
  final bool hasMerchant;
  final bool canOpenMerchant;
  final bool hasPriceInfo;
  final String? headlinePrice;
  final String? originalPriceLabel;
  final String? savingsLabel;
  final String? countdownText;
  final bool countdownExpired;
  final String distanceLabel;
  final List<Widget> statusChips;
  final VoidCallback? onTapMerchant;
  final VoidCallback onCopyLink;

  const _DealSummarySection({
    required this.title,
    required this.merchantName,
    required this.merchantInitial,
    required this.merchantLogoProvider,
    required this.hasMerchant,
    required this.canOpenMerchant,
    required this.hasPriceInfo,
    required this.headlinePrice,
    required this.originalPriceLabel,
    required this.savingsLabel,
    required this.countdownText,
    required this.countdownExpired,
    required this.distanceLabel,
    required this.statusChips,
    required this.onTapMerchant,
    required this.onCopyLink,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (countdownText != null || distanceLabel.isNotEmpty)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 6,
              children: [
                if (countdownText != null)
                  _InlineMetaItem(
                    icon: countdownExpired
                        ? Icons.event_busy
                        : Icons.timer_outlined,
                    label: countdownText!,
                    color: countdownExpired
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF9A3412),
                  ),
                if (countdownText != null && distanceLabel.isNotEmpty)
                  Text(
                    '•',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (distanceLabel.isNotEmpty)
                  const _InlineMetaItem(
                    icon: Icons.near_me_outlined,
                    label: '',
                    color: Color(0xFF0F4C81),
                  ),
                if (distanceLabel.isNotEmpty)
                  Text(
                    distanceLabel,
                    style: const TextStyle(
                      color: Color(0xFF0F4C81),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          if (countdownText != null || distanceLabel.isNotEmpty)
            const SizedBox(height: 12),
          if (statusChips.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statusChips,
            ),
            const SizedBox(height: 18),
          ],
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          if (hasMerchant && merchantName != null) ...[
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTapMerchant,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: merchantLogoProvider,
                      child: merchantLogoProvider != null
                          ? null
                          : Text(
                              merchantInitial,
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sold by',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            merchantName!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canOpenMerchant)
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (hasPriceInfo && headlinePrice != null) ...[
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      headlinePrice!,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: const Color(0xFFC2410C),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (originalPriceLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          originalPriceLabel!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                  ],
                ),
                if (savingsLabel != null) ...[
                  const SizedBox(height: 8),
                  _StaticInfoPill(
                    icon: Icons.savings_outlined,
                    label: savingsLabel!,
                    backgroundColor: const Color(0xFFFFEDD5),
                    foregroundColor: const Color(0xFF9A3412),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onCopyLink,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.link,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Copy shareable link',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.copy_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DealActivitySection extends StatelessWidget {
  final bool loading;
  final List<_DealStatItem> items;
  final Widget Function(IconData icon, String label, int value) statBuilder;

  const _DealActivitySection({
    required this.loading,
    required this.items,
    required this.statBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Deal activity',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (loading)
                  Text(
                    'Updating...',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map((item) => statBuilder(item.icon, item.label, item.value))
                  .toList(),
            ),
            if (loading) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(minHeight: 2),
            ],
          ],
        ),
      ),
    );
  }
}

class _DealDetailsSection extends StatelessWidget {
  final String description;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateFormat dateFormat;
  final String? termsAndConditions;
  final bool showTerms;
  final VoidCallback onToggleTerms;

  const _DealDetailsSection({
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.dateFormat,
    required this.termsAndConditions,
    required this.showTerms,
    required this.onToggleTerms,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              description,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 16.0),
            if (startDate != null || endDate != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 24),
                  Text(
                    'Validity:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  if (startDate != null)
                    Text(
                      'Starts: ${dateFormat.format(startDate!)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  if (endDate != null)
                    Text(
                      'Expires: ${dateFormat.format(endDate!)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ),
            if (termsAndConditions != null && termsAndConditions!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 24),
                  GestureDetector(
                    onTap: onToggleTerms,
                    child: Row(
                      children: [
                        Text(
                          'Terms & Conditions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(showTerms ? Icons.expand_less : Icons.expand_more),
                      ],
                    ),
                  ),
                  if (showTerms)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        termsAndConditions!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineMetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InlineMetaItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}

class _StaticInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _StaticInfoPill({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyActionConfig {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;

  const _StickyActionConfig({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
  });
}
