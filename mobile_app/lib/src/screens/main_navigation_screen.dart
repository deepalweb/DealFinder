import 'package:flutter/material.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'home_screen.dart';
import 'user_profile_screen.dart';
import 'favorites_screen.dart';
import 'all_deals_screen.dart';
import 'stores_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final String userId;
  final String token;
  const MainNavigationScreen(
      {Key? key, required this.userId, required this.token})
      : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final List<int> _screenVersions = List<int>.filled(5, 0);

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index <= 2) {
        _screenVersions[index] += 1;
      }
      _selectedIndex = index;
    });
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return KeyedSubtree(
          key: ValueKey('home-${_screenVersions[0]}'),
          child: HomeScreen(
            onNavigateToFavorites: () => setState(() => _selectedIndex = 3),
          ),
        );
      case 1:
        return KeyedSubtree(
          key: ValueKey('all-deals-${_screenVersions[1]}'),
          child: const AllDealsScreen(),
        );
      case 2:
        return KeyedSubtree(
          key: ValueKey('stores-${_screenVersions[2]}'),
          child: const StoresScreen(),
        );
      case 3:
        return FavoritesScreen(userId: widget.userId, token: widget.token);
      case 4:
      default:
        return const UserProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreen(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 0 ? Icons.home : Icons.home_outlined),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(
                _selectedIndex == 1 ? Icons.explore : Icons.explore_outlined),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon:
                Icon(_selectedIndex == 2 ? Icons.store : Icons.store_outlined),
            label: 'Stores',
          ),
          BottomNavigationBarItem(
            icon: Icon(
                _selectedIndex == 3 ? Icons.favorite : Icons.favorite_border),
            label: AppLocalizations.of(context)!.favorites,
          ),
          BottomNavigationBarItem(
            icon:
                Icon(_selectedIndex == 4 ? Icons.person : Icons.person_outline),
            label: AppLocalizations.of(context)!.profile,
          ),
        ],
      ),
    );
  }
}
