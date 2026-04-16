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
  final String? url; // Promotion URL for "Go to Promotion" button
  final String? websiteUrl; // Added for "Visit Website" button
  final String? termsAndConditions; // Added for T&C section
  final double? price;
  final double? originalPrice;
  final double? discountedPrice;
  final String? location;
  final double? distance;
  final String? merchantLogoUrl;
  final int ratingsCount;
  final String? merchantCurrency;
  final DateTime? createdAt;

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
    this.url,
    this.websiteUrl,
    this.termsAndConditions,
    this.price,
    this.originalPrice,
    this.discountedPrice,
    this.location,
    this.distance,
    this.merchantLogoUrl,
    this.ratingsCount = 0,
    this.merchantCurrency,
    this.createdAt,
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

    // Debug: Check merchant logo
    String? logoUrl = (json['merchant'] is Map ? json['merchant']['logo'] as String? : null) ?? json['merchantLogoUrl'] as String?;
    if (kDebugMode && logoUrl != null) {
      print('✅ Logo found for ${json['title']}: $logoUrl');
    } else if (kDebugMode) {
      print('❌ No logo for ${json['title']}');
    }

    return Promotion(
      id: json['_id'] as String? ?? json['id'] as String? ?? 'unknown_id_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'No Title',
      description: json['description'] as String? ?? 'No Description',
      merchantId: json['merchantId'] as String? ?? (json['merchant'] is Map ? json['merchant']['_id'] as String? : null),
      merchantName: json['merchantName'] as String? ?? (json['merchant'] is Map ? json['merchant']['name'] as String? : null),
      merchantLogoUrl: logoUrl,
      merchantCurrency: json['merchantCurrency'] as String? ?? (json['merchant'] is Map ? json['merchant']['currency'] as String? : null),
      imageDataString: _resizeUnsplash(json['imageUrl'] as String? ?? json['image'] as String? ?? json['imageDataString'] as String?),
      code: json['code'] as String?,
      discount: json['discount'] as String?,
      startDate: parseDate(json['startDate'] as String?),
      endDate: parseDate(json['endDate'] as String?),
      category: json['category'] as String?,
      featured: json['featured'] as bool?,
      url: json['url'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      termsAndConditions: json['termsAndConditions'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      discountedPrice: (json['discountedPrice'] as num?)?.toDouble(),
      location: json['location'] as String?,
      distance: json['merchant'] is Map && json['merchant']['distance'] != null
          ? (json['merchant']['distance'] as num?)?.toDouble()
          : null,
      ratingsCount: (json['ratings'] as List?)?.length ?? 0,
      createdAt: parseDate(json['createdAt'] as String?),
    );
  }

  static String? _resizeUnsplash(String? url) {
    if (url == null) return null;
    if (url.contains('unsplash.com')) {
      return url.replaceAll(RegExp(r'w=\d+'), 'w=600').replaceAll(RegExp(r'q=\d+'), 'q=60');
    }
    return url;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'merchantLogoUrl': merchantLogoUrl,
      'imageUrl': imageDataString,
      'imageDataString': imageDataString,
      'code': code,
      'discount': discount,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'category': category,
      'featured': featured,
      'url': url,
      'websiteUrl': websiteUrl,
      'termsAndConditions': termsAndConditions,
      'price': price,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'location': location,
      'distance': distance,
      'ratings': List.generate(ratingsCount, (_) => {}),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
