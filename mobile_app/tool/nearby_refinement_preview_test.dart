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
import 'package:deal_finder_mobile/src/screens/nearby_deals_screen.dart';
import 'package:deal_finder_mobile/src/screens/main_navigation_screen.dart';
import 'groupon_preview_test.dart' show loadPreviewFonts;

class NearbyFixtureApi extends ApiService {
  @override
  Future<NearbyPromotionsResult> fetchNearbyPromotionsWithCache(
          double lat, double lng,
          {double radiusKm = 10, String? locationName}) async =>
      NearbyPromotionsResult(promotions: [
        Promotion(
            id: 'dining',
            merchantId: 'fixture-store',
            merchantName: 'Ceylon Roast & Grill',
            title: '[FIXTURE] 30% off selected lunch meals',
            description: 'Design fixture, not live inventory',
            category: 'food_dining',
            latitude: lat + .003,
            longitude: lng + .001,
            discount: '30% off',
            bankName: 'Sample Bank',
            cardTypes: ['credit'],
            minimumSpend: 3000,
            maximumBenefit: 1000,
            endDate: DateTime.utc(2099, 1, 12),
            imageDataString: 'assets/discover/stitch-2.jpg'),
        Promotion(
            id: 'bento',
            merchantId: 'fixture-store',
            merchantName: 'City Bento',
            title: '[FIXTURE] Bento lunch package',
            description: 'Fixed-price fixture',
            category: 'food_dining',
            latitude: lat - .004,
            longitude: lng + .004,
            price: 2400,
            originalPrice: 3200,
            endDate: DateTime.utc(2099, 1, 15),
            imageDataString: 'assets/discover/stitch-1.jpg'),
      ]);
  @override
  Future<List<Map<String, dynamic>>> fetchMerchants(
          {bool forceRefresh = false}) async =>
      [];
}

/// Geometry fixture only: real Google cartography is unavailable in widget tests.
class MapGeometryFixture extends CustomPainter {
  MapGeometryFixture(this.dark);
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = dark ? const Color(0xFF1A2D29) : const Color(0xFFF0F2EC));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width * .19, size.height),
        Paint()
          ..color = dark ? const Color(0xFF163B49) : const Color(0xFFD4E9F0));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * .68, 80, size.width * .25, 130),
            const Radius.circular(24)),
        Paint()
          ..color = dark ? const Color(0xFF264E3A) : const Color(0xFFD6E9D9));
    final road = Paint()
      ..color = dark ? const Color(0xFF57655D) : Colors.white
      ..strokeWidth = 7;
    for (var i = 1; i < 6; i++) {
      canvas.drawLine(Offset(size.width * .15, i * 75.0),
          Offset(size.width, i * 75.0 - 25), road);
    }
    for (final x in [.26, .43, .61, .84]) {
      canvas.drawLine(Offset(size.width * x, 0),
          Offset(size.width * x - 20, size.height), road);
    }
    for (final point in [(0.40, 100.0, '30% OFF'), (.72, 200.0, 'LKR 2,400')]) {
      final box = RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * point.$1 - 35, point.$2, 85, 28),
          const Radius.circular(16));
      canvas.drawRRect(box, Paint()..color = const Color(0xFF007B59));
      final text = TextPainter(
          text: TextSpan(
              text: point.$3,
              style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          textDirection: TextDirection.ltr)
        ..layout();
      text.paint(
          canvas, Offset(box.left + (box.width - text.width) / 2, box.top + 7));
    }
  }

  @override
  bool shouldRepaint(MapGeometryFixture oldDelegate) =>
      oldDelegate.dark != dark;
}

void main() {
  testWidgets(
      'render Nearby actual controls and sheets with an explicitly labelled map fixture',
      (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await BrowsingArea.select(BrowsingArea.initial);
    await loadPreviewFonts(tester);
    final previousShadows = debugDisableShadows;
    debugDisableShadows = false;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dir = Directory('design-preview/nearby-refinement')
      ..createSync(recursive: true);
    for (final config in [
      (390.0, 844.0, false, 1.0, 'en', 'light'),
      (390.0, 844.0, true, 1.0, 'en', 'dark'),
      (320.0, 760.0, false, 1.0, 'en', 'narrow'),
      (320.0, 760.0, true, 2.0, 'en', 'large'),
      (390.0, 844.0, false, 2.0, 'si', 'sinhala'),
      (390.0, 844.0, true, 2.0, 'ta', 'tamil'),
    ]) {
      tester.view.physicalSize = Size(config.$1, config.$2);
      final key = GlobalKey();
      final base = config.$3 ? AppTheme.darkTheme() : AppTheme.lightTheme();
      final style = WidgetStateProperty.all(
          const TextStyle(fontFamily: 'Roboto', fontSize: 12));
      await tester.pumpWidget(MaterialApp(
          theme: base.copyWith(
              textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
              chipTheme: base.chipTheme.copyWith(
                  labelStyle:
                      const TextStyle(fontFamily: 'Roboto', fontSize: 12)),
              textButtonTheme: TextButtonThemeData(
                  style:
                      base.textButtonTheme.style?.copyWith(textStyle: style)),
              filledButtonTheme: FilledButtonThemeData(
                  style: base.filledButtonTheme.style
                      ?.copyWith(textStyle: style))),
          locale: Locale(config.$5),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(config.$4),
                  disableAnimations: true),
              child: child!),
          home: RepaintBoundary(
              key: key,
              child: MainNavigationScreen(
                  homeScreenBuilder: (_) => const SizedBox.shrink(),
                  nearbyScreenBuilder: (_) => NearbyDealsScreen(
                      api: NearbyFixtureApi(),
                      mapBuilder: (map) => Stack(children: [
                            Positioned.fill(
                                child: CustomPaint(
                                    painter: MapGeometryFixture(config.$3))),
                            Positioned(
                                left: 12,
                                top: 75,
                                child: Container(
                                    padding: const EdgeInsets.all(5),
                                    color:
                                        config.$3 ? Colors.black : Colors.white,
                                    child: const Text(
                                        'FIXTURE MAP · not Google tiles',
                                        style: TextStyle(
                                            fontFamily: 'Roboto',
                                            fontSize: 10)))),
                          ]))))));
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future.wait([1, 2].map((i) => precacheImage(
          AssetImage('assets/discover/stitch-$i.jpg'), key.currentContext!))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      Future<void> capture(String name) async => tester.runAsync(() async {
            final image = await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            File('${dir.path}/${config.$6}-$name.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
      await capture('map');
      final sheet = tester.widget<DraggableScrollableSheet>(
          find.byType(DraggableScrollableSheet));
      sheet.controller!.jumpTo(.92);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture('list');
      await tester.pumpWidget(const SizedBox.shrink());
    }
    debugDisableShadows = previousShadows;
  });
}
