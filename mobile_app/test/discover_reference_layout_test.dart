import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:deal_finder_mobile/src/models/promotion.dart';
import 'package:deal_finder_mobile/src/widgets/discover_offer_surface.dart';
import 'design_system_test.dart' show host;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final offer = Promotion(
      id: 'reference',
      title: 'Weekend seafood lunch',
      merchantName: 'Ceylon Dining',
      description: 'Fixture',
      discount: '25% OFF',
      bankName: 'Sample Bank',
      minimumSpend: 3000,
      maximumBenefit: 1500,
      endDate: DateTime.now().add(const Duration(days: 2)));
  testWidgets('reference surfaces retain compact default proportions',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final layout in DiscoverSurfaceLayout.values) {
      final key = GlobalKey();
      await tester.pumpWidget(host(Scaffold(
          body: SingleChildScrollView(
              child: DiscoverOfferSurface(
                  key: key, offer: offer, layout: layout, onOpen: () {})))));
      await tester.pumpAndSettle();
      final height = tester.getSize(find.byKey(key)).height;
      expect(
          height,
          lessThan(switch (layout) {
            DiscoverSurfaceLayout.editorial => 240,
            DiscoverSurfaceLayout.detail => 380,
            DiscoverSurfaceLayout.expiry => 190,
          }));
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('compact reference surfaces expand at double text size',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final layout in DiscoverSurfaceLayout.values) {
      var opened = false;
      await tester.pumpWidget(host(
          Scaffold(
              body: SingleChildScrollView(
                  child: DiscoverOfferSurface(
                      offer: offer,
                      layout: layout,
                      onOpen: () => opened = true))),
          dark: true,
          scale: 2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ceylon Dining'));
      expect(opened, true);
      expect(tester.takeException(), isNull);
    }
  });
}
