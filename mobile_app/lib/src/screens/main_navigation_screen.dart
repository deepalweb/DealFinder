import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'user_profile_screen.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';
import 'deals_list_screen.dart';
import 'stores_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final String userId;
  final String token;
  const MainNavigationScreen({Key? key, required this.userId, required this.token}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(),
    DealsListScreen(), // All Deals
    StoresScreen(),    // Stores
    FavoritesScreen(userId: widget.userId, token: widget.token),
    UserProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'All Deals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Stores',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
