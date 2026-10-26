// Run manually: flutter test --no-pub tool/groupon_preview_test.dart
// Design fixtures only; this file is outside the normal regression suite.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'package:deal_finder_mobile/src/config/app_theme.dart';
import 'package:deal_finder_mobile/src/models/promotion.dart';
import 'package:deal_finder_mobile/src/screens/home_screen.dart';
import 'package:deal_finder_mobile/src/screens/main_navigation_screen.dart';
import 'package:deal_finder_mobile/src/services/browsing_area.dart';
import '../test/discover_visual_feed_test.dart' show FeedApi;
import '../test/offer_detail_marketplace_test.dart' show DetailApi;
import 'package:deal_finder_mobile/src/screens/deal_detail_screen.dart';
import 'package:deal_finder_mobile/src/screens/categories_screen.dart';

class PreviewApi extends FeedApi {
  @override
  Future<List<Promotion>> fetchPromotions({bool forceRefresh = false}) async =>
      [
        for (var i = 0; i < 12; i++)
          Promotion(
            id: 'fixture-$i',
            merchantId: 'fixture-store-$i',
            title:
                '[DEMO] ${i == 11 ? 'Fresh grocery savings' : i.isOdd ? 'Burger and coffee combo' : 'Weekend seafood lunch'}',
            merchantName: i == 11
                ? 'Fresh Mart'
                : i.isOdd
                    ? 'Street Burger'
                    : 'Ceylon Dining',
            description: 'Design fixture, not a live promotion.',
            imageDataString:
                'assets/discover/stitch-${i == 11 ? 3 : i.isOdd ? 2 : 1}.jpg',
            featured: i == 0,
            category: i == 11 ? 'daily_essentials' : 'food_dining',
            bankName: i <= 2 || (i >= 5 && i != 9) ? 'Sample Bank' : null,
            cardTypes: i <= 2 || (i >= 5 && i != 9) ? ['credit'] : [],
            minimumSpend: i <= 2 || (i >= 5 && i != 9) ? 3000 : null,
            maximumBenefit: i >= 10 ? 1500 : null,
            discount: '${20 + i * 2}% OFF',
            originalPrice: 3200,
            discountedPrice: 3200 * (1 - (20 + i * 2) / 100),
            latitude: 6.911 + i * .001,
            longitude: 79.854,
            deliveryAvailable: true,
            pickupAvailable: true,
            averageRating: 4.8,
            ratingsCount: 12,
            endDate: DateTime.now().add(Duration(days: i == 9 ? 1 : 8)),
          ),
      ];
}

Future<void> loadPreviewFonts(WidgetTester tester) async {
  var root = File(Platform.resolvedExecutable).parent;
  while (!File(
          '${root.path}/bin/cache/artifacts/material_fonts/roboto-regular.ttf')
      .existsSync()) {
    if (root.parent.path == root.path) {
      throw StateError('Flutter SDK fonts not found');
    }
    root = root.parent;
  }
  final config = File('.dart_tool/package_config.json');
  final packages = jsonDecode(config.readAsStringSync())['packages'] as List;
  final cupertino = packages.singleWhere((p) => p['name'] == 'cupertino_icons');
  final cupertinoRoot =
      config.absolute.uri.resolve(cupertino['rootUri'] as String);
  final fonts = {
    'Roboto': File(
        '${root.path}/bin/cache/artifacts/material_fonts/roboto-regular.ttf'),
    'MaterialIcons': File(
        '${root.path}/bin/cache/artifacts/material_fonts/materialicons-regular.otf'),
    'packages/cupertino_icons/CupertinoIcons': File(
        '${Directory.fromUri(cupertinoRoot).path}/assets/CupertinoIcons.ttf'),
  };
  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key)
      ..addFont(
          Future.value(ByteData.sublistView(entry.value.readAsBytesSync())));
    await tester.runAsync(() => loader.load());
  }
}

void main() {
  testWidgets('export photo-first Discover fixture previews', (tester) async {
    // This manual renderer executes inside a widget test, outside test/.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await BrowsingArea.select(BrowsingArea.initial);
    await loadPreviewFonts(tester);
    tester.view.physicalSize = const Size(390, 2700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      tester.view.physicalSize = const Size(390, 2700);
      final base = dark ? AppTheme.darkTheme() : AppTheme.lightTheme();
      final key = GlobalKey();
      final buttonText = WidgetStateProperty.all(
          const TextStyle(fontFamily: 'Roboto', fontSize: 12));
      await tester.pumpWidget(MaterialApp(
          theme: base.copyWith(
              textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
              chipTheme: base.chipTheme.copyWith(
                  labelStyle:
                      base.chipTheme.labelStyle?.copyWith(fontFamily: 'Roboto'),
                  secondaryLabelStyle: base.chipTheme.secondaryLabelStyle
                      ?.copyWith(fontFamily: 'Roboto')),
              navigationBarTheme:
                  base.navigationBarTheme.copyWith(labelTextStyle: buttonText),
              filledButtonTheme: FilledButtonThemeData(
                  style: base.filledButtonTheme.style
                      ?.copyWith(textStyle: buttonText)),
              textButtonTheme: TextButtonThemeData(
                  style: base.textButtonTheme.style
                      ?.copyWith(textStyle: buttonText)),
              outlinedButtonTheme:
                  OutlinedButtonThemeData(style: base.outlinedButtonTheme.style?.copyWith(textStyle: buttonText))),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepaintBoundary(key: key, child: MainNavigationScreen(homeScreenBuilder: (_) => HomeScreen(api: PreviewApi())))));
      await tester.pumpAndSettle();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await boundary.toImage(pixelRatio: 2);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        final dir = Directory('design-preview')..createSync(recursive: true);
        File('${dir.path}/discover-groupon-${dark ? 'dark' : 'light'}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        img.dispose();
      });
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await boundary.toImage(pixelRatio: 2);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        File('design-preview/discover-groupon-${dark ? 'dark' : 'light'}-phone.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        img.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
  testWidgets('export category and detail fixture previews', (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await loadPreviewFonts(tester);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final name in ['categories', 'details']) {
      final key = GlobalKey();
      final theme = AppTheme.lightTheme();
      final screen = name == 'categories'
          ? const CategoriesScreen()
          : DealDetailScreen(
              api: DetailApi(),
              promotion: Promotion(
                  id: 'preview-detail',
                  title: '[DEMO] Weekend seafood lunch',
                  description:
                      'A seafood lunch set. Design fixture, not a live promotion.',
                  merchantName: 'Ceylon Dining',
                  imageDataString: 'assets/discover/stitch-1.jpg',
                  images: [
                    'assets/discover/stitch-2.jpg',
                    'assets/discover/stitch-3.jpg'
                  ],
                  termsAndConditions:
                      'Selected credit cards. Minimum spend LKR 3,000. Check availability with the merchant.',
                  discountedPrice: 2400,
                  originalPrice: 3200));
      await tester.pumpWidget(MaterialApp(
          theme: theme.copyWith(
            textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
            appBarTheme: theme.appBarTheme.copyWith(
                titleTextStyle: theme.appBarTheme.titleTextStyle
                    ?.copyWith(fontFamily: 'Roboto')),
            textButtonTheme: TextButtonThemeData(
                style: theme.textButtonTheme.style?.copyWith(
                    textStyle: WidgetStateProperty.all(
                        const TextStyle(fontFamily: 'Roboto', fontSize: 14)))),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepaintBoundary(key: key, child: screen)));
      await tester.pumpAndSettle();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await boundary.toImage(pixelRatio: 2);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        File('design-preview/groupon-$name-light-phone.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        img.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
