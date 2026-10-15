// Run manually: flutter test --no-pub tool/discover_preview_test.dart
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
        File('${dir.path}/discover-uber-style-${dark ? 'dark' : 'light'}.png')
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
        File('design-preview/discover-uber-style-${dark ? 'dark' : 'light'}-phone.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        img.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
