import 'package:deal_finder_mobile/src/screens/home_screen.dart';
import 'package:deal_finder_mobile/src/screens/all_deals_screen.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'package:deal_finder_mobile/src/config/app_theme.dart';
import 'package:deal_finder_mobile/src/screens/main_navigation_screen.dart';
import 'package:deal_finder_mobile/src/services/app_session.dart';
import 'package:deal_finder_mobile/src/widgets/sign_in_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget host(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
      home: child,
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppSession.changes.value = const AppSession();
  });

  for (final accepted in [false, true]) {
    testWidgets(
        'protected action ${accepted ? 'resumes' : 'cancels'} on original offer',
        (tester) async {
      var executed = 0;
      final input = TextEditingController(text: 'Original offer input');
      await tester.pumpWidget(host(Builder(
          builder: (context) => Scaffold(
                body: Column(children: [
                  TextField(controller: input),
                  FilledButton(
                      onPressed: () async {
                        final signedIn = await requireSignIn(context,
                            loginBuilder: (loginContext) => Scaffold(
                                  appBar:
                                      AppBar(title: const Text('Test sign in')),
                                  body: FilledButton(
                                      onPressed: () async {
                                        if (accepted) {
                                          final prefs = await SharedPreferences
                                              .getInstance();
                                          await prefs.setString(
                                              'userId', 'test-user');
                                          await prefs.setString(
                                              'userToken', 'test-token');
                                          await AppSession.refresh();
                                        }
                                        if (loginContext.mounted) {
                                          Navigator.pop(loginContext, accepted);
                                        }
                                      },
                                      child: const Text('Finish sign in')),
                                ));
                        if (signedIn) executed++;
                      },
                      child: const Text('Save original offer')),
                ]),
              ))));
      await tester.tap(find.text('Save original offer'));
      await tester.pumpAndSettle();
      expect(executed, 0);
      await tester.tap(find.text('Finish sign in'));
      await tester.pumpAndSettle();
      expect(executed, accepted ? 1 : 0);
      expect(find.text('Save original offer'), findsOneWidget);
      expect(input.text, 'Original offer input');
      await tester.pumpWidget(const SizedBox.shrink());
      input.dispose();
    });
  }

  testWidgets('guest tabs stay reachable and keep independent route stacks',
      (tester) async {
    await tester.pumpWidget(host(MainNavigationScreen(
      homeScreenBuilder: (context) => Scaffold(
          body: FilledButton(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Original offer')),
                      body: const Text('Offer eligibility'),
                    ))),
        child: const Text('Open offer'),
      )),
      nearbyScreenBuilder: (_) => const Text('Nearby results'),
      storesScreenBuilder: (_) => const Text('Store results'),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open offer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nearby'));
    await tester.pumpAndSettle();
    expect(find.text('Nearby results'), findsOneWidget);
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(find.text('Offer eligibility'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Open offer'), findsOneWidget);
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInGate), findsOneWidget);
    await tester.tap(find.text('Stores'));
    await tester.pumpAndSettle();
    expect(find.text('Store results'), findsOneWidget);
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInGate), findsOneWidget);
  });
  testWidgets('bank shortcuts open within Discover without replacing Stores',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(MainNavigationScreen(
      storesScreenBuilder: (_) => const Text('Merchant directory'),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Stores'), findsOneWidget);
    expect(
        tester
            .widgetList<NavigationDestination>(
                find.byType(NavigationDestination))
            .map((item) => item.label),
        ['Discover', 'Nearby', 'Stores', 'Saved', 'Account']);
    tester
        .widget<HomeScreen>(find.byType(HomeScreen))
        .onNavigateBankOffers!('Fixture Bank');
    await tester.pumpAndSettle();
    final results = tester.widget<AllDealsScreen>(find.byType(AllDealsScreen));
    expect(results.bankOffersOnly, isTrue);
    expect(results.initialBankName, 'Fixture Bank');
    await tester.tap(find.text('Stores'));
    await tester.pumpAndSettle();
    expect(find.text('Merchant directory'), findsOneWidget);
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(find.byType(AllDealsScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
