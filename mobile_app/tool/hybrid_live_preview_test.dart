// Live widgets with isolated fixtures; no API/database mutations.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'package:deal_finder_mobile/src/config/app_theme.dart';
import 'package:deal_finder_mobile/src/models/promotion.dart';
import 'package:deal_finder_mobile/src/screens/home_screen.dart';
import 'package:deal_finder_mobile/src/screens/deal_detail_screen.dart';
import 'package:deal_finder_mobile/src/screens/main_navigation_screen.dart';
import 'package:deal_finder_mobile/src/services/browsing_area.dart';
import 'groupon_preview_test.dart' show loadPreviewFonts;
import '../test/offer_detail_marketplace_test.dart' show DetailApi;

class LivePreviewApi extends DetailApi {
  final offers = [
    Promotion(
        id: 'bill',
        merchantId: 'store',
        title: '[DEMO] Weekend dining offer',
        description:
            'A local dining offer. Design fixture, not live inventory.',
        merchantName: 'Ceylon Dining',
        location: 'Colombo 03',
        discount: '25% off your food bill',
        minimumSpend: 3000,
        maximumBenefit: 1000,
        bankName: 'Sample Bank',
        cardTypes: ['credit'],
        category: 'food_dining',
        visitAvailable: true,
        latitude: 6.911,
        longitude: 79.854,
        imageDataString: 'assets/discover/stitch-1.jpg',
        images: [
          'assets/discover/stitch-1.jpg',
          'assets/discover/stitch-2.jpg'
        ],
        termsAndConditions:
            '25% applies to the eligible food bill. Minimum spend LKR 3,000; maximum discount LKR 1,000. Selected credit cards only. Taxes and service charges are excluded in this fixture.',
        endDate: DateTime.now().add(const Duration(days: 10))),
    Promotion(
        id: 'package',
        merchantId: 'store',
        title: '[DEMO] Burger & coffee package',
        merchantName: 'Street Burger',
        location: 'Colombo 03',
        description:
            'One burger and coffee. Fixed package price, no card restriction.',
        price: 1900,
        category: 'food_dining',
        visitAvailable: true,
        latitude: 6.915,
        longitude: 79.854,
        imageDataString: 'assets/discover/stitch-2.jpg',
        endDate: DateTime.now().add(const Duration(days: 10))),
    for (var i = 0; i < 2; i++)
      Promotion(
          id: 'bank-$i',
          merchantId: 'store',
          title: '[DEMO] Selected lunch menu',
          merchantName: i == 0 ? 'Harbour Table' : 'City Bistro',
          description: 'Bill-level discount fixture.',
          discount:
              i == 0 ? '20% off your food bill' : '15% off your food bill',
          minimumSpend: 2000,
          maximumBenefit: 750,
          bankName: 'Sample Bank',
          cardTypes: ['debit'],
          category: 'food_dining',
          visitAvailable: true,
          latitude: 6.921 + i * .001,
          longitude: 79.854,
          imageDataString: 'assets/discover/stitch-${i + 1}.jpg',
          endDate: DateTime.now().add(const Duration(days: 10))),
    Promotion(
        id: 'grocery',
        merchantId: 'store',
        title: '[DEMO] Online grocery offer',
        merchantName: 'Fresh Market',
        description: 'Design fixture.',
        discount: 'Save LKR 500',
        minimumSpend: 5000,
        merchantType: 'online',
        fulfillmentType: 'order',
        category: 'daily_essentials',
        orderLink: 'https://example.com',
        imageDataString: 'assets/discover/stitch-3.jpg',
        endDate: DateTime.now().add(const Duration(days: 1)))
  ];
  @override
  Future<List<Promotion>> fetchPromotions({bool forceRefresh = false}) async =>
      offers;
  @override
  Future<Map<String, dynamic>> fetchMerchantById(String merchantId) async => {
        '_id': merchantId,
        'name': 'Ceylon Dining',
        'address': 'Colombo 03',
        'location': {
          'coordinates': [79.854, 6.911]
        }
      };
}

void main() {
  testWidgets('render integrated hybrid screens from real widgets',
      (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await BrowsingArea.select(BrowsingArea.initial);
    await loadPreviewFonts(tester);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      for (final large in [false, true]) {
        tester.view.physicalSize =
            large ? const Size(320, 760) : const Size(390, 844);
        for (final detail in [false, true]) {
          final api = LivePreviewApi();
          final key = GlobalKey();
          final base = dark ? AppTheme.darkTheme() : AppTheme.lightTheme();
          final font = WidgetStateProperty.all(
              const TextStyle(fontFamily: 'Roboto', fontSize: 14));
          await tester.pumpWidget(MaterialApp(
              theme: base.copyWith(
                  textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
                  appBarTheme: base.appBarTheme.copyWith(
                      titleTextStyle: base.appBarTheme.titleTextStyle
                          ?.copyWith(fontFamily: 'Roboto')),
                  textButtonTheme: TextButtonThemeData(
                      style: base.textButtonTheme.style
                          ?.copyWith(textStyle: font)),
                  filledButtonTheme: FilledButtonThemeData(
                      style: base.filledButtonTheme.style
                          ?.copyWith(textStyle: font)),
                  outlinedButtonTheme: OutlinedButtonThemeData(
                      style: base.outlinedButtonTheme.style
                          ?.copyWith(textStyle: font)),
                  navigationBarTheme:
                      base.navigationBarTheme.copyWith(labelTextStyle: WidgetStateProperty.all(const TextStyle(fontFamily: 'Roboto', fontSize: 12)))),
              builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(large ? 2 : 1)), child: child!),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: RepaintBoundary(key: key, child: detail ? DealDetailScreen(promotion: api.offers.first, api: api) : MainNavigationScreen(homeScreenBuilder: (_) => HomeScreen(api: api)))));
          await tester.pumpAndSettle();
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 200)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (final scrolled in [false, true]) {
            if (scrolled) {
              await tester.drag(
                  find
                      .descendant(
                          of: find
                              .byType(detail
                                  ? SingleChildScrollView
                                  : CustomScrollView)
                              .first,
                          matching: find.byType(Scrollable))
                      .first,
                  const Offset(0, -430));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
            await tester.runAsync(() async {
              final boundary = key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
              final img = await boundary.toImage(pixelRatio: 2);
              final bytes =
                  await img.toByteData(format: ui.ImageByteFormat.png);
              final dir = Directory('design-preview/hybrid-live')
                ..createSync(recursive: true);
              File('${dir.path}/${detail ? 'details' : 'discover'}-${dark ? 'dark' : 'light'}-${large ? '320-large' : '390'}${scrolled ? '-scrolled' : ''}.png')
                  .writeAsBytesSync(bytes!.buffer.asUint8List());
              img.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    }
  });
}
