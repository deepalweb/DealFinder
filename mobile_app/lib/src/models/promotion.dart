import 'package:flutter/foundation.dart';

class Promotion {
  static const Duration _colomboOffset = Duration(hours: 5, minutes: 30);

  final String id;
  final String title;
  final String description;
  final String?
      merchantId; // Assuming it might be nullable or not always present
  final String? merchantName; // Assuming it might be nullable
  final String?
      imageDataString; // Changed from imageUrl to hold Base64 string or a regular URL
  final String? code;
  final String? discount; // Could be "10% off", "$5", etc.
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category;
  final bool? featured;
  final String? url; // Promotion URL for "Go to Promotion" button
  final String? websiteUrl; // Added for "Visit Website" button
  final String? orderLink;
  final String? termsAndConditions; // Added for T&C section
  final double? price;
  final double? originalPrice;
  final double? discountedPrice;
  final String? location;
  final double? distance;
  final double? latitude;
  final double? longitude;
  final String? merchantLogoUrl;
  final double? averageRating;
  final int ratingsCount;
  final String? merchantCurrency;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? status;
  final String? fulfillmentType;
  final bool visitAvailable;
  final bool deliveryAvailable;
  final bool pickupAvailable;
  final String? merchantType;
  final bool merchantDeliveryAvailable;
  final bool merchantPickupAvailable;
  final String? merchantOrderLink;
  final String? bankName;
  final List<String> cardTypes;
  final String? offerType;
  final double? minimumSpend;
  final double? maximumBenefit;

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
    this.orderLink,
    this.termsAndConditions,
    this.price,
    this.originalPrice,
    this.discountedPrice,
    this.location,
    this.distance,
    this.latitude,
    this.longitude,
    this.merchantLogoUrl,
    this.averageRating,
    this.ratingsCount = 0,
    this.merchantCurrency,
    this.createdAt,
    this.updatedAt,
    this.status,
    this.fulfillmentType,
    this.visitAvailable = true,
    this.deliveryAvailable = false,
    this.pickupAvailable = false,
    this.merchantType,
    this.merchantDeliveryAvailable = false,
    this.merchantPickupAvailable = false,
    this.merchantOrderLink,
    this.bankName,
    this.cardTypes = const [],
    this.offerType,
    this.minimumSpend,
    this.maximumBenefit,
  });

  // Safe discount percentage calculation
  int? get discountPercentage {
    if (originalPrice == null ||
        discountedPrice == null ||
        originalPrice! <= 0) {
      return null;
    }
    return ((originalPrice! - discountedPrice!) / originalPrice! * 100).round();
  }

  static DateTime _colomboNow() {
    final nowUtc = DateTime.now().toUtc();
    return nowUtc.add(_colomboOffset);
  }

  static DateTime _startOfColomboDay([DateTime? reference]) {
    final colombo = reference ?? _colomboNow();
    return DateTime.utc(colombo.year, colombo.month, colombo.day)
        .subtract(_colomboOffset);
  }

  static DateTime _endOfColomboDayExclusive([DateTime? reference]) {
    return _startOfColomboDay(reference).add(const Duration(days: 1));
  }

  bool get hasStarted {
    final endExclusive = _endOfColomboDayExclusive();
    return startDate == null || startDate!.isBefore(endExclusive);
  }

  bool get isExpired {
    final start = _startOfColomboDay();
    return endDate != null && endDate!.isBefore(start);
  }

  bool get hasVerifiedActiveStatus {
    final normalized = status?.trim().toLowerCase();
    return normalized == 'active' ||
        normalized == 'scheduled' ||
        normalized == 'approved' ||
        normalized == 'pending_approval';
  }

  bool get isVerifiedActiveDeal {
    return hasVerifiedActiveStatus && hasStarted && !isExpired;
  }

  DateTime get latestActivityAt =>
      updatedAt ?? createdAt ?? startDate ?? DateTime(1970);

  bool get supportsVisit {
    if (fulfillmentType == 'order') return visitAvailable;
    if (fulfillmentType == 'hybrid') return visitAvailable;
    return visitAvailable;
  }

  bool get supportsDelivery => deliveryAvailable || merchantDeliveryAvailable;

  bool get supportsPickup => pickupAvailable || merchantPickupAvailable;

  String get effectiveMerchantType {
    final raw = merchantType?.trim().toLowerCase();
    if (raw == 'online' || raw == 'hybrid' || raw == 'offline') {
      return raw!;
    }
    if (fulfillmentType == 'order') return 'online';
    if (fulfillmentType == 'hybrid') return 'hybrid';
    return 'offline';
  }

  String? get effectiveOrderLink {
    final candidate =
        (orderLink ?? merchantOrderLink ?? websiteUrl ?? url)?.trim();
    if (candidate == null || candidate.isEmpty) return null;
    return candidate;
  }

  factory Promotion.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse dates
    DateTime? parseDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) {
        return null;
      }
      try {
        final parsed = DateTime.parse(dateString);
        return parsed.isUtc ? parsed.toLocal() : parsed;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error parsing date: $dateString, Error: $e');
        }
        return null; // Return null if parsing fails
      }
    }

    String? logoUrl = (json['merchant'] is Map
            ? json['merchant']['logo'] as String?
            : null) ??
        json['merchantLogoUrl'] as String?;
    final merchantData = json['merchant'] is Map<String, dynamic>
        ? json['merchant'] as Map<String, dynamic>
        : null;
    final merchantType =
        (merchantData?['merchantType'] ?? json['merchantType']) as String?;
    final merchantLocation = merchantData?['location'] is Map<String, dynamic>
        ? merchantData!['location'] as Map<String, dynamic>
        : null;
    final coordinates = merchantLocation?['coordinates'] is List
        ? merchantLocation!['coordinates'] as List
        : null;

    double? latitude;
    double? longitude;

    if (coordinates != null && coordinates.length >= 2) {
      longitude = (coordinates[0] as num?)?.toDouble();
      latitude = (coordinates[1] as num?)?.toDouble();
    } else {
      latitude = (merchantLocation?['latitude'] as num?)?.toDouble() ??
          (json['latitude'] as num?)?.toDouble();
      longitude = (merchantLocation?['longitude'] as num?)?.toDouble() ??
          (json['longitude'] as num?)?.toDouble();
    }
    return Promotion(
      id: json['_id'] as String? ??
          json['id'] as String? ??
          'unknown_id_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'No Title',
      description: json['description'] as String? ?? 'No Description',
      merchantId: json['merchantId'] as String? ??
          (json['merchant'] is Map ? json['merchant']['_id'] as String? : null),
      merchantName: json['merchantName'] as String? ??
          (json['merchant'] is Map
              ? json['merchant']['name'] as String?
              : null),
      merchantLogoUrl: logoUrl,
      merchantCurrency: json['merchantCurrency'] as String? ??
          (json['merchant'] is Map
              ? json['merchant']['currency'] as String?
              : null),
      imageDataString: _resizeUnsplash(json['sectionImage'] as String? ??
          json['imageUrl'] as String? ??
          json['image'] as String? ??
          json['imageDataString'] as String?),
      code: json['code'] as String?,
      discount: json['discount'] as String?,
      startDate: parseDate(json['startDate'] as String?),
      endDate: parseDate(json['endDate'] as String?),
      category: json['category'] as String?,
      featured: json['featured'] as bool?,
      url: json['url'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      orderLink: (json['orderLink'] as String?) ??
          (merchantData?['orderLink'] as String?),
      termsAndConditions: json['termsAndConditions'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      discountedPrice: (json['discountedPrice'] as num?)?.toDouble(),
      location: json['location'] as String?,
      distance: merchantData != null && merchantData['distance'] != null
          ? (merchantData['distance'] as num?)?.toDouble()
          : null,
      latitude: latitude,
      longitude: longitude,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      ratingsCount: json['ratings'] is List
          ? (json['ratings'] as List).length
          : (json['ratingsCount'] is int ? json['ratingsCount'] as int : 0),
      createdAt: parseDate(json['createdAt'] as String?),
      updatedAt: parseDate(json['updatedAt'] as String?),
      status: json['status'] as String?,
      fulfillmentType: json['fulfillmentType'] as String?,
      visitAvailable: json['visitAvailable'] as bool? ?? true,
      deliveryAvailable: json['deliveryAvailable'] as bool? ?? false,
      pickupAvailable: json['pickupAvailable'] as bool? ?? false,
      merchantType: merchantType,
      merchantDeliveryAvailable:
          merchantData?['deliveryAvailable'] as bool? ?? false,
      merchantPickupAvailable:
          merchantData?['pickupAvailable'] as bool? ?? false,
      merchantOrderLink: merchantData?['orderLink'] as String?,
      bankName: json['bankName'] as String?,
      cardTypes: (json['cardTypes'] as List?)
              ?.whereType<String>()
              .map((type) => type.trim().toLowerCase())
              .where((type) => type.isNotEmpty)
              .toList() ??
          const [],
      offerType: json['offerType'] as String?,
      minimumSpend: (json['minimumSpend'] as num?)?.toDouble(),
      maximumBenefit: (json['maximumBenefit'] as num?)?.toDouble(),
    );
  }

  static String? _resizeUnsplash(String? url) {
    if (url == null) return null;
    if (url.contains('unsplash.com')) {
      return url
          .replaceAll(RegExp(r'w=\d+'), 'w=600')
          .replaceAll(RegExp(r'q=\d+'), 'q=60');
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
      'orderLink': orderLink,
      'termsAndConditions': termsAndConditions,
      'price': price,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'location': location,
      'distance': distance,
      'latitude': latitude,
      'longitude': longitude,
      'averageRating': averageRating,
      'ratings': List.generate(ratingsCount, (_) => {}),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status,
      'fulfillmentType': fulfillmentType,
      'visitAvailable': visitAvailable,
      'deliveryAvailable': deliveryAvailable,
      'pickupAvailable': pickupAvailable,
      'merchantType': merchantType,
      'merchantOrderLink': merchantOrderLink,
      'merchantDeliveryAvailable': merchantDeliveryAvailable,
      'merchantPickupAvailable': merchantPickupAvailable,
      'bankName': bankName,
      'cardTypes': cardTypes,
      'offerType': offerType,
      'minimumSpend': minimumSpend,
      'maximumBenefit': maximumBenefit,
    };
  }

  Promotion copyWith({
    String? id,
    String? title,
    String? description,
    String? merchantId,
    String? merchantName,
    String? imageDataString,
    String? code,
    String? discount,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    bool? featured,
    String? url,
    String? websiteUrl,
    String? orderLink,
    String? termsAndConditions,
    double? price,
    double? originalPrice,
    double? discountedPrice,
    String? location,
    double? distance,
    double? latitude,
    double? longitude,
    String? merchantLogoUrl,
    double? averageRating,
    int? ratingsCount,
    String? merchantCurrency,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? fulfillmentType,
    bool? visitAvailable,
    bool? deliveryAvailable,
    bool? pickupAvailable,
    String? merchantType,
    bool? merchantDeliveryAvailable,
    bool? merchantPickupAvailable,
    String? merchantOrderLink,
    String? bankName,
    List<String>? cardTypes,
    String? offerType,
    double? minimumSpend,
    double? maximumBenefit,
  }) {
    return Promotion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      imageDataString: imageDataString ?? this.imageDataString,
      code: code ?? this.code,
      discount: discount ?? this.discount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      featured: featured ?? this.featured,
      url: url ?? this.url,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      orderLink: orderLink ?? this.orderLink,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      location: location ?? this.location,
      distance: distance ?? this.distance,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      merchantLogoUrl: merchantLogoUrl ?? this.merchantLogoUrl,
      averageRating: averageRating ?? this.averageRating,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      merchantCurrency: merchantCurrency ?? this.merchantCurrency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      fulfillmentType: fulfillmentType ?? this.fulfillmentType,
      visitAvailable: visitAvailable ?? this.visitAvailable,
      deliveryAvailable: deliveryAvailable ?? this.deliveryAvailable,
      pickupAvailable: pickupAvailable ?? this.pickupAvailable,
      merchantType: merchantType ?? this.merchantType,
      merchantDeliveryAvailable:
          merchantDeliveryAvailable ?? this.merchantDeliveryAvailable,
      merchantPickupAvailable:
          merchantPickupAvailable ?? this.merchantPickupAvailable,
      merchantOrderLink: merchantOrderLink ?? this.merchantOrderLink,
      bankName: bankName ?? this.bankName,
      cardTypes: cardTypes ?? this.cardTypes,
      offerType: offerType ?? this.offerType,
      minimumSpend: minimumSpend ?? this.minimumSpend,
      maximumBenefit: maximumBenefit ?? this.maximumBenefit,
    );
  }
}
