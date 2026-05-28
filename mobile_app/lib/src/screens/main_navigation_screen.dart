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
  final WidgetBuilder? homeScreenBuilder;
  final WidgetBuilder? dealsScreenBuilder;
  final WidgetBuilder? storesScreenBuilder;
  final WidgetBuilder? favoritesScreenBuilder;
  final WidgetBuilder? profileScreenBuilder;

  const MainNavigationScreen(
      {Key? key,
      required this.userId,
      required this.token,
      this.homeScreenBuilder,
      this.dealsScreenBuilder,
      this.storesScreenBuilder,
      this.favoritesScreenBuilder,
      this.profileScreenBuilder})
      : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  List<Widget>? _screens;
  static const _navItems = <({
    IconData activeIcon,
    Color accent,
    Color accentSoft,
    IconData icon,
    String Function(AppLocalizations) label,
  })>[
    (
      activeIcon: CupertinoIcons.house_fill,
      accent: Color(0xFF2563EB),
      accentSoft: Color(0xFFE0EEFF),
      icon: CupertinoIcons.house,
      label: _homeLabel,
    ),
    (
      activeIcon: CupertinoIcons.compass_fill,
      accent: Color(0xFF7C3AED),
      accentSoft: Color(0xFFF1E7FF),
      icon: CupertinoIcons.compass,
      label: _exploreLabel,
    ),
    (
      activeIcon: Icons.storefront_rounded,
      accent: Color(0xFF059669),
      accentSoft: Color(0xFFE0F7EF),
      icon: Icons.storefront_outlined,
      label: _storesLabel,
    ),
    (
      activeIcon: CupertinoIcons.heart_fill,
      accent: Color(0xFFE11D48),
      accentSoft: Color(0xFFFFE3EB),
      icon: CupertinoIcons.heart,
      label: _favoritesLabel,
    ),
    (
      activeIcon: CupertinoIcons.person_fill,
      accent: Color(0xFFF59E0B),
      accentSoft: Color(0xFFFFF1CC),
      icon: CupertinoIcons.person,
      label: _profileLabel,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screens ??= [
      widget.homeScreenBuilder?.call(context) ??
          HomeScreen(
            onNavigateToFavorites: () => setState(() => _selectedIndex = 3),
          ),
      widget.dealsScreenBuilder?.call(context) ?? const AllDealsScreen(),
      widget.storesScreenBuilder?.call(context) ?? const StoresScreen(),
      widget.favoritesScreenBuilder?.call(context) ??
          FavoritesScreen(userId: widget.userId, token: widget.token),
      widget.profileScreenBuilder?.call(context) ?? const UserProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens!,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xF7FFFFFF),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFD9DDE6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 20,
                offset: Offset(0, 10),
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
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: _NavigationBarItem(
                    selected: selected,
                    icon: item.icon,
                    activeIcon: item.activeIcon,
                    accent: item.accent,
                    accentSoft: item.accentSoft,
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
  static String _exploreLabel(AppLocalizations l10n) => l10n.deals;
  static String _storesLabel(AppLocalizations l10n) => l10n.stores;
  static String _favoritesLabel(AppLocalizations l10n) => l10n.favorites;
  static String _profileLabel(AppLocalizations l10n) => l10n.profile;
}

class _NavigationBarItem extends StatelessWidget {
  const _NavigationBarItem({
    required this.selected,
    required this.icon,
    required this.activeIcon,
    required this.accent,
    required this.accentSoft,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData activeIcon;
  final Color accent;
  final Color accentSoft;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 8 : 6,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color:
                selected ? accentSoft.withValues(alpha: 0.92) : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: selected ? 18 : 0,
                height: selected ? 3 : 0,
                margin: EdgeInsets.only(bottom: selected ? 5 : 3),
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.92)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              AnimatedScale(
                scale: selected ? 1.02 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Icon(
                  selected ? activeIcon : icon,
                  size: 19,
                  color: selected ? accent : const Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? accent : const Color(0xFF8E8E93),
                  letterSpacing: -0.1,
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
