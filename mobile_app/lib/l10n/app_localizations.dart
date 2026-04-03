import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta')
  ];

  /// App title
  ///
  /// In en, this message translates to:
  /// **'DealFinder'**
  String get appTitle;

  /// Welcome message on home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}!'**
  String welcomeBack(String name);

  /// Home screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Find the best deals for you'**
  String get findBestDeals;

  /// Search bar hint text
  ///
  /// In en, this message translates to:
  /// **'Search deals, categories, merchants...'**
  String get searchHint;

  /// Featured deals section title
  ///
  /// In en, this message translates to:
  /// **'Featured Deals'**
  String get featuredDeals;

  /// Nearby deals section title
  ///
  /// In en, this message translates to:
  /// **'Nearby Deals'**
  String get nearbyDeals;

  /// Trending section title
  ///
  /// In en, this message translates to:
  /// **'Trending Now'**
  String get trendingNow;

  /// View all button
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Quick action nearby label
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// Quick action coupons label
  ///
  /// In en, this message translates to:
  /// **'Coupons'**
  String get coupons;

  /// Quick action scan QR label
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQR;

  /// Quick action favorites label
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Stats deals label
  ///
  /// In en, this message translates to:
  /// **'Deals'**
  String get deals;

  /// Stats merchants label
  ///
  /// In en, this message translates to:
  /// **'Merchants'**
  String get merchants;

  /// Stats users label
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// Footer privacy policy link
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Footer about link
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Footer contact link
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// Footer copyright text
  ///
  /// In en, this message translates to:
  /// **'© 2025 DealFinder. All rights reserved.'**
  String get copyright;

  /// Empty state for featured deals
  ///
  /// In en, this message translates to:
  /// **'No featured deals available.'**
  String get noFeaturedDeals;

  /// Empty state for nearby deals
  ///
  /// In en, this message translates to:
  /// **'No other deals available currently.'**
  String get noNearbyDeals;

  /// Empty state for trending deals
  ///
  /// In en, this message translates to:
  /// **'No trending deals available.'**
  String get noTrendingDeals;

  /// API error title
  ///
  /// In en, this message translates to:
  /// **'API Connection Failed'**
  String get apiConnectionFailed;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Notifications screen title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Coupons snackbar message
  ///
  /// In en, this message translates to:
  /// **'Coupons coming soon!'**
  String get couponsComing;

  /// Days left countdown
  ///
  /// In en, this message translates to:
  /// **'{days}d left'**
  String daysLeft(int days);

  /// Hours left countdown
  ///
  /// In en, this message translates to:
  /// **'{hours}h left'**
  String hoursLeft(int hours);

  /// Minutes left countdown
  ///
  /// In en, this message translates to:
  /// **'{minutes}m left'**
  String minutesLeft(int minutes);

  /// Expired label
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// Trending hot label
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get hot;

  /// Login screen title
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// Login screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSubtitle;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Sign in button
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Social login divider text
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No account prompt
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// Sign up link
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Register screen title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// Register screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Join DealFinder today'**
  String get registerSubtitle;

  /// Full name field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Already have account prompt
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Get directions button
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirections;

  /// Share deal button
  ///
  /// In en, this message translates to:
  /// **'Share Deal'**
  String get shareDeal;

  /// Save to favorites button
  ///
  /// In en, this message translates to:
  /// **'Save to Favorites'**
  String get saveFavorites;

  /// Remove favorite button
  ///
  /// In en, this message translates to:
  /// **'Remove Favorite'**
  String get removeFavorite;

  /// Go to promotion button
  ///
  /// In en, this message translates to:
  /// **'Go to Promotion'**
  String get goToPromotion;

  /// Visit website button
  ///
  /// In en, this message translates to:
  /// **'Visit Website'**
  String get visitWebsite;

  /// Write review button
  ///
  /// In en, this message translates to:
  /// **'Write Review'**
  String get writeReview;

  /// Report deal button
  ///
  /// In en, this message translates to:
  /// **'Report Deal'**
  String get reportDeal;

  /// Add to calendar button
  ///
  /// In en, this message translates to:
  /// **'Add to Calendar'**
  String get addToCalendar;

  /// No location snackbar
  ///
  /// In en, this message translates to:
  /// **'No location available for this deal.'**
  String get noLocationAvailable;

  /// Maps error snackbar
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Maps.'**
  String get couldNotOpenMaps;

  /// All deals tab label
  ///
  /// In en, this message translates to:
  /// **'All Deals'**
  String get allDeals;

  /// Stores tab label
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get stores;

  /// Home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Profile tab label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
