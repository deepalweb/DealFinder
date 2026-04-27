import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/promotion.dart';
import '../config/app_config.dart';
import 'cache_service.dart';

class ApiService {
  static String get _baseUrl => AppConfig.baseUrl;

  static Future<void> warmUp() async {
    try {
      await http
          .get(Uri.parse('${AppConfig.baseUrl}status'))
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  // Makes an authenticated request, auto-refreshes token on 401
  Future<http.Response> _authGet(String url) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('userToken');
    var response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode == 401) {
      token = await _refreshToken();
      if (token != null) {
        response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        ).timeout(const Duration(seconds: 30));
      }
    }
    return response;
  }

  Future<String?> _refreshToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final idToken = await user.getIdToken(true); // force refresh
      final response = await http
          .post(
            Uri.parse('${_baseUrl}users/firebase-auth'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken}),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'] as String?;
        if (newToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userToken', newToken);
          return newToken;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<Promotion>> fetchPromotions({bool forceRefresh = false}) async {
    // Check cache first unless force refresh
    if (!forceRefresh) {
      final cached = await CacheService.loadPromotions();
      if (cached != null && cached.isNotEmpty) {
        if (kDebugMode)
          print('✅ Loaded ${cached.length} promotions from cache');
        return cached;
      }
    }

    // Fetch from network
    try {
      if (kDebugMode) print('🌐 Fetching promotions from network...');
      final response = await http
          .get(Uri.parse('${_baseUrl}promotions?limit=50'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        final promotions = body.map((e) => Promotion.fromJson(e)).toList();
        try {
          await CacheService.savePromotions(promotions);
          if (kDebugMode)
            print('💾 Saved ${promotions.length} promotions to cache');
        } catch (_) {}
        return promotions;
      }
      throw Exception(
          'Failed to load promotions. Status code: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) print('❌ Network error: $e');
      final cached = await CacheService.loadPromotions(forceStale: true);
      if (cached != null) {
        if (kDebugMode)
          print('📦 Using stale cache (${cached.length} promotions)');
        return cached;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}users/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON.
      // The backend returns the user object and tokens.
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 400 || response.statusCode == 401) {
      // Specific error for invalid credentials or bad request
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Invalid email or password.');
    } else {
      // For other errors, throw a generic exception.
      throw Exception(
          'Failed to login. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> registerUser(
      Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}users/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(userData),
    );
    if (response.statusCode == 201) {
      // Registration successful
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 400) {
      // Bad request (e.g., validation errors, email exists)
      final errorBody = jsonDecode(response.body);
      // Backend might return specific error messages or an array of errors
      if (errorBody['errors'] != null && errorBody['errors'] is List) {
        // Join multiple validation errors if present
        String messages =
            (errorBody['errors'] as List).map((e) => e['msg']).join(', ');
        throw Exception(messages.isNotEmpty
            ? messages
            : 'Registration failed. Please check your input.');
      }
      throw Exception(errorBody['message'] ??
          'Registration failed. Please check your input.');
    } else {
      throw Exception(
          'Registration failed. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // Direct login (bypass Firebase) - fallback when Firebase is unavailable
  Future<Map<String, dynamic>> directLogin(
      {required String email, required String password}) async {
    try {
      if (kDebugMode) print('🔐 Attempting direct backend login for: $email');

      final response = await http
          .post(
            Uri.parse('${_baseUrl}users/login'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (kDebugMode) print('✅ Direct login successful');
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Invalid email or password.');
      } else {
        throw Exception('Login failed. Status code: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Connection timed out. Is the backend running?');
    } catch (e) {
      if (kDebugMode) print('❌ Direct login error: $e');
      rethrow;
    }
  }

  // Fetch stats: deals and merchants count
  Future<Map<String, int>> fetchStats() async {
    final results = await Future.wait([
      fetchPromotions(),
      fetchMerchants(),
    ]);
    return {
      'deals': (results[0] as List).length,
      'merchants': (results[1] as List).length,
    };
  }

  // Fetch user's favorite promotions
  Future<List<Promotion>> fetchFavorites(String userId, String token) async {
    final response = await http.get(
      Uri.parse('${_baseUrl}users/$userId/favorites'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Promotion.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load favorites');
    }
  }

  // Fetch notifications for the user (assumes /notifications?userId=...)
  Future<List<Map<String, dynamic>>> fetchNotifications(
      String userId, String token) async {
    try {
      final response =
          await _authGet('${_baseUrl}notifications?userId=$userId');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Fetch all merchants/stores
  Future<List<Map<String, dynamic>>> fetchMerchants(
      {bool forceRefresh = false}) async {
    // Check cache first unless force refresh
    if (!forceRefresh) {
      final cached = await CacheService.loadMerchants();
      if (cached != null && cached.isNotEmpty) {
        if (kDebugMode) print('✅ Loaded ${cached.length} merchants from cache');
        return cached;
      }
    }

    // Fetch from network
    try {
      if (kDebugMode) print('🌐 Fetching merchants from network...');
      final response = await http
          .get(Uri.parse('${_baseUrl}merchants'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final merchants = data.cast<Map<String, dynamic>>();
        try {
          await CacheService.saveMerchants(merchants);
          if (kDebugMode)
            print('💾 Saved ${merchants.length} merchants to cache');
        } catch (_) {}
        return merchants;
      }
      throw Exception('Failed to load merchants');
    } catch (e) {
      if (kDebugMode) print('❌ Network error: $e');
      final cached = await CacheService.loadMerchants(forceStale: true);
      if (cached != null) {
        if (kDebugMode)
          print('📦 Using stale cache (${cached.length} merchants)');
        return cached;
      }
      rethrow;
    }
  }

  // Search promotions by query (title, description, merchant, etc.)
  Future<List<Promotion>> searchPromotions(String query) async {
    final response =
        await http.get(Uri.parse('${_baseUrl}promotions?search=$query'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Promotion.fromJson(item)).toList();
    } else {
      throw Exception(
          'Failed to search promotions. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // Filter promotions by category
  Future<List<Promotion>> filterPromotionsByCategory(String category) async {
    final response =
        await http.get(Uri.parse('${_baseUrl}promotions?category=$category'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Promotion.fromJson(item)).toList();
    } else {
      throw Exception(
          'Failed to filter promotions. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // Fetch comments (reviews) for a promotion
  Future<List<Map<String, dynamic>>> fetchPromotionComments(
      String promotionId) async {
    final response = await http
        .get(Uri.parse('${_baseUrl}promotions/$promotionId/comments'));
    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      if (data is Map<String, dynamic>) {
        return [data];
      }
      return [];
    } else {
      throw Exception('Failed to load comments');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPromotionRatings(
      String promotionId) async {
    final response =
        await http.get(Uri.parse('${_baseUrl}promotions/$promotionId/ratings'));
    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      if (data is Map<String, dynamic>) {
        return [data];
      }
      return [];
    } else {
      throw Exception('Failed to load ratings');
    }
  }

  Future<Map<String, dynamic>> fetchPromotionStats(String promotionId) async {
    final response =
        await http.get(Uri.parse('${_baseUrl}promotions/$promotionId/stats'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final fallbackResponse =
        await http.get(Uri.parse('${_baseUrl}promotions/$promotionId'));
    if (fallbackResponse.statusCode == 200) {
      final data = jsonDecode(fallbackResponse.body) as Map<String, dynamic>;
      final comments = data['comments'];
      final ratings = data['ratings'];
      final commentList = comments is List ? comments : const [];
      final ratingList = ratings is List ? ratings : const [];
      final ratingValues = ratingList
          .whereType<Map<String, dynamic>>()
          .map((rating) => (rating['value'] as num?)?.toDouble())
          .whereType<double>()
          .toList();

      return {
        'commentCount': commentList.length,
        'ratingsCount': ratingList.length,
        'averageRating': ratingValues.isNotEmpty
            ? ratingValues.reduce((a, b) => a + b) / ratingValues.length
            : 0.0,
        'favoriteCount': 0,
        'clickCount': 0,
        'viewCount': 0,
        'directionCount': 0,
      };
    }

    throw Exception('Failed to load promotion stats');
  }

  // Post a comment (review) for a promotion (requires auth)
  Future<Map<String, dynamic>> postPromotionComment(
      String promotionId, String text, String token) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}promotions/$promotionId/comments'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': text}),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to post comment: ${response.body}');
    }
  }

  // Post or update a rating for a promotion (requires auth)
  Future<Map<String, dynamic>> postPromotionRating(
      String promotionId, double value, String token) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}promotions/$promotionId/ratings'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'value': value}),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to post rating: ${response.body}');
    }
  }

  Future<void> recordPromotionClick(
    String promotionId, {
    String type = 'click',
    String? token,
    String? userId,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.post(
      Uri.parse('${_baseUrl}promotions/$promotionId/click'),
      headers: headers,
      body: jsonEncode({
        'type': type,
        if (userId != null && userId.isNotEmpty) 'userId': userId,
      }),
    );

    if (response.statusCode != 201) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to record click');
    }
  }

  // Fetch a single promotion by ID
  Future<Promotion> fetchPromotionById(String id) async {
    final response = await http.get(Uri.parse('${_baseUrl}promotions/$id'));
    if (response.statusCode == 200) {
      return Promotion.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load promotion $id');
  }

  // Fetch a single merchant by ID
  Future<Map<String, dynamic>> fetchMerchantById(String merchantId) async {
    final response =
        await http.get(Uri.parse('${_baseUrl}merchants/$merchantId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load merchant');
    }
  }

  // Fetch promotions by merchant ID
  Future<List<Map<String, dynamic>>> fetchPromotionsByMerchant(
      String merchantId) async {
    final response = await http
        .get(Uri.parse('${_baseUrl}promotions?merchantId=$merchantId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load promotions for merchant');
    }
  }

  Future<List<Promotion>> fetchMerchantPromotions(String merchantId) async {
    final response = await http
        .get(Uri.parse('${_baseUrl}promotions/merchant/$merchantId'))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((item) => Promotion.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    final errorBody = jsonDecode(response.body);
    throw Exception(
        errorBody['message'] ?? 'Failed to load merchant promotions');
  }

  // Firebase Auth sync — verify Firebase ID token and get backend JWT
  Future<Map<String, dynamic>> firebaseAuthSync({
    required String idToken,
    String? name,
    String? role,
    String? businessName,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${_baseUrl}users/firebase-auth'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'idToken': idToken,
              if (name != null) 'name': name,
              if (role != null) 'role': role,
              if (businessName != null) 'businessName': businessName,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Authentication failed');
      }
    } on TimeoutException {
      throw Exception('Connection timed out. Is the backend running?');
    } catch (e) {
      rethrow;
    }
  }

  // Google Sign-In
  Future<Map<String, dynamic>> googleSignIn(String idToken) async {
    final response = await http.post(
      Uri.parse('${_baseUrl}users/google-signin'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Google Sign-In failed');
    }
  }

  Future<void> changePassword({
    required String userId,
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('userToken') ?? token;
    var response = await http
        .post(
          Uri.parse('${_baseUrl}users/$userId/change-password'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $savedToken'
          },
          body: jsonEncode(
              {'currentPassword': currentPassword, 'newPassword': newPassword}),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 401) {
      final newToken = await _refreshToken();
      if (newToken != null) {
        response = await http
            .post(
              Uri.parse('${_baseUrl}users/$userId/change-password'),
              headers: {
                'Content-Type': 'application/json; charset=UTF-8',
                'Authorization': 'Bearer $newToken'
              },
              body: jsonEncode({
                'currentPassword': currentPassword,
                'newPassword': newPassword
              }),
            )
            .timeout(const Duration(seconds: 30));
      }
    }
    if (response.statusCode == 200) return;
    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? 'Failed to change password');
  }

  Future<List<Promotion>> fetchNearbyPromotions(double lat, double lng,
      {double radiusKm = 10}) async {
    try {
      if (kDebugMode)
        print(
            '🌐 Fetching nearby deals: lat=$lat, lng=$lng, radius=${radiusKm}km');

      final url =
          '${_baseUrl}promotions/nearby?latitude=$lat&longitude=$lng&radius=$radiusKm';
      if (kDebugMode) print('📍 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
      ).timeout(
        const Duration(
            seconds:
                30), // Reduced from 60 to 30 seconds (backend now optimized)
        onTimeout: () {
          if (kDebugMode) print('⏱️ Nearby request timed out after 30 seconds');
          throw TimeoutException('The server took too long to respond');
        },
      );

      if (kDebugMode) {
        print('📡 Nearby API response: ${response.statusCode}');
        print('📦 Response body length: ${response.body.length}');
        print(
            '📄 Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        if (kDebugMode) print('✅ Loaded ${body.length} nearby promotions');
        return body.map((item) => Promotion.fromJson(item)).toList();
      }

      if (kDebugMode)
        print('❌ Nearby API returned ${response.statusCode}: ${response.body}');
      throw Exception('Server returned error: ${response.statusCode}');
    } on TimeoutException catch (e) {
      if (kDebugMode) print('⏱️ Timeout: $e');
      throw Exception(
          'Request timed out. The server might be slow or there are too many merchants to process.');
    } catch (e) {
      if (kDebugMode) print('❌ Nearby deals error: $e');
      rethrow;
    }
  }

  Future<Map<String, List<Promotion>>> fetchCuratedHomeSections() async {
    final response = await http.get(
      Uri.parse('${_baseUrl}promotions/sections'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to load curated sections');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    List<Promotion> parseList(String key) {
      final raw = data[key];
      if (raw is! List) return [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(Promotion.fromJson)
          .toList();
    }

    return {
      'banner': parseList('banner'),
      'hotDeals': parseList('hotDeals'),
      'newThisWeek': parseList('newThisWeek'),
    };
  }

  Future<List<Promotion>> fetchCuratedSection(
    String sectionKey, {
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    final query = <String, String>{};
    if (latitude != null) query['latitude'] = latitude.toString();
    if (longitude != null) query['longitude'] = longitude.toString();
    if (radiusKm != null) query['radius'] = radiusKm.toString();

    final uri = Uri.parse('${_baseUrl}promotions/sections/$sectionKey')
        .replace(queryParameters: query.isEmpty ? null : query);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Failed to load curated section');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'];
    if (items is! List) return [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(Promotion.fromJson)
        .toList();
  }

  // Notification API methods
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final response = await _authGet('${_baseUrl}notifications/preferences');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load notification preferences');
  }

  Future<void> updateNotificationPreferences(
      Map<String, dynamic> preferences) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');
    final response = await http.put(
      Uri.parse('${_baseUrl}notifications/preferences'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(preferences),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update preferences');
    }
  }

  Future<void> subscribeToNotifications(String token, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('userToken');
    final response = await http.post(
      Uri.parse('${_baseUrl}notifications/subscribe'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({'subscription': token, 'type': type}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to subscribe');
    }
  }

  Future<void> unsubscribeFromNotifications(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');
    final response = await http.post(
      Uri.parse('${_baseUrl}notifications/unsubscribe'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'type': type}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to unsubscribe');
    }
  }

  Future<void> sendTestNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');
    final response = await http.post(
      Uri.parse('${_baseUrl}notifications/test'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send test notification');
    }
  }

  // Create a new promotion (merchant only)
  Future<Map<String, dynamic>> createPromotion(
      Map<String, dynamic> promotionData, String token) async {
    final response = await http
        .post(
          Uri.parse('${_baseUrl}promotions'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(promotionData),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorBody = jsonDecode(response.body);
      if (errorBody is Map<String, dynamic>) {
        if (errorBody['errors'] is List) {
          final messages = (errorBody['errors'] as List)
              .map((e) =>
                  e is Map<String, dynamic> ? (e['msg'] ?? e['message']) : null)
              .whereType<String>()
              .join(', ');
          if (messages.isNotEmpty) {
            throw Exception(messages);
          }
        }
        throw Exception(errorBody['message'] ?? 'Failed to create promotion');
      }
      throw Exception('Failed to create promotion');
    }
  }

  Future<Map<String, dynamic>> updatePromotion(String promotionId,
      Map<String, dynamic> promotionData, String token) async {
    final response = await http
        .put(
          Uri.parse('${_baseUrl}promotions/$promotionId'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(promotionData),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final errorBody = jsonDecode(response.body);
    if (errorBody is Map<String, dynamic>) {
      if (errorBody['errors'] is List) {
        final messages = (errorBody['errors'] as List)
            .map((e) =>
                e is Map<String, dynamic> ? (e['msg'] ?? e['message']) : null)
            .whereType<String>()
            .join(', ');
        if (messages.isNotEmpty) {
          throw Exception(messages);
        }
      }
      throw Exception(errorBody['message'] ?? 'Failed to update promotion');
    }
    throw Exception('Failed to update promotion');
  }

  Future<void> deletePromotion(String promotionId, String token) async {
    final response = await http.delete(
      Uri.parse('${_baseUrl}promotions/$promotionId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return;
    }

    final errorBody = jsonDecode(response.body);
    throw Exception(errorBody['message'] ?? 'Failed to delete promotion');
  }

  // Update merchant information
  Future<Map<String, dynamic>> updateMerchant(String merchantId,
      Map<String, dynamic> merchantData, String token) async {
    final response = await http
        .put(
          Uri.parse('${_baseUrl}merchants/$merchantId'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(merchantData),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to update merchant');
    }
  }

  // Initialize merchant profile for existing merchant user
  Future<Map<String, dynamic>> initializeMerchantProfile({
    required String businessName,
    required String token,
    String? contactInfo,
    String? address,
  }) async {
    final response = await http
        .post(
          Uri.parse('${_baseUrl}users/initialize-merchant-profile'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'businessName': businessName,
            if (contactInfo != null) 'contactInfo': contactInfo,
            if (address != null) 'address': address,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(
          errorBody['message'] ?? 'Failed to initialize merchant profile');
    }
  }

  // Fetch user profile by ID
  Future<Map<String, dynamic>> fetchUserProfile(
      String userId, String token) async {
    final response = await http.get(
      Uri.parse('${_baseUrl}users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to fetch user profile');
    }
  }

  // Upload single image to Azure Blob Storage
  Future<String> uploadImage(File imageFile, String token,
      {String folder = 'images'}) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('${_baseUrl}images/upload'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['folder'] = folder;
    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['imageUrl'] as String;
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to upload image');
    }
  }

  // Upload multiple images to Azure Blob Storage
  Future<List<String>> uploadMultipleImages(List<File> imageFiles, String token,
      {String folder = 'images'}) async {
    final request = http.MultipartRequest(
        'POST', Uri.parse('${_baseUrl}images/upload-multiple'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['folder'] = folder;

    for (final file in imageFiles) {
      request.files.add(await http.MultipartFile.fromPath('images', file.path));
    }

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['imageUrls'] as List).cast<String>();
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to upload images');
    }
  }

  // Delete image from Azure Blob Storage
  Future<void> deleteImage(String imageUrl, String token) async {
    final response = await http
        .delete(
          Uri.parse('${_baseUrl}images/delete'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'imageUrl': imageUrl}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to delete image');
    }
  }
}
