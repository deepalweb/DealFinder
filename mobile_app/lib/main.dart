import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/main_navigation_screen.dart';
import 'src/screens/deal_detail_screen.dart';
import 'src/models/promotion.dart';
import 'src/services/push_notification_service.dart';
import 'src/services/api_service.dart';
import 'firebase_options.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  await ApiService.warmUp();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await PushNotificationService.initialize(navKey: _navigatorKey);
  } catch (_) {}
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Map<String, String?>> _getAuth() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userToken': prefs.getString('userToken'),
      'userId': prefs.getString('userId'),
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String?>> (
      future: _getAuth(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }
        final userToken = snapshot.data!['userToken'];
        final userId = snapshot.data!['userId'];
        return MaterialApp(
          title: 'Deal Finder',
          debugShowCheckedModeBanner: false,
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
          navigatorKey: _navigatorKey,
          onGenerateRoute: (settings) {
            if (settings.name == '/deal' && settings.arguments is Promotion) {
              return MaterialPageRoute(
                builder: (_) => DealDetailScreen(promotion: settings.arguments as Promotion),
              );
            }
            return null;
          },
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E88E5),
              primary: const Color(0xFF1E88E5),
              secondary: const Color(0xFF0D47A1),
              tertiary: const Color(0xFF29B6F6),
              surface: const Color(0xFFF8FAFF),
              error: const Color(0xFFE53935),
              brightness: Brightness.light,
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
            fontFamily: 'Roboto',
            appBarTheme: const AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 2,
              backgroundColor: Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              titleTextStyle: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              iconTheme: IconThemeData(color: Colors.white),
            ),
            cardTheme: const CardThemeData(
              elevation: 3,
              shadowColor: Color(0x331E88E5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            chipTheme: const ChipThemeData(
              backgroundColor: Color(0xFFE3F2FD),
              selectedColor: Color(0xFF1E88E5),
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E88E5)),
              secondaryLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: StadiumBorder(side: BorderSide(color: Color(0xFF1E88E5), width: 1)),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: Color(0xFF1E88E5), width: 2),
              ),
              hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: const Color(0x551E88E5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E88E5),
                side: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1E88E5),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              selectedItemColor: Color(0xFF1E88E5),
              unselectedItemColor: Color(0xFF9E9E9E),
              backgroundColor: Colors.white,
              elevation: 8,
              selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: TextStyle(fontSize: 11),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            snackBarTheme: const SnackBarThemeData(
              backgroundColor: Color(0xFF323232),
              contentTextStyle: TextStyle(color: Colors.white),
              actionTextColor: Color(0xFF29B6F6),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            dividerTheme: const DividerThemeData(
              color: Color(0xFFEEEEEE),
              thickness: 1,
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
              displayMedium: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
              titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1A1A2E)),
              titleMedium: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
              bodyLarge: TextStyle(color: Color(0xFF333333)),
              bodyMedium: TextStyle(color: Color(0xFF555555)),
              bodySmall: TextStyle(color: Color(0xFF777777)),
            ),
          ),
          home: (userToken != null && userId != null)
            ? MainNavigationScreen(userId: userId, token: userToken)
            : const LoginScreen(),
        );
      },
    );
  }
}
