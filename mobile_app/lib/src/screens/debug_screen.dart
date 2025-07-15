import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:http/http.dart' as http;

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _debugInfo = 'Tap "Test API" to check connection...';
  bool _isLoading = false;

  Future<void> _testAPI() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Testing API connection...';
    });

    try {
      // Test direct HTTP call first
      final response = await http.get(
        Uri.parse('https://dealfinder-h0hnh3emahabaahw.southindia-01.azurewebsites.net/api/promotions'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      String result = 'Direct HTTP Test:\n';
      result += 'Status Code: ${response.statusCode}\n';
      result += 'Response Length: ${response.body.length} chars\n';
      result += 'Headers: ${response.headers}\n\n';

      if (response.statusCode == 200) {
        result += 'Response Preview:\n${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...\n\n';
        
        // Now test API service
        try {
          final apiService = ApiService();
          final promotions = await apiService.fetchPromotions();
          result += 'API Service Test:\n';
          result += 'Promotions Count: ${promotions.length}\n';
          if (promotions.isNotEmpty) {
            result += 'First Promotion:\n';
            result += 'ID: ${promotions.first.id}\n';
            result += 'Title: ${promotions.first.title}\n';
            result += 'Description: ${promotions.first.description}\n';
          }
        } catch (apiError) {
          result += 'API Service Error: $apiError\n';
        }
      } else {
        result += 'HTTP Error: ${response.body}\n';
      }

      setState(() {
        _debugInfo = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugInfo = 'Connection Error: $e\n\nPossible issues:\n1. No internet connection\n2. Backend server is down\n3. Firewall blocking requests';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug API'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testAPI,
              child: _isLoading 
                ? const CircularProgressIndicator()
                : const Text('Test API'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugInfo,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}