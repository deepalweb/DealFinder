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
  /// **'Deal Finder'**
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
  /// **'© 2025 Deal Finder. All rights reserved.'**
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
  /// **'Join Deal Finder today'**
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

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @profileTab.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTab;

  /// No description provided for @securityTab.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityTab;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose how the app should read across all screens.'**
  String get selectLanguage;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSinhala.
  ///
  /// In en, this message translates to:
  /// **'Sinhala'**
  String get languageSinhala;

  /// No description provided for @languageTamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get languageTamil;

  /// No description provided for @savedDealsAndStores.
  ///
  /// In en, this message translates to:
  /// **'Saved Deals & Stores'**
  String get savedDealsAndStores;

  /// No description provided for @savedDealsStoresSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review your favorites and followed stores in one place.'**
  String get savedDealsStoresSubtitle;

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettingsTitle;

  /// No description provided for @notificationSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control push alerts, categories, and quiet hours.'**
  String get notificationSettingsSubtitle;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @emailCannotBeChangedYet.
  ///
  /// In en, this message translates to:
  /// **'Email cannot be changed from the app yet'**
  String get emailCannotBeChangedYet;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// No description provided for @saveLocalChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Local Changes'**
  String get saveLocalChanges;

  /// No description provided for @merchantDashboard.
  ///
  /// In en, this message translates to:
  /// **'Merchant Dashboard'**
  String get merchantDashboard;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @notificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage push notifications, email alerts, categories, quiet hours, and device testing from the full notification settings screen.'**
  String get notificationsDescription;

  /// No description provided for @openNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Notification Settings'**
  String get openNotificationSettings;

  /// No description provided for @notificationsHelp.
  ///
  /// In en, this message translates to:
  /// **'Use that screen to enable push on this device and send test notifications.'**
  String get notificationsHelp;

  /// No description provided for @noFavoriteDealsYet.
  ///
  /// In en, this message translates to:
  /// **'No favorite deals yet'**
  String get noFavoriteDealsYet;

  /// No description provided for @startFavoritingDeals.
  ///
  /// In en, this message translates to:
  /// **'Start favoriting deals to see them here.'**
  String get startFavoritingDeals;

  /// No description provided for @noFavoriteStoresYet.
  ///
  /// In en, this message translates to:
  /// **'No favorite stores yet'**
  String get noFavoriteStoresYet;

  /// No description provided for @startFollowingStores.
  ///
  /// In en, this message translates to:
  /// **'Start following stores to see them here.'**
  String get startFollowingStores;

  /// No description provided for @noContactInfo.
  ///
  /// In en, this message translates to:
  /// **'No contact info'**
  String get noContactInfo;

  /// No description provided for @chooseImageSource.
  ///
  /// In en, this message translates to:
  /// **'Choose Image Source'**
  String get chooseImageSource;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @profilePictureUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated!'**
  String get profilePictureUpdated;

  /// No description provided for @failedToUpdatePicture.
  ///
  /// In en, this message translates to:
  /// **'Failed to update picture'**
  String get failedToUpdatePicture;

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameCannotBeEmpty;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @storesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get storesPageTitle;

  /// No description provided for @followingStores.
  ///
  /// In en, this message translates to:
  /// **'Following Stores'**
  String get followingStores;

  /// No description provided for @followingStoresSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick access to merchants you already care about'**
  String get followingStoresSubtitle;

  /// No description provided for @popularRightNow.
  ///
  /// In en, this message translates to:
  /// **'Popular Right Now'**
  String get popularRightNow;

  /// No description provided for @popularRightNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stores with the strongest mix of followers and active deals'**
  String get popularRightNowSubtitle;

  /// No description provided for @freshMerchants.
  ///
  /// In en, this message translates to:
  /// **'Fresh Merchants'**
  String get freshMerchants;

  /// No description provided for @freshMerchantsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Newer stores to explore before everyone else finds them'**
  String get freshMerchantsSubtitle;

  /// No description provided for @browseAllStores.
  ///
  /// In en, this message translates to:
  /// **'Browse All Stores'**
  String get browseAllStores;

  /// No description provided for @discoverStoresTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover stores near your style'**
  String get discoverStoresTitle;

  /// No description provided for @discoverStoresSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow standout merchants, compare categories, and jump straight into the best local deals.'**
  String get discoverStoresSubtitle;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @foodStores.
  ///
  /// In en, this message translates to:
  /// **'Food Stores'**
  String get foodStores;

  /// No description provided for @newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// No description provided for @storesSummary.
  ///
  /// In en, this message translates to:
  /// **'{visible} visible • {following} following • {total} total stores'**
  String storesSummary(int visible, int following, int total);

  /// No description provided for @searchStoresHint.
  ///
  /// In en, this message translates to:
  /// **'Search stores or try Sinhala like කෑම, ඉලෙක්ට්‍රොනික්'**
  String get searchStoresHint;

  /// No description provided for @activeFiltersLabel.
  ///
  /// In en, this message translates to:
  /// **'Active filters ({count})'**
  String activeFiltersLabel(int count);

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @searchFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Search: {query}'**
  String searchFilterLabel(String query);

  /// No description provided for @categoryFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}'**
  String categoryFilterLabel(String category);

  /// No description provided for @sortFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort: {sort}'**
  String sortFilterLabel(String sort);

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get mostPopular;

  /// No description provided for @followingFirst.
  ///
  /// In en, this message translates to:
  /// **'Following First'**
  String get followingFirst;

  /// No description provided for @aToZ.
  ///
  /// In en, this message translates to:
  /// **'A to Z'**
  String get aToZ;

  /// No description provided for @noStoresMatchView.
  ///
  /// In en, this message translates to:
  /// **'No stores match this view'**
  String get noStoresMatchView;

  /// No description provided for @noStoresMatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a broader search, switch category, or clear your filters to explore more merchants.'**
  String get noStoresMatchSubtitle;

  /// No description provided for @storesWillAppearSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stores will show up here as soon as merchants start publishing their profiles.'**
  String get storesWillAppearSubtitle;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @showFollowed.
  ///
  /// In en, this message translates to:
  /// **'Show followed'**
  String get showFollowed;

  /// No description provided for @failedToLoadStores.
  ///
  /// In en, this message translates to:
  /// **'Failed to load stores'**
  String get failedToLoadStores;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @resetView.
  ///
  /// In en, this message translates to:
  /// **'Reset view'**
  String get resetView;

  /// No description provided for @filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTitle;

  /// No description provided for @sortByTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortByTitle;

  /// No description provided for @mostRecent.
  ///
  /// In en, this message translates to:
  /// **'Most Recent'**
  String get mostRecent;

  /// No description provided for @highestDiscount.
  ///
  /// In en, this message translates to:
  /// **'Highest Discount'**
  String get highestDiscount;

  /// No description provided for @priceLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get priceLowToHigh;

  /// No description provided for @priceHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get priceHighToLow;

  /// No description provided for @nearest.
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get nearest;

  /// No description provided for @failedToLoadDeals.
  ///
  /// In en, this message translates to:
  /// **'Failed to load deals'**
  String get failedToLoadDeals;

  /// No description provided for @noDealsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No deals available'**
  String get noDealsAvailable;

  /// No description provided for @noDealsMatchView.
  ///
  /// In en, this message translates to:
  /// **'No deals match this view'**
  String get noDealsMatchView;

  /// No description provided for @noDealsMatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a broader category, adjust your price or discount filters, or clear filters to explore more deals.'**
  String get noDealsMatchSubtitle;

  /// No description provided for @nearbyPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearbyPageTitle;

  /// No description provided for @changeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change Location'**
  String get changeLocation;

  /// No description provided for @searchNearbyHint.
  ///
  /// In en, this message translates to:
  /// **'Search nearby deals or Sinhala like කෑම...'**
  String get searchNearbyHint;

  /// No description provided for @allLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLabel;

  /// No description provided for @foodLabel.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get foodLabel;

  /// No description provided for @beautyLabel.
  ///
  /// In en, this message translates to:
  /// **'Beauty'**
  String get beautyLabel;

  /// No description provided for @shoppingLabel.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shoppingLabel;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get listView;

  /// No description provided for @mapView.
  ///
  /// In en, this message translates to:
  /// **'Map View'**
  String get mapView;

  /// No description provided for @noActiveNearbyDeals.
  ///
  /// In en, this message translates to:
  /// **'No active nearby deals'**
  String get noActiveNearbyDeals;

  /// No description provided for @activeNearbyDealsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active nearby deal{pluralSuffix}'**
  String activeNearbyDealsCount(int count, String pluralSuffix);

  /// No description provided for @closestFirst.
  ///
  /// In en, this message translates to:
  /// **'Closest first'**
  String get closestFirst;

  /// No description provided for @bestDealNearby.
  ///
  /// In en, this message translates to:
  /// **'Best deal nearby'**
  String get bestDealNearby;

  /// No description provided for @bestNearby.
  ///
  /// In en, this message translates to:
  /// **'Best Nearby'**
  String get bestNearby;

  /// No description provided for @closest.
  ///
  /// In en, this message translates to:
  /// **'Closest'**
  String get closest;

  /// No description provided for @popularNearYou.
  ///
  /// In en, this message translates to:
  /// **'Popular near you'**
  String get popularNearYou;

  /// No description provided for @endingTodayNearby.
  ///
  /// In en, this message translates to:
  /// **'Ending today nearby'**
  String get endingTodayNearby;

  /// No description provided for @nearbyDealsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby deals'**
  String get nearbyDealsTitle;

  /// No description provided for @resultsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String resultsLabel(int count);

  /// No description provided for @locationRequired.
  ///
  /// In en, this message translates to:
  /// **'Location Required'**
  String get locationRequired;

  /// No description provided for @enableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocation;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @noNearbyDealsFound.
  ///
  /// In en, this message translates to:
  /// **'No nearby deals found'**
  String get noNearbyDealsFound;

  /// No description provided for @noNearbyDealsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try increasing the radius or changing filters to widen the search.'**
  String get noNearbyDealsSubtitle;

  /// No description provided for @endingSoonLabel.
  ///
  /// In en, this message translates to:
  /// **'Ending Soon'**
  String get endingSoonLabel;

  /// No description provided for @liveNearbyOffersReady.
  ///
  /// In en, this message translates to:
  /// **'Live nearby offers are ready to explore.'**
  String get liveNearbyOffersReady;

  /// No description provided for @liveDealsAround.
  ///
  /// In en, this message translates to:
  /// **'Live deals around {locationName} are ready to explore.'**
  String liveDealsAround(String locationName);

  /// No description provided for @nearbyNowCount.
  ///
  /// In en, this message translates to:
  /// **'{count} nearby now'**
  String nearbyNowCount(Object count);

  /// No description provided for @endingSoonCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ending soon'**
  String endingSoonCount(Object count);

  /// No description provided for @freshLocalDeals.
  ///
  /// In en, this message translates to:
  /// **'Fresh local deals'**
  String get freshLocalDeals;

  /// No description provided for @openSearchDealsStores.
  ///
  /// In en, this message translates to:
  /// **'Open search for deals and stores'**
  String get openSearchDealsStores;

  /// No description provided for @searchDealsNearYou.
  ///
  /// In en, this message translates to:
  /// **'Search deals near you'**
  String get searchDealsNearYou;

  /// No description provided for @searchDealsExamples.
  ///
  /// In en, this message translates to:
  /// **'Try: burgers, salons, repair'**
  String get searchDealsExamples;

  /// No description provided for @browseNearbyDeals.
  ///
  /// In en, this message translates to:
  /// **'Browse nearby deals'**
  String get browseNearbyDeals;

  /// No description provided for @under1km.
  ///
  /// In en, this message translates to:
  /// **'Under 1km'**
  String get under1km;

  /// No description provided for @bankCards.
  ///
  /// In en, this message translates to:
  /// **'Bank Cards'**
  String get bankCards;

  /// No description provided for @offlineShowingCachedDeals.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing cached deals'**
  String get offlineShowingCachedDeals;

  /// No description provided for @noDealsFoundInView.
  ///
  /// In en, this message translates to:
  /// **'No deals found in this view'**
  String get noDealsFoundInView;

  /// No description provided for @tryRefreshOrBrowse.
  ///
  /// In en, this message translates to:
  /// **'Try refreshing, explore nearby deals, or open the full deals list to keep browsing.'**
  String get tryRefreshOrBrowse;

  /// No description provided for @noDealsMatchSelectedCategory.
  ///
  /// In en, this message translates to:
  /// **'No deals match the selected category right now. Clear the filter or switch to another category.'**
  String get noDealsMatchSelectedCategory;

  /// No description provided for @clearCategory.
  ///
  /// In en, this message translates to:
  /// **'Clear category'**
  String get clearCategory;

  /// No description provided for @refreshDeals.
  ///
  /// In en, this message translates to:
  /// **'Refresh deals'**
  String get refreshDeals;

  /// No description provided for @topDealsNearYou.
  ///
  /// In en, this message translates to:
  /// **'Top Deals Near You'**
  String get topDealsNearYou;

  /// No description provided for @nearbyPicksReady.
  ///
  /// In en, this message translates to:
  /// **'Nearby picks ready right now'**
  String get nearbyPicksReady;

  /// No description provided for @nearbyPicksAround.
  ///
  /// In en, this message translates to:
  /// **'Nearby picks around {locationName}'**
  String nearbyPicksAround(String locationName);

  /// No description provided for @nearbyPicksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} nearby picks'**
  String nearbyPicksCount(int count);

  /// No description provided for @openMap.
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get openMap;

  /// No description provided for @enableLocationUnlockNearby.
  ///
  /// In en, this message translates to:
  /// **'Enable location to unlock nearby deals'**
  String get enableLocationUnlockNearby;

  /// No description provided for @turnOnLocation.
  ///
  /// In en, this message translates to:
  /// **'Turn on location'**
  String get turnOnLocation;

  /// No description provided for @showNearbyDealsMapAccess.
  ///
  /// In en, this message translates to:
  /// **'Show nearby deals, map access, and faster local results.'**
  String get showNearbyDealsMapAccess;

  /// No description provided for @locationEnabledLoading.
  ///
  /// In en, this message translates to:
  /// **'Location enabled! Loading nearby deals...'**
  String get locationEnabledLoading;

  /// No description provided for @recommendedForYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended For You'**
  String get recommendedForYouTitle;

  /// No description provided for @popularPicksNearYou.
  ///
  /// In en, this message translates to:
  /// **'Popular picks based on what is working near you'**
  String get popularPicksNearYou;

  /// No description provided for @popularPicksLearning.
  ///
  /// In en, this message translates to:
  /// **'Popular picks while we learn your preferences'**
  String get popularPicksLearning;

  /// No description provided for @bankCardOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank Card Offers'**
  String get bankCardOffersTitle;

  /// No description provided for @bankCardOffersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Credit and debit card promotions from your banks'**
  String get bankCardOffersSubtitle;

  /// No description provided for @browseCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Browse Categories'**
  String get browseCategoriesTitle;

  /// No description provided for @browseCategoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Jump into the deal type you care about fastest'**
  String get browseCategoriesSubtitle;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @flashSalesTitle.
  ///
  /// In en, this message translates to:
  /// **'Flash Sales'**
  String get flashSalesTitle;

  /// No description provided for @flashSalesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Time-sensitive promotions worth checking now'**
  String get flashSalesSubtitle;

  /// No description provided for @newDealsTitle.
  ///
  /// In en, this message translates to:
  /// **'New Deals'**
  String get newDealsTitle;

  /// No description provided for @newDealsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fresh deals just added'**
  String get newDealsSubtitle;

  /// No description provided for @browseAllDealsCount.
  ///
  /// In en, this message translates to:
  /// **'Browse All {count} Deals'**
  String browseAllDealsCount(int count);

  /// No description provided for @browseAllDeals.
  ///
  /// In en, this message translates to:
  /// **'Browse all deals'**
  String get browseAllDeals;

  /// No description provided for @viewsLabel.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get viewsLabel;

  /// No description provided for @likesLabel.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likesLabel;

  /// No description provided for @commentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsLabel;

  /// No description provided for @clicksLabel.
  ///
  /// In en, this message translates to:
  /// **'Clicks'**
  String get clicksLabel;

  /// No description provided for @directionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directionsLabel;

  /// No description provided for @featuredLabel.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featuredLabel;

  /// No description provided for @endingTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Ending today'**
  String get endingTodayLabel;

  /// No description provided for @getDirectionsToMerchant.
  ///
  /// In en, this message translates to:
  /// **'Get directions to merchant'**
  String get getDirectionsToMerchant;

  /// No description provided for @visitNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Visit Now'**
  String get visitNowLabel;

  /// No description provided for @openOrderLink.
  ///
  /// In en, this message translates to:
  /// **'Open order link'**
  String get openOrderLink;

  /// No description provided for @orderNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get orderNowLabel;

  /// No description provided for @pickupOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup Order'**
  String get pickupOrderLabel;

  /// No description provided for @callMerchant.
  ///
  /// In en, this message translates to:
  /// **'Call merchant'**
  String get callMerchant;

  /// No description provided for @callLabel.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callLabel;

  /// No description provided for @messageOnWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Message merchant on WhatsApp'**
  String get messageOnWhatsApp;

  /// No description provided for @whatsAppLabel.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsAppLabel;

  /// No description provided for @openDealLink.
  ///
  /// In en, this message translates to:
  /// **'Open deal link'**
  String get openDealLink;

  /// No description provided for @goToDealLabel.
  ///
  /// In en, this message translates to:
  /// **'Go to Deal'**
  String get goToDealLabel;

  /// No description provided for @openMerchantWebsite.
  ///
  /// In en, this message translates to:
  /// **'Open merchant website'**
  String get openMerchantWebsite;

  /// No description provided for @websiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get websiteLabel;

  /// No description provided for @openDealLabel.
  ///
  /// In en, this message translates to:
  /// **'Open deal'**
  String get openDealLabel;

  /// No description provided for @toggleFavoriteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Toggle Favorite'**
  String get toggleFavoriteTooltip;

  /// No description provided for @dealLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Deal link copied!'**
  String get dealLinkCopied;

  /// No description provided for @youMightAlsoLike.
  ///
  /// In en, this message translates to:
  /// **'You might also like'**
  String get youMightAlsoLike;

  /// No description provided for @errorLoadingRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Error loading recommendations'**
  String get errorLoadingRecommendations;

  /// No description provided for @noRecommendationsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No recommendations available'**
  String get noRecommendationsAvailable;

  /// No description provided for @ratingsReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ratings & Reviews'**
  String get ratingsReviewsTitle;

  /// No description provided for @ratingSingular.
  ///
  /// In en, this message translates to:
  /// **'rating'**
  String get ratingSingular;

  /// No description provided for @ratingsPlural.
  ///
  /// In en, this message translates to:
  /// **'ratings'**
  String get ratingsPlural;

  /// No description provided for @rateThisDeal.
  ///
  /// In en, this message translates to:
  /// **'Rate this deal'**
  String get rateThisDeal;

  /// No description provided for @yourRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Your rating:'**
  String get yourRatingLabel;

  /// No description provided for @loginToRateDeal.
  ///
  /// In en, this message translates to:
  /// **'Log in to rate this deal.'**
  String get loginToRateDeal;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first to comment!'**
  String get noCommentsYet;

  /// No description provided for @loginToWriteComment.
  ///
  /// In en, this message translates to:
  /// **'Log in to write a comment'**
  String get loginToWriteComment;

  /// No description provided for @writeCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get writeCommentHint;

  /// No description provided for @postLabel.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postLabel;

  /// No description provided for @locationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationTitle;

  /// No description provided for @distanceFromHere.
  ///
  /// In en, this message translates to:
  /// **'{distance} from here'**
  String distanceFromHere(String distance);

  /// No description provided for @couldNotLaunchPrefix.
  ///
  /// In en, this message translates to:
  /// **'Could not launch'**
  String get couldNotLaunchPrefix;

  /// No description provided for @noMerchantPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'No merchant phone number available.'**
  String get noMerchantPhoneNumber;

  /// No description provided for @couldNotOpenWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp.'**
  String get couldNotOpenWhatsApp;

  /// No description provided for @pleaseLoginTo.
  ///
  /// In en, this message translates to:
  /// **'Please log in to {action}.'**
  String pleaseLoginTo(String action);

  /// No description provided for @ratingSaved.
  ///
  /// In en, this message translates to:
  /// **'Rating saved!'**
  String get ratingSaved;

  /// No description provided for @commentPosted.
  ///
  /// In en, this message translates to:
  /// **'Comment posted!'**
  String get commentPosted;

  /// No description provided for @couldNotStartPhoneCall.
  ///
  /// In en, this message translates to:
  /// **'Could not start the phone call.'**
  String get couldNotStartPhoneCall;

  /// No description provided for @failedToSaveRating.
  ///
  /// In en, this message translates to:
  /// **'Failed to save rating'**
  String get failedToSaveRating;

  /// No description provided for @failedToPostComment.
  ///
  /// In en, this message translates to:
  /// **'Failed to post comment'**
  String get failedToPostComment;

  /// No description provided for @soldByLabel.
  ///
  /// In en, this message translates to:
  /// **'Sold by'**
  String get soldByLabel;

  /// No description provided for @copyShareableLink.
  ///
  /// In en, this message translates to:
  /// **'Copy shareable link'**
  String get copyShareableLink;

  /// No description provided for @detailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Details:'**
  String get detailsTitle;

  /// No description provided for @validityTitle.
  ///
  /// In en, this message translates to:
  /// **'Validity:'**
  String get validityTitle;

  /// No description provided for @startsLabel.
  ///
  /// In en, this message translates to:
  /// **'Starts:'**
  String get startsLabel;

  /// No description provided for @expiresLabel.
  ///
  /// In en, this message translates to:
  /// **'Expires:'**
  String get expiresLabel;

  /// No description provided for @termsAndConditionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditionsTitle;

  /// No description provided for @cardOfferDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Card Offer Details'**
  String get cardOfferDetailsTitle;

  /// No description provided for @cardOfferDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check eligible cards, offer type, and spend conditions.'**
  String get cardOfferDetailsSubtitle;

  /// No description provided for @cardOfferDetailsNote.
  ///
  /// In en, this message translates to:
  /// **'Before paying, confirm the exact eligible bank, card type, discount cap, and whether the offer applies in-store, online, or on selected days only.'**
  String get cardOfferDetailsNote;
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
