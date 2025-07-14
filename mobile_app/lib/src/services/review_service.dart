import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReviewService {
  static const String _reviewsKey = 'dealReviews';
  static const String _ratingsKey = 'dealRatings';

  static Future<void> addReview(String dealId, double rating, String comment) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName') ?? 'Anonymous';
    
    // Add review
    final reviews = await getReviews(dealId);
    final newReview = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'dealId': dealId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'date': DateTime.now().toIso8601String(),
    };
    
    reviews.add(newReview);
    await _saveReviews(dealId, reviews);
    
    // Update rating
    await _updateAverageRating(dealId);
  }

  static Future<List<Map<String, dynamic>>> getReviews(String dealId) async {
    final prefs = await SharedPreferences.getInstance();
    final reviewsJson = prefs.getString('${_reviewsKey}_$dealId') ?? '[]';
    final List<dynamic> reviewsList = jsonDecode(reviewsJson);
    return reviewsList.cast<Map<String, dynamic>>();
  }

  static Future<double> getAverageRating(String dealId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('${_ratingsKey}_$dealId') ?? 0.0;
  }

  static Future<int> getReviewCount(String dealId) async {
    final reviews = await getReviews(dealId);
    return reviews.length;
  }

  static Future<bool> hasUserReviewed(String dealId) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName') ?? 'Anonymous';
    final reviews = await getReviews(dealId);
    return reviews.any((review) => review['userName'] == userName);
  }

  static Future<void> _saveReviews(String dealId, List<Map<String, dynamic>> reviews) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_reviewsKey}_$dealId', jsonEncode(reviews));
  }

  static Future<void> _updateAverageRating(String dealId) async {
    final reviews = await getReviews(dealId);
    if (reviews.isEmpty) return;
    
    final totalRating = reviews.fold<double>(0, (sum, review) => sum + (review['rating'] as double));
    final averageRating = totalRating / reviews.length;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${_ratingsKey}_$dealId', averageRating);
  }

  static Future<void> deleteReview(String dealId, String reviewId) async {
    final reviews = await getReviews(dealId);
    reviews.removeWhere((review) => review['id'] == reviewId);
    await _saveReviews(dealId, reviews);
    await _updateAverageRating(dealId);
  }
}