import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deal_finder_mobile/src/models/promotion.dart';
import 'package:deal_finder_mobile/src/screens/deal_detail_screen.dart';
import 'package:deal_finder_mobile/src/config/app_theme.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../test/offer_detail_marketplace_test.dart' show DetailApi;
import 'groupon_preview_test.dart' show loadPreviewFonts;

void main() {
  testWidgets('render refined actual detail page in both themes and large text',
      (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await loadPreviewFonts(tester);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dir = Directory('design-preview/details-refinement')
      ..createSync(recursive: true);
    final offer = Promotion(
        id: 'detail-fixture',
        merchantId: 'fixture-store',
        title: '[FIXTURE] 25% off your food bill',
        merchantName: 'Ceylon Dining',
        description:
            'Design fixture, not live inventory. Enjoy selected lunch and dinner dishes. Contact the merchant to confirm availability.',
        imageDataString: 'assets/discover/stitch-1.jpg',
        images: ['assets/discover/stitch-2.jpg'],
        discount: '25% off',
        bankName: 'Sample Bank',
        cardTypes: ['credit'],
        minimumSpend: 3000,
        maximumBenefit: 1000,
        visitAvailable: true,
        latitude: 6.91,
        longitude: 79.85,
        distance: 650,
        averageRating: 4.8,
        ratingsCount: 12,
        termsAndConditions:
            'Selected credit cards only. Reservation required. Confirm eligibility with the merchant before paying.',
        endDate: DateTime.utc(2099, 1, 20, 18, 29));
    for (final config in [
      ('light', 390.0, false, 1.0, const Locale('en')),
      ('dark', 390.0, true, 1.0, const Locale('en')),
      ('large', 320.0, true, 2.0, const Locale('en')),
      ('sinhala', 390.0, false, 2.0, const Locale('si')),
      ('tamil', 390.0, true, 2.0, const Locale('ta')),
    ]) {
      tester.view.physicalSize = Size(config.$2, 844);
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
          theme: (config.$3 ? AppTheme.darkTheme() : AppTheme.lightTheme())
              .copyWith(
            textTheme:
                (config.$3 ? AppTheme.darkTheme() : AppTheme.lightTheme())
                    .textTheme
                    .apply(fontFamily: 'Roboto'),
            appBarTheme: const AppBarTheme(
                titleTextStyle: TextStyle(fontFamily: 'Roboto', fontSize: 18)),
          ),
          locale: config.$5,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(config.$4),
                  disableAnimations: true),
              child: child!),
          home: RepaintBoundary(
              key: key,
              child: DealDetailScreen(api: DetailApi(), promotion: offer))));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        for (final path in [
          'assets/discover/stitch-1.jpg',
          'assets/discover/stitch-2.jpg'
        ]) {
          await precacheImage(AssetImage(path), key.currentContext!);
        }
      });
      await tester.pumpAndSettle();
      for (final state in ['summary', 'conditions']) {
        if (state == 'conditions') {
          await tester.scrollUntilVisible(
              find.text(offer.termsAndConditions!), 180,
              scrollable: find
                  .descendant(
                      of: find.byType(SingleChildScrollView).first,
                      matching: find.byType(Scrollable))
                  .first);
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final img = await boundary.toImage(pixelRatio: 2);
          final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
          File('${dir.path}/${config.$1}-$state.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          img.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
