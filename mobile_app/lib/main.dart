import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/main_navigation_screen.dart';
import 'src/services/push_notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await PushNotificationService.initialize();
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
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
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF6B35),
              primary: const Color(0xFFFF6B35),
              secondary: const Color(0xFF6C3CE1),
              tertiary: const Color(0xFFFFB347),
              surface: const Color(0xFFFFFBF8),
              error: const Color(0xFFE53935),
              brightness: Brightness.light,
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
            fontFamily: 'Roboto',
            appBarTheme: const AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 2,
              backgroundColor: Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              titleTextStyle: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              iconTheme: IconThemeData(color: Colors.white),
            ),
            cardTheme: CardThemeData(
              elevation: 3,
              shadowColor: Color(0x33FF6B35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            chipTheme: ChipThemeData(
              backgroundColor: Color(0xFFFFF0EB),
              selectedColor: Color(0xFFFF6B35),
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFFF6B35)),
              secondaryLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: StadiumBorder(side: BorderSide(color: Color(0xFFFF6B35), width: 1)),
            ),
            inputDecorationTheme: InputDecorationTheme(
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
                borderSide: BorderSide(color: Color(0xFFFF6B35), width: 2),
              ),
              hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: Color(0x55FF6B35),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFFFF6B35),
                side: BorderSide(color: Color(0xFFFF6B35), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFFFF6B35),
                textStyle: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              selectedItemColor: Color(0xFFFF6B35),
              unselectedItemColor: Color(0xFF9E9E9E),
              backgroundColor: Colors.white,
              elevation: 8,
              selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: TextStyle(fontSize: 11),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: Color(0xFF323232),
              contentTextStyle: TextStyle(color: Colors.white),
              actionTextColor: Color(0xFFFFB347),
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
