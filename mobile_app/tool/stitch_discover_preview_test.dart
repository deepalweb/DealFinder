import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'package:deal_finder_mobile/src/config/app_theme.dart';
import 'package:deal_finder_mobile/src/models/promotion.dart';
import 'package:deal_finder_mobile/src/services/api_service.dart';
import 'package:deal_finder_mobile/src/services/browsing_area.dart';
import 'package:deal_finder_mobile/src/screens/home_screen.dart';
import 'package:deal_finder_mobile/src/screens/main_navigation_screen.dart';
import '../test/discover_visual_feed_test.dart' show FeedApi;
import 'groupon_preview_test.dart' show loadPreviewFonts;

final fixtureNow = DateTime.utc(2099, 1, 2, 8);

/// Fixed, labelled records; no network or database writes.
class StitchFixtureApi extends FeedApi {
  StitchFixtureApi() {
    offers = [
      _offer('banner', 'ComBank dining exclusive', 'Up to 50% off',
          bank: 'Sample Bank', minimum: 3500, featured: true),
      _offer('expiry', 'Artisan Pizza Co.', '60% off pizza',
          expiry: fixtureNow.add(const Duration(hours: 1, minutes: 42))),
      _offer('top-1', 'The Birdhouse Express', 'LKR 800 off', image: 1),
      _offer('top-2', 'Curry Pot Authentic', 'Buy 1 get 1', image: 2),
      for (var i = 0; i < 4; i++)
        _offer(
            'bank-$i',
            [
              'Burger Lab Colombo',
              'Wasabi Express',
              'Dulce Bakery & Café',
              'Ceylon Crab Kitchen'
            ][i],
            ['Buy 1 get 1', '30% off', '20% off', 'Save LKR 1,500'][i],
            image: i.isEven ? 2 : 1,
            bank: ['Sampath Bank', 'Commercial Bank', 'HNB', 'ComBank'][i]),
      _offer('more-1', 'Trattoria Bella Colombo', 'LKR 1,200 off',
          image: 1, minimum: 3000),
      _offer('more-2', 'Waffle & Sweet Co.', 'Buy 1 get 1 combo', image: 2),
      _offer('more-3', 'The Tandoori Club', '40% off dinner', image: 1),
    ];
  }
  late final List<Promotion> offers;
  Promotion _offer(String id, String name, String discount,
          {int image = 2,
          String? bank,
          double? minimum,
          bool featured = false,
          DateTime? expiry}) =>
      Promotion(
          id: id,
          merchantId: 'fixture-store',
          title: '[FIXTURE] $discount',
          merchantName: name,
          description: 'Design fixture. Not live inventory.',
          discount: discount,
          bankName: bank,
          minimumSpend: minimum,
          cardTypes: bank == null ? [] : ['credit'],
          featured: featured,
          category: 'food_dining',
          visitAvailable: true,
          latitude: 6.913 + id.length * .0002,
          longitude: 79.854,
          location: 'Colombo 03',
          averageRating: 4.8,
          ratingsCount: 120,
          endDate: expiry ?? fixtureNow.add(const Duration(days: 10)),
          imageDataString: 'assets/discover/stitch-$image.jpg');
  @override
  Future<List<Promotion>> fetchPromotions({bool forceRefresh = false}) async =>
      offers;
  @override
  Future<CuratedHomeSectionsResponse> fetchCuratedHomeSections() async =>
      CuratedHomeSectionsResponse(
          banner: [offers[0]],
          hotDeals: [offers[2], offers[3]],
          newThisWeek: [],
          flashSales: [offers[1]],
          bannerManaged: true,
          hotDealsManaged: true,
          newThisWeekManaged: false,
          flashSalesManaged: true);
}

void main() {
  testWidgets(
      'render actual Stitch Discover across reference and accessible layouts',
      (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await BrowsingArea.select(BrowsingArea.initial);
    await loadPreviewFonts(tester);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dir = Directory('design-preview/stitch-match')
      ..createSync(recursive: true);
    for (final config in [
      (390.0, 844.0, false, 1.0, 'en', 'light-390'),
      (390.0, 844.0, true, 1.0, 'en', 'dark-390'),
      (320.0, 760.0, false, 1.0, 'en', 'light-320'),
      (320.0, 760.0, true, 2.0, 'en', 'dark-320-large'),
      (390.0, 844.0, false, 2.0, 'si', 'sinhala-large'),
      (390.0, 844.0, true, 2.0, 'ta', 'tamil-large'),
    ]) {
      tester.view.physicalSize = Size(config.$1, config.$2);
      final key = GlobalKey();
      final api = StitchFixtureApi();
      final base = config.$3 ? AppTheme.darkTheme() : AppTheme.lightTheme();
      await tester.pumpWidget(MaterialApp(
          theme: base.copyWith(
              textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
              outlinedButtonTheme: OutlinedButtonThemeData(
                  style: base.outlinedButtonTheme.style?.copyWith(
                      textStyle: WidgetStateProperty.all(const TextStyle(
                          fontFamily: 'Roboto', fontSize: 12)))),
              textButtonTheme: TextButtonThemeData(
                  style: base.textButtonTheme.style?.copyWith(
                      textStyle: WidgetStateProperty.all(const TextStyle(
                          fontFamily: 'Roboto', fontSize: 12))))),
          locale: Locale(config.$5),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(config.$4), disableAnimations: true),
              child: child!),
          home: RepaintBoundary(key: key, child: MainNavigationScreen(homeScreenBuilder: (_) => HomeScreen(api: api, now: () => fixtureNow)))));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future.wait([1, 2].map((i) => precacheImage(
            AssetImage('assets/discover/stitch-$i.jpg'), key.currentContext!)));
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      Future<void> capture(String suffix) async => tester.runAsync(() async {
            final boundary = key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            final img = await boundary.toImage(pixelRatio: 2);
            final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
            File('${dir.path}/${config.$6}$suffix.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
            img.dispose();
          });
      await capture('-viewport');
      final scroll = tester.state<ScrollableState>(find
          .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable))
          .first);
      for (var i = 0; i < 3; i++) {
        scroll.position.jumpTo(scroll.position.maxScrollExtent);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      if (config.$4 == 1 && config.$1 == 390) {
        final height = scroll.position.maxScrollExtent +
            scroll.position.viewportDimension +
            68;
        scroll.position.jumpTo(0);
        tester.view.physicalSize = Size(config.$1, height.ceilToDouble());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capture('-full');
      } else {
        await capture('-bottom');
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
