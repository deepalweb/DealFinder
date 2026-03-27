import 'package:flutter/material.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'home_screen.dart';
import 'user_profile_screen.dart';
import 'favorites_screen.dart';
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

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onNavigateToFavorites: () => setState(() => _selectedIndex = 3)),
      const DealsListScreen(),
      const StoresScreen(),
      FavoritesScreen(userId: widget.userId, token: widget.token),
      const UserProfileScreen(),
    ];
  }

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
        items: [
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 0 ? Icons.home : Icons.home_outlined),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 1 ? Icons.local_offer : Icons.local_offer_outlined),
            label: AppLocalizations.of(context)!.allDeals,
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 2 ? Icons.store : Icons.store_outlined),
            label: AppLocalizations.of(context)!.stores,
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 3 ? Icons.favorite : Icons.favorite_border),
            label: AppLocalizations.of(context)!.favorites,
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedIndex == 4 ? Icons.person : Icons.person_outline),
            label: AppLocalizations.of(context)!.profile,
          ),
        ],
      ),
    );
  }
}
