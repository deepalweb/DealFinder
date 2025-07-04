import 'package:flutter/foundation.dart';

class Promotion {
  final String id;
  final String title;
  final String description;
  final String? merchantId; // Assuming it might be nullable or not always present
  final String? merchantName; // Assuming it might be nullable
  final String? imageUrl;
  final String? code;
  final String? discount; // Could be "10% off", "$5", etc.
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category;
  final bool? featured;
  final String? websiteUrl; // Added for "Visit Website" button
  final String? termsAndConditions; // Added for T&C section

  Promotion({
    required this.id,
    required this.title,
    required this.description,
    this.merchantId,
    this.merchantName,
    this.imageUrl,
    this.code,
    this.discount,
    this.startDate,
    this.endDate,
    this.category,
    this.featured,
    this.websiteUrl,
    this.termsAndConditions,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse dates
    DateTime? _parseDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) {
        return null;
      }
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing date: $dateString, Error: $e');
        }
        return null; // Return null if parsing fails
      }
    }

    return Promotion(
      // Assuming the API uses '_id', but providing fallback for 'id'
      id: json['_id'] as String? ?? json['id'] as String? ?? 'unknown_id_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'No Title',
      description: json['description'] as String? ?? 'No Description',
      merchantId: json['merchantId'] as String?,
      merchantName: json['merchantName'] as String?, // Or potentially json['merchant']['name'] if nested
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String?,
      code: json['code'] as String?,
      discount: json['discount'] as String?,
      startDate: _parseDate(json['startDate'] as String?),
      endDate: _parseDate(json['endDate'] as String?),
      category: json['category'] as String?,
      featured: json['featured'] as bool?,
      websiteUrl: json['websiteUrl'] as String?,
      termsAndConditions: json['termsAndConditions'] as String?,
    );
  }

  // Optional: toJson method if you need to send this object back to an API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'imageUrl': imageUrl,
      'code': code,
      'discount': discount,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'category': category,
      'featured': featured,
      'websiteUrl': websiteUrl,
      'termsAndConditions': termsAndConditions,
    };
  }
}
