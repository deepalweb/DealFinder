import '../widgets/stitch_discover_components.dart' show stitchDiscoverTheme;
import '../widgets/discover_offer_rating.dart';
import '../widgets/hybrid_offer_layout.dart';
import '../services/browsing_area.dart';
import '../utils/offer_presentation.dart';
import '../widgets/discovery_offer_card.dart' show offerMoney;
import 'dart:convert'; // For base64Decode
import 'dart:async';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../services/image_helper.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:intl/intl.dart'; // For date formatting
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/promotion.dart';
import '../services/favorites_manager.dart';
import '../services/saved_offer_service.dart';
import '../services/api_service.dart';
import '../services/recommendation_service.dart';
import '../services/deal_history_service.dart';
import '../services/location_service.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../screens/merchant_profile_screen.dart';
import '../utils/bank_card_promotion_support.dart';
import '../utils/deal_expiry_helper.dart';
import '../widgets/deal_verification_badge.dart';
import '../widgets/rating_widget.dart';
import '../widgets/modern_deal_card.dart';
import '../widgets/sign_in_gate.dart';

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
  final ApiService? api;
  const DealDetailScreen({super.key, required this.promotion, this.api});

  @override
  State<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends State<DealDetailScreen> {
  bool _isFavorite = false;
  bool _detailsExpanded = true;
  int _galleryIndex = 0;
  final _offerAnchor = GlobalKey(),
      _highlightsAnchor = GlobalKey(),
      _merchantAnchor = GlobalKey(),
      _conditionsAnchor = GlobalKey();
  void _section(GlobalKey key) {
    final target = key.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(target,
          duration: AppMotion.duration(context), alignment: .1);
    }
  }

  List<Map<String, dynamic>> _comments = [];
  List<Map<String, dynamic>> _ratings = [];
  List<Map<String, dynamic>> _redemptionFeedback = [];
  bool _loadingComments = true;
  bool _submittingComment = false;
  bool _submittingRating = false;
  double _averageRating = 0;
  double _userRating = 0;
  int _reviewCount = 0;
  late final ApiService _apiService = widget.api ?? ApiService();
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
  int _redeemCount = 0;
  int _reportCount = 0;
  String? _trustStatus;
  String? _trustLabel;
  bool? _userRedemptionWorked;
  bool _submittingRedemptionFeedback = false;
  bool _creatingRedemptionQr = false;
  bool _dealAlertEnabled = false;
  bool _loadingDealAlert = false;
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
    FavoritesManager.changes.addListener(_refreshFavoriteSnapshot);
    _loadUserAuth().then((_) {
      _loadFavoriteStatus();
      _loadDealAlertStatus();
    });
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
    FavoritesManager.changes.removeListener(_refreshFavoriteSnapshot);
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
    if (_isPlatformBankOffer) return;
    await DealHistoryService.addToHistory(widget.promotion.id);
    await RecommendationService.trackView(
        widget.promotion.id, widget.promotion.category);
    try {
      final prefs = await SharedPreferences.getInstance();
      await _apiService.recordPromotionClick(
        widget.promotion.id,
        type: 'view',
        token: prefs.getString('userToken'),
        userId: prefs.getString('userId'),
      );
      await _fetchPromotionStats();
    } catch (_) {}
  }

  Future<void> _loadUserAuth() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
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

  Future<void> _loadDealAlertStatus() async {
    if (_isPlatformBankOffer || _userToken == null) return;
    try {
      final status =
          await _apiService.fetchDealAlertStatus(widget.promotion.id);
      if (!mounted) return;
      setState(() {
        _dealAlertEnabled = status['subscribed'] == true;
      });
    } catch (_) {}
  }

  bool _openingSignIn = false;
  Future<bool> _ensureSignedIn() async {
    if (_openingSignIn) return false;
    _openingSignIn = true;
    try {
      if (!await requireSignIn(context) || !mounted) return false;
      await _loadUserAuth();
      return mounted && _userToken != null && _userId != null;
    } finally {
      _openingSignIn = false;
    }
  }

  Future<void> _toggleDealAlert() async {
    if (_isPlatformBankOffer) return;
    if (!await _ensureSignedIn() || !mounted) return;

    final nextEnabled = !_dealAlertEnabled;
    setState(() => _loadingDealAlert = true);
    try {
      if (nextEnabled) {
        await _apiService.enableDealAlert(widget.promotion.id);
      } else {
        await _apiService.disableDealAlert(widget.promotion.id);
      }
      if (!mounted) return;
      setState(() => _dealAlertEnabled = nextEnabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nextEnabled
              ? _t(
                  'Deal alerts enabled.',
                  'Deal alerts සක්‍රීය කළා.',
                  'Deal alerts இயக்கப்பட்டது.',
                )
              : _t(
                  'Deal alerts disabled.',
                  'Deal alerts අක්‍රීය කළා.',
                  'Deal alerts நிறுத்தப்பட்டது.',
                )),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update deal alert: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingDealAlert = false);
    }
  }

  Future<void> _refreshFavoriteSnapshot() async {
    final saved = await FavoritesManager.isFavorite(widget.promotion.id);
    if (mounted) setState(() => _isFavorite = saved);
  }

  bool _savingFavorite = false;
  Future<void> _toggleFavorite() async {
    if (_savingFavorite || _isPlatformBankOffer) return;
    _savingFavorite = true;
    try {
      if (!await _ensureSignedIn() || !mounted) return;
      final next = !await FavoritesManager.isFavorite(widget.promotion.id);
      await SavedOfferService.setSaved(widget.promotion, next,
          api: _apiService);
      if (!mounted) return;
      setState(() => _isFavorite = next);
      if (next && _isPlatformBankOffer) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.savedOnDevice)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.saveOfferFailed)));
      }
    } finally {
      _savingFavorite = false;
    }
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

    final area = await BrowsingArea.read();
    if (area == null || !mounted) return;
    final distanceKm = LocationService.calculateDistance(
      area.latitude,
      area.longitude,
      coords.$1,
      coords.$2,
    );

    setState(() {
      _liveDistanceMeters = distanceKm * 1000;
    });
  }

  Future<List<Promotion>> _fetchRecommendedDeals() async {
    try {
      final recommended = await _apiService.fetchRecommendedPromotions(
        limit: 6,
        excludePromotionId: widget.promotion.id,
      );
      if (recommended.isNotEmpty) return recommended.take(5).toList();

      final allPromos = await _apiService.fetchPromotions();
      return allPromos
          .where((p) =>
              OfferPresentation(p).public &&
              OfferPresentation(p).identity !=
                  OfferPresentation(widget.promotion).identity)
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
      if (!_isPlatformBankOffer) {
        await _apiService.recordPromotionClick(
          widget.promotion.id,
          type: 'outbound',
          token: _userToken,
          userId: _userId,
        );
      }
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

  bool get _supportsVisit =>
      widget.promotion.fulfillmentType != 'order' &&
      widget.promotion.supportsVisit;

  bool get _showsVisitNow => _supportsVisit && !_isPlatformBankOffer;

  bool get _supportsDelivery => widget.promotion.supportsDelivery;

  bool get _supportsPickup => widget.promotion.supportsPickup;

  String? get _effectiveOrderLink {
    final offerLink = widget.promotion.orderLink?.trim();
    if (offerLink != null && offerLink.isNotEmpty) return offerLink;
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

  String _displayTitle(Promotion promotion) => promotion.title.trim();

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
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _comments = [];
        _ratings = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingComments = false;
        });
      }
    }
  }

  Future<void> _fetchPromotionStats() async {
    try {
      final stats = await _apiService.fetchPromotionStats(widget.promotion.id);
      if (!mounted) return;
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
        _redeemCount = (stats['redeemCount'] as num?)?.toInt() ?? _redeemCount;
        final trust = stats['trustSummary'];
        if (trust is Map<String, dynamic>) {
          _trustStatus = trust['status'] as String? ?? _trustStatus;
          _trustLabel = trust['label'] as String? ?? _trustLabel;
          _reportCount =
              (trust['reportCount'] as num?)?.toInt() ?? _reportCount;
        }
        _reviewCount = (stats['ratingsCount'] as num?)?.toInt() ?? _reviewCount;
        _averageRating =
            (stats['averageRating'] as num?)?.toDouble() ?? _averageRating;
      });
    } catch (_) {
      if (!mounted) return;
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
    if (!await _ensureSignedIn() || !mounted) return;

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
    if (!await _ensureSignedIn() || !mounted) return;

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
    if (!await _ensureSignedIn() || !mounted) return;

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

  Future<void> _showRedemptionQr() async {
    if (_isPlatformBankOffer) return;
    if (!await _ensureSignedIn() || !mounted) return;

    setState(() => _creatingRedemptionQr = true);
    try {
      final redemption = await _apiService.createPromotionRedemption(
        widget.promotion.id,
        _userToken!,
      );
      if (!mounted) return;
      final token = (redemption['token'] ?? '').toString();
      final expiresAt = (redemption['expiresAt'] ?? '').toString();
      if (token.isEmpty) throw Exception('Missing redemption token');

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_t(
            'Show this QR at the store',
            'මෙම QR එක store එකට පෙන්වන්න',
            'இந்த QR-ஐ store-ல் காட்டவும்',
          )),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: token,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                _t(
                  'Valid for 15 minutes.',
                  'මිනිත්තු 15ක් වලංගුයි.',
                  '15 நிமிடங்களுக்கு செல்லுபடியாகும்.',
                ),
                textAlign: TextAlign.center,
              ),
              if (expiresAt.isNotEmpty)
                Text(
                  expiresAt,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create redemption QR: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _creatingRedemptionQr = false);
      }
    }
  }

  Future<void> _submitComment() async {
    debugPrint('DEBUG: _submitComment called');
    if (_isPlatformBankOffer) {
      debugPrint('DEBUG: Skipping - is platform bank offer');
      return;
    }
    if (!await _ensureSignedIn() || !mounted) return;

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
  Widget build(BuildContext context) => Theme(
      data: stitchDiscoverTheme(Theme.of(context)),
      child: Builder(builder: _buildDetails));

  Widget _buildDetails(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final promotion = widget.promotion;
    final theme = Theme.of(context);
    final dateFormat =
        DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag());
    final orderLink = _effectiveOrderLink;
    final deepLink = '${AppConfig.publicBaseUrl}/deal/${promotion.id}';
    final hasMerchant =
        promotion.merchantName != null && promotion.merchantName!.isNotEmpty;
    final headlinePrice = _headlinePriceText(promotion);
    final originalPriceLabel = _originalPriceText(promotion);
    final distanceLabel = OfferPresentation(promotion).onlineOnly
        ? ''
        : _formatDistance(_displayDistanceMeters);
    final isVerifiedDeal =
        (_trustStatus ?? promotion.trustStatus) == 'verified' ||
            promotion.adminVerified;
    final verifiedLabel = isVerifiedDeal
        ? (_trustLabel ??
            promotion.trustLabel ??
            _t('Verified deal', 'Verified deal', 'Verified deal'))
        : null;
    final whyVisitCard = _WhyVisitCard(
      savingsLabel: null,
      distanceLabel: null,
      countdownText: _countdownText == null
          ? null
          : _formatCountdownInline(_countdownText!),
      verifiedLabel: verifiedLabel,
    );
    final displayTitle = _displayTitle(promotion);
    final merchantLogoProvider = _buildMerchantLogoProvider(
      (_merchantData?['logo'] ?? promotion.merchantLogoUrl)?.toString(),
    );
    final activityItems = <_DealStatItem>[
      if (_viewCount > 0)
        _DealStatItem(
            icon: Icons.visibility_outlined,
            label: l10n.viewsLabel,
            value: _viewCount),
      if (_favoriteCount > 0)
        _DealStatItem(
            icon: Icons.favorite_border,
            label: l10n.likesLabel,
            value: _favoriteCount),
      if (_directionCount > 0)
        _DealStatItem(
            icon: Icons.directions_outlined,
            label: l10n.directionsLabel,
            value: _directionCount),
    ];
    final statusChips = <Widget>[
      if (promotion.featured == true)
        _buildInfoPill(
          icon: Icons.auto_awesome,
          label: l10n.featuredLabel,
          backgroundColor: AppColors.turmeric.withValues(alpha: 0.16),
          foregroundColor: AppColors.brand,
        ),
      if (DealExpiryHelper.isEndingToday(promotion.endDate))
        _buildInfoPill(
          icon: Icons.schedule,
          label: l10n.endingTodayLabel,
          backgroundColor: AppColors.chili.withValues(alpha: 0.12),
          foregroundColor: AppColors.chili,
        ),
      if (((_trustStatus ?? promotion.trustStatus) ?? '').isNotEmpty &&
          ((_trustStatus ?? promotion.trustStatus) != 'standard'))
        DealVerificationBadge(
          compact: false,
          status: (_trustStatus ?? promotion.trustStatus)!,
          label: _trustLabel ?? promotion.trustLabel,
        )
      else if (promotion.adminVerified)
        const DealVerificationBadge(compact: false),
    ];
    final primaryActionButtons = <Widget>[
      if (_showsVisitNow &&
          (_supportsDelivery || _supportsPickup) &&
          orderLink != null &&
          orderLink.isNotEmpty)
        Semantics(
          button: true,
          label: l10n.getDirectionsToMerchant,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label:
                Text(_t('Get directions', 'මාර්ගය බලන්න', 'வழிகாட்டல் பெறுக')),
            onPressed: _openDirections,
          ),
        ),
    ];
    // Contact actions stay outlined (Ash border, Ceylon Ink text) — only one
    // filled Ceylon Ink CTA per screen, per the "single CTA style" rule.
    final callButton = _merchantPhoneNumber.isNotEmpty
        ? Semantics(
            button: true,
            label: l10n.callMerchant,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.call_outlined, size: 18),
              label: Text(l10n.callLabel),
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
              onPressed: _launchWhatsApp,
            ),
          )
        : null;
    final secondaryActionButtons = <Widget>[
      if (!_isPlatformBankOffer)
        Semantics(
          button: true,
          label: _dealAlertEnabled
              ? _t(
                  'Disable deal alerts',
                  'Deal alerts අක්‍රීය කරන්න',
                  'Deal alerts நிறுத்தவும்',
                )
              : _t(
                  'Notify me about this deal',
                  'මෙම deal එක ගැන මට දැනුම් දෙන්න',
                  'இந்த deal பற்றி எனக்கு அறிவிக்கவும்',
                ),
          child: OutlinedButton.icon(
            icon: _loadingDealAlert
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _dealAlertEnabled
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                    size: 18,
                  ),
            label: Text(_dealAlertEnabled
                ? _t(
                    'Alerts On',
                    'Alerts On',
                    'Alerts On',
                  )
                : _t(
                    'Notify me',
                    'මට දැනුම් දෙන්න',
                    'எனக்கு அறிவிக்கவும்',
                  )),
            style: _dealAlertEnabled
                ? OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brand,
                    backgroundColor: AppColors.turmeric.withValues(alpha: 0.18),
                    side: const BorderSide(color: AppColors.turmeric),
                  )
                : null,
            onPressed: _loadingDealAlert ? null : _toggleDealAlert,
          ),
        ),
      if (_showsVisitNow && !_isPlatformBankOffer)
        Semantics(
          button: true,
          label: _t(
            'Show redemption QR',
            'Redemption QR පෙන්වන්න',
            'Redemption QR காட்டவும்',
          ),
          child: OutlinedButton.icon(
            icon: _creatingRedemptionQr
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.qr_code_2_rounded, size: 18),
            label: Text(_t(
              'Show QR',
              'QR පෙන්වන්න',
              'QR காட்டவும்',
            )),
            onPressed: _creatingRedemptionQr ? null : _showRedemptionQr,
          ),
        ),
      if (_showsVisitNow &&
          (!_supportsDelivery && !_supportsPickup) &&
          promotion.url != null &&
          promotion.url!.isNotEmpty)
        Semantics(
          button: true,
          label: l10n.openDealLink,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.launch, size: 18),
            label: Text(l10n.goToDealLabel),
            onPressed: () => _launchURL(promotion.url!),
          ),
        ),
      if ((_showsVisitNow ||
              orderLink != null ||
              (promotion.url ?? '').isNotEmpty) &&
          (promotion.websiteUrl ?? '').isNotEmpty)
        Semantics(
          button: true,
          label: l10n.openMerchantWebsite,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.public, size: 18),
            label: Text(l10n.websiteLabel),
            onPressed: () => _launchURL(promotion.websiteUrl!),
          ),
        ),
    ];
    final _StickyActionConfig? stickyPrimaryAction = (_supportsDelivery ||
                _supportsPickup) &&
            orderLink != null &&
            orderLink.isNotEmpty
        ? _StickyActionConfig(
            label: _t('Open merchant website',
                'වෙළඳසැල් වෙබ් අඩවිය විවෘත කරන්න', 'வணிகர் இணையதளத்தைத் திற'),
            icon: Icons.delivery_dining,
            onPressed: () => _launchURL(orderLink),
            backgroundColor: AppColors.brand,
            foregroundColor: AppColors.sand,
          )
        : _showsVisitNow
            ? _StickyActionConfig(
                label: _t('Get directions', 'මාර්ගය බලන්න', 'வழிகாட்டல் பெறுக'),
                icon: Icons.directions_outlined,
                onPressed: _openDirections,
                backgroundColor: AppColors.brand,
                foregroundColor: AppColors.sand,
              )
            : (promotion.url ?? '').isNotEmpty
                ? _StickyActionConfig(
                    label: l10n.openDealLabel,
                    icon: Icons.launch,
                    onPressed: () => _launchURL(promotion.url!),
                    backgroundColor: AppColors.brand,
                    foregroundColor: AppColors.sand,
                  )
                : (promotion.websiteUrl ?? '').isNotEmpty
                    ? _StickyActionConfig(
                        label: l10n.websiteLabel,
                        icon: Icons.public,
                        onPressed: () => _launchURL(promotion.websiteUrl!),
                        backgroundColor: AppColors.brand,
                        foregroundColor: AppColors.sand,
                      )
                    : null;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_t('Deal details', 'දීමනාවේ විස්තර', 'சலுகை விவரங்கள்')),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        titleTextStyle: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700),
        actions: [
          if (!_isPlatformBankOffer)
            IconButton(
                tooltip: _isFavorite ? l10n.removeFavorite : l10n.saveFavorites,
                onPressed: _savingFavorite ? null : _toggleFavorite,
                icon:
                    Icon(_isFavorite ? Icons.bookmark : Icons.bookmark_border)),
          IconButton(
              tooltip: l10n.shareDeal,
              icon: const Icon(Icons.ios_share),
              onPressed: _shareDeal),
          PopupMenuButton<String>(
              tooltip: _t('More', 'තවත්', 'மேலும்'),
              onSelected: (action) async {
                if (action == 'copy') {
                  await Clipboard.setData(ClipboardData(text: deepLink));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.dealLinkCopied)));
                  }
                } else if (action == 'save') {
                  await _toggleFavorite();
                } else if (action == 'alert') {
                  await _toggleDealAlert();
                } else if (action == 'report') {
                  _showReportDealDialog();
                }
              },
              itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'copy', child: Text(l10n.copyShareableLink)),
                    if (!_isPlatformBankOffer) ...[
                      PopupMenuItem(
                          value: 'save',
                          enabled: !_savingFavorite,
                          child: Text(_isFavorite
                              ? l10n.removeFavorite
                              : l10n.saveFavorites)),
                      PopupMenuItem(
                          value: 'alert',
                          enabled: !_loadingDealAlert,
                          child: Text(_dealAlertEnabled
                              ? _t(
                                  'Disable deal alerts',
                                  'දීමනා දැනුම්දීම් අක්‍රීය කරන්න',
                                  'சலுகை அறிவிப்புகளை நிறுத்து')
                              : _t('Notify me', 'මට දැනුම් දෙන්න',
                                  'எனக்கு அறிவிக்கவும்'))),
                      PopupMenuItem(
                          value: 'report',
                          child: Text(_t('Report deal', 'දීමනාව වාර්තා කරන්න',
                              'சலுகையைப் புகாரளி')))
                    ]
                  ])
        ],
      ),
      bottomNavigationBar: stickyPrimaryAction == null
          ? null
          : _buildStickyActionBar(
              theme: theme,
              primaryAction: stickyPrimaryAction,
            ),
      body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Hero(
                        tag: 'dealImage_${promotion.id}',
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AspectRatio(
                                aspectRatio: 1.8,
                                child: Stack(fit: StackFit.expand, children: [
                                  PageView(
                                      onPageChanged: (i) =>
                                          setState(() => _galleryIndex = i),
                                      children: {
                                        if (promotion.imageDataString != null)
                                          promotion.imageDataString!,
                                        ...promotion.images
                                      }.isEmpty
                                          ? [_buildImageWidget(context, null)]
                                          : {
                                              if (promotion.imageDataString !=
                                                  null)
                                                promotion.imageDataString!,
                                              ...promotion.images
                                            }
                                              .map((image) => _buildImageWidget(
                                                  context, image))
                                              .toList()),
                                  if ({
                                        if (promotion.imageDataString != null)
                                          promotion.imageDataString!,
                                        ...promotion.images
                                      }.length >
                                      1)
                                    Positioned(
                                        right: 12,
                                        bottom: 12,
                                        child: Material(
                                            color: theme.colorScheme.surface,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Text(
                                                    '${_galleryIndex + 1} / ${{
                                                  if (promotion
                                                          .imageDataString !=
                                                      null)
                                                    promotion.imageDataString!,
                                                  ...promotion.images
                                                }.length}')))),
                                ])))),
                    const SizedBox(height: 16),
                    SizedBox(key: _offerAnchor),
                    _DealSummarySection(
                      title: displayTitle,
                      rating: DiscoverOfferRating(
                          offer: promotion.copyWith(
                              averageRating: _reviewCount > 0
                                  ? _averageRating
                                  : promotion.averageRating,
                              ratingsCount: _reviewCount > 0
                                  ? _reviewCount
                                  : promotion.ratingsCount)),
                      distanceLabel: distanceLabel,
                      merchantName: promotion.merchantName,
                      merchantLogoProvider: merchantLogoProvider,
                      hasMerchant: hasMerchant,
                      canOpenMerchant: promotion.merchantId != null,
                      headlinePrice: headlinePrice,
                      originalPriceLabel: originalPriceLabel,
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
                    ),
                    const SizedBox(height: 18),
                    SizedBox(key: _conditionsAnchor),
                    HybridConditionsPanel(
                        title: _t(
                            'Before you use this offer',
                            'දීමනාව භාවිත කිරීමට පෙර',
                            'சலுகையைப் பயன்படுத்துவதற்கு முன்'),
                        facts: [
                          if (promotion.bankName?.isNotEmpty == true)
                            promotion.bankName!,
                          if (promotion.cardTypes.isNotEmpty)
                            promotion.cardTypes
                                .map((type) => switch (type) {
                                      'credit' => l10n.creditCardLabel,
                                      'debit' => l10n.debitCardLabel,
                                      'prepaid' => l10n.prepaidCardLabel,
                                      _ => type
                                    })
                                .join(' · '),
                          if (OfferPresentation.validAmount(
                                  promotion.minimumSpend) !=
                              null)
                            l10n.minimumSpendLabel(
                                offerMoney(promotion, promotion.minimumSpend!)),
                          if (OfferPresentation.validAmount(
                                  promotion.maximumBenefit) !=
                              null)
                            '${_t('Maximum discount', 'උපරිම වට්ටම', 'அதிகபட்ச தள்ளுபடி')}: ${offerMoney(promotion, promotion.maximumBenefit!)}',
                          if (OfferPresentation(promotion).onlineOnly)
                            _t(
                                'Online · Merchant website',
                                'මාර්ගගත · වෙළඳසැල් වෙබ් අඩවිය',
                                'இணையம் · வணிகர் இணையதளம்')
                          else
                            [
                              if (promotion.supportsVisit) l10n.inStoreLabel,
                              if (promotion.supportsDelivery)
                                l10n.deliveryLabel,
                              if (promotion.supportsPickup) l10n.pickupLabel
                            ].join(' · '),
                          if (promotion.endDate != null)
                            l10n.offerEndsOn(dateFormat.format(promotion
                                .endDate!
                                .toUtc()
                                .add(const Duration(hours: 5, minutes: 30))))
                          else
                            _t('Expiry not provided', 'අවසන් දිනය සපයා නැත',
                                'முடிவுத் தேதி வழங்கப்படவில்லை'),
                          if (promotion.termsAndConditions?.trim().isNotEmpty ==
                              true)
                            promotion.termsAndConditions!,
                        ].where((value) => value.isNotEmpty).toList()),
                    const SizedBox(height: 12),
                    Wrap(spacing: 12, children: [
                      TextButton(
                          onPressed: () => _section(_offerAnchor),
                          child: Text(_t('Offer', 'දීමනාව', 'சலுகை'))),
                      TextButton(
                          onPressed: () => _section(_conditionsAnchor),
                          child: Text(
                              _t('Conditions', 'කොන්දේසි', 'நிபந்தனைகள்'))),
                      if (whyVisitCard.hasContent)
                        TextButton(
                            onPressed: () => _section(_highlightsAnchor),
                            child: Text(
                                _t('Highlights', 'විශේෂතා', 'சிறப்பம்சங்கள்'))),
                      if (promotion.supportsVisit)
                        TextButton(
                            onPressed: () => _section(_merchantAnchor),
                            child: Text(_t('Merchant', 'වෙළඳසැල', 'வணிகர்'))),
                    ]),
                    SizedBox(key: _highlightsAnchor),
                    if (whyVisitCard.hasContent) ...[
                      whyVisitCard,
                      const SizedBox(height: 16)
                    ],
                    _DealDetailsSection(
                      description: promotion.description,
                      startDate: promotion.startDate,
                      endDate: promotion.endDate,
                      dateFormat: dateFormat,
                      termsAndConditions: null,
                      expanded: _detailsExpanded,
                      onToggleExpanded: () {
                        setState(() {
                          _detailsExpanded = !_detailsExpanded;
                        });
                      },
                    ),
                    const SizedBox(height: 20.0),
                    _buildDealActionPanel(
                      theme: theme,
                      primaryActions: primaryActionButtons,
                      callButton: callButton,
                      whatsappButton: whatsappButton,
                      directionsButton: null,
                      secondaryActions: secondaryActionButtons,
                    ),
                    const SizedBox(height: 20.0),
                    _buildRecommendationsSection(theme),
                    if (activityItems.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: activityItems
                                  .map((item) => _buildStatChip(
                                      item.icon, item.label, item.value))
                                  .toList())),
                    _buildRatingsReviewsSection(theme),
                    const SizedBox(height: 20.0),
                    const Divider(height: 32, thickness: 1.2),
                    if (promotion.supportsVisit &&
                        promotion.fulfillmentType != 'order')
                      Container(
                          key: _merchantAnchor,
                          child: _buildLocationSection(theme, distanceLabel)),
                    const SizedBox(height: 20.0),
                    const SizedBox(height: 10.0),
                  ],
                ),
              ))),
    );
  }

  Widget _buildRecommendationsSection(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child:
              Text(l10n.youMightAlsoLike, style: theme.textTheme.titleLarge)),
      FutureBuilder<List<Promotion>>(
          future: _recommendedDealsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.errorLoadingRecommendations));
            }
            if (snapshot.data?.isEmpty ?? true) {
              return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.noRecommendationsAvailable));
            }
            return SizedBox(
                height:
                    294 + (MediaQuery.textScalerOf(context).scale(16) - 16) * 6,
                child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final deal = snapshot.data![index];
                      return ModernDealCard(
                          width: 184,
                          promotion: deal,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      DealDetailScreen(promotion: deal))));
                    }));
          }),
    ]);
  }

  Widget _buildRedemptionFeedbackSection(ThemeData theme) {
    Widget feedbackButton({
      required bool worked,
      required IconData icon,
      required String label,
      required int count,
    }) {
      final selected = _userRedemptionWorked == worked;
      // "Worked" is a trust signal (Betel Green); "didn't work" is a problem
      // flag (Chili) — matching the two colors' reserved roles.
      final color = worked ? AppColors.betelGreen : AppColors.chili;
      return Expanded(
        child: OutlinedButton.icon(
          onPressed: _submittingRedemptionFeedback
              ? null
              : () => _submitRedemptionFeedback(worked),
          icon: Icon(icon, size: 18),
          label: Text('$label ($count)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: selected ? AppColors.sand : color,
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
        color: theme.colorScheme.surfaceContainerHighest,
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
                  TextButton(
                      onPressed: _ensureSignedIn,
                      child: Text(l10n.discoverySignIn)),
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
                                      backgroundColor:
                                          AppColors.border(context),
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

  Widget _buildImageWidget(BuildContext context, String? imageDataString) {
    Widget image(BoxFit fit) => imageDataString?.startsWith('assets/') == true
        ? Image.asset(imageDataString!, fit: fit, excludeFromSemantics: true)
        : ImageHelper.buildOptimizedImage(imageDataString, fit: fit);
    return Semantics(
        button: true,
        label: _t('View image', 'රූපය බලන්න', 'படத்தைப் பார்க்கவும்'),
        child: InkWell(
            onTap: () => showDialog<void>(
                context: context,
                builder: (context) => Dialog(
                      backgroundColor: Colors.black,
                      insetPadding: EdgeInsets.zero,
                      child: SafeArea(
                          child: Stack(children: [
                        Center(
                            child: InteractiveViewer(
                                child: image(BoxFit.contain))),
                        Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                                tooltip: _t('Close', 'වසන්න', 'மூடு'),
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.white))),
                      ])),
                    )),
            child: image(BoxFit.cover)));
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
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDealActionPanel({
    required ThemeData theme,
    required List<Widget> primaryActions,
    required Widget? callButton,
    required Widget? whatsappButton,
    required Widget? directionsButton,
    required List<Widget> secondaryActions,
  }) {
    const gap = 10.0;

    List<Widget> buildRows(List<Widget> actions, double fullWidth) {
      if (fullWidth < 420 || MediaQuery.textScalerOf(context).scale(16) > 24) {
        return actions
            .map((action) =>
                _buildActionButtonShell(width: fullWidth, child: action))
            .toList();
      }
      final halfWidth = (fullWidth - gap) / 2;
      final rows = <Widget>[];
      for (var i = 0; i < actions.length; i += 2) {
        if (i + 1 == actions.length) {
          rows.add(
              _buildActionButtonShell(width: fullWidth, child: actions[i]));
        } else {
          rows.add(Row(children: [
            _buildActionButtonShell(width: halfWidth, child: actions[i]),
            const SizedBox(width: gap),
            _buildActionButtonShell(width: halfWidth, child: actions[i + 1]),
          ]));
        }
      }
      return rows;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth - 34;
        final primary = <Widget>[
          ...primaryActions,
          if (directionsButton != null) directionsButton,
        ];
        final contact = <Widget>[
          if (callButton != null) callButton,
          if (whatsappButton != null) whatsappButton,
        ];
        final primaryRows = buildRows([...primary, ...contact], fullWidth);
        final secondaryRows = buildRows(secondaryActions, fullWidth);

        if (primaryRows.isEmpty && secondaryRows.isEmpty) {
          return const SizedBox.shrink();
        }

        Widget sectionTitle(String title, IconData icon) {
          return Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              )),
            ],
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (primaryRows.isNotEmpty) ...[
                sectionTitle(
                  _t('Use this deal', 'මෙම deal එක භාවිත කරන්න',
                      'இந்த deal-ஐ பயன்படுத்தவும்'),
                  Icons.touch_app_outlined,
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < primaryRows.length; i++) ...[
                  if (i > 0) const SizedBox(height: gap),
                  primaryRows[i],
                ],
              ],
              if (primaryRows.isNotEmpty && secondaryRows.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 14),
              ],
              if (secondaryRows.isNotEmpty) ...[
                sectionTitle(
                  _t('More options', 'තවත් විකල්ප', 'மேலும் விருப்பங்கள்'),
                  Icons.tune_rounded,
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < secondaryRows.length; i++) ...[
                  if (i > 0) const SizedBox(height: gap),
                  secondaryRows[i],
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtonShell({
    required Widget child,
    required double width,
  }) {
    return ConstrainedBox(
      constraints:
          BoxConstraints(minWidth: width, maxWidth: width, minHeight: 52),
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
  }) {
    return ColoredBox(
        color: theme.colorScheme.surfaceContainerLow,
        child: SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  onPressed: primaryAction.onPressed,
                  icon: Icon(primaryAction.icon, size: 20),
                  label: Text(primaryAction.label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: theme.colorScheme.onPrimary)),
                ))));
  }

  String? _headlinePriceText(Promotion promotion) {
    final v = OfferPresentation(promotion);
    if (v.useDiscountHeadline) return promotion.discount!.trim();
    return v.price == null
        ? promotion.discount?.trim()
        : offerMoney(promotion, v.price!);
  }

  String? _originalPriceText(Promotion promotion) {
    final previous = OfferPresentation(promotion).useDiscountHeadline
        ? null
        : OfferPresentation(promotion).previous;
    return previous == null ? null : offerMoney(promotion, previous);
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
  final Widget rating;
  final String distanceLabel;
  final String? merchantName;
  final ImageProvider<Object>? merchantLogoProvider;
  final bool hasMerchant;
  final bool canOpenMerchant;
  final String? headlinePrice;
  final String? originalPriceLabel;
  final List<Widget> statusChips;
  final VoidCallback? onTapMerchant;

  const _DealSummarySection({
    required this.title,
    required this.rating,
    required this.distanceLabel,
    required this.merchantName,
    required this.merchantLogoProvider,
    required this.hasMerchant,
    required this.canOpenMerchant,
    required this.headlinePrice,
    required this.originalPriceLabel,
    required this.statusChips,
    required this.onTapMerchant,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(
          header: true,
          child: hybridCopy(context, title, size: 22, weight: FontWeight.w700)),
      if (hasMerchant && merchantName != null)
        InkWell(
            onTap: onTapMerchant,
            child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(children: [
                  if (merchantLogoProvider != null) ...[
                    CircleAvatar(
                        radius: 12, backgroundImage: merchantLogoProvider),
                    const SizedBox(width: 8)
                  ],
                  Expanded(
                      child: hybridCopy(context, merchantName!,
                          size: 15, color: colors.onSurfaceVariant)),
                  if (canOpenMerchant)
                    const Icon(Icons.chevron_right, size: 20),
                ]))),
      Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            rating,
            if (distanceLabel.isNotEmpty)
              Text('≈ $distanceLabel',
                  style:
                      TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
          ]),
      const SizedBox(height: 10),
      if (headlinePrice != null) ...[
        Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              hybridCopy(context, headlinePrice!,
                  size: 26, weight: FontWeight.w700, color: colors.primary),
              if (originalPriceLabel != null)
                Text(originalPriceLabel!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: colors.onSurfaceVariant))
            ]),
        const SizedBox(height: 6)
      ],
      if (statusChips.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: statusChips)
      ],
    ]);
  }
}

