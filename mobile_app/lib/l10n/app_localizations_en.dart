// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DealFinder';

  @override
  String welcomeBack(String name) {
    return 'Welcome back, $name!';
  }

  @override
  String get findBestDeals => 'Find the best deals for you';

  @override
  String get searchHint => 'Search deals, categories, merchants...';

  @override
  String get featuredDeals => 'Featured Deals';

  @override
  String get nearbyDeals => 'Nearby Deals';

  @override
  String get trendingNow => 'Trending Now';

  @override
  String get viewAll => 'View All';

  @override
  String get nearby => 'Nearby';

  @override
  String get coupons => 'Coupons';

  @override
  String get scanQR => 'Scan QR';

  @override
  String get favorites => 'Favorites';

  @override
  String get deals => 'Deals';

  @override
  String get merchants => 'Merchants';

  @override
  String get users => 'Users';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get about => 'About';

  @override
  String get contact => 'Contact';

  @override
  String get copyright => '© 2025 DealFinder. All rights reserved.';

  @override
  String get noFeaturedDeals => 'No featured deals available.';

  @override
  String get noNearbyDeals => 'No other deals available currently.';

  @override
  String get noTrendingDeals => 'No trending deals available.';

  @override
  String get apiConnectionFailed => 'API Connection Failed';

  @override
  String get retry => 'Retry';

  @override
  String get notifications => 'Notifications';

  @override
  String get couponsComing => 'Coupons coming soon!';

  @override
  String daysLeft(int days) {
    return '${days}d left';
  }

  @override
  String hoursLeft(int hours) {
    return '${hours}h left';
  }

  @override
  String minutesLeft(int minutes) {
    return '${minutes}m left';
  }

  @override
  String get expired => 'Expired';

  @override
  String get hot => 'Hot';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerSubtitle => 'Join DealFinder today';

  @override
  String get fullName => 'Full Name';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get getDirections => 'Get Directions';

  @override
  String get shareDeal => 'Share Deal';

  @override
  String get saveFavorites => 'Save to Favorites';

  @override
  String get removeFavorite => 'Remove Favorite';

  @override
  String get goToPromotion => 'Go to Promotion';

  @override
  String get visitWebsite => 'Visit Website';

  @override
  String get writeReview => 'Write Review';

  @override
  String get reportDeal => 'Report Deal';

  @override
  String get addToCalendar => 'Add to Calendar';

  @override
  String get noLocationAvailable => 'No location available for this deal.';

  @override
  String get couldNotOpenMaps => 'Could not open Google Maps.';

  @override
  String get allDeals => 'All Deals';

  @override
  String get stores => 'Stores';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';
}
