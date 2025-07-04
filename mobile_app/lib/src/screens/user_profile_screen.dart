import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart'; // For logout navigation

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String _name = 'Loading...';
  String _email = 'Loading...';
  String _role = 'Loading...';
  String? _businessName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('userName') ?? 'N/A';
    _email = prefs.getString('userEmail') ?? 'N/A';
    _role = prefs.getString('userRole') ?? 'user'; // Default to 'user' if not found
    if (_role == 'merchant') {
      _businessName = prefs.getString('userBusinessName');
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    // Logout logic will be fully implemented in the next step
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userRole');
    await prefs.remove('userBusinessName');

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData, // Allows pull-to-refresh user data
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: <Widget>[
                  // User Avatar (Placeholder)
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: Icon(
                      _role == 'merchant' ? Icons.store_mall_directory : Icons.person,
                      size: 50,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow('Name', _name),
                  _buildInfoRow('Email', _email),
                  _buildInfoRow('Role', _role.capitalize()),
                  if (_role == 'merchant' && _businessName != null && _businessName!.isNotEmpty)
                    _buildInfoRow('Business Name', _businessName!),

                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      // Placeholder for Edit Profile functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit Profile tapped (Not implemented yet).')),
                      );
                    },
                    child: const Text('Edit Profile'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _logout, // Placeholder, will be implemented next
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
    );
  }
}

// Helper extension to capitalize strings
extension StringExtension on String {
    String capitalize() {
      if (isEmpty) return this;
      return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
    }
}
