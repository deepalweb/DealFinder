import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deal_finder_mobile/src/widgets/discover_search_hint.dart';

Widget hintHost({bool reduceMotion = false}) => MaterialApp(
    home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: const Scaffold(
            body: DiscoverSearchHint(
                searchLabel: 'Search deals and stores',
                suggestions: ['Try pizza', 'Try groceries']))));

void main() {
  testWidgets(
      'search examples rotate while retaining a stable accessible label',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(hintHost());
    expect(find.text('Try pizza'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Try groceries'), findsOneWidget);
    expect(find.bySemanticsLabel('Search deals and stores'), findsOneWidget);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion keeps the search example stationary',
      (tester) async {
    await tester.pumpWidget(hintHost(reduceMotion: true));
    await tester.pump(const Duration(seconds: 15));
    expect(find.text('Try pizza'), findsOneWidget);
    expect(find.text('Try groceries'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
