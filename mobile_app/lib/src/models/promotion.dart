import 'package:flutter/foundation.dart';

class Promotion {
  final String id;
  final String title;
  final String description;
  final String? merchantId; // Assuming it might be nullable or not always present
  final String? merchantName; // Assuming it might be nullable
  final String? imageDataString; // Changed from imageUrl to hold Base64 string or a regular URL
  final String? code;
  final String? discount; // Could be "10% off", "$5", etc.
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category;
  final bool? featured;
  final String? websiteUrl; // Added for "Visit Website" button
  final String? termsAndConditions; // Added for T&C section
  final double? price;
  final double? originalPrice;
  final double? discountedPrice;

  Promotion({
    required this.id,
    required this.title,
    required this.description,
    this.merchantId,
    this.merchantName,
    this.imageDataString,
    this.code,
    this.discount,
    this.startDate,
    this.endDate,
    this.category,
    this.featured,
    this.websiteUrl,
    this.termsAndConditions,
    this.price,
    this.originalPrice,
    this.discountedPrice,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse dates
    DateTime? parseDate(String? dateString) {
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
      // Assuming the API might send 'imageUrl' or 'image' for either Base64 or a URL.
      // If it's specifically for Base64, the API field name might be different.
      imageDataString: json['imageUrl'] as String? ?? json['image'] as String?,
      code: json['code'] as String?,
      discount: json['discount'] as String?,
      startDate: parseDate(json['startDate'] as String?),
      endDate: parseDate(json['endDate'] as String?),
      category: json['category'] as String?,
      featured: json['featured'] as bool?,
      websiteUrl: json['websiteUrl'] as String?,
      termsAndConditions: json['termsAndConditions'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      discountedPrice: (json['discountedPrice'] as num?)?.toDouble(),
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
      'imageDataString': imageDataString,
      'code': code,
      'discount': discount,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'category': category,
      'featured': featured,
      'websiteUrl': websiteUrl,
      'termsAndConditions': termsAndConditions,
      'price': price,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
    };
  }
}
