import 'package:deal_finder_mobile/src/screens/main_navigation_screen.dart';
import 'package:deal_finder_mobile/src/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design_system_test.dart' show host;
import 'profile_redesign_test.dart' show ProfileApi;

void main() {
  testWidgets('system back from account editor restores the overview',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'userId': 'user',
      'userToken': 'test-token',
      'userName': 'Alex',
      'userEmail': 'alex@example.test',
      'userRole': 'user'
    });
    await tester.pumpWidget(host(MainNavigationScreen(
      userId: 'user',
      token: 'test-token',
      homeScreenBuilder: (_) => const Text('Discover content'),
      nearbyScreenBuilder: (_) => const SizedBox(),
      storesScreenBuilder: (_) => const SizedBox(),
      favoritesScreenBuilder: (_) => const SizedBox(),
      profileScreenBuilder: (_) => UserProfileScreen(api: ProfileApi()),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Account').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Edit profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
