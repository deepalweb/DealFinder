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
import 'src/config/app_theme.dart';
import 'firebase_options.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

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
                final brightness = MediaQuery.of(context).platformBrightness;
                SystemChrome.setSystemUIOverlayStyle(
                  AppTheme.systemOverlayStyle(brightness),
                );
                return child ?? const SizedBox.shrink();
              },
              theme: AppTheme.lightTheme(),
              darkTheme: AppTheme.darkTheme(),
              themeMode: ThemeMode.system,
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
