import 'package:flutter/material.dart';
import '../models/promotion.dart';
import '../services/review_service.dart';
import '../widgets/rating_widget.dart';

class ReviewScreen extends StatefulWidget {
  final Promotion promotion;

  const ReviewScreen({super.key, required this.promotion});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _commentController = TextEditingController();
  double _rating = 5.0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;
  int _reviewCount = 0;
  bool _hasUserReviewed = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    final reviews = await ReviewService.getReviews(widget.promotion.id);
    final averageRating = await ReviewService.getAverageRating(widget.promotion.id);
    final reviewCount = await ReviewService.getReviewCount(widget.promotion.id);
    final hasUserReviewed = await ReviewService.hasUserReviewed(widget.promotion.id);

    setState(() {
      _reviews = reviews;
      _averageRating = averageRating;
      _reviewCount = reviewCount;
      _hasUserReviewed = hasUserReviewed;
    });
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ReviewService.addReview(
        widget.promotion.id,
        _rating,
        _commentController.text.trim(),
      );

      _commentController.clear();
      setState(() => _rating = 5.0);
      await _loadReviews();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews & Ratings'),
      ),
      body: Column(
        children: [
          // Deal info header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.local_offer, size: 30),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.promotion.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          RatingWidget(rating: _averageRating, size: 16),
                          const SizedBox(width: 8),
                          Text('$_averageRating ($_reviewCount reviews)'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Write review section
          if (!_hasUserReviewed)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Write a Review',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Rating: '),
                      InteractiveRatingWidget(
                        initialRating: _rating,
                        onRatingChanged: (rating) => setState(() => _rating = rating),
                      ),
                      const SizedBox(width: 8),
                      Text('$_rating/5'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Share your experience with this deal...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitReview,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Submit Review'),
                    ),
                  ),
                ],
              ),
            ),

          // Reviews list
          Expanded(
            child: _reviews.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No reviews yet'),
                        Text('Be the first to review this deal!'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final review = _reviews[index];
                      final date = DateTime.parse(review['date']);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    child: Text(review['userName'][0].toUpperCase()),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          review['userName'],
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${date.day}/${date.month}/${date.year}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  RatingWidget(rating: review['rating'].toDouble(), size: 16),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(review['comment']),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}