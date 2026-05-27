import 'dart:async';

import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'package:deal_finder_mobile/main.dart';
import 'package:deal_finder_mobile/src/screens/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows unauthenticated home when no session is stored',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(
        authLoader: () async => {
          'userToken': null,
          'userId': null,
        },
        unauthenticatedHomeBuilder: (_) => const Scaffold(
          body: Text('Signed Out'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Signed Out'), findsOneWidget);
  });

  testWidgets('shows authenticated home when session exists',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(
        authLoader: () async => {
          'userToken': 'token-123',
          'userId': 'user-123',
        },
        authenticatedHomeBuilder: (userId, token) => Scaffold(
          body: Text('Signed In: $userId / $token'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Signed In: user-123 / token-123'), findsOneWidget);
  });

  testWidgets('shows a loading indicator while auth is resolving',
      (WidgetTester tester) async {
    final completer = Completer<Map<String, String?>>();

    await tester.pumpWidget(
      MyApp(
        authLoader: () => completer.future,
        unauthenticatedHomeBuilder: (_) => const Scaffold(
          body: Text('Signed Out'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete({
      'userToken': null,
      'userId': null,
    });
    await tester.pumpAndSettle();

    expect(find.text('Signed Out'), findsOneWidget);
  });

  testWidgets('keeps tab state when switching between bottom navigation items',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('si'),
          Locale('ta'),
        ],
        home: MainNavigationScreen(
          userId: 'user-1',
          token: 'token-1',
          homeScreenBuilder: (_) => const _CounterTab(label: 'Home Counter'),
          dealsScreenBuilder: (_) => const Scaffold(
            body: Center(child: Text('Deals Screen')),
          ),
          storesScreenBuilder: (_) => const Scaffold(
            body: Center(child: Text('Stores Screen')),
          ),
          favoritesScreenBuilder: (_) => const Scaffold(
            body: Center(child: Text('Favorites Screen')),
          ),
          profileScreenBuilder: (_) => const Scaffold(
            body: Center(child: Text('Profile Screen')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home Counter: 0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('increment-home-counter')));
    await tester.pumpAndSettle();
    expect(find.text('Home Counter: 1'), findsOneWidget);

    await tester.tap(find.text('Deals'));
    await tester.pumpAndSettle();
    expect(find.text('Deals Screen'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Home Counter: 1'), findsOneWidget);
  });
}

class _CounterTab extends StatefulWidget {
  const _CounterTab({required this.label});

  final String label;

  @override
  State<_CounterTab> createState() => _CounterTabState();
}

class _CounterTabState extends State<_CounterTab> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.label}: $_count'),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const Key('increment-home-counter'),
              onPressed: () => setState(() => _count += 1),
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}
