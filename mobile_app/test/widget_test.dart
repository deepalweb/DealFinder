import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deal_finder_mobile/main.dart';

void main() {
  testWidgets('shows login screen when no session is stored',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsWidgets);
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Demo Login'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
