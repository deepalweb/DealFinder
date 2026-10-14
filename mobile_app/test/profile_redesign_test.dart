import 'dart:async';
import 'package:deal_finder_mobile/src/models/promotion.dart';
import 'package:deal_finder_mobile/src/screens/user_profile_screen.dart';
import 'package:deal_finder_mobile/src/screens/merchant_profile_screen.dart';
import 'package:deal_finder_mobile/src/services/api_service.dart';
import 'package:deal_finder_mobile/src/widgets/discovery_offer_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design_system_test.dart' show host;

class ProfileApi extends ApiService {
  bool unavailable = false;
  final save = Completer<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> fetchUserProfile(
          String userId, String token) async =>
      {'name': 'Alex', 'email': 'alex@example.test', 'role': 'user'};
  @override
  Future<List<Promotion>> fetchFavorites(String userId, String token) async =>
      [];
  @override
  Future<List<Map<String, dynamic>>> fetchFollowingMerchants(
          String userId) async =>
      [];
  @override
  Future<Map<String, dynamic>> updateUserProfile(String userId, String token,
          {String? name,
          String? email,
          String? businessName,
          String? profilePicture}) =>
      save.future;
  @override
  Future<Map<String, dynamic>> fetchMerchantById(String id) async {
    if (unavailable) throw Exception('Offline');
    return {
      '_id': id,
      'name': 'Ceylon Coffee',
      'description': 'Coffee and lunch.',
      'merchantType': 'offline',
      'address': 'Colombo 03',
      'followers': 12
    };
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPromotionsByMerchant(
          String id) async =>
      [
        {
          '_id': 'offer',
          'title': 'Coffee offer',
          'description': 'Selected cards',
          'status': 'active',
          'bankName': 'Test Bank'
        },
        {
          '_id': 'future',
          'title': 'Future offer',
          'description': 'Not started',
          'status': 'scheduled',
          'startDate':
              DateTime.now().add(const Duration(days: 3)).toIso8601String()
        },
        {
          '_id': 'expired',
          'title': 'Expired offer',
          'description': 'Ended',
          'status': 'active',
          'endDate':
              DateTime.now().subtract(const Duration(days: 3)).toIso8601String()
        },
      ];
  @override
  Future<List<Map<String, dynamic>>> fetchMerchantRatings(String id) async =>
      [];
  @override
  Future<List<Map<String, dynamic>>> fetchMerchantReviews(String id) async =>
      [];
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('profiles adapt to small phones and landscape', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(375, 812), const Size(844, 390)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(host(UserProfileScreen(api: ProfileApi())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
          host(MerchantProfileScreen(merchantId: 'store', api: ProfileApi())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('account overview and focused editor retain rejected input',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'userName': 'Alex',
      'userEmail': 'alex@example.test',
      'userId': 'user',
      'userToken': 'test-token',
      'userRole': 'user'
    });
    final api = ProfileApi();
    await tester.pumpWidget(host(UserProfileScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Alex'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Alex updated');
    // Use the button's localized text rather than relying on screen coordinates.
    final saveButton = find.byType(ElevatedButton).first;
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();
    expect(find.text('Saving…'), findsOneWidget);
    api.save.completeError(Exception('Please try again'));
    await tester.pumpAndSettle();
    expect(find.text('Alex updated'), findsOneWidget);
    expect(
        (await SharedPreferences.getInstance()).getString('userName'), 'Alex');
    expect(tester.takeException(), isNull);
  });
  testWidgets('merchant offers lead, future offers hidden, expired reachable',
      (tester) async {
    await tester.pumpWidget(
        host(MerchantProfileScreen(merchantId: 'store', api: ProfileApi())));
    await tester.pumpAndSettle();
    expect(find.byType(DiscoveryOfferCard), findsOneWidget);
    expect(find.text('Coffee offer'), findsOneWidget);
    expect(find.text('Future offer'), findsNothing);
    expect(find.text('Closed now'), findsNothing); // No published hours.
    await tester.tap(find.text('Expired (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Expired offer'), findsOneWidget);
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('Coffee and lunch.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('merchant retry recovers from unavailable data', (tester) async {
    final api = ProfileApi()..unavailable = true;
    await tester
        .pumpWidget(host(MerchantProfileScreen(merchantId: 'store', api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    api.unavailable = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Ceylon Coffee'), findsWidgets);
    expect(find.byType(DiscoveryOfferCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('profiles fit narrow dark screens at double text size',
      (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
        host(UserProfileScreen(api: ProfileApi()), dark: true, scale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(host(
        MerchantProfileScreen(merchantId: 'store', api: ProfileApi()),
        dark: true,
        scale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Reviews'));
    await tester.tap(find.text('Reviews'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
