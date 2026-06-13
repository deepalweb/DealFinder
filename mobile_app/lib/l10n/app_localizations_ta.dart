// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'டீல் ஃபைண்டர்';

  @override
  String welcomeBack(String name) {
    return 'மீண்டும் வரவேற்கிறோம், $name!';
  }

  @override
  String get findBestDeals => 'உங்களுக்கான சிறந்த டீல்களை கண்டறியுங்கள்';

  @override
  String get searchHint => 'டீல்கள், வகைகள், வணிகர்களை தேடுங்கள்...';

  @override
  String get featuredDeals => 'சிறப்பு டீல்கள்';

  @override
  String get nearbyDeals => 'அருகிலுள்ள டீல்கள்';

  @override
  String get trendingNow => 'இப்போது பிரபலமானவை';

  @override
  String get viewAll => 'அனைத்தும் காண்க';

  @override
  String get nearby => 'அருகில்';

  @override
  String get scanQR => 'QR ஸ்கேன்';

  @override
  String get favorites => 'பிடித்தவை';

  @override
  String get deals => 'டீல்கள்';

  @override
  String get merchants => 'வணிகர்கள்';

  @override
  String get users => 'பயனர்கள்';

  @override
  String get privacyPolicy => 'தனியுரிமை கொள்கை';

  @override
  String get about => 'எங்களை பற்றி';

  @override
  String get contact => 'தொடர்பு கொள்ளுங்கள்';

  @override
  String get copyright =>
      '© 2025 டீல் ஃபைண்டர். அனைத்து உரிமைகளும் பாதுகாக்கப்பட்டவை.';

  @override
  String get noFeaturedDeals => 'சிறப்பு டீல்கள் எதுவும் இல்லை.';

  @override
  String get noNearbyDeals => 'தற்போது வேறு டீல்கள் இல்லை.';

  @override
  String get noTrendingDeals => 'பிரபலமான டீல்கள் இல்லை.';

  @override
  String get apiConnectionFailed => 'API இணைப்பு தோல்வியடைந்தது';

  @override
  String get retry => 'மீண்டும் முயற்சிக்கவும்';

  @override
  String get notifications => 'அறிவிப்புகள்';

  @override
  String daysLeft(int days) {
    return '$days நாட்கள் மீதமுள்ளன';
  }

  @override
  String hoursLeft(int hours) {
    return '$hours மணி நேரம் மீதமுள்ளது';
  }

  @override
  String minutesLeft(int minutes) {
    return '$minutes நிமிடங்கள் மீதமுள்ளன';
  }

  @override
  String get expired => 'காலாவதியானது';

  @override
  String get hot => 'பிரபலம்';

  @override
  String get loginTitle => 'மீண்டும் வரவேற்கிறோம்';

  @override
  String get loginSubtitle => 'தொடர உள்நுழையவும்';

  @override
  String get email => 'மின்னஞ்சல்';

  @override
  String get password => 'கடவுச்சொல்';

  @override
  String get forgotPassword => 'கடவுச்சொல் மறந்துவிட்டதா?';

  @override
  String get signIn => 'உள்நுழைக';

  @override
  String get orContinueWith => 'அல்லது இதன் மூலம் தொடரவும்';

  @override
  String get noAccount => 'கணக்கு இல்லையா?';

  @override
  String get signUp => 'பதிவு செய்யுங்கள்';

  @override
  String get registerTitle => 'கணக்கு உருவாக்கவும்';

  @override
  String get registerSubtitle => 'இன்று டீல் ஃபைண்டரில் சேரவும்';

  @override
  String get fullName => 'முழு பெயர்';

  @override
  String get confirmPassword => 'கடவுச்சொல்லை உறுதிப்படுத்தவும்';

  @override
  String get alreadyHaveAccount => 'ஏற்கனவே கணக்கு உள்ளதா?';

  @override
  String get getDirections => 'வழிகாட்டுதல் பெறுக';

  @override
  String get shareDeal => 'டீலை பகிரவும்';

  @override
  String get saveFavorites => 'பிடித்தவைகளில் சேர்க்கவும்';

  @override
  String get removeFavorite => 'பிடித்தவைகளிலிருந்து நீக்கவும்';

  @override
  String get goToPromotion => 'சலுகைக்கு செல்லவும்';

  @override
  String get visitWebsite => 'வலைத்தளத்தை பார்வையிடவும்';

  @override
  String get writeReview => 'மதிப்பாய்வு எழுதவும்';

  @override
  String get reportDeal => 'டீலை புகாரளிக்கவும்';

  @override
  String get addToCalendar => 'நாட்காட்டியில் சேர்க்கவும்';

  @override
  String get noLocationAvailable => 'இந்த டீலுக்கு இடம் இல்லை.';

  @override
  String get couldNotOpenMaps => 'Google Maps திறக்க முடியவில்லை.';

  @override
  String get allDeals => 'அனைத்து டீல்கள்';

  @override
  String get stores => 'கடைகள்';

  @override
  String get home => 'முகப்பு';

  @override
  String get profile => 'சுயவிவரம்';

  @override
  String get myProfile => 'என் சுயவிவரம்';

  @override
  String get profileTab => 'சுயவிவரம்';

  @override
  String get securityTab => 'பாதுகாப்பு';

  @override
  String get appLanguage => 'பயன்பாட்டு மொழி';

  @override
  String get selectLanguage =>
      'முழு பயன்பாட்டிலும் பயன்படுத்த வேண்டிய மொழியை தேர்வு செய்யுங்கள்.';

  @override
  String get language => 'மொழி';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSinhala => 'සිංහල';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get savedDealsAndStores => 'சேமித்த Deals மற்றும் Stores';

  @override
  String get savedDealsStoresSubtitle =>
      'உங்கள் விருப்ப deals மற்றும் பின்தொடரும் stores-ஐ ஒரே இடத்தில் பார்க்கவும்.';

  @override
  String get notificationSettingsTitle => 'அறிவிப்பு அமைப்புகள்';

  @override
  String get notificationSettingsSubtitle =>
      'Push alerts, categories மற்றும் quiet hours ஆகியவற்றை கட்டுப்படுத்துங்கள்.';

  @override
  String get accountDetails => 'கணக்கு விவரங்கள்';

  @override
  String get emailCannotBeChangedYet =>
      'Email ஐ இப்போது app மூலம் மாற்ற முடியாது';

  @override
  String get role => 'பங்கு';

  @override
  String get businessName => 'வணிக பெயர்';

  @override
  String get saveLocalChanges => 'Local மாற்றங்களை சேமிக்கவும்';

  @override
  String get merchantDashboard => 'Merchant Dashboard';

  @override
  String get logout => 'Logout';

  @override
  String get changePassword => 'கடவுச்சொல்லை மாற்றவும்';

  @override
  String get notificationsDescription =>
      'முழு notification settings screen-இல் இருந்து push notifications, email alerts, categories மற்றும் quiet hours ஐ நிர்வகிக்கவும்.';

  @override
  String get openNotificationSettings => 'அறிவிப்பு அமைப்புகளை திறக்கவும்';

  @override
  String get notificationsHelp =>
      'அந்த screen-இல் இந்த சாதனத்தில் push enable செய்து test notifications அனுப்பலாம்.';

  @override
  String get noFavoriteDealsYet => 'விருப்ப deals இன்னும் இல்லை';

  @override
  String get startFavoritingDeals =>
      'அவற்றை இங்கே பார்க்க deals-ஐ favorite செய்யத் தொடங்குங்கள்.';

  @override
  String get noFavoriteStoresYet => 'விருப்ப stores இன்னும் இல்லை';

  @override
  String get startFollowingStores =>
      'அவற்றை இங்கே பார்க்க stores-ஐ follow செய்யத் தொடங்குங்கள்.';

  @override
  String get noContactInfo => 'தொடர்பு தகவல் இல்லை';

  @override
  String get chooseImageSource => 'பட மூலத்தை தேர்வு செய்யவும்';

  @override
  String get camera => 'கேமரா';

  @override
  String get gallery => 'கேலரி';

  @override
  String get profilePictureUpdated => 'சுயவிவர படம் புதுப்பிக்கப்பட்டது!';

  @override
  String get failedToUpdatePicture => 'படத்தை புதுப்பிக்க முடியவில்லை';

  @override
  String get nameCannotBeEmpty => 'பெயர் காலியாக இருக்க முடியாது';

  @override
  String get profileUpdatedSuccessfully =>
      'சுயவிவரம் வெற்றிகரமாக புதுப்பிக்கப்பட்டது!';

  @override
  String get failedToUpdateProfile => 'சுயவிவரத்தை புதுப்பிக்க முடியவில்லை';

  @override
  String get removedFromFavorites => 'விருப்பங்களில் இருந்து அகற்றப்பட்டது';

  @override
  String get storesPageTitle => 'கடைகள்';

  @override
  String get followingStores => 'பின்தொடரும் கடைகள்';

  @override
  String get followingStoresSubtitle =>
      'நீங்கள் ஏற்கனவே விரும்பும் வணிகர்களுக்கு விரைவான அணுகல்';

  @override
  String get popularRightNow => 'இப்போது பிரபலமானவை';

  @override
  String get popularRightNowSubtitle =>
      'Followers மற்றும் active deals அதிகமுள்ள கடைகள்';

  @override
  String get freshMerchants => 'புதிய வணிகர்கள்';

  @override
  String get freshMerchantsSubtitle =>
      'மற்றவர்கள் கண்டுபிடிக்கும் முன் புதிய stores-ஐ பாருங்கள்';

  @override
  String get browseAllStores => 'அனைத்து கடைகளையும் பார்க்கவும்';

  @override
  String get discoverStoresTitle =>
      'உங்கள் விருப்பத்திற்கு பொருந்தும் கடைகளை கண்டறியுங்கள்';

  @override
  String get discoverStoresSubtitle =>
      'சிறந்த local deals-க்கு நேராக செல்ல merchants-ஐ follow செய்யவும், categories-ஐ compare செய்யவும்.';

  @override
  String get following => 'பின்தொடருவது';

  @override
  String get popular => 'பிரபலமானது';

  @override
  String get foodStores => 'உணவு கடைகள்';

  @override
  String get newest => 'புதியவை';

  @override
  String storesSummary(int visible, int following, int total) {
    return '$visible காண்பிக்கப்படுகிறது • $following follow செய்கிறீர்கள் • மொத்தம் $total stores';
  }

  @override
  String get searchStoresHint =>
      'Stores ஐ தேடுங்கள் அல்லது கෑම, ඉලෙක්ට්‍රොනික් போன்ற Sinhala ஐ முயற்சிக்கவும்';

  @override
  String activeFiltersLabel(int count) {
    return 'செயலில் உள்ள filters ($count)';
  }

  @override
  String get clearAll => 'அனைத்தையும் நீக்கு';

  @override
  String searchFilterLabel(String query) {
    return 'தேடல்: $query';
  }

  @override
  String categoryFilterLabel(String category) {
    return 'வகை: $category';
  }

  @override
  String sortFilterLabel(String sort) {
    return 'வரிசை: $sort';
  }

  @override
  String get mostPopular => 'மிகவும் பிரபலமானது';

  @override
  String get followingFirst => 'Follow செய்தவை முதலில்';

  @override
  String get aToZ => 'A முதல் Z';

  @override
  String get noStoresMatchView => 'இந்த view-க்கு பொருந்தும் stores இல்லை';

  @override
  String get noStoresMatchSubtitle =>
      'மேலும் merchants பார்க்க விரிவான தேடல், வேறு category, அல்லது filters clear செய்யவும்.';

  @override
  String get storesWillAppearSubtitle =>
      'Merchants தங்கள் profiles publish செய்தவுடன் stores இங்கே தோன்றும்.';

  @override
  String get clearFilters => 'Filters ஐ நீக்கு';

  @override
  String get showFollowed => 'Follow செய்ததை காட்டு';

  @override
  String get failedToLoadStores => 'கடைகளை ஏற்ற முடியவில்லை';

  @override
  String get unknownError => 'அறியப்படாத பிழை';

  @override
  String get tryAgain => 'மீண்டும் முயற்சிக்கவும்';

  @override
  String get resetView => 'View ஐ மீட்டமைக்கவும்';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get sortByTitle => 'Sort by';

  @override
  String get mostRecent => 'அண்மையவை';

  @override
  String get highestDiscount => 'அதிக தள்ளுபடி';

  @override
  String get priceLowToHigh => 'விலை: குறைவு முதல் அதிகம்';

  @override
  String get priceHighToLow => 'விலை: அதிகம் முதல் குறைவு';

  @override
  String get nearest => 'அருகிலுள்ளது';

  @override
  String get failedToLoadDeals => 'Deals ஐ ஏற்ற முடியவில்லை';

  @override
  String get noDealsAvailable => 'Deals இல்லை';

  @override
  String get noDealsMatchView => 'இந்த view-க்கு deals பொருந்தவில்லை';

  @override
  String get noDealsMatchSubtitle =>
      'மேலும் deals பார்க்க category-ஐ விரிவுபடுத்தவும், விலை அல்லது discount filters ஐ மாற்றவும், அல்லது filters clear செய்யவும்.';

  @override
  String get nearbyPageTitle => 'அருகில்';

  @override
  String get changeLocation => 'இடத்தை மாற்றவும்';

  @override
  String get searchNearbyHint =>
      'அருகிலுள்ள deals-ஐ தேடுங்கள் அல்லது කෑම போன்ற சொல்லை பயன்படுத்துங்கள்...';

  @override
  String get allLabel => 'அனைத்தும்';

  @override
  String get foodLabel => 'உணவு';

  @override
  String get beautyLabel => 'அழகு';

  @override
  String get shoppingLabel => 'ஷாப்பிங்';

  @override
  String get listView => 'பட்டியல் View';

  @override
  String get mapView => 'Map View';

  @override
  String get noActiveNearbyDeals => 'செயலில் உள்ள அருகிலுள்ள deals இல்லை';

  @override
  String activeNearbyDealsCount(int count, String pluralSuffix) {
    return '$count செயலில் உள்ள அருகிலுள்ள deal$pluralSuffix';
  }

  @override
  String get closestFirst => 'அருகிலுள்ளவை முதலில்';

  @override
  String get bestDealNearby => 'சிறந்த அருகிலுள்ள deal';

  @override
  String get bestNearby => 'சிறந்த அருகில்';

  @override
  String get closest => 'அருகில்';

  @override
  String get popularNearYou => 'உங்கள் அருகிலுள்ள பிரபலமானவை';

  @override
  String get endingTodayNearby => 'இன்று முடியும் அருகிலுள்ள deals';

  @override
  String get nearbyDealsTitle => 'அருகிலுள்ள deals';

  @override
  String resultsLabel(int count) {
    return '$count முடிவுகள்';
  }

  @override
  String get locationRequired => 'இடம் தேவைப்படுகிறது';

  @override
  String get enableLocation => 'இடத்தை செயல்படுத்தவும்';

  @override
  String get openSettings => 'அமைப்புகளை திறக்கவும்';

  @override
  String get noNearbyDealsFound => 'அருகிலுள்ள deals எதுவும் கிடைக்கவில்லை';

  @override
  String get noNearbyDealsSubtitle =>
      'தேடலை விரிவுபடுத்த radius ஐ அதிகரிக்கவும் அல்லது filters ஐ மாற்றவும்.';

  @override
  String get endingSoonLabel => 'விரைவில் முடியும்';

  @override
  String get liveNearbyOffersReady =>
      'அருகிலுள்ள live offers பார்க்க தயாராக உள்ளன.';

  @override
  String liveDealsAround(String locationName) {
    return '$locationName சுற்றியுள்ள live deals தயாராக உள்ளன.';
  }

  @override
  String nearbyNowCount(Object count) {
    return 'இப்போது அருகில் $count';
  }

  @override
  String endingSoonCount(Object count) {
    return 'விரைவில் முடியும் $count';
  }

  @override
  String get freshLocalDeals => 'புதிய local deals';

  @override
  String get openSearchDealsStores =>
      'deals மற்றும் stores க்கான search ஐத் திறக்கவும்';

  @override
  String get searchDealsNearYou => 'உங்கள் அருகிலுள்ள deals ஐ தேடுங்கள்';

  @override
  String get searchDealsExamples => 'உதா: burgers, salons, repair';

  @override
  String get browseNearbyDeals => 'அருகிலுள்ள deals ஐ பார்க்கவும்';

  @override
  String get under1km => '1km க்குள்';

  @override
  String get bankCards => 'Bank Cards';

  @override
  String get offlineShowingCachedDeals =>
      'Offline — cached deals காட்டப்படுகிறது';

  @override
  String get noDealsFoundInView => 'இந்த view இல் deals எதுவும் கிடைக்கவில்லை';

  @override
  String get tryRefreshOrBrowse =>
      'Refresh செய்யவும், nearby deals பார்க்கவும், அல்லது full deals list ஐ திறக்கவும்.';

  @override
  String get noDealsMatchSelectedCategory =>
      'தேர்ந்த category க்கு இப்போது deals பொருந்தவில்லை. Filter ஐ clear செய்யவும் அல்லது வேறு category ஐத் தேர்ந்தெடுக்கவும்.';

  @override
  String get clearCategory => 'Category ஐ clear செய்';

  @override
  String get refreshDeals => 'Deals ஐ refresh செய்';

  @override
  String get topDealsNearYou => 'உங்கள் அருகிலுள்ள Top Deals';

  @override
  String get nearbyPicksReady => 'அருகிலுள்ள picks இப்போது தயாராக உள்ளன';

  @override
  String nearbyPicksAround(String locationName) {
    return '$locationName சுற்றியுள்ள picks';
  }

  @override
  String nearbyPicksCount(int count) {
    return '$count அருகிலுள்ள picks';
  }

  @override
  String get openMap => 'Map ஐ திறக்கவும்';

  @override
  String get enableLocationUnlockNearby =>
      'Nearby deals பார்க்க location ஐ enable செய்யவும்';

  @override
  String get turnOnLocation => 'Location ஐ இயக்கவும்';

  @override
  String get showNearbyDealsMapAccess =>
      'Nearby deals, map access மற்றும் வேகமான local results ஐ காண்க.';

  @override
  String get locationEnabledLoading =>
      'Location enabled! Nearby deals load ஆகிறது...';

  @override
  String get recommendedForYouTitle => 'உங்களுக்கான பரிந்துரைகள்';

  @override
  String get popularPicksNearYou =>
      'உங்கள் அருகில் நன்றாக செயல்படும் popular picks';

  @override
  String get popularPicksLearning =>
      'உங்கள் விருப்பங்களை கற்றுக்கொள்ளும் வரை popular picks';

  @override
  String get bankCardOffersTitle => 'Bank Card Offers';

  @override
  String get bankCardOffersSubtitle =>
      'உங்கள் வங்கிகளின் credit மற்றும் debit card promotions';

  @override
  String get browseCategoriesTitle => 'Categories ஐ பார்க்கவும்';

  @override
  String get browseCategoriesSubtitle =>
      'உங்களுக்கு முக்கியமான deal type க்கு விரைவாக செல்லுங்கள்';

  @override
  String get allCategories => 'அனைத்து Categories';

  @override
  String get flashSalesTitle => 'Flash Sales';

  @override
  String get flashSalesSubtitle =>
      'இப்போது பார்க்க வேண்டிய time-sensitive promotions';

  @override
  String get newDealsTitle => 'புதிய Deals';

  @override
  String get newDealsSubtitle => 'புதியதாக சேர்க்கப்பட்ட deals';

  @override
  String browseAllDealsCount(int count) {
    return 'அனைத்து $count Deals ஐ பார்க்கவும்';
  }

  @override
  String get browseAllDeals => 'அனைத்து deals ஐ பார்க்கவும்';

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
  String get endingTodayLabel => 'இன்று முடியும்';

  @override
  String get getDirectionsToMerchant => 'Merchant க்கு directions பெறுங்கள்';

  @override
  String get visitNowLabel => 'இப்போது செல்லவும்';

  @override
  String get openOrderLink => 'Order link ஐத் திறக்கவும்';

  @override
  String get orderNowLabel => 'இப்போது Order செய்யவும்';

  @override
  String get pickupOrderLabel => 'Pickup Order';

  @override
  String get callMerchant => 'Merchant ஐ அழைக்கவும்';

  @override
  String get callLabel => 'Call';

  @override
  String get messageOnWhatsApp =>
      'WhatsApp இல் merchant க்கு message செய்யவும்';

  @override
  String get whatsAppLabel => 'WhatsApp';

  @override
  String get openDealLink => 'Deal link ஐத் திறக்கவும்';

  @override
  String get goToDealLabel => 'Deal க்கு செல்லவும்';

  @override
  String get openMerchantWebsite => 'Merchant website ஐ திறக்கவும்';

  @override
  String get websiteLabel => 'Website';

  @override
  String get openDealLabel => 'Deal ஐ திறக்கவும்';

  @override
  String get toggleFavoriteTooltip => 'Favorite ஐ toggle செய்யவும்';

  @override
  String get dealLinkCopied => 'Deal link copy செய்யப்பட்டது!';

  @override
  String get youMightAlsoLike => 'இதைவும் நீங்கள் விரும்பலாம்';

  @override
  String get errorLoadingRecommendations =>
      'Recommendations load செய்வதில் பிழை';

  @override
  String get noRecommendationsAvailable => 'Recommendations இல்லை';

  @override
  String get ratingsReviewsTitle => 'Ratings மற்றும் Reviews';

  @override
  String get ratingSingular => 'rating';

  @override
  String get ratingsPlural => 'ratings';

  @override
  String get rateThisDeal => 'இந்த deal ஐ rate செய்யவும்';

  @override
  String get yourRatingLabel => 'உங்கள் rating:';

  @override
  String get loginToRateDeal => 'இந்த deal ஐ rate செய்ய log in செய்யவும்.';

  @override
  String get noCommentsYet =>
      'இன்னும் comments இல்லை. முதலில் comment செய்யுங்கள்!';

  @override
  String get loginToWriteComment => 'Comment எழுத log in செய்யவும்';

  @override
  String get writeCommentHint => 'Comment எழுதுங்கள்...';

  @override
  String get postLabel => 'Post';

  @override
  String get locationTitle => 'இடம்';

  @override
  String distanceFromHere(String distance) {
    return 'இங்கிருந்து $distance';
  }

  @override
  String get couldNotLaunchPrefix => 'Launch செய்ய முடியவில்லை';

  @override
  String get noMerchantPhoneNumber => 'Merchant phone number இல்லை.';

  @override
  String get couldNotOpenWhatsApp => 'WhatsApp ஐ திறக்க முடியவில்லை.';

  @override
  String pleaseLoginTo(String action) {
    return '$action செய்ய log in செய்யவும்.';
  }

  @override
  String get ratingSaved => 'Rating save செய்யப்பட்டது!';

  @override
  String get commentPosted => 'Comment post செய்யப்பட்டது!';

  @override
  String get couldNotStartPhoneCall => 'Phone call ஐ தொடங்க முடியவில்லை.';

  @override
  String get failedToSaveRating => 'Rating save செய்ய முடியவில்லை';

  @override
  String get failedToPostComment => 'Comment post செய்ய முடியவில்லை';

  @override
  String get soldByLabel => 'விற்பவர்';

  @override
  String get copyShareableLink => 'Shareable link ஐ copy செய்யவும்';

  @override
  String get detailsTitle => 'விவரங்கள்:';

  @override
  String get validityTitle => 'செல்லுபடியாகும் காலம்:';

  @override
  String get startsLabel => 'தொடக்கம்:';

  @override
  String get expiresLabel => 'முடிவு:';

  @override
  String get termsAndConditionsTitle => 'விதிமுறைகள் மற்றும் நிபந்தனைகள்';

  @override
  String get cardOfferDetailsTitle => 'Card Offer விவரங்கள்';

  @override
  String get cardOfferDetailsSubtitle =>
      'சரியான cards, offer type மற்றும் spend conditions ஐ சரிபார்க்கவும்.';

  @override
  String get cardOfferDetailsNote =>
      'பணம் செலுத்தும் முன் சரியான bank, card type, discount cap மற்றும் offer in-store, online அல்லது குறிப்பிட்ட நாட்களில் மட்டுமே பொருந்துமா என்பதை உறுதிப்படுத்துங்கள்.';
}
