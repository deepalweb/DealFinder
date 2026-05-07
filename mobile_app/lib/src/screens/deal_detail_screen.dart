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
import 'package:shimmer/shimmer.dart';
import '../models/promotion.dart';
import '../services/favorites_manager.dart';
import '../services/api_service.dart';
import '../services/recommendation_service.dart';
import '../services/deal_history_service.dart';
import '../config/app_config.dart';
import '../screens/merchant_profile_screen.dart';
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
  // TODO: Replace with your actual auth logic
  String? _userToken; // Set this from your auth provider
  String? _userId;

  Map<String, dynamic>? _merchantData;
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
      setState(() {
        _merchantData = data;
      });
    } catch (e) {
      setState(() {
        _merchantData = null;
      });
    }
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

  String? get _countdownText {
    final end = widget.promotion.endDate;
    if (end == null) return null;

    final diff = end.difference(DateTime.now());
    if (diff.isNegative || diff.inSeconds <= 0) {
      return 'Expired';
    }
    if (diff.inDays >= 1) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} left';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} left';
    }
    if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} min left';
    }
    return '${diff.inSeconds}s left';
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
      'Hi, I am contacting you about "${widget.promotion.title}" on DealFinder.',
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
    final callButton = _merchantPhoneNumber.isNotEmpty
        ? ElevatedButton.icon(
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
          )
        : null;
    final whatsappButton = _merchantPhoneNumber.isNotEmpty
        ? OutlinedButton.icon(
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
          )
        : null;
    final directionsButton = ElevatedButton.icon(
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
    );
    final secondaryActionButtons = <Widget>[
      if (promotion.url != null && promotion.url!.isNotEmpty)
        ElevatedButton.icon(
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
      if (promotion.websiteUrl != null && promotion.websiteUrl!.isNotEmpty)
        OutlinedButton.icon(
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
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(promotion.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            tooltip: 'Toggle Favorite',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Deal',
            onPressed: _shareDeal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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

            // Shareable Deep Link & Expiry Countdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Shareable Link (copy to clipboard)
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final link =
                          '${AppConfig.publicBaseUrl}/deal/${promotion.id}';
                      await Clipboard.setData(ClipboardData(text: link));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Deal link copied!')),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.link,
                            color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Shareable Link',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.copy,
                            size: 16, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ),
                // Expiry Countdown
                if (_countdownText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _countdownText == 'Expired'
                          ? Colors.grey.shade200
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _countdownText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _countdownText == 'Expired'
                            ? Colors.grey.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12.0),

            // Badges and Highlights (e.g., Featured, New, Popular)
            Row(
              children: [
                if (promotion.featured == true)
                  Container(
                    margin: const EdgeInsets.only(right: 6.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.orange.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Text('FEATURED',
                        style: TextStyle(
                            color: Colors.orange[900],
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
              ],
            ),
            if (promotion.featured == true) const SizedBox(height: 6.0),

            // Promotion Title
            Text(
              promotion.title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatChip(
                            Icons.visibility_outlined, 'Views', _viewCount),
                        _buildStatChip(
                            Icons.favorite_border, 'Likes', _favoriteCount),
                        _buildStatChip(Icons.chat_bubble_outline, 'Comments',
                            _commentCount),
                        _buildStatChip(
                            Icons.ads_click_outlined, 'Clicks', _clickCount),
                        _buildStatChip(Icons.directions_outlined, 'Directions',
                            _directionCount),
                      ],
                    ),
                    if (_loadingStats) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Merchant Information (with logo/avatar if available)
            if (promotion.merchantName != null &&
                promotion.merchantName!.isNotEmpty)
              GestureDetector(
                onTap: () {
                  if (promotion.merchantId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MerchantProfileScreen(
                            merchantId: promotion.merchantId!),
                      ),
                    );
                  }
                },
                child: Card(
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 8.0),
                    child: Row(
                      children: [
                        if (_merchantData != null &&
                            _merchantData!['logo'] != null &&
                            _merchantData!['logo'].toString().isNotEmpty)
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: _merchantData!['logo']
                                    .toString()
                                    .startsWith('http')
                                ? NetworkImage(_merchantData!['logo'])
                                : null,
                            backgroundColor: Colors.grey[200],
                            child: _merchantData!['logo']
                                    .toString()
                                    .startsWith('http')
                                ? null
                                : const Icon(Icons.storefront_outlined,
                                    color: Colors.grey),
                          )
                        else
                          Icon(Icons.storefront_outlined,
                              size: 20,
                              color: theme.textTheme.bodyMedium?.color),
                        const SizedBox(width: 8.0),
                        Text(
                          promotion.merchantName!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            decoration: TextDecoration.underline,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (promotion.merchantName != null &&
                promotion.merchantName!.isNotEmpty)
              const SizedBox(height: 16.0),

            if (_countdownText != null) ...[
              Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: _countdownText == 'Expired'
                    ? Colors.grey.shade100
                    : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      Icon(
                        _countdownText == 'Expired'
                            ? Icons.event_busy
                            : Icons.timer_outlined,
                        color: _countdownText == 'Expired'
                            ? Colors.grey.shade700
                            : Colors.red.shade700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _countdownText == 'Expired'
                              ? 'This deal has expired.'
                              : 'Offer ends in $_countdownText',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _countdownText == 'Expired'
                                ? Colors.grey.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
            ],

            // Discount & Code Section
            if (promotion.discount != null || promotion.code != null)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (promotion.discount != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Discount:',
                                  style: theme.textTheme.labelMedium),
                              Text(
                                promotion.discount!,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (promotion.code != null)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.content_copy, size: 16),
                          label: Text(promotion.code!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: theme.colorScheme.onSecondary,
                          ),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: promotion.code!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Code "${promotion.code}" copied to clipboard!')),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16.0),

            // Visual Price Section
            if (promotion.originalPrice != null ||
                promotion.discountedPrice != null ||
                promotion.price != null)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    children: [
                      if (promotion.originalPrice != null)
                        Text(
                          'Rs. ${promotion.originalPrice!.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                      if (promotion.discountedPrice != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            'Rs. ${promotion.discountedPrice!.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      if (promotion.price != null &&
                          promotion.discountedPrice == null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            'Rs. ${promotion.price!.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      if (promotion.discount != null &&
                          promotion.discount!.contains('%'))
                        Container(
                          margin: const EdgeInsets.only(left: 12.0),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            promotion.discount!,
                            style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16.0),

            // Description, Validity, Terms, all in a Card
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
                      'Details:',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      promotion.description,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 16.0),
                    if (promotion.startDate != null ||
                        promotion.endDate != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 24),
                          Text(
                            'Validity:',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6.0),
                          if (promotion.startDate != null)
                            Text(
                                'Starts: ${dateFormat.format(promotion.startDate!)}',
                                style: theme.textTheme.bodyMedium),
                          if (promotion.endDate != null)
                            Text(
                                'Expires: ${dateFormat.format(promotion.endDate!)}',
                                style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    if (promotion.termsAndConditions != null &&
                        promotion.termsAndConditions!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 24),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showTerms = !_showTerms;
                              });
                            },
                            child: Row(
                              children: [
                                Text(
                                  'Terms & Conditions',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Icon(_showTerms
                                    ? Icons.expand_less
                                    : Icons.expand_more),
                              ],
                            ),
                          ),
                          if (_showTerms)
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                promotion.termsAndConditions!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
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

                  rows.add(
                    _buildActionButtonShell(
                      width: fullWidth,
                      child: directionsButton,
                    ),
                  );

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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
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
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
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
                        ),
                      ],
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
                      const SizedBox(height: 8.0),
                      if (_merchantData != null &&
                          _merchantData!['latitude'] != null &&
                          _merchantData!['longitude'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: AppConfig.hasGoogleMapsApiKey
                              ? Image.network(
                                  'https://maps.googleapis.com/maps/api/staticmap?center=${_merchantData!['latitude']},${_merchantData!['longitude']}&zoom=15&size=600x200&markers=color:red%7C${_merchantData!['latitude']},${_merchantData!['longitude']}&key=${AppConfig.googleMapsApiKey}',
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    height: 120,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(Icons.map,
                                          color: Colors.grey),
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 120,
                                  color: Colors.grey[200],
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Add GOOGLE_MAPS_API_KEY to show the map preview.',
                                    textAlign: TextAlign.center,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
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
}
