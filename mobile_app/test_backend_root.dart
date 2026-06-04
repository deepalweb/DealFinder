import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== Backend Root URL Test ===\n');
  
  final urls = [
    'https://dealfinderlk-eafsbyd7ghaph0az.southindia-01.azurewebsites.net/',
    'https://dealfinderlk-eafsbyd7ghaph0az.southindia-01.azurewebsites.net/api/',
    'https://dealfinderlk-eafsbyd7ghaph0az.southindia-01.azurewebsites.net/api/status',
    'https://dealfinderlk-eafsbyd7ghaph0az.southindia-01.azurewebsites.net/api/promotions',
    'https://dealfinderlk-eafsbyd7ghaph0az.southindia-01.azurewebsites.net/status',
    'https://dealfinderlk-eafsbyd7ghaph0az.southindia-01.azurewebsites.net/promotions',
  ];
  
  for (final url in urls) {
    await testUrl(url);
  }
  
  print('=== Test Complete ===');
}

Future<void> testUrl(String url) async {
  print('Testing: $url');
  
  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));
    
    print('Status: ${response.statusCode}');
    print('Content-Type: ${response.headers['content-type']}');
    
    if (response.body.startsWith('{') || response.body.startsWith('[')) {
      print('Response Type: JSON');
      try {
        final data = jsonDecode(response.body);
        if (data is List) {
          print('✅ Valid JSON - List with ${data.length} items');
        } else if (data is Map) {
          print('✅ Valid JSON - Object with keys: ${(data).keys.take(5).join(', ')}');
        }
      } catch (e) {
        print('⚠️ Invalid JSON: $e');
      }
    } else if (response.body.contains('<!DOCTYPE html>') || response.body.contains('<html')) {
      print('Response Type: HTML (Frontend, not API)');
    } else {
      print('Response Type: Other');
      print('First 100 chars: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}');
    }
  } catch (e) {
    print('❌ ERROR: $e');
  }
  
  print('');
}
