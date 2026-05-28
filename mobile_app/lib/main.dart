import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/main_navigation_screen.dart';
import 'src/screens/deal_detail_screen.dart';
import 'src/screens/notifications_screen.dart';
import 'src/models/promotion.dart';
import 'src/services/app_language_controller.dart';
import 'src/services/push_notification_service.dart';
import 'src/services/api_service.dart';
import 'firebase_options.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

const _iosPrimary = Color(0xFF007AFF);
const _iosSecondary = Color(0xFF5AC8FA);
const _iosSurface = Color(0xFFF2F2F7);
const _iosCard = Color(0xFFFFFFFF);
const _iosText = Color(0xFF111827);
const _iosSubtleText = Color(0xFF6B7280);
const _iosBorder = Color(0xFFD8D8DE);
const _iosError = Color(0xFFFF3B30);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadEnvironment();
  await appLanguageController.load();
  await ApiService.warmUp();
  await _initializeRemoteServices();
  runApp(const MyApp());
}

Future<void> _loadEnvironment() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
}

Future<void> _initializeRemoteServices() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await PushNotificationService.initialize(navKey: _navigatorKey);
  } catch (error) {
    debugPrint('Remote services initialization skipped: $error');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.authLoader,
    this.authenticatedHomeBuilder,
    this.unauthenticatedHomeBuilder,
  });

  final Future<Map<String, String?>> Function()? authLoader;
  final Widget Function(String userId, String token)? authenticatedHomeBuilder;
  final WidgetBuilder? unauthenticatedHomeBuilder;

  Future<Map<String, String?>> _getAuth() async {
    if (authLoader != null) {
      return authLoader!();
    }

    final prefs = await SharedPreferences.getInstance();
    return {
      'userToken': prefs.getString('userToken'),
      'userId': prefs.getString('userId'),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appLanguageController,
      builder: (context, _) {
        return FutureBuilder<Map<String, String?>>(
          future: _getAuth(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const MaterialApp(
                home: Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            final userToken = snapshot.data!['userToken'];
            final userId = snapshot.data!['userId'];
            return MaterialApp(
              title: 'Deal Finder',
              debugShowCheckedModeBanner: false,
              locale: appLanguageController.locale,
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
                if (settings.name == '/deal' &&
                    settings.arguments is Promotion) {
                  return MaterialPageRoute(
                    builder: (_) => DealDetailScreen(
                      promotion: settings.arguments as Promotion,
                    ),
                  );
                }
                if (settings.name == '/notifications') {
                  return MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  );
                }
                return null;
              },
              builder: (context, child) {
                final mediaQuery = MediaQuery.of(context);
                final brightness = mediaQuery.platformBrightness;
                final darkIcons = brightness != Brightness.dark;
                SystemChrome.setSystemUIOverlayStyle(
                  SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness:
                        darkIcons ? Brightness.dark : Brightness.light,
                    statusBarBrightness:
                        darkIcons ? Brightness.light : Brightness.dark,
                    systemNavigationBarColor: Colors.white,
                    systemNavigationBarIconBrightness:
                        darkIcons ? Brightness.dark : Brightness.light,
                  ),
                );
                return child ?? const SizedBox.shrink();
              },
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: _iosPrimary,
                  primary: _iosPrimary,
                  secondary: _iosSecondary,
                  tertiary: const Color(0xFF34C759),
                  surface: _iosSurface,
                  surfaceContainerHighest: _iosCard,
                  error: _iosError,
                  brightness: Brightness.light,
                ),
                visualDensity: VisualDensity.adaptivePlatformDensity,
                scaffoldBackgroundColor: _iosSurface,
                splashFactory: NoSplash.splashFactory,
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: {
                    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                  },
                ),
                cupertinoOverrideTheme: const CupertinoThemeData(
                  primaryColor: _iosPrimary,
                  scaffoldBackgroundColor: _iosSurface,
                  barBackgroundColor: Color(0xF7FFFFFF),
                  textTheme: CupertinoTextThemeData(
                    primaryColor: _iosPrimary,
                    textStyle: TextStyle(
                      color: _iosText,
                      fontSize: 17,
                    ),
                    navTitleTextStyle: TextStyle(
                      color: _iosText,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    navLargeTitleTextStyle: TextStyle(
                      color: _iosText,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                appBarTheme: const AppBarTheme(
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  backgroundColor: Color(0xF7FFFFFF),
                  surfaceTintColor: Colors.transparent,
                  foregroundColor: _iosText,
                  centerTitle: true,
                  titleTextStyle: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _iosText,
                  ),
                  systemOverlayStyle: SystemUiOverlayStyle.dark,
                  iconTheme: IconThemeData(color: _iosPrimary),
                  actionsIconTheme: IconThemeData(color: _iosPrimary),
                ),
                cardTheme: const CardThemeData(
                  color: _iosCard,
                  elevation: 0,
                  shadowColor: Color(0x14000000),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(22)),
                    side: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
                chipTheme: const ChipThemeData(
                  backgroundColor: Color(0xFFFFFFFF),
                  selectedColor: Color(0xFFEAF3FF),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _iosText,
                  ),
                  secondaryLabelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _iosPrimary,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: StadiumBorder(
                    side: BorderSide(color: _iosBorder, width: 1),
                  ),
                ),
                inputDecorationTheme: const InputDecorationTheme(
                  filled: true,
                  fillColor: Color(0xFFFFFFFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    borderSide: BorderSide(color: _iosBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    borderSide: BorderSide(color: _iosPrimary, width: 1.5),
                  ),
                  hintStyle: TextStyle(color: _iosSubtleText),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _iosPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 15,
                    ),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _iosPrimary,
                    side: const BorderSide(
                      color: _iosBorder,
                      width: 1,
                    ),
                    backgroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: _iosPrimary,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                  selectedItemColor: _iosPrimary,
                  unselectedItemColor: _iosSubtleText,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  selectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  unselectedLabelStyle: TextStyle(fontSize: 11),
                ),
                floatingActionButtonTheme: const FloatingActionButtonThemeData(
                  backgroundColor: _iosPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                  ),
                ),
                snackBarTheme: const SnackBarThemeData(
                  backgroundColor: Color(0xFF1F2937),
                  contentTextStyle: TextStyle(color: Colors.white),
                  actionTextColor: _iosSecondary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                dividerTheme: const DividerThemeData(
                  color: Color(0xFFE5E7EB),
                  thickness: 1,
                ),
                textTheme: const TextTheme(
                  displayLarge: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _iosText,
                  ),
                  displayMedium: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _iosText,
                  ),
                  titleLarge: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: _iosText,
                  ),
                  titleMedium: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _iosText,
                  ),
                  bodyLarge: TextStyle(color: _iosText),
                  bodyMedium: TextStyle(color: _iosSubtleText),
                  bodySmall: TextStyle(color: _iosSubtleText),
                ),
              ),
              home: (userToken != null && userId != null)
                  ? (authenticatedHomeBuilder?.call(userId, userToken) ??
                      MainNavigationScreen(userId: userId, token: userToken))
                  : (unauthenticatedHomeBuilder?.call(context) ??
                      const LoginScreen()),
            );
          },
        );
      },
    );
  }
}
