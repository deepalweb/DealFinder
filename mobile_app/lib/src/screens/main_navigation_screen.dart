import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'home_screen.dart';
import 'user_profile_screen.dart';
import 'favorites_screen.dart';
import 'all_deals_screen.dart';
import 'stores_screen.dart';
import 'nearby_deals_screen.dart';
import '../services/app_session.dart';
import '../widgets/sign_in_gate.dart';
import '../widgets/stitch_discover_components.dart' show stitchDiscoverTheme;

class MainNavigationScreen extends StatefulWidget {
  final String userId;
  final String token;
  final WidgetBuilder? homeScreenBuilder;
  final WidgetBuilder? nearbyScreenBuilder;
  final WidgetBuilder? storesScreenBuilder;
  final WidgetBuilder? favoritesScreenBuilder;
  final WidgetBuilder? profileScreenBuilder;

  const MainNavigationScreen(
      {Key? key,
      this.userId = '',
      this.token = '',
      this.homeScreenBuilder,
      this.nearbyScreenBuilder,
      this.storesScreenBuilder,
      this.favoritesScreenBuilder,
      this.profileScreenBuilder})
      : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  late AppSession _session;
  final _navigatorKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());
  final _visited = <int>{0};

  @override
  void initState() {
    super.initState();
    _session = AppSession(userId: widget.userId, token: widget.token);
    AppSession.changes.addListener(_sessionChanged);
  }

  @override
  void dispose() {
    AppSession.changes.removeListener(_sessionChanged);
    super.dispose();
  }

  void _sessionChanged() {
    if (!mounted) return;
    final next = AppSession.changes.value;
    if (next.userId == _session.userId && next.token == _session.token) return;
    setState(() {
      _session = next;
      // Private routes belong to one account. Public route stacks stay intact.
      _navigatorKeys[3] = GlobalKey<NavigatorState>();
      _navigatorKeys[4] = GlobalKey<NavigatorState>();
    });
  }

  Widget _destination(int index, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (index) {
      case 0:
        return widget.homeScreenBuilder?.call(context) ??
            HomeScreen(
              onNavigateToFavorites: () => _selectTab(3),
              onNavigateNearby: () => _selectTab(1),
              onNavigateAccount: () => _selectTab(4),
              onNavigateBankOffers: _openBankOffers,
            );
      case 1:
        return widget.nearbyScreenBuilder?.call(context) ??
            NearbyDealsScreen(onNavigateAccount: () => _selectTab(4));
      case 2:
        return widget.storesScreenBuilder?.call(context) ??
            const StoresScreen();
      case 3:
        return widget.favoritesScreenBuilder?.call(context) ??
            (_session.isSignedIn
                ? FavoritesScreen(
                    userId: _session.userId, token: _session.token)
                : SignInGate(title: l10n.savedTab));
      default:
        return widget.profileScreenBuilder?.call(context) ??
            (_session.isSignedIn
                ? const UserProfileScreen()
                : SignInGate(title: l10n.accountTab));
    }
  }

  void _openBankOffers(String? bank) {
    _navigatorKeys[0].currentState?.push(MaterialPageRoute(
        settings: const RouteSettings(name: '/bank-offers'),
        builder: (_) => AllDealsScreen(
            bankOffersOnly: true,
            initialBankName: bank,
            initialContextTitle: AppLocalizations.of(context)!.bankOffersTab)));
  }

  Widget _tab(int index) {
    if (!_visited.contains(index)) return const SizedBox.shrink();
    return NavigatorPopHandler<Object?>(
      enabled: index == _selectedIndex,
      onPopWithResult: (result) =>
          _navigatorKeys[index].currentState!.maybePop(result),
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (context) => _destination(index, context),
        ),
      ),
    );
  }

  static const _navItems = <({
    IconData activeIcon,
    Color accent,
    Color accentSoft,
    IconData icon,
    String Function(AppLocalizations) label,
  })>[
    (
      activeIcon: CupertinoIcons.compass_fill,
      accent: Color(0xFF2563EB),
      accentSoft: Color(0xFFE0EEFF),
      icon: CupertinoIcons.compass,
      label: _homeLabel,
    ),
    (
      activeIcon: CupertinoIcons.location_fill,
      accent: Color(0xFF7C3AED),
      accentSoft: Color(0xFFF1E7FF),
      icon: CupertinoIcons.location,
      label: _exploreLabel,
    ),
    (
      activeIcon: Icons.storefront,
      accent: Color(0xFF059669),
      accentSoft: Color(0xFFE0F7EF),
      icon: Icons.storefront_outlined,
      label: _storesLabel,
    ),
    (
      activeIcon: CupertinoIcons.bookmark_fill,
      accent: Color(0xFFE11D48),
      accentSoft: Color(0xFFFFE3EB),
      icon: CupertinoIcons.bookmark,
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

  void _onItemTapped(int index) => _selectTab(index);

  void _selectTab(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _visited.add(index);
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final screens =
        IndexedStack(index: _selectedIndex, children: List.generate(5, _tab));
    if (wide) {
      return Scaffold(
          body: SafeArea(
              child: Row(children: [
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _selectTab,
          labelType: NavigationRailLabelType.all,
          backgroundColor: theme.colorScheme.surface,
          destinations: _navItems
              .map((item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.activeIcon),
                    label: Text(item.label(l10n)),
                  ))
              .toList(),
        ),
        VerticalDivider(width: 1, color: theme.colorScheme.outlineVariant),
        Expanded(child: screens),
      ])));
    }
    final navigation = NavigationBar(
      height: _selectedIndex <= 1
          ? (MediaQuery.textScalerOf(context).scale(16) > 24 ? 104 : 68)
          : null,
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      destinations: _navItems
          .map((item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon),
              label: item.label(l10n)))
          .toList(),
    );
    final discoverTheme = stitchDiscoverTheme(theme);
    return Scaffold(
      body: screens,
      bottomNavigationBar: _selectedIndex > 1
          ? navigation
          : Theme(
              data: discoverTheme.copyWith(
                  navigationBarTheme: discoverTheme.navigationBarTheme.copyWith(
                backgroundColor: discoverTheme.colorScheme.surfaceContainerLow,
                indicatorColor: Colors.transparent,
                iconTheme: WidgetStateProperty.resolveWith((states) =>
                    IconThemeData(
                        size: 22,
                        color: states.contains(WidgetState.selected)
                            ? discoverTheme.colorScheme.primary
                            : discoverTheme.colorScheme.onSurfaceVariant)),
                labelTextStyle: WidgetStateProperty.resolveWith((states) =>
                    theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: states.contains(WidgetState.selected)
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: states.contains(WidgetState.selected)
                            ? discoverTheme.colorScheme.primary
                            : discoverTheme.colorScheme.onSurfaceVariant)),
              )),
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color:
                                  discoverTheme.colorScheme.outlineVariant))),
                  child: navigation)),
    );
  }

  static String _homeLabel(AppLocalizations l10n) => l10n.discoverTab;
  static String _exploreLabel(AppLocalizations l10n) => l10n.nearbyTab;
  static String _storesLabel(AppLocalizations l10n) => l10n.stores;
  static String _favoritesLabel(AppLocalizations l10n) => l10n.savedTab;
  static String _profileLabel(AppLocalizations l10n) => l10n.accountTab;
}
