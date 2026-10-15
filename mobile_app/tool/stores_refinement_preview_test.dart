import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deal_finder_mobile/src/config/app_theme.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'package:deal_finder_mobile/src/screens/stores_screen.dart';
import 'package:deal_finder_mobile/src/screens/merchant_profile_screen.dart';
import '../test/stores_refinement_test.dart' show StoreFixtureApi;
import 'groupon_preview_test.dart' show loadPreviewFonts;

void main() {
  testWidgets('render actual Stores and store detail fixtures', (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await loadPreviewFonts(tester);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dir = Directory('design-preview/stores-refinement')
      ..createSync(recursive: true);
    for (final config in [
      ('light', 390.0, false, 1.0, const Locale('en')),
      ('dark', 390.0, true, 1.0, const Locale('en')),
      ('large', 320.0, true, 2.0, const Locale('en')),
      ('sinhala', 390.0, false, 2.0, const Locale('si')),
      ('tamil', 390.0, true, 2.0, const Locale('ta')),
    ]) {
      tester.view.physicalSize = Size(config.$2, 844);
      for (final screen in ['directory', 'store']) {
        final key = GlobalKey();
        final base = config.$3 ? AppTheme.darkTheme() : AppTheme.lightTheme();
        await tester.pumpWidget(MaterialApp(
            theme: base.copyWith(
                textTheme: base.textTheme.apply(fontFamily: 'Roboto')),
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
                child: screen == 'directory'
                    ? StoresScreen(api: StoreFixtureApi())
                    : MerchantProfileScreen(
                        merchantId: 'cafe',
                        api: StoreFixtureApi(),
                        mapBuilder: (_) => const ColoredBox(
                            color: Color(0xFFE9EFEA),
                            child: Center(
                                child: Text(
                                    'FIXTURE MAP · not Google tiles')))))));
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
        expect(tester.takeException(), isNull);
        Future<void> capture(String suffix) async {
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.runAsync(() async {
            final boundary = key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            final img = await boundary.toImage(pixelRatio: 2);
            final data = await img.toByteData(format: ui.ImageByteFormat.png);
            File('${dir.path}/${config.$1}-$screen$suffix.png')
                .writeAsBytesSync(data!.buffer.asUint8List());
            img.dispose();
          });
        }

        await capture('');
        if (screen == 'store') {
          final l10n = AppLocalizations.of(key.currentContext!)!;
          await tester.scrollUntilVisible(find.text(l10n.about), 160,
              scrollable: find.byType(Scrollable).first);
          await tester.pumpAndSettle();
          await tester.tap(find.text(l10n.about));
          await capture('-about');
          await tester.scrollUntilVisible(
              find.text(l10n.profileReviewsLabel), -160,
              scrollable: find.byType(Scrollable).first);
          await tester.pumpAndSettle();
          await tester.tap(find.text(l10n.profileReviewsLabel));
          await capture('-reviews');
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });
}
