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
      backgroundColor: const Color(0xFFF4F8FF),
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens!,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFDFEFE),
                Color(0xFFF6FAFF),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2EBF5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Color(0x0D0F4C81),
                blurRadius: 6,
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
  static String _exploreLabel(AppLocalizations _) => 'Deals';
  static String _storesLabel(AppLocalizations _) => 'Stores';
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
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 8 : 6,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent,
                      Color.lerp(accent, Colors.white, 0.12)!,
                    ],
                  )
                : null,
            color: selected ? null : accentSoft.withValues(alpha: 0.28),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: selected ? 14 : 8,
                height: 2.5,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.92)
                      : accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              AnimatedScale(
                scale: selected ? 1.04 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Icon(
                  selected ? activeIcon : icon,
                  size: 19,
                  color:
                      selected ? Colors.white : accent.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color:
                      selected ? Colors.white : accent.withValues(alpha: 0.86),
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
