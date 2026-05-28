// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Deal Finder';

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
  String get copyright => '© 2025 Deal Finder. All rights reserved.';

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
  String get registerSubtitle => 'Join Deal Finder today';

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

  @override
  String get myProfile => 'My Profile';

  @override
  String get profileTab => 'Profile';

  @override
  String get securityTab => 'Security';

  @override
  String get appLanguage => 'App Language';

  @override
  String get selectLanguage =>
      'Choose how the app should read across all screens.';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSinhala => 'Sinhala';

  @override
  String get languageTamil => 'Tamil';

  @override
  String get savedDealsAndStores => 'Saved Deals & Stores';

  @override
  String get savedDealsStoresSubtitle =>
      'Review your favorites and followed stores in one place.';

  @override
  String get notificationSettingsTitle => 'Notification Settings';

  @override
  String get notificationSettingsSubtitle =>
      'Control push alerts, categories, and quiet hours.';

  @override
  String get accountDetails => 'Account Details';

  @override
  String get emailCannotBeChangedYet =>
      'Email cannot be changed from the app yet';

  @override
  String get role => 'Role';

  @override
  String get businessName => 'Business Name';

  @override
  String get saveLocalChanges => 'Save Local Changes';

  @override
  String get merchantDashboard => 'Merchant Dashboard';

  @override
  String get logout => 'Logout';

  @override
  String get changePassword => 'Change Password';

  @override
  String get notificationsDescription =>
      'Manage push notifications, email alerts, categories, quiet hours, and device testing from the full notification settings screen.';

  @override
  String get openNotificationSettings => 'Open Notification Settings';

  @override
  String get notificationsHelp =>
      'Use that screen to enable push on this device and send test notifications.';

  @override
  String get noFavoriteDealsYet => 'No favorite deals yet';

  @override
  String get startFavoritingDeals => 'Start favoriting deals to see them here.';

  @override
  String get noFavoriteStoresYet => 'No favorite stores yet';

  @override
  String get startFollowingStores => 'Start following stores to see them here.';

  @override
  String get noContactInfo => 'No contact info';

  @override
  String get chooseImageSource => 'Choose Image Source';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get profilePictureUpdated => 'Profile picture updated!';

  @override
  String get failedToUpdatePicture => 'Failed to update picture';

  @override
  String get nameCannotBeEmpty => 'Name cannot be empty';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully!';

  @override
  String get failedToUpdateProfile => 'Failed to update profile';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String get storesPageTitle => 'Stores';

  @override
  String get followingStores => 'Following Stores';

  @override
  String get followingStoresSubtitle =>
      'Quick access to merchants you already care about';

  @override
  String get popularRightNow => 'Popular Right Now';

  @override
  String get popularRightNowSubtitle =>
      'Stores with the strongest mix of followers and active deals';

  @override
  String get freshMerchants => 'Fresh Merchants';

  @override
  String get freshMerchantsSubtitle =>
      'Newer stores to explore before everyone else finds them';

  @override
  String get browseAllStores => 'Browse All Stores';

  @override
  String get discoverStoresTitle => 'Discover stores near your style';

  @override
  String get discoverStoresSubtitle =>
      'Follow standout merchants, compare categories, and jump straight into the best local deals.';

  @override
  String get following => 'Following';

  @override
  String get popular => 'Popular';

  @override
  String get foodStores => 'Food Stores';

  @override
  String get newest => 'Newest';

  @override
  String storesSummary(int visible, int following, int total) {
    return '$visible visible • $following following • $total total stores';
  }

  @override
  String get searchStoresHint =>
      'Search stores or try Sinhala like කෑම, ඉලෙක්ට්‍රොනික්';

  @override
  String activeFiltersLabel(int count) {
    return 'Active filters ($count)';
  }

  @override
  String get clearAll => 'Clear all';

  @override
  String searchFilterLabel(String query) {
    return 'Search: $query';
  }

  @override
  String categoryFilterLabel(String category) {
    return 'Category: $category';
  }

  @override
  String sortFilterLabel(String sort) {
    return 'Sort: $sort';
  }

  @override
  String get mostPopular => 'Most Popular';

  @override
  String get followingFirst => 'Following First';

  @override
  String get aToZ => 'A to Z';

  @override
  String get noStoresMatchView => 'No stores match this view';

  @override
  String get noStoresMatchSubtitle =>
      'Try a broader search, switch category, or clear your filters to explore more merchants.';

  @override
  String get storesWillAppearSubtitle =>
      'Stores will show up here as soon as merchants start publishing their profiles.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get showFollowed => 'Show followed';

  @override
  String get failedToLoadStores => 'Failed to load stores';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get resetView => 'Reset view';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get sortByTitle => 'Sort by';

  @override
  String get mostRecent => 'Most Recent';

  @override
  String get highestDiscount => 'Highest Discount';

  @override
  String get priceLowToHigh => 'Price: Low to High';

  @override
  String get priceHighToLow => 'Price: High to Low';

  @override
  String get nearest => 'Nearest';

  @override
  String get failedToLoadDeals => 'Failed to load deals';

  @override
  String get noDealsAvailable => 'No deals available';

  @override
  String get noDealsMatchView => 'No deals match this view';

  @override
  String get noDealsMatchSubtitle =>
      'Try a broader category, adjust your price or discount filters, or clear filters to explore more deals.';

  @override
  String get nearbyPageTitle => 'Nearby';

  @override
  String get changeLocation => 'Change Location';

  @override
  String get searchNearbyHint => 'Search nearby deals or Sinhala like කෑම...';

  @override
  String get allLabel => 'All';

  @override
  String get foodLabel => 'Food';

  @override
  String get beautyLabel => 'Beauty';

  @override
  String get shoppingLabel => 'Shopping';

  @override
  String get listView => 'List View';

  @override
  String get mapView => 'Map View';

  @override
  String get noActiveNearbyDeals => 'No active nearby deals';

  @override
  String activeNearbyDealsCount(int count, String pluralSuffix) {
    return '$count active nearby deal$pluralSuffix';
  }

  @override
  String get closestFirst => 'Closest first';

  @override
  String get bestDealNearby => 'Best deal nearby';

  @override
  String get bestNearby => 'Best Nearby';

  @override
  String get closest => 'Closest';

  @override
  String get popularNearYou => 'Popular near you';

  @override
  String get endingTodayNearby => 'Ending today nearby';

  @override
  String get nearbyDealsTitle => 'Nearby deals';

  @override
  String resultsLabel(int count) {
    return '$count results';
  }

  @override
  String get locationRequired => 'Location Required';

  @override
  String get enableLocation => 'Enable Location';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get noNearbyDealsFound => 'No nearby deals found';

  @override
  String get noNearbyDealsSubtitle =>
      'Try increasing the radius or changing filters to widen the search.';

  @override
  String get endingSoonLabel => 'Ending Soon';

  @override
  String get liveNearbyOffersReady =>
      'Live nearby offers are ready to explore.';

  @override
  String liveDealsAround(String locationName) {
    return 'Live deals around $locationName are ready to explore.';
  }

  @override
  String nearbyNowCount(Object count) {
    return '$count nearby now';
  }

  @override
  String endingSoonCount(Object count) {
    return '$count ending soon';
  }

  @override
  String get freshLocalDeals => 'Fresh local deals';

  @override
  String get openSearchDealsStores => 'Open search for deals and stores';

  @override
  String get searchDealsNearYou => 'Search deals near you';

  @override
  String get searchDealsExamples => 'Try: burgers, salons, repair';

  @override
  String get browseNearbyDeals => 'Browse nearby deals';

  @override
  String get under1km => 'Under 1km';

  @override
  String get bankCards => 'Bank Cards';

  @override
  String get offlineShowingCachedDeals => 'Offline — showing cached deals';

  @override
  String get noDealsFoundInView => 'No deals found in this view';

  @override
  String get tryRefreshOrBrowse =>
      'Try refreshing, explore nearby deals, or open the full deals list to keep browsing.';

  @override
  String get noDealsMatchSelectedCategory =>
      'No deals match the selected category right now. Clear the filter or switch to another category.';

  @override
  String get clearCategory => 'Clear category';

  @override
  String get refreshDeals => 'Refresh deals';

  @override
  String get topDealsNearYou => 'Top Deals Near You';

  @override
  String get nearbyPicksReady => 'Nearby picks ready right now';

  @override
  String nearbyPicksAround(String locationName) {
    return 'Nearby picks around $locationName';
  }

  @override
  String nearbyPicksCount(int count) {
    return '$count nearby picks';
  }

  @override
  String get openMap => 'Open map';

  @override
  String get enableLocationUnlockNearby =>
      'Enable location to unlock nearby deals';

  @override
  String get turnOnLocation => 'Turn on location';

  @override
  String get showNearbyDealsMapAccess =>
      'Show nearby deals, map access, and faster local results.';

  @override
  String get locationEnabledLoading =>
      'Location enabled! Loading nearby deals...';

  @override
  String get recommendedForYouTitle => 'Recommended For You';

  @override
  String get popularPicksNearYou =>
      'Popular picks based on what is working near you';

  @override
  String get popularPicksLearning =>
      'Popular picks while we learn your preferences';

  @override
  String get bankCardOffersTitle => 'Bank Card Offers';

  @override
  String get bankCardOffersSubtitle =>
      'Credit and debit card promotions from your banks';

  @override
  String get browseCategoriesTitle => 'Browse Categories';

  @override
  String get browseCategoriesSubtitle =>
      'Jump into the deal type you care about fastest';

  @override
  String get allCategories => 'All Categories';

  @override
  String get flashSalesTitle => 'Flash Sales';

  @override
  String get flashSalesSubtitle =>
      'Time-sensitive promotions worth checking now';

  @override
  String get newDealsTitle => 'New Deals';

  @override
  String get newDealsSubtitle => 'Fresh deals just added';

  @override
  String browseAllDealsCount(int count) {
    return 'Browse All $count Deals';
  }

  @override
  String get browseAllDeals => 'Browse all deals';

  @override
  String get viewsLabel => 'Views';

  @override
  String get likesLabel => 'Likes';

  @override
  String get commentsLabel => 'Comments';

  @override
  String get clicksLabel => 'Clicks';

  @override
  String get directionsLabel => 'Directions';

  @override
  String get featuredLabel => 'Featured';

  @override
  String get endingTodayLabel => 'Ending today';

  @override
  String get getDirectionsToMerchant => 'Get directions to merchant';

  @override
  String get visitNowLabel => 'Visit Now';

  @override
  String get openOrderLink => 'Open order link';

  @override
  String get orderNowLabel => 'Order Now';

  @override
  String get pickupOrderLabel => 'Pickup Order';

  @override
  String get callMerchant => 'Call merchant';

  @override
  String get callLabel => 'Call';

  @override
  String get messageOnWhatsApp => 'Message merchant on WhatsApp';

  @override
  String get whatsAppLabel => 'WhatsApp';

  @override
  String get openDealLink => 'Open deal link';

  @override
  String get goToDealLabel => 'Go to Deal';

  @override
  String get openMerchantWebsite => 'Open merchant website';

  @override
  String get websiteLabel => 'Website';

  @override
  String get openDealLabel => 'Open deal';

  @override
  String get toggleFavoriteTooltip => 'Toggle Favorite';

  @override
  String get dealLinkCopied => 'Deal link copied!';

  @override
  String get youMightAlsoLike => 'You might also like';

  @override
  String get errorLoadingRecommendations => 'Error loading recommendations';

  @override
  String get noRecommendationsAvailable => 'No recommendations available';

  @override
  String get ratingsReviewsTitle => 'Ratings & Reviews';

  @override
  String get ratingSingular => 'rating';

  @override
  String get ratingsPlural => 'ratings';

  @override
  String get rateThisDeal => 'Rate this deal';

  @override
  String get yourRatingLabel => 'Your rating:';

  @override
  String get loginToRateDeal => 'Log in to rate this deal.';

  @override
  String get noCommentsYet => 'No comments yet. Be the first to comment!';

  @override
  String get loginToWriteComment => 'Log in to write a comment';

  @override
  String get writeCommentHint => 'Write a comment...';

  @override
  String get postLabel => 'Post';

  @override
  String get locationTitle => 'Location';

  @override
  String distanceFromHere(String distance) {
    return '$distance from here';
  }

  @override
  String get couldNotLaunchPrefix => 'Could not launch';

  @override
  String get noMerchantPhoneNumber => 'No merchant phone number available.';

  @override
  String get couldNotOpenWhatsApp => 'Could not open WhatsApp.';

  @override
  String pleaseLoginTo(String action) {
    return 'Please log in to $action.';
  }

  @override
  String get ratingSaved => 'Rating saved!';

  @override
  String get commentPosted => 'Comment posted!';

  @override
  String get couldNotStartPhoneCall => 'Could not start the phone call.';

  @override
  String get failedToSaveRating => 'Failed to save rating';

  @override
  String get failedToPostComment => 'Failed to post comment';

  @override
  String get soldByLabel => 'Sold by';

  @override
  String get copyShareableLink => 'Copy shareable link';

  @override
  String get detailsTitle => 'Details:';

  @override
  String get validityTitle => 'Validity:';

  @override
  String get startsLabel => 'Starts:';

  @override
  String get expiresLabel => 'Expires:';

  @override
  String get termsAndConditionsTitle => 'Terms & Conditions';

  @override
  String get cardOfferDetailsTitle => 'Card Offer Details';

  @override
  String get cardOfferDetailsSubtitle =>
      'Check eligible cards, offer type, and spend conditions.';

  @override
  String get cardOfferDetailsNote =>
      'Before paying, confirm the exact eligible bank, card type, discount cap, and whether the offer applies in-store, online, or on selected days only.';
}
