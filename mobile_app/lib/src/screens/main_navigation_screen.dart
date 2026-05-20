import 'package:flutter/cupertino.dart';
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
  static const _navItems = <({
    IconData activeIcon,
    IconData icon,
    String Function(AppLocalizations) label,
  })>[
    (
      activeIcon: CupertinoIcons.house_fill,
      icon: CupertinoIcons.house,
      label: _homeLabel,
    ),
    (
      activeIcon: CupertinoIcons.compass_fill,
      icon: CupertinoIcons.compass,
      label: _exploreLabel,
    ),
    (
      activeIcon: Icons.storefront_rounded,
      icon: Icons.storefront_outlined,
      label: _storesLabel,
    ),
    (
      activeIcon: CupertinoIcons.heart_fill,
      icon: CupertinoIcons.heart,
      label: _favoritesLabel,
    ),
    (
      activeIcon: CupertinoIcons.person_fill,
      icon: CupertinoIcons.person,
      label: _profileLabel,
    ),
  ];

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
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      extendBody: true,
      body: _buildScreen(_selectedIndex),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFDFEFE),
                Color(0xFFF6FAFF),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2EBF5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: Color(0x0D0F4C81),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final selected = index == _selectedIndex;
              final label = item.label(localizations);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _NavigationBarItem(
                    selected: selected,
                    icon: item.icon,
                    activeIcon: item.activeIcon,
                    label: label,
                    onTap: () => _onItemTapped(index),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  static String _homeLabel(AppLocalizations l10n) => l10n.home;
  static String _exploreLabel(AppLocalizations _) => 'Explore';
  static String _storesLabel(AppLocalizations _) => 'Stores';
  static String _favoritesLabel(AppLocalizations l10n) => l10n.favorites;
  static String _profileLabel(AppLocalizations l10n) => l10n.profile;
}

class _NavigationBarItem extends StatelessWidget {
  const _NavigationBarItem({
    required this.selected,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 10 : 8,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      const Color(0xFF1976D2),
                    ],
                  )
                : null,
            color: selected ? null : Colors.transparent,
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x261E88E5),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.04 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Icon(
                  selected ? activeIcon : icon,
                  size: 21,
                  color: selected ? Colors.white : const Color(0xFF708198),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF708198),
                  letterSpacing: 0,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
