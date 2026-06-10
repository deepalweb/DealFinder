import 'dart:convert'; // For base64Decode
import 'dart:async';
// For Uint8List
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:intl/intl.dart'; // For date formatting
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/promotion.dart';
import '../services/favorites_manager.dart';
import '../services/api_service.dart';
import '../services/recommendation_service.dart';
import '../services/deal_history_service.dart';
import '../services/location_service.dart';
import '../config/app_config.dart';
import '../screens/merchant_profile_screen.dart';
import '../utils/bank_card_promotion_support.dart';
import '../utils/deal_expiry_helper.dart';
import '../widgets/deal_verification_badge.dart';
import '../widgets/rating_widget.dart';

String _localizedText(BuildContext context, String en, String si, String ta) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'si':
      return si;
    case 'ta':
      return ta;
    default:
      return en;
  }
}

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
  List<Map<String, dynamic>> _redemptionFeedback = [];
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
  int _workedCount = 0;
  int _didntWorkCount = 0;
  bool? _userRedemptionWorked;
  bool _submittingRedemptionFeedback = false;
  Timer? _countdownTimer;

  String _t(String en, String si, String ta) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'si':
        return si;
      case 'ta':
        return ta;
      default:
        return en;
    }
  }

  late Future<List<Promotion>> _recommendedDealsFuture;
  bool get _isPlatformBankOffer =>
      BankCardPromotionSupport.isBankCardPromotion(widget.promotion) &&
      widget.promotion.merchantId == null;

  @override
  void initState() {
    super.initState();
    _loadUserAuth().then((_) => _loadFavoriteStatus());
    if (!_isPlatformBankOffer) {
      _loadReviewsAndStats();
    } else {
      _loadingComments = false;
    }
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
    if (_isPlatformBankOffer) return;
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
      _userRedemptionWorked = _findUserRedemptionFeedback(_redemptionFeedback);
    });
  }

  Future<void> _loadFavoriteStatus() async {
    var isFav = await FavoritesManager.isFavorite(widget.promotion.id);
    if (_userId != null && _userToken != null) {
      try {
        final favorites =
            await _apiService.fetchFavorites(_userId!, _userToken!);
        isFav = isFav ||
            favorites.any((promotion) => promotion.id == widget.promotion.id);
      } catch (_) {}
    }
    if (isFav) {
      await FavoritesManager.addFavoritePromotion(widget.promotion);
    }
    if (!mounted) return;
    setState(() {
      _isFavorite = isFav;
    });
  }

  Future<void> _toggleFavorite() async {
    final nextFavorite = !_isFavorite;
    if (nextFavorite) {
      await FavoritesManager.addFavoritePromotion(widget.promotion);
    } else {
      await FavoritesManager.removeFavorite(widget.promotion.id);
    }
    if (_userId != null && _userToken != null) {
      try {
        if (nextFavorite) {
          await _apiService.addFavorite(
            _userId!,
            widget.promotion.id,
            _userToken!,
          );
        } else {
          await _apiService.removeFavorite(
            _userId!,
            widget.promotion.id,
            _userToken!,
          );
        }
      } catch (_) {}
    }
    setState(() {
      _isFavorite = nextFavorite;
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
    debugPrint('DEBUG: _openDirections called');
    String? url;
    final merchant = _merchantData;

    if (merchant != null) {
      final coords = merchant['location']?['coordinates'];
      if (coords != null && coords.length == 2) {
        final lng = coords[0];
        final lat = coords[1];
        url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
        debugPrint('DEBUG: Using merchant coords: $lat, $lng');
      } else if (merchant['address'] != null &&
          merchant['address'].toString().isNotEmpty) {
        final query = Uri.encodeComponent(merchant['address'].toString());
        url = 'https://www.google.com/maps/dir/?api=1&destination=$query';
        debugPrint('DEBUG: Using merchant address: ${merchant['address']}');
      }
    }

    if (url == null &&
        widget.promotion.location != null &&
        widget.promotion.location!.isNotEmpty) {
      final query = Uri.encodeComponent(widget.promotion.location!);
      url = 'https://www.google.com/maps/dir/?api=1&destination=$query';
      debugPrint(
          'DEBUG: Using promotion location: ${widget.promotion.location}');
    }

    if (url == null) {
      debugPrint('DEBUG: No URL found, showing error snackbar');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.noLocationAvailable)),
      );
      return;
    }

    debugPrint('DEBUG: Attempting to open URL: $url');
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
    } catch (e) {
      debugPrint('DEBUG: Failed to record click: $e');
    }

    try {
      final launched =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      debugPrint('DEBUG: Launch result: $launched');
      if (!launched) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.couldNotOpenMaps)),
        );
      }
    } catch (e) {
      debugPrint('DEBUG: Launch error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening maps: $e')),
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
        SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.couldNotLaunchPrefix} $urlString')),
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

  bool get _showsVisitNow => _supportsVisit && !_isPlatformBankOffer;

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
    return promotion.featured == true
        ? _t('Flash Deal', 'Flash Deal', 'Flash Deal')
        : _t('Deal details', 'Deal විස්තර', 'Deal விவரங்கள்');
  }

  String _formatCountdownInline(String countdownText) {
    if (countdownText == 'Expired') {
      return _t('Expired', 'කල් ඉකුත්', 'காலாவதியானது');
    }
    return '${_t('Ends in', 'අවසන් වීමට', 'முடிவதற்கு')} $countdownText';
  }

  Future<void> _launchPhoneCall() async {
    final phone = _merchantPhoneNumber;
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.noMerchantPhoneNumber)),
        );
      }
      return;
    }

    final uri = Uri.parse('tel:$phone');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_t(
                  'Could not start the phone call.',
                  'Phone call එක ආරම්භ කළ නොහැකි විය.',
                  'Phone call ஐ தொடங்க முடியவில்லை.'))),
        );
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    final phone = _merchantPhoneNumber;
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.noMerchantPhoneNumber)),
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
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.couldNotOpenWhatsApp)),
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
      _fetchRedemptionFeedback(),
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
    try {
      final stats = await _apiService.fetchPromotionStats(widget.promotion.id);
      setState(() {
        _viewCount = (stats['viewCount'] as num?)?.toInt() ?? 0;
        _favoriteCount = (stats['favoriteCount'] as num?)?.toInt() ?? 0;
        _commentCount =
            (stats['commentCount'] as num?)?.toInt() ?? _comments.length;
        _clickCount = (stats['clickCount'] as num?)?.toInt() ?? 0;
        _directionCount = (stats['directionCount'] as num?)?.toInt() ?? 0;
        _workedCount = (stats['workedCount'] as num?)?.toInt() ?? _workedCount;
        _didntWorkCount =
            (stats['didntWorkCount'] as num?)?.toInt() ?? _didntWorkCount;
        _reviewCount = (stats['ratingsCount'] as num?)?.toInt() ?? _reviewCount;
        _averageRating =
            (stats['averageRating'] as num?)?.toDouble() ?? _averageRating;
      });
    } catch (_) {
      setState(() {
        _commentCount = _comments.length;
        _reviewCount = _ratings.length;
      });
    } finally {}
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

  bool? _findUserRedemptionFeedback(List<Map<String, dynamic>> feedback) {
    if (_userId == null || _userId!.isEmpty) return null;

    for (final entry in feedback) {
      final feedbackUserId = _normalizeId(entry['user']);
      if (feedbackUserId == _userId) {
        return entry['worked'] == true;
      }
    }

    return null;
  }

  Future<void> _fetchRedemptionFeedback() async {
    try {
      final response = await _apiService
          .fetchPromotionRedemptionFeedback(widget.promotion.id);
      final feedback = response['feedback'] is List
          ? (response['feedback'] as List)
              .whereType<Map<String, dynamic>>()
              .toList()
          : const <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _redemptionFeedback = feedback;
        _workedCount = (response['workedCount'] as num?)?.toInt() ?? 0;
        _didntWorkCount = (response['didntWorkCount'] as num?)?.toInt() ?? 0;
        _userRedemptionWorked = _findUserRedemptionFeedback(feedback);
      });
    } catch (_) {}
  }

  void _showAuthRequiredMessage(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseLoginTo(action))),
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
    debugPrint('DEBUG: _submitRating called with rating: $rating');
    if (_isPlatformBankOffer) {
      debugPrint('DEBUG: Skipping - is platform bank offer');
      return;
    }
    if (_userToken == null) {
      debugPrint('DEBUG: No user token, showing auth required');
      _showAuthRequiredMessage('rate this deal');
      return;
    }

    setState(() => _submittingRating = true);
    try {
      debugPrint('DEBUG: Posting rating to API...');
      final ratings = await _apiService.postPromotionRating(
        widget.promotion.id,
        rating,
        _userToken!,
      );
      debugPrint(
          'DEBUG: Rating posted successfully, received ${ratings.length} ratings');
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
          SnackBar(content: Text(AppLocalizations.of(context)!.ratingSaved)),
        );
      }
    } catch (e) {
      debugPrint('DEBUG: Error posting rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${_t('Failed to save rating', 'Rating save කිරීමට අසමත් විය', 'Rating save செய்ய முடியவில்லை')}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submittingRating = false);
      }
    }
  }

  Future<void> _submitRedemptionFeedback(bool worked) async {
    if (_isPlatformBankOffer) return;
    if (_userToken == null) {
      _showAuthRequiredMessage(worked
          ? _t(
              'mark this deal as worked',
              'මෙම deal එක worked ලෙස සලකුණු කිරීමට',
              'இந்த deal worked என்று குறிக்க')
          : _t(
              'mark this deal as not working',
              'මෙම deal එක not working ලෙස සලකුණු කිරීමට',
              'இந்த deal not working என்று குறிக்க'));
      return;
    }

    setState(() => _submittingRedemptionFeedback = true);
    try {
      final response = await _apiService.postPromotionRedemptionFeedback(
        widget.promotion.id,
        worked,
        _userToken!,
      );
      if (!mounted) return;
      final feedback = response['feedback'] is List
          ? (response['feedback'] as List)
              .whereType<Map<String, dynamic>>()
              .toList()
          : const <Map<String, dynamic>>[];
      setState(() {
        _redemptionFeedback = feedback;
        _workedCount = (response['workedCount'] as num?)?.toInt() ?? 0;
        _didntWorkCount = (response['didntWorkCount'] as num?)?.toInt() ?? 0;
        _userRedemptionWorked = worked;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t(
            'Thanks for confirming this deal.',
            'මෙම deal එක confirm කළාට ස්තුතියි.',
            'இந்த deal-ஐ உறுதிசெய்ததற்கு நன்றி.',
          )),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_t('Failed to save feedback', 'Feedback save කිරීමට අසමත් විය', 'Feedback save செய்ய முடியவில்லை')}: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submittingRedemptionFeedback = false);
      }
    }
  }

  Future<void> _showReportDealDialog() async {
    if (_isPlatformBankOffer) return;
    if (_userToken == null) {
      _showAuthRequiredMessage(_t(
        'report this deal',
        'මෙම deal එක report කිරීමට',
        'இந்த deal-ஐ report செய்ய',
      ));
      return;
    }

    var reason = 'expired_or_invalid';
    final detailsController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_t(
            'Report deal',
            'Deal report කරන්න',
            'Deal report செய்யவும்',
          )),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: const [
                  DropdownMenuItem(
                    value: 'expired_or_invalid',
                    child: Text('Expired or invalid'),
                  ),
                  DropdownMenuItem(
                    value: 'fake_or_misleading',
                    child: Text('Fake or misleading'),
                  ),
                  DropdownMenuItem(
                    value: 'wrong_information',
                    child: Text('Wrong information'),
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
      await _apiService.reportPromotion(
          widget.promotion.id,
          {
            'reason': reason,
            'description': description,
          },
          _userToken!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t(
            'Thanks, we sent this deal report to admin.',
            'ස්තුතියි, මෙම deal report එක admin වෙත යැව්වා.',
            'நன்றி, இந்த deal report admin-க்கு அனுப்பப்பட்டது.',
          )),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to report deal: $e')),
      );
    }
  }

  Future<void> _submitComment() async {
    debugPrint('DEBUG: _submitComment called');
    if (_isPlatformBankOffer) {
      debugPrint('DEBUG: Skipping - is platform bank offer');
      return;
    }
    if (_userToken == null) {
      debugPrint('DEBUG: No user token, showing auth required');
      _showAuthRequiredMessage('comment on this deal');
      return;
    }

    final text = _commentController.text.trim();
    if (text.isEmpty) {
      debugPrint('DEBUG: Comment text is empty');
      return;
    }

    debugPrint('DEBUG: Posting comment: $text');
    setState(() => _submittingComment = true);
    try {
      final comment = await _apiService.postPromotionComment(
        widget.promotion.id,
        text,
        _userToken!,
      );

      debugPrint('DEBUG: Comment posted successfully');
      setState(() {
        _comments = [..._comments, comment];
        _commentCount = _comments.length;
      });
      _commentController.clear();

      await _fetchPromotionStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.commentPosted)),
        );
      }
    } catch (e) {
      debugPrint('DEBUG: Error posting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${_t('Failed to post comment', 'Comment post කිරීමට අසමත් විය', 'Comment post செய்ய முடியவில்லை')}: $e')),
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
    final l10n = AppLocalizations.of(context)!;
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
        label: l10n.viewsLabel,
        value: _viewCount,
      ),
      _DealStatItem(
        icon: Icons.favorite_border,
        label: l10n.likesLabel,
        value: _favoriteCount,
      ),
      _DealStatItem(
        icon: Icons.chat_bubble_outline,
        label: l10n.commentsLabel,
        value: _commentCount,
      ),
      _DealStatItem(
        icon: Icons.ads_click_outlined,
        label: l10n.clicksLabel,
        value: _clickCount,
      ),
      _DealStatItem(
        icon: Icons.directions_outlined,
        label: l10n.directionsLabel,
        value: _directionCount,
      ),
    ];
    final statusChips = <Widget>[
      if (promotion.featured == true)
        _buildInfoPill(
          icon: Icons.auto_awesome,
          label: l10n.featuredLabel,
          backgroundColor: const Color(0xFFFFF3E0),
          foregroundColor: const Color(0xFFB45309),
        ),
      if (DealExpiryHelper.isEndingToday(promotion.endDate))
        _buildInfoPill(
          icon: Icons.schedule,
          label: l10n.endingTodayLabel,
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
      if (_showsVisitNow)
        Semantics(
          button: true,
          label: l10n.getDirectionsToMerchant,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: Text(l10n.visitNowLabel),
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
          label: l10n.openOrderLink,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.delivery_dining, size: 18),
            label: Text(
                _supportsDelivery ? l10n.orderNowLabel : l10n.pickupOrderLabel),
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
            label: l10n.callMerchant,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.call_outlined, size: 18),
              label: Text(l10n.callLabel),
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
            label: l10n.messageOnWhatsApp,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: Text(l10n.whatsAppLabel),
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
      label: l10n.getDirectionsToMerchant,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.directions, size: 18),
        label: Text(l10n.getDirections),
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
          label: l10n.openDealLink,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.launch, size: 18),
            label: Text(l10n.goToDealLabel),
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
          label: l10n.openMerchantWebsite,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.public, size: 18),
            label: Text(l10n.websiteLabel),
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
    final _StickyActionConfig? stickyPrimaryAction = (_supportsDelivery ||
                _supportsPickup) &&
            orderLink != null &&
            orderLink.isNotEmpty
        ? _StickyActionConfig(
            label:
                _supportsDelivery ? l10n.orderNowLabel : l10n.pickupOrderLabel,
            icon: Icons.delivery_dining,
            onPressed: () => _launchURL(orderLink),
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          )
        : _showsVisitNow
            ? _StickyActionConfig(
                label: l10n.visitNowLabel,
                icon: Icons.storefront_outlined,
                onPressed: _openDirections,
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              )
            : (promotion.url ?? '').isNotEmpty
                ? _StickyActionConfig(
                    label: l10n.openDealLabel,
                    icon: Icons.launch,
                    onPressed: () => _launchURL(promotion.url!),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  )
                : (promotion.websiteUrl ?? '').isNotEmpty
                    ? _StickyActionConfig(
                        label: l10n.websiteLabel,
                        icon: Icons.public,
                        onPressed: () => _launchURL(promotion.websiteUrl!),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      )
                    : null;
    final _StickyActionConfig? stickySecondaryAction =
        (!_showsVisitNow || stickyPrimaryAction?.label != 'Visit now')
            ? _StickyActionConfig(
                label: l10n.getDirections,
                icon: Icons.directions,
                onPressed: _openDirections,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: theme.colorScheme.onSurface,
              )
            : _merchantPhoneNumber.isNotEmpty
                ? _StickyActionConfig(
                    label: l10n.callLabel,
                    icon: Icons.call_outlined,
                    onPressed: _launchPhoneCall,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: theme.colorScheme.onSurface,
                  )
                : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(displayHeaderTitle, overflow: TextOverflow.ellipsis),
        actions: [
          Semantics(
            button: true,
            label: _isFavorite ? l10n.removeFavorite : l10n.saveFavorites,
            child: IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null,
              ),
              tooltip: l10n.toggleFavoriteTooltip,
              onPressed: _toggleFavorite,
            ),
          ),
          Semantics(
            button: true,
            label: l10n.shareDeal,
            child: IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: l10n.shareDeal,
              onPressed: _shareDeal,
            ),
          ),
          if (!_isPlatformBankOffer)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: _t(
                'Report deal',
                'Deal report කරන්න',
                'Deal report செய்யவும்',
              ),
              onPressed: _showReportDealDialog,
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
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22.0),
                  child: _buildImageWidget(context, promotion.imageDataString),
                ),
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
              activityItems: activityItems,
              statBuilder: _buildStatChip,
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
                  SnackBar(content: Text(l10n.dealLinkCopied)),
                );
              },
            ),
            const SizedBox(height: 16.0),
            if (BankCardPromotionSupport.isBankCardPromotion(promotion)) ...[
              _BankCardOfferSection(promotion: promotion),
              const SizedBox(height: 16.0),
            ],
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

                  if (!_showsVisitNow) {
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

            _buildRecommendationsSection(theme),
            _buildRatingsReviewsSection(theme),
            const SizedBox(height: 20.0),
            const Divider(height: 32, thickness: 1.2),

            _buildLocationSection(theme, distanceLabel),
            const SizedBox(height: 20.0),

            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
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
              l10n.youMightAlsoLike,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12.0),
            FutureBuilder<List<Promotion>>(
              future: _recommendedDealsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return SizedBox(
                    height: 180,
                    child: Center(
                      child: Text(l10n.errorLoadingRecommendations),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SizedBox(
                    height: 180,
                    child: Center(
                      child: Text(l10n.noRecommendationsAvailable),
                    ),
                  );
                }

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
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DealDetailScreen(promotion: deal),
                                  ),
                                );
                              },
                              child: Container(
                                height: 70,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _buildRecommendationImage(
                                  deal.imageDataString,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              deal.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
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
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedemptionFeedbackSection(ThemeData theme) {
    Widget feedbackButton({
      required bool worked,
      required IconData icon,
      required String label,
      required int count,
    }) {
      final selected = _userRedemptionWorked == worked;
      final color = worked ? Colors.green : Colors.deepOrange;
      return Expanded(
        child: OutlinedButton.icon(
          onPressed: _submittingRedemptionFeedback
              ? null
              : () => _submitRedemptionFeedback(worked),
          icon: Icon(icon, size: 18),
          label: Text('$label ($count)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: selected ? Colors.white : color,
            backgroundColor: selected ? color : Colors.transparent,
            side: BorderSide(color: color.withValues(alpha: 0.65)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(
              'Did this deal work?',
              'මෙම deal එක වැඩ කළාද?',
              'இந்த deal வேலை செய்ததா?',
            ),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              feedbackButton(
                worked: true,
                icon: Icons.check_circle_outline,
                label: _t('Worked', 'වැඩ කළා', 'Worked'),
                count: _workedCount,
              ),
              const SizedBox(width: 10),
              feedbackButton(
                worked: false,
                icon: Icons.error_outline,
                label: _t("Didn't", 'වැඩ නැහැ', 'இல்லை'),
                count: _didntWorkCount,
              ),
            ],
          ),
          if (_submittingRedemptionFeedback) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (_userRedemptionWorked != null) ...[
            const SizedBox(height: 8),
            Text(
              _userRedemptionWorked == true
                  ? _t(
                      'You marked this deal as worked.',
                      'ඔබ මෙම deal එක worked ලෙස සලකුණු කර ඇත.',
                      'இந்த deal worked என்று நீங்கள் குறித்துள்ளீர்கள்.',
                    )
                  : _t(
                      'You marked this deal as not working.',
                      'ඔබ මෙම deal එක not working ලෙස සලකුණු කර ඇත.',
                      'இந்த deal not working என்று நீங்கள் குறித்துள்ளீர்கள்.',
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

  Widget _buildRatingsReviewsSection(ThemeData theme) {
    if (_isPlatformBankOffer) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        const SizedBox(height: 20.0),
        const Divider(height: 32, thickness: 1.2),
        Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: theme.colorScheme.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.ratingsReviewsTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12.0),
                if (_reviewCount > 0) ...[
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
                        ),
                      ),
                      Text(
                        '($_reviewCount ${_reviewCount == 1 ? l10n.ratingSingular : l10n.ratingsPlural})',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                ],
                Text(
                  l10n.rateThisDeal,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
                    '${l10n.yourRatingLabel} ${_userRating.toStringAsFixed(0)}/5',
                    style: theme.textTheme.bodyMedium,
                  ),
                if (_submittingRating) ...[
                  const SizedBox(height: 8.0),
                  const LinearProgressIndicator(minHeight: 2),
                ],
                if (_userToken == null) ...[
                  const SizedBox(height: 8.0),
                  Text(
                    l10n.loginToRateDeal,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 16.0),
                _buildRedemptionFeedbackSection(theme),
                const SizedBox(height: 16.0),
                Text(
                  '${l10n.commentsLabel} ($_commentCount)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8.0),
                if (_loadingComments)
                  const Center(child: CircularProgressIndicator()),
                if (!_loadingComments && _comments.isEmpty)
                  Text(
                    l10n.noCommentsYet,
                    style: theme.textTheme.bodyMedium,
                  ),
                if (!_loadingComments && _comments.isNotEmpty)
                  Column(
                    children: _comments
                        .map(
                          (c) => Card(
                            elevation: 0.5,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: c['user']?['profilePicture'] != null &&
                                      c['user']!['profilePicture']
                                          .toString()
                                          .isNotEmpty
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        c['user']!['profilePicture'],
                                      ),
                                      backgroundColor: Colors.grey[200],
                                    )
                                  : CircleAvatar(
                                      backgroundColor:
                                          theme.colorScheme.primaryContainer,
                                      child: Text(
                                        ((c['user']?['name'] ?? 'U')
                                                    .toString()
                                                    .trim()
                                                    .isNotEmpty
                                                ? (c['user']?['name'] ?? 'U')
                                                    .toString()
                                                    .trim()[0]
                                                : 'U')
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color: theme
                                              .colorScheme.onPrimaryContainer,
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
                          ),
                        )
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
                            ? l10n.loginToWriteComment
                            : l10n.writeCommentHint,
                        border: const OutlineInputBorder(),
                      ),
                    );
                    final button = FilledButton(
                      onPressed: _submittingComment ? null : _submitComment,
                      child: _submittingComment
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.postLabel),
                    );

                    if (stackActions) {
                      return Column(
                        children: [
                          composer,
                          const SizedBox(height: 12),
                          SizedBox(width: double.infinity, child: button),
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
      ],
    );
  }

  Widget _buildLocationSection(ThemeData theme, String distanceLabel) {
    if (widget.promotion.location == null ||
        widget.promotion.location!.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
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
              l10n.locationTitle,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Icon(Icons.location_on, color: theme.colorScheme.primary),
                const SizedBox(width: 8.0),
                Expanded(child: Text(widget.promotion.location!)),
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
                      l10n.distanceFromHere(distanceLabel),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12.0),
            OutlinedButton.icon(
              icon: const Icon(Icons.directions),
              label: Text(l10n.getDirections),
              onPressed: _openDirections,
            ),
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
    return Tooltip(
      message: '$label: $value',
      child: Semantics(
        label: '$label $value',
        child: Container(
          constraints: const BoxConstraints(minWidth: 76),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '$value',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
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
  final List<_DealStatItem> activityItems;
  final Widget Function(IconData icon, String label, int value) statBuilder;
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
    required this.activityItems,
    required this.statBuilder,
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
          if (hasMerchant && merchantName != null) ...[
            GestureDetector(
              onTap: onTapMerchant,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: merchantLogoProvider,
                    child: merchantLogoProvider != null
                        ? null
                        : Text(
                            merchantInitial,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      merchantName!,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (canOpenMerchant)
                    Icon(
                      Icons.chevron_right,
                      size: 24,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (countdownText != null || distanceLabel.isNotEmpty)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
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
                    backgroundColor: countdownExpired
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFFFEDD5),
                    borderColor: countdownExpired
                        ? const Color(0xFFFCA5A5)
                        : const Color(0xFFFDBA74),
                  ),
                if (distanceLabel.isNotEmpty)
                  _InlineMetaItem(
                    icon: Icons.near_me_outlined,
                    label: distanceLabel,
                    color: const Color(0xFF0F4C81),
                    backgroundColor: const Color(0xFFE0F2FE),
                    borderColor: const Color(0xFF93C5FD),
                  ),
              ],
            ),
          if (countdownText != null || distanceLabel.isNotEmpty)
            const SizedBox(height: 12),
          if (countdownText != null || distanceLabel.isNotEmpty)
            const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          if (statusChips.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statusChips,
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
          if (activityItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: activityItems
                  .map((item) => statBuilder(item.icon, item.label, item.value))
                  .toList(),
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
                      _localizedText(
                          context,
                          'Copy shareable link',
                          'Shareable link copy කරන්න',
                          'Shareable link ஐ copy செய்யவும்'),
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
              _localizedText(context, 'Details:', 'විස්තර:', 'விவரங்கள்:'),
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
                    _localizedText(context, 'Validity:', 'වලංගු කාලය:',
                        'செல்லுபடியாகும் காலம்:'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  if (startDate != null)
                    Text(
                      '${_localizedText(context, 'Starts:', 'ආරම්භය:', 'தொடக்கம்:')} ${dateFormat.format(startDate!)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  if (endDate != null)
                    Text(
                      '${_localizedText(context, 'Expires:', 'කල් ඉකුත් වීම:', 'முடிவு:')} ${dateFormat.format(endDate!)}',
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
                          _localizedText(
                              context,
                              'Terms & Conditions',
                              'නියමයන් සහ කොන්දේසි',
                              'விதிமுறைகள் மற்றும் நிபந்தனைகள்'),
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

class _BankCardOfferSection extends StatelessWidget {
  final Promotion promotion;

  const _BankCardOfferSection({required this.promotion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bankName = BankCardPromotionSupport.bankName(promotion);
    final cardTypes = BankCardPromotionSupport.cardTypes(promotion);
    final offerTypes = BankCardPromotionSupport.offerTypes(promotion);
    final minimumSpend = BankCardPromotionSupport.minimumSpendLabel(promotion);
    final maximumBenefit =
        BankCardPromotionSupport.maximumBenefitLabel(promotion);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.credit_card_rounded,
                    color: Color(0xFF0F4C81),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizedText(context, 'Card Offer Details',
                            'Card Offer විස්තර', 'Card Offer விவரங்கள்'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _localizedText(
                            context,
                            'Check eligible cards, offer type, and spend conditions.',
                            'සුදුසු cards, offer type සහ spend conditions පරීක්ෂා කරන්න.',
                            'சரியான cards, offer type மற்றும் spend conditions ஐ சரிபார்க்கவும்.'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (bankName != null)
                  _StaticInfoPill(
                    icon: Icons.account_balance_outlined,
                    label: bankName,
                    backgroundColor: const Color(0xFFF3E8FF),
                    foregroundColor: const Color(0xFF7C3AED),
                  ),
                if (cardTypes.isNotEmpty)
                  _StaticInfoPill(
                    icon: Icons.credit_card_outlined,
                    label: cardTypes.join(' + '),
                    backgroundColor: const Color(0xFFE8F0FE),
                    foregroundColor: const Color(0xFF0F4C81),
                  ),
                if (offerTypes.isNotEmpty)
                  _StaticInfoPill(
                    icon: Icons.account_balance_wallet_outlined,
                    label: offerTypes.join(' • '),
                    backgroundColor: const Color(0xFFECFDF5),
                    foregroundColor: const Color(0xFF047857),
                  ),
                if (minimumSpend != null)
                  _StaticInfoPill(
                    icon: Icons.payments_outlined,
                    label: minimumSpend,
                    backgroundColor: const Color(0xFFFFF7ED),
                    foregroundColor: const Color(0xFFC2410C),
                  ),
                if (maximumBenefit != null)
                  _StaticInfoPill(
                    icon: Icons.savings_outlined,
                    label: maximumBenefit,
                    backgroundColor: const Color(0xFFFFEDD5),
                    foregroundColor: const Color(0xFF9A3412),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _localizedText(
                context,
                'Before paying, confirm the exact eligible bank, card type, discount cap, and whether the offer applies in-store, online, or on selected days only.',
                'ගෙවීමට පෙර සුදුසු bank, card type, discount cap සහ offer එක in-store, online හෝ නිශ්චිත දිනවල පමණක් අදාළද යන්න තහවුරු කරන්න.',
                'பணம் செலுத்தும் முன் சரியான bank, card type, discount cap மற்றும் offer in-store, online அல்லது குறிப்பிட்ட நாட்களில் மட்டுமே பொருந்துமா என்பதை உறுதிப்படுத்துங்கள்.',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
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
  final Color? backgroundColor;
  final Color? borderColor;
  const _InlineMetaItem({
    required this.icon,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasLabel = label.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor ?? color.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          if (hasLabel) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                height: 1,
              ),
            ),
          ],
        ],
      ),
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
