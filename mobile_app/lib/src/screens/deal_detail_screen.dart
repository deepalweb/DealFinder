import 'dart:convert'; // For base64Decode
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
  double _averageRating = 0;
  int _reviewCount = 0;
  final ApiService _apiService = ApiService();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $urlString')),
      );
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
      final results = await Future.wait([
        _apiService.fetchPromotionComments(widget.promotion.id),
        _apiService.fetchPromotionRatings(widget.promotion.id),
      ]);
      final comments = results[0] as List<Map<String, dynamic>>;
      final ratings = results[1] as List<Map<String, dynamic>>;
      final ratingValues = ratings
          .map((rating) => (rating['value'] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      setState(() {
        _comments = comments;
        _ratings = ratings;
        _commentCount = comments.length;
        _reviewCount = ratings.length;
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

  Future<void> _submitReview(double rating, String review) async {
    if (_userToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in to submit a review.')),
      );
      return;
    }
    try {
      await _apiService.postPromotionComment(
          widget.promotion.id, review, _userToken!);
      await _apiService.postPromotionRating(
          widget.promotion.id, rating, _userToken!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted!')),
      );
      _loadReviewsAndStats();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final promotion = widget.promotion;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

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
                if (promotion.endDate != null)
                  Builder(
                    builder: (context) {
                      final now = DateTime.now();
                      final end = promotion.endDate!;
                      final diff = end.difference(now);
                      if (diff.inDays >= 1) {
                        return Text(
                          '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} left',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold),
                        );
                      } else if (diff.inHours > 0) {
                        return Text(
                          '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} left',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold),
                        );
                      } else if (diff.inMinutes > 0) {
                        return Text(
                          '${diff.inMinutes} min left',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold),
                        );
                      } else {
                        return Text(
                          'Expired',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey),
                        );
                      }
                    },
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
              height: 48,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: _openDirections,
                    ),
                  ),
                  if (promotion.url != null && promotion.url!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.launch, size: 18),
                        label: const Text('Go to Deal'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () => _launchURL(promotion.url!),
                      ),
                    ),
                  ],
                  if (promotion.websiteUrl != null &&
                      promotion.websiteUrl!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.public, size: 18),
                        label: const Text('Website'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () => _launchURL(promotion.websiteUrl!),
                      ),
                    ),
                  ],
                ],
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
                    Row(
                      children: [
                        _averageRating > 0
                            ? Row(
                                children: List.generate(
                                    5,
                                    (i) => Icon(
                                          i < _averageRating.round()
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 24,
                                        )),
                              )
                            : const Icon(Icons.star_border,
                                color: Colors.grey, size: 24),
                        const SizedBox(width: 8),
                        Text(_averageRating.toStringAsFixed(1),
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text('($_reviewCount ratings)',
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    if (_loadingComments)
                      const Center(child: CircularProgressIndicator()),
                    if (!_loadingComments && _comments.isEmpty)
                      Text(
                        _reviewCount > 0
                            ? 'No written reviews yet. Be the first to add one!'
                            : 'No reviews yet. Be the first to review!',
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
                                    leading: c['user']?['avatar'] != null &&
                                            c['user']!['avatar']
                                                .toString()
                                                .isNotEmpty
                                        ? CircleAvatar(
                                            backgroundImage: NetworkImage(
                                                c['user']!['avatar']),
                                            backgroundColor: Colors.grey[200],
                                          )
                                        : const Icon(Icons.account_circle,
                                            size: 32),
                                    title: Text(
                                      c['user']?['name'] ?? 'User',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    subtitle: Text(c['text'] ?? '',
                                        style: theme.textTheme.bodyMedium),
                                  ),
                                ))
                            .toList(),
                      ),
                    const SizedBox(height: 12.0),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.rate_review_outlined),
                      label: const Text('Write a Review'),
                      onPressed: () async {
                        double rating = 5;
                        TextEditingController reviewController =
                            TextEditingController();
                        final result = await showDialog<Map<String, dynamic>>(
                          context: context,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  title: const Text('Write a Review'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(
                                            5,
                                            (index) => IconButton(
                                                  icon: Icon(
                                                    index < rating
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    color: Colors.amber,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      rating = index + 1.0;
                                                    });
                                                  },
                                                )),
                                      ),
                                      TextField(
                                        controller: reviewController,
                                        decoration: const InputDecoration(
                                          labelText: 'Your review',
                                        ),
                                        maxLines: 3,
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop({
                                          'rating': rating,
                                          'review': reviewController.text,
                                        });
                                      },
                                      child: const Text('Submit'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                        if (result != null) {
                          _submitReview(result['rating'], result['review']);
                        }
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
                      const SizedBox(height: 8.0),
                      if (_merchantData != null &&
                          _merchantData!['latitude'] != null &&
                          _merchantData!['longitude'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.network(
                            'https://maps.googleapis.com/maps/api/staticmap?center=${_merchantData!['latitude']},${_merchantData!['longitude']}&zoom=15&size=600x200&markers=color:red%7C${_merchantData!['latitude']},${_merchantData!['longitude']}&key=${AppConfig.googleMapsApiKey}',
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 120,
                              color: Colors.grey[200],
                              child: const Center(
                                  child: Icon(Icons.map, color: Colors.grey)),
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
    if (error != null) {
      print("DetailScreen Image loading/decoding error: $error");
    }
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
        print('Error decoding Base64 image for DetailScreen: $e');
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
}
