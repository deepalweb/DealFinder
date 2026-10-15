import 'dart:async';
import 'package:deal_finder_mobile/src/models/promotion.dart';
import 'package:deal_finder_mobile/src/screens/all_deals_screen.dart';
import 'package:deal_finder_mobile/src/screens/categories_screen.dart';
import 'package:deal_finder_mobile/src/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design_system_test.dart' show host;

class PagingApi extends ApiService {
  int pageCalls = 0;
  bool failPage = true;
  Completer<List<Promotion>>? pending;
  @override
  Future<List<Promotion>> fetchPromotions({bool forceRefresh = false}) async =>
      [
        Promotion(id: 'visible', title: 'Initial offer', description: ''),
        for (var i = 1; i < 50; i++)
          Promotion(
              id: '$i',
              title: 'Unpublished',
              description: '',
              status: 'pending_review'),
      ];
  @override
  Future<List<Promotion>> fetchPromotionPage(
      {int limit = 50, int skip = 0}) async {
    expect(skip, 50);
    pageCalls++;
    if (pending != null) return pending!.future;
    if (failPage) throw StateError('Offline');
    return [Promotion(id: 'last', title: 'Final offer', description: '')];
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('pagination retries the same offset and stops at the actual end',
      (tester) async {
    final api = PagingApi();
    await tester.pumpWidget(host(AllDealsScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Load more offers'), 300,
        scrollable: find
            .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable))
            .first);
    await tester.tap(find.text('Load more offers'));
    await tester.pumpAndSettle();
    expect(api.pageCalls, 1);
    expect(find.text('Initial offer'), findsOneWidget);
    api.failPage = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(api.pageCalls, 2);
    await tester.scrollUntilVisible(find.text('Final offer'), 250,
        scrollable: find
            .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable))
            .first);
    expect(find.text('Final offer'), findsOneWidget);
    expect(find.text('Load more offers'), findsNothing);
    expect(find.text('Unpublished'), findsNothing);
  });
  testWidgets('disposed results ignore late pages', (tester) async {
    final api = PagingApi()..pending = Completer<List<Promotion>>();
    await tester.pumpWidget(host(AllDealsScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Load more offers'), 300,
        scrollable: find
            .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable))
            .first);
    await tester.tap(find.text('Load more offers'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    api.pending!
        .complete([Promotion(id: 'late', title: 'Late', description: '')]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  for (final language in ['en', 'si', 'ta']) {
    for (final width in [320.0, 390.0, 840.0]) {
      testWidgets('categories fit $language at $width with double text',
          (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final base =
            host(const CategoriesScreen(), dark: true, scale: 2) as MaterialApp;
        await tester.pumpWidget(MaterialApp(
            theme: base.theme,
            builder: base.builder,
            locale: Locale(language),
            supportedLocales: base.supportedLocales,
            localizationsDelegates: base.localizationsDelegates,
            home: base.home));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(GridView), const Offset(0, -700));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
