import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/promotion.dart';

class ApiService {
  // Using the production Azure URL as discussed.
  static const String _baseUrl = 'https://dealfinder-h0hnh3emahabaahw.southindia-01.azurewebsites.net/api/';
  // For local development, you might use:
  // static const String _baseUrl = 'http://10.0.2.2:3001/api/'; // Android emulator
  // static const String _baseUrl = 'http://localhost:3001/api/'; // iOS simulator/desktop

  Future<List<Promotion>> fetchPromotions() async {
    final response = await http.get(Uri.parse('${_baseUrl}promotions'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Promotion> promotions = body.map((dynamic item) => Promotion.fromJson(item)).toList();

      return promotions;
    } else {
      throw Exception('Failed to load promotions. Status code: ${response.statusCode}, Body: ${response.body}');
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
    }
    else {
      // For other errors, throw a generic exception.
      throw Exception('Failed to login. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> registerUser(Map<String, dynamic> userData) async {
    print('Registering user with data: $userData'); // Debug log
    print('API URL: ${_baseUrl}users/register'); // Debug log
    
    final response = await http.post(
      Uri.parse('${_baseUrl}users/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(userData),
    );
    
    print('Registration response status: ${response.statusCode}'); // Debug log
    print('Registration response body: ${response.body}'); // Debug log

    if (response.statusCode == 201) { // Registration successful
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 400) { // Bad request (e.g., validation errors, email exists)
      final errorBody = jsonDecode(response.body);
      // Backend might return specific error messages or an array of errors
      if (errorBody['errors'] != null && errorBody['errors'] is List) {
        // Join multiple validation errors if present
        String messages = (errorBody['errors'] as List).map((e) => e['msg']).join(', ');
        throw Exception(messages.isNotEmpty ? messages : 'Registration failed. Please check your input.');
      }
      throw Exception(errorBody['message'] ?? 'Registration failed. Please check your input.');
    } else {
      throw Exception('Registration failed. Status code: ${response.statusCode}, Body: ${response.body}');
    }
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
  Future<List<Map<String, dynamic>>> fetchNotifications(String userId, String token) async {
    final response = await http.get(
      Uri.parse('${_baseUrl}notifications?userId=$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  // Fetch all merchants/stores
  Future<List<Map<String, dynamic>>> fetchMerchants() async {
    final response = await http.get(Uri.parse('${_baseUrl}merchants'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load merchants');
    }
  }

  // Search promotions by query (title, description, merchant, etc.)
  Future<List<Promotion>> searchPromotions(String query) async {
    final response = await http.get(Uri.parse('${_baseUrl}promotions?search=$query'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Promotion.fromJson(item)).toList();
    } else {
      throw Exception('Failed to search promotions. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // Filter promotions by category
  Future<List<Promotion>> filterPromotionsByCategory(String category) async {
    final response = await http.get(Uri.parse('${_baseUrl}promotions?category=$category'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Promotion.fromJson(item)).toList();
    } else {
      throw Exception('Failed to filter promotions. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // Fetch comments (reviews) for a promotion
  Future<List<Map<String, dynamic>>> fetchPromotionComments(String promotionId) async {
    final response = await http.get(Uri.parse('${_baseUrl}promotions/$promotionId/comments'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load comments');
    }
  }

  // Post a comment (review) for a promotion (requires auth)
  Future<Map<String, dynamic>> postPromotionComment(String promotionId, String text, String token) async {
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
  Future<Map<String, dynamic>> postPromotionRating(String promotionId, double value, String token) async {
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

  // Fetch a single merchant by ID
  Future<Map<String, dynamic>> fetchMerchantById(String merchantId) async {
    final response = await http.get(Uri.parse('${_baseUrl}merchants/$merchantId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load merchant');
    }
  }

  // Fetch promotions by merchant ID
  Future<List<Map<String, dynamic>>> fetchPromotionsByMerchant(String merchantId) async {
    final response = await http.get(Uri.parse('${_baseUrl}promotions?merchantId=$merchantId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load promotions for merchant');
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

  // Fetch nearby promotions based on location
  Future<List<Promotion>> fetchNearbyPromotions(double lat, double lng, {double radiusKm = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}promotions/nearby?latitude=$lat&longitude=$lng&radius=$radiusKm'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        print('📍 Nearby API returned ${body.length} promotions');
        return body.map((dynamic item) => Promotion.fromJson(item)).toList();
      } else {
        print('⚠️ Nearby API failed with status ${response.statusCode}: ${response.body}');
        // Fallback to all promotions if location-based API not available
        final allPromotions = await fetchPromotions();
        return allPromotions.take(10).toList(); // Limit to 10 for nearby simulation
      }
    } catch (e) {
      print('❌ Nearby promotions error: $e');
      // Fallback to all promotions
      try {
        final allPromotions = await fetchPromotions();
        return allPromotions.take(10).toList();
      } catch (e2) {
        print('❌ Fallback promotions also failed: $e2');
        return [];
      }
    }
  }
}
