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
  String get coupons => 'கூப்பன்கள்';

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
  String get couponsComing => 'கூப்பன்கள் விரைவில் வருகின்றன!';

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
}
