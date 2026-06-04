import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== Backend Connection Test ===\n');
  
  // Test production backend
  const productionUrl = 'https://dealfinderlk-eafsbyd7ghaph0az.southindia-01.azurewebsites.net/api/';
  
  print('Testing: $productionUrl');
  print('');
  
  // Test 1: Status endpoint
  await testEndpoint(
    '${productionUrl}status',
    'Status Check',
  );
  
  // Test 2: Promotions endpoint
  await testEndpoint(
    '${productionUrl}promotions?limit=5',
    'Fetch Promotions',
  );
  
  // Test 3: Merchants endpoint
  await testEndpoint(
    '${productionUrl}merchants',
    'Fetch Merchants',
  );
  
  // Test 4: Bank offers endpoint
  await testEndpoint(
    '${productionUrl}bank-offers?limit=5',
    'Fetch Bank Offers',
  );
  
  print('\n=== Test Complete ===');
}

Future<void> testEndpoint(String url, String name) async {
  print('Testing: $name');
  print('URL: $url');
  
  try {
    final stopwatch = Stopwatch()..start();
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));
    
    stopwatch.stop();
    
    print('Status: ${response.statusCode}');
    print('Time: ${stopwatch.elapsedMilliseconds}ms');
    
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data is List) {
          print('Result: ✅ SUCCESS - Received ${data.length} items');
        } else if (data is Map) {
          print('Result: ✅ SUCCESS - Received data object');
          print('Keys: ${(data).keys.join(', ')}');
        } else {
          print('Result: ✅ SUCCESS - Received data');
        }
      } catch (e) {
        print('Result: ⚠️ SUCCESS but invalid JSON: $e');
      }
    } else {
      print('Result: ❌ FAILED - ${response.statusCode}');
      print('Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
    }
  } catch (e) {
    print('Result: ❌ ERROR - $e');
  }
  
  print('');
}
