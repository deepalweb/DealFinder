import 'dart:convert'; // For base64Decode
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:intl/intl.dart'; // For date formatting
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/promotion.dart';
import '../services/favorites_manager.dart';
import '../services/api_service.dart';
import '../services/recommendation_service.dart';
import '../services/deal_history_service.dart';
import '../services/deal_comparison_service.dart';
import '../services/review_service.dart';
import '../widgets/rating_widget.dart';
import '../screens/deal_comparison_screen.dart';
import '../screens/review_screen.dart';

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
  bool _loadingComments = true;
  double _averageRating = 0;
  int _reviewCount = 0;
  final ApiService _apiService = ApiService();
  // TODO: Replace with your actual auth logic
  String? _userToken; // Set this from your auth provider

  Map<String, dynamic>? _merchantData;

  late Future<List<Promotion>> _recommendedDealsFuture;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
    _fetchComments();
    _loadUserAuth();
    _fetchMerchantData();
    _recommendedDealsFuture = _fetchRecommendedDeals();
    _trackView();
  }
  
  Future<void> _trackView() async {
    await DealHistoryService.addToHistory(widget.promotion.id);
    await RecommendationService.trackView(widget.promotion.id, widget.promotion.category);
  }

  Future<void> _loadUserAuth() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userToken = prefs.getString('userToken');
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
    });
  }

  Future<void> _fetchMerchantData() async {
    if (widget.promotion.merchantId == null) return;
    try {
      final data = await _apiService.fetchMerchantById(widget.promotion.merchantId!);
      setState(() { _merchantData = data; });
    } catch (e) {
      setState(() { _merchantData = null; });
    }
  }

  Future<List<Promotion>> _fetchRecommendedDeals() async {
    try {
      // Fetch all promotions and filter out the current one
      final allPromos = await _apiService.fetchPromotions();
      return allPromos.where((p) => p.id != widget.promotion.id).take(5).toList();
    } catch (e) {
      return [];
    }
  }

  // Helper to launch URL - requires url_launcher package
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $urlString')),
      );
    }
  }

  void _shareDeal() {
    final promo = widget.promotion;
    final text = '${promo.title}\n${promo.description}\n${promo.websiteUrl ?? ''}';
    Share.share(text.trim());
  }

  Future<void> _fetchComments() async {
    setState(() { _loadingComments = true; });
    try {
      final comments = await _apiService.fetchPromotionComments(widget.promotion.id);
      setState(() {
        _comments = comments;
        _reviewCount = comments.length;
        if (comments.isNotEmpty) {
          // If your backend provides ratings, calculate average here
          final ratings = comments.map((c) => (c['rating'] ?? 5.0) as num).toList();
          _averageRating = ratings.isNotEmpty ? ratings.reduce((a, b) => a + b) / ratings.length : 0;
        } else {
          _averageRating = 0;
        }
      });
    } catch (e) {
      setState(() { _comments = []; });
    } finally {
      setState(() { _loadingComments = false; });
    }
  }

  Future<void> _submitReview(double rating, String review) async {
    if (_userToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to submit a review.')),
      );
      return;
    }
    try {
      await _apiService.postPromotionComment(widget.promotion.id, review, _userToken!);
      await _apiService.postPromotionRating(widget.promotion.id, rating, _userToken!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review submitted!')),
      );
      _fetchComments();
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
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
            onPressed: () {
              // TODO: Navigate to notifications page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Notifications (to be implemented)')),
              );
            },
          ),
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
                      final link = 'https://dealfinder.app/deal/${promotion.id}';
                      await Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Deal link copied!')),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.link, color: theme.colorScheme.primary, size: 20),
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
                        Icon(Icons.copy, size: 16, color: theme.colorScheme.primary),
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
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.red[700], fontWeight: FontWeight.bold),
                        );
                      } else if (diff.inHours > 0) {
                        return Text(
                          '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} left',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.red[700], fontWeight: FontWeight.bold),
                        );
                      } else if (diff.inMinutes > 0) {
                        return Text(
                          '${diff.inMinutes} min left',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.red[700], fontWeight: FontWeight.bold),
                        );
                      } else {
                        return Text(
                          'Expired',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 4, offset: Offset(0,2))],
                    ),
                    child: Text('FEATURED', style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
              ],
            ),
            if (promotion.featured == true)
              const SizedBox(height: 6.0),

            // Promotion Title
            Text(
              promotion.title,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),

            // Merchant Information (with logo/avatar if available)
            if (promotion.merchantName != null && promotion.merchantName!.isNotEmpty)
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Navigate to merchant profile (to be implemented)')),
                  );
                },
                child: Card(
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  color: theme.colorScheme.surfaceVariant,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                    child: Row(
                      children: [
                        if (_merchantData != null && _merchantData!['logo'] != null && _merchantData!['logo'].toString().isNotEmpty)
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: _merchantData!['logo'].toString().startsWith('http')
                              ? NetworkImage(_merchantData!['logo'])
                              : null,
                            backgroundColor: Colors.grey[200],
                            child: _merchantData!['logo'].toString().startsWith('http') ? null : Icon(Icons.storefront_outlined, color: Colors.grey),
                          )
                        else
                          Icon(Icons.storefront_outlined, size: 20, color: theme.textTheme.bodyMedium?.color),
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
            if (promotion.merchantName != null && promotion.merchantName!.isNotEmpty)
              const SizedBox(height: 16.0),

            // Discount & Code Section
            if (promotion.discount != null || promotion.code != null)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                              Text('Discount:', style: theme.textTheme.labelMedium),
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
                            Clipboard.setData(ClipboardData(text: promotion.code!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Code "${promotion.code}" copied to clipboard!')),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16.0),

            // Visual Price Section
            if (promotion.originalPrice != null || promotion.discountedPrice != null || promotion.price != null)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                      if (promotion.price != null && promotion.discountedPrice == null)
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
                      if (promotion.discount != null && promotion.discount!.contains('%'))
                        Container(
                          margin: const EdgeInsets.only(left: 12.0),
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            promotion.discount!,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: theme.colorScheme.surfaceContainerLowest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details:',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      promotion.description,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 16.0),
                    if (promotion.startDate != null || promotion.endDate != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(height: 24),
                          Text(
                            'Validity:',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6.0),
                          if (promotion.startDate != null)
                            Text('Starts: ${dateFormat.format(promotion.startDate!)}', style: theme.textTheme.bodyMedium),
                          if (promotion.endDate != null)
                            Text('Expires: ${dateFormat.format(promotion.endDate!)}', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    if (promotion.termsAndConditions != null && promotion.termsAndConditions!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(height: 24),
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
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Icon(_showTerms ? Icons.expand_less : Icons.expand_more),
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
            Divider(height: 32, thickness: 1.2),

            // Action Buttons
            Center(
              child: Wrap(
                spacing: 12.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: [
                  if (promotion.url != null && promotion.url!.isNotEmpty)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.launch),
                      label: const Text('Go to Promotion'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      onPressed: () => _launchURL(promotion.url!),
                    ),
                  if (promotion.websiteUrl != null && promotion.websiteUrl!.isNotEmpty)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.public),
                      label: const Text('Visit Website'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.tertiary,
                        foregroundColor: theme.colorScheme.onTertiary,
                      ),
                      onPressed: () => _launchURL(promotion.websiteUrl!),
                    ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share Deal'),
                    onPressed: _shareDeal,
                  ),
                  OutlinedButton.icon(
                    icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border_outlined, color: theme.colorScheme.primary),
                    label: Text(_isFavorite ? 'Remove Favorite' : 'Save to Favorites'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                    ),
                    onPressed: _toggleFavorite,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.compare_arrows),
                    label: const Text('Add to Compare'),
                    onPressed: () async {
                      await DealComparisonService.addToComparison(widget.promotion.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to comparison')),
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.rate_review),
                    label: const Text('Write Review'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReviewScreen(promotion: widget.promotion),
                        ),
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Report Deal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red[900],
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Report submitted (to be implemented)')),
                      );
                    },
                  ),
                  if (promotion.endDate != null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.event),
                      label: const Text('Add to Calendar'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Add to calendar (to be implemented)')),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            Divider(height: 32, thickness: 1.2),

            // Recommendations/Similar Deals
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: theme.colorScheme.surfaceContainerLowest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You might also like',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12.0),
                    FutureBuilder<List<Promotion>>(
                      future: _recommendedDealsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return SizedBox(
                            height: 180,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        } else if (snapshot.hasError) {
                          return SizedBox(
                            height: 180,
                            child: Center(child: Text('Error loading recommendations')),
                          );
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return SizedBox(
                            height: 180,
                            child: Center(child: Text('No recommendations available')),
                          );
                        } else {
                          final recommendedDeals = snapshot.data!;
                          return SizedBox(
                            height: 180,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: recommendedDeals.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final deal = recommendedDeals[index];
                                return Container(
                                  width: 140,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
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
                                              builder: (context) => DealDetailScreen(promotion: deal),
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
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: deal.imageDataString != null && deal.imageDataString!.isNotEmpty
                                              ? (deal.imageDataString!.startsWith('http')
                                                  ? Image.network(deal.imageDataString!, fit: BoxFit.cover, width: double.infinity, height: 70, errorBuilder: (c, e, s) => Icon(Icons.broken_image))
                                                  : (deal.imageDataString!.startsWith('data:image')
                                                      ? Image.memory(
                                                          base64Decode(deal.imageDataString!.substring(deal.imageDataString!.indexOf(',') + 1)),
                                                          fit: BoxFit.cover,
                                                          width: double.infinity,
                                                          height: 70,
                                                          errorBuilder: (c, e, s) => Icon(Icons.broken_image),
                                                        )
                                                      : Icon(Icons.broken_image)))
                                              : Icon(Icons.broken_image),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        deal.title,
                                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
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
            Divider(height: 32, thickness: 1.2),

            // Ratings & Reviews Section
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: theme.colorScheme.surfaceContainerLowest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ratings & Reviews',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      children: [
                        _averageRating > 0
                          ? Row(
                              children: List.generate(5, (i) => Icon(
                                i < _averageRating.round()
                                  ? Icons.star
                                  : Icons.star_border,
                                color: Colors.amber,
                                size: 24,
                              )),
                            )
                          : Icon(Icons.star_border, color: Colors.grey, size: 24),
                        const SizedBox(width: 8),
                        Text(_averageRating.toStringAsFixed(1), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text('($_reviewCount reviews)', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    if (_loadingComments)
                      const Center(child: CircularProgressIndicator()),
                    if (!_loadingComments && _comments.isEmpty)
                      Text('No reviews yet. Be the first to review!', style: theme.textTheme.bodyMedium),
                    if (!_loadingComments && _comments.isNotEmpty)
                      Column(
                        children: _comments.map((c) => Card(
                          elevation: 0.5,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            leading: c['user']?['avatar'] != null && c['user']!['avatar'].toString().isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(c['user']!['avatar']),
                                  backgroundColor: Colors.grey[200],
                                )
                              : Icon(Icons.account_circle, size: 32),
                            title: Text(c['user']?['name'] ?? 'User',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),),
                            subtitle: Text(c['text'] ?? '', style: theme.textTheme.bodyMedium),
                            trailing: c['rating'] != null ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 18),
                                Text(c['rating'].toString()),
                              ],
                            ) : null,
                          ),
                        )).toList(),
                      ),
                    const SizedBox(height: 12.0),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.rate_review_outlined),
                      label: const Text('Write a Review'),
                      onPressed: () async {
                        double rating = 5;
                        TextEditingController reviewController = TextEditingController();
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
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(5, (index) => IconButton(
                                          icon: Icon(
                                            index < rating ? Icons.star : Icons.star_border,
                                            color: Colors.amber,
                                          ),
                                          onPressed: () {
                                            setState(() { rating = index + 1.0; });
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
                                      onPressed: () => Navigator.of(context).pop(),
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
            Divider(height: 32, thickness: 1.2),

            // Map/Location Section
            if (promotion.location != null && promotion.location!.isNotEmpty)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: theme.colorScheme.surfaceContainerLowest,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Location', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: theme.colorScheme.primary),
                          const SizedBox(width: 8.0),
                          Expanded(child: Text(promotion.location!)),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      if (_merchantData != null && _merchantData!['latitude'] != null && _merchantData!['longitude'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.network(
                            'https://maps.googleapis.com/maps/api/staticmap?center=${_merchantData!['latitude']},${_merchantData!['longitude']}&zoom=15&size=600x200&markers=color:red%7C${_merchantData!['latitude']},${_merchantData!['longitude']}&key=YOUR_GOOGLE_MAPS_API_KEY',
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 120,
                              color: Colors.grey[200],
                              child: Center(child: Icon(Icons.map, color: Colors.grey)),
                            ),
                          ),
                        ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.directions),
                        label: const Text('Get Directions'),
                        onPressed: () async {
                          final query = Uri.encodeComponent(promotion.location!);
                          final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$query';
                          if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
                            await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not open maps.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20.0),

            // Deal Tags/Type (Web-inspired)
            Row(
              children: [
                if (promotion.category != null && promotion.category!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.label, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          promotion.category!.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Placeholder for tags/type (e.g., Online Only, Limited Time)
                // Add more tags here if your backend provides them
                Container(
                  margin: const EdgeInsets.only(right: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.flash_on, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text('LIMITED TIME', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
                // Example: In-Store Only tag (uncomment if you have this info)
                // Container(
                //   margin: const EdgeInsets.only(right: 8.0),
                //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                //   decoration: BoxDecoration(
                //     color: Colors.green[50],
                //     borderRadius: BorderRadius.circular(16),
                //   ),
                //   child: Row(
                //     children: [
                //       Icon(Icons.store, size: 16, color: Colors.green[700]),
                //       const SizedBox(width: 4),
                //       Text('IN-STORE', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12)),
                //     ],
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: 10.0),

            // Related Categories/Tags (Web-inspired)
            if (promotion.category != null && promotion.category!.isNotEmpty)
              Wrap(
                spacing: 8.0,
                children: [
                  Chip(
                    label: Text(promotion.category!),
                    avatar: Icon(Icons.category, size: 18, color: theme.colorScheme.primary),
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    labelStyle: TextStyle(color: theme.colorScheme.primary),
                  ),
                  // Add more chips for tags if available
                ],
              ),
            const SizedBox(height: 10.0),

            // Merchant Quick Info (Web-inspired, placeholder)
            if (promotion.merchantName != null && promotion.merchantName!.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.people, size: 18, color: theme.colorScheme.secondary),
                  const SizedBox(width: 4),
                  Text('1.2k followers', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary)),
                  const SizedBox(width: 16),
                  Icon(Icons.star, size: 18, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('4.8', style: theme.textTheme.bodySmall?.copyWith(color: Colors.amber)),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () {
                      // TODO: Implement follow merchant logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Follow merchant (to be implemented)')),
                      );
                    },
                    child: Text('Follow'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(60, 28),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      textStyle: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10.0),

            // Deal Analytics (Web-inspired, placeholder)
            Row(
              children: [
                Icon(Icons.visibility, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('2,345 views today', style: theme.textTheme.bodySmall),
                const SizedBox(width: 16),
                Icon(Icons.favorite, size: 18, color: Colors.red[400]),
                const SizedBox(width: 4),
                Text('512 saved', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleFavorite,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          color: Colors.white,
        ),
        tooltip: _isFavorite ? 'Remove from Favorites' : 'Save to Favorites',
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
      child: Icon(Icons.broken_image_outlined, size: 60, color: Colors.grey[600]),
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
    if (imageDataString.startsWith('data:image') && imageDataString.contains(';base64,')) {
      try {
        final String base64Data = imageDataString.substring(imageDataString.indexOf(',') + 1);
        final Uint8List decodedBytes = base64Decode(base64Data);
        final image = Image.memory(
          decodedBytes,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildImageErrorPlaceholder(context, error: error),
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
        errorBuilder: (context, error, stackTrace) => _buildImageErrorPlaceholder(context, error: error),
      );
      return GestureDetector(
        onTap: () => showFullScreenImage(image),
        child: image,
      );
    }
    return _buildImageErrorPlaceholder(context);
  }
}
