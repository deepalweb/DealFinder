import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'package:deal_finder_mobile/src/config/app_theme.dart';
import 'package:deal_finder_mobile/src/models/promotion.dart';
import 'package:deal_finder_mobile/src/screens/main_navigation_screen.dart';
import 'package:deal_finder_mobile/src/widgets/app_search_field.dart';
import 'package:deal_finder_mobile/src/widgets/modern_deal_card.dart';
import 'package:deal_finder_mobile/src/widgets/merchant_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {bool dark = false, double scale = 1}) => MaterialApp(
      theme: dark ? AppTheme.darkTheme() : AppTheme.lightTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: child,
    );

MainNavigationScreen navigation() => MainNavigationScreen(
      userId: 'demo',
      token: 'demo',
      homeScreenBuilder: (_) => const Text('Home content'),
      nearbyScreenBuilder: (_) => const Text('Deals content'),
      bankOffersScreenBuilder: (_) => const Text('Stores content'),
      favoritesScreenBuilder: (_) => const Text('Favorites content'),
      profileScreenBuilder: (_) => const Text('Profile content'),
    );

void main() {
  testWidgets('store carousel fits its compact card and keeps actions working',
      (tester) async {
    var opened = false;
    var followed = false;
    await tester.pumpWidget(host(
        Scaffold(
            body: Center(
                child: SizedBox(
          width: 288,
          height: 380,
          child: MerchantCard(
            merchant: const {
              'name': 'A local cafe',
              'category': 'food_dining',
              'address': 'Colombo 03, Sri Lanka',
              'activeDeals': 2
            },
            compact: true,
            isFollowing: false,
            onVisit: () => opened = true,
            onFollowToggle: () => followed = true,
            onShare: () {},
          ),
        ))),
        dark: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('View store'));
    expect(opened, isTrue);
    await tester.tap(find.text('Follow'));
    expect(followed, isTrue);
  });

  testWidgets('Sinhala section actions and cards use localized labels',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('si'),
      theme: AppTheme.lightTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
      home: Scaffold(
          body: MerchantCard(
              merchant: const {'name': 'Sample'},
              isFollowing: false,
              onVisit: () {},
              onFollowToggle: () {},
              onShare: () {})),
    ));
    await tester.pumpAndSettle();
    expect(find.text('වෙළඳසැල බලන්න'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow dark navigation remains usable at double text size',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(navigation(), dark: true, scale: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nearby'));
    await tester.pumpAndSettle();
    expect(find.text('Deals content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet uses a navigation rail with working destinations',
      (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(navigation()));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    await tester.tap(find.text('Bank Offers'));
    await tester.pumpAndSettle();
    expect(find.text('Stores content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'search clears an internally owned controller and notifies filters',
      (tester) async {
    String? lastQuery;
    await tester.pumpWidget(host(Scaffold(
        body: AppSearchField(onChanged: (value) => lastQuery = value))));
    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pump();
    expect(lastQuery, 'coffee');
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(lastQuery, '');
    expect(find.text('coffee'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'compact deal card supports dark mode and large text without an image',
      (tester) async {
    await tester.pumpWidget(host(
        Scaffold(
            body: Center(
                child: SizedBox(
          width: 184,
          child: ModernDealCard(
              promotion: Promotion(
            id: 'demo',
            title: 'Coffee and cake for two with a generous discount',
            description: 'Sample',
            merchantName: 'A local cafe',
            originalPrice: 1600,
            discountedPrice: 1200,
            discount: '25%',
          )),
        ))),
        dark: true,
        scale: 2));
    await tester.pumpAndSettle();
    expect(find.text('Rs. 1200'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