/// Optional, substantiated highlights after eligibility and conditions.
class _WhyVisitCard extends StatelessWidget {
  final String? savingsLabel;
  final String? distanceLabel;
  final String? countdownText;
  final String? verifiedLabel;

  const _WhyVisitCard({
    required this.savingsLabel,
    required this.distanceLabel,
    required this.countdownText,
    required this.verifiedLabel,
  });

  bool get hasContent =>
      savingsLabel != null ||
      distanceLabel != null ||
      countdownText != null ||
      verifiedLabel != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget row(IconData icon, String label, {Color? iconColor}) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: iconColor ?? theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _localizedText(context, 'Highlights', 'විශේෂතා', 'சிறப்பம்சங்கள்'),
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.onSurface),
          ),
          // Savings gets the Turmeric accent — the one thing on this card
          // that's about money, so it's the one thing that gets that color.
          if (savingsLabel != null)
            row(Icons.savings_outlined, savingsLabel!,
                iconColor: AppColors.turmeric),
          if (distanceLabel != null)
            row(Icons.near_me_outlined, distanceLabel!),
          if (countdownText != null) row(Icons.timer_outlined, countdownText!),
          // Verified is a trust claim, so — and only here — Betel Green.
          if (verifiedLabel != null)
            row(Icons.verified_outlined, verifiedLabel!,
                iconColor: AppColors.betelGreen),
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
  final bool expanded;
  final VoidCallback onToggleExpanded;

  const _DealDetailsSection({
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.dateFormat,
    required this.termsAndConditions,
    required this.expanded,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onToggleExpanded,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _localizedText(context, 'Full details',
                              'සම්පූර්ණ විස්තර', 'முழு விவரங்கள்'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(expanded ? Icons.expand_less : Icons.expand_more),
                    ],
                  )),
            ),
            AnimatedSize(
              duration: AppMotion.duration(context, 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topLeft,
              child: !expanded
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            description,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(height: 1.5),
                          ),
                          if (startDate != null || endDate != null) ...[
                            const Divider(height: 32),
                            Text(
                              _localizedText(context, 'Validity:',
                                  'වලංගු කාලය:', 'செல்லுபடியாகும் காலம்:'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            if (startDate != null)
                              Text(
                                '${_localizedText(context, 'Starts:', 'ආරම්භය:', 'தொடக்கம்:')} ${dateFormat.format(startDate!.toUtc().add(const Duration(hours: 5, minutes: 30)))}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            if (endDate != null)
                              Text(
                                '${_localizedText(context, 'Expires:', 'කල් ඉකුත් වීම:', 'முடிவு:')} ${dateFormat.format(endDate!.toUtc().add(const Duration(hours: 5, minutes: 30)))}',
                                style: theme.textTheme.bodyMedium,
                              ),
                          ],
                          if (termsAndConditions != null &&
                              termsAndConditions!.isNotEmpty) ...[
                            const Divider(height: 32),
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
                            const SizedBox(height: 6.0),
                            Text(
                              termsAndConditions!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
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
