import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/promotion.dart'; // Placeholder for Promotion model

class ApiService {
  // Using the production Azure URL as discussed.
  static const String _baseUrl = 'https://dealfinder-h0hnh3emahabaahw.southindia-01.azurewebsites.net/api/';

  Future<List<Promotion>> fetchPromotions() async {
    final response = await http.get(Uri.parse('${_baseUrl}promotions'));

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON.
      List<dynamic> body = jsonDecode(response.body);
      List<Promotion> promotions = body.map((dynamic item) => Promotion.fromJson(item)).toList();
      return promotions;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load promotions. Status code: ${response.statusCode}');
    }
  }
}
