import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/promotion.dart'; // Placeholder for Promotion model
// TODO: Potentially create a User model if not already planned
// import '../models/user.dart';

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
}
