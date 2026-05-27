'use client';

import { useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import toast from 'react-hot-toast';
import PromotionCard from '@/components/ui/PromotionCard';
import SkeletonCard from '@/components/ui/SkeletonCard';
import { useAuth } from '@/contexts/AuthContext';
import { type LanguageCode, useLanguage } from '@/contexts/LanguageContext';
import { DEALFINDER_CATEGORIES, normalizeCategoryId } from '@/lib/categories';
import { AiAPI, BankOfferAPI, PromotionAPI, UserAPI, invalidateCache } from '@/lib/api';

type Promotion = {
  _id?: string;
  id?: string;
  title?: string;
  description?: string;
  category?: string;
  discount?: string | number;
  featured?: boolean;
  url?: string;
  image?: string;
  originalPrice?: number | string;
  discountedPrice?: number | string;
  maximumBenefit?: number | string;
  createdAt?: string;
  endDate?: string;
  recommendationReasons?: string[];
  aiMeta?: {
    score?: number;
    distanceKm?: number | null;
  };
  merchant?: string | {
    _id?: string;
    name?: string;
    currency?: string;
    distance?: number;
    location?: {
      coordinates?: [number, number];
    };
  };
};

type FavoritePromotion = Promotion;
const DOWNLOAD_URL = 'https://drive.google.com/uc?export=download&id=12xY8BPO4HqN6oH4vj0wcJSwXiDM0tDKu';

const CATEGORIES = DEALFINDER_CATEGORIES.filter((category) =>
  ['electronics', 'fashion', 'food_bev', 'travel', 'beauty_health', 'home_garden', 'entertainment', 'all'].includes(category.id)
).map((category) => ({
  id: category.id,
  name: category.id === 'all' ? 'More' : category.name,
  icon: category.icon,
}));

const TRENDING_SEARCHES = [
  'Pizza deals Colombo',
  'Bank offers Sri Lanka',
  'Buffet offers',
  'Hotel deals Colombo',
  'Dialog packages',
];

const HOME_COPY: Record<LanguageCode, {
  heroBadge: string;
  heroTitle: string;
  heroDescription: string;
  primaryCta: string;
  secondaryCta: string;
  pills: string[];
  searchLabel: string;
  searchPlaceholder: string;
  searchButton: string;
  trendingLabel: string;
  statsEyebrow: string;
  statsTitle: string;
  statsDescription: string;
  positioningEyebrow: string;
  positioningTitle: string;
  positioningDescription: string;
  highlightTitles: [string, string];
  highlightPoints: [string[], string[]];
  trustEyebrow: string;
  trustTitle: string;
  verificationSteps: string[];
  trustBoxTitle: string;
  trustBoxText: string;
  compareEyebrow: string;
  compareTitle: string;
  compareDescription: string;
  comparisonTitles: [string, string];
  comparisonItems: [string[], string[]];
  previewEyebrow: string;
  previewTitle: string;
  previewCards: { label: string; title: string; body: string }[];
  previewDetailLabel: string;
  previewWhyLabel: string;
  previewWhyItems: string[];
  liveSectionEyebrow: string;
  liveSectionTitle: string;
  endingSoonEyebrow: string;
  endingSoonTitle: string;
  nearbyEyebrow: string;
  nearbyTitle: string;
  categoryTitle: string;
  categoryMeta: string;
  categoryFooter: string;
  businessEyebrow: string;
  businessTitle: string;
  businessDescription: string;
  businessBenefits: string[];
  businessPrimary: string;
  businessSecondary: string;
  businessPanelTitle: string;
  businessPanelItems: { label: string; value: string }[];
  finalEyebrow: string;
  finalTitle: string;
  finalDescription: string;
  finalPrimary: string;
  finalSecondary: string;
}> = {
  en: {
    heroBadge: 'Sri Lanka deal discovery for shoppers who want real, current offers',
    heroTitle: 'The fastest way to find Sri Lankan deals that are still valid',
    heroDescription: 'Stop checking bank apps, restaurant pages, Instagram promos, and WhatsApp groups one by one. DealFinder puts food promos, bank offers, hotel deals, electronics discounts, and nearby finds in one place.',
    primaryCta: "Get Today's Best Deals",
    secondaryCta: 'Browse Live Deals',
    pills: ['Verified offer details', 'Nearby deal discovery', 'Bank offers and local promos'],
    searchLabel: 'Search what you actually want to save on',
    searchPlaceholder: 'Pizza deals Colombo, hotel buffet, bank offers...',
    searchButton: 'See Matches',
    trendingLabel: 'Trending searches',
    statsEyebrow: 'Live platform snapshot',
    statsTitle: 'Real signals instead of padded vanity metrics',
    statsDescription: 'This section reflects live inventory, merchant breadth, and current coverage so the proof feels more credible at a glance.',
    positioningEyebrow: 'Sri Lanka deals hub',
    positioningTitle: 'Find restaurant deals, bank offers, hotel promotions, and shopping discounts in Sri Lanka',
    positioningDescription: 'DealFinder helps shoppers discover Sri Lanka deals faster by bringing together Colombo restaurant offers, supermarket discounts, bank card promotions, hotel deals, electronics sales, and nearby flash offers in one place.',
    highlightTitles: ['Popular deal searches in Sri Lanka', 'What businesses can promote'],
    highlightPoints: [
      [
        'Find Sri Lanka bank offers, card promotions, and supermarket discounts in one place',
        'Browse restaurant deals in Colombo, buffet offers, and hotel promotions without jumping across apps',
        'Check electronics deals, fashion discounts, and nearby offers before they expire',
      ],
      [
        'Restaurant promotions, cafe deals, buffet discounts, and food delivery offers',
        'Hotel deals, weekend stay offers, spa packages, and travel promotions in Sri Lanka',
        'Retail discounts, mobile deals, bank card offers, and seasonal flash sales',
      ],
    ],
    trustEyebrow: 'Trusted deal details',
    trustTitle: 'Why shoppers trust these Sri Lanka offers',
    verificationSteps: [
      'Live Sri Lanka deals show clear expiry timing so shoppers can spot limited-time offers quickly.',
      'Nearby deals only use your location when you allow it, helping you find promotions close to you.',
      'Each deal stays connected to the original store, restaurant, hotel, bank offer, or merchant source.',
    ],
    trustBoxTitle: 'Real deals, not empty coupon pages',
    trustBoxText: 'The homepage focuses on live deal counts, real merchant coverage, and useful categories such as food deals, hotel offers, bank promotions, and retail discounts in Sri Lanka.',
    compareEyebrow: 'Better than scattered searching',
    compareTitle: 'A smarter way to find Sri Lanka deals than checking Daraz, bank apps, and promo pages separately',
    compareDescription: 'Shoppers looking for Sri Lanka bank offers, restaurant deals, hotel promotions, supermarket discounts, and nearby flash sales need one place to compare live offers instead of jumping across multiple websites and apps.',
    comparisonTitles: ['Checking deals the hard way', 'Finding offers with DealFinder'],
    comparisonItems: [
      [
        'Search Daraz, bank apps, restaurant Facebook pages, and promo groups one by one',
        'Waste time checking whether a Sri Lanka deal, buffet offer, or card promotion is still valid',
        'Miss nearby restaurant deals, hotel offers, and flash sales because they are scattered across channels',
      ],
      [
        'See Sri Lanka bank offers, food promos, hotel deals, supermarket discounts, and flash sales in one place',
        'Get a faster shortlist when you search for restaurant deals in Colombo or nearby shopping discounts',
        'Save, compare, and revisit the deals worth acting on before they expire',
      ],
    ],
    previewEyebrow: 'Real app experience',
    previewTitle: 'Search, compare, and save the best deals in Sri Lanka',
    previewCards: [
      { label: 'Search', title: 'Search by store or category', body: 'Look for restaurant deals, bank offers, hotel promotions, electronics discounts, or city-based offers.' },
      { label: 'Compare', title: 'Compare live offers quickly', body: 'Understand which Sri Lanka deal gives the better discount without opening multiple sources.' },
      { label: 'Save', title: 'Save deals before they expire', body: 'Keep nearby promotions, buffet offers, and flash sales handy when you want to revisit them.' },
    ],
    previewDetailLabel: 'Deal details',
    previewWhyLabel: 'Why shoppers use it',
    previewWhyItems: [
      'See clear savings, expiry timing, and merchant details at a glance',
      'Find Sri Lanka restaurant deals, bank offers, and retail discounts faster',
      'Use one app for discovery, comparison, and saved offers',
    ],
    liveSectionEyebrow: 'Live now',
    liveSectionTitle: 'Best deals today',
    endingSoonEyebrow: 'Urgency',
    endingSoonTitle: 'Ending soon',
    nearbyEyebrow: 'Nearby picks',
    nearbyTitle: 'Nearby deals',
    categoryTitle: 'Browse deals by category',
    categoryMeta: 'Popular ways shoppers explore offers',
    categoryFooter: 'Explore common deal interests like restaurant offers in Colombo, Sri Lanka bank promotions, hotel deals, buffet discounts, and electronics savings.',
    businessEyebrow: 'For businesses',
    businessTitle: 'Help merchants reach shoppers who are already looking for deals',
    businessDescription: 'DealFinder can help restaurants, hotels, supermarkets, banks, and retail brands promote live offers to people who are actively searching for discounts, nearby deals, and limited-time promotions in Sri Lanka.',
    businessBenefits: [
      'Promote current offers in one trusted deals app',
      'Reach nearby shoppers with strong purchase intent',
      'Push seasonal, weekend, and expiring campaigns',
      'Support restaurant, hotel, retail, and bank promotions',
    ],
    businessPrimary: 'Explore merchant pages',
    businessSecondary: 'Contact the team',
    businessPanelTitle: 'Why merchants can benefit',
    businessPanelItems: [
      { label: 'Offer types', value: 'Restaurant deals, hotel offers, bank promos, retail discounts' },
      { label: 'Audience intent', value: 'Shoppers already searching for nearby savings and active offers' },
      { label: 'Best use cases', value: 'Weekend campaigns, buffet promotions, flash sales, and expiring deals' },
    ],
    finalEyebrow: 'App-first CTA',
    finalTitle: 'Ready to stop hunting across ten different promo channels?',
    finalDescription: "Get the app, discover today's best deals, and keep the full browse path as a secondary option.",
    finalPrimary: 'Start saving now',
    finalSecondary: 'See nearby offers',
  },
  si: {
    heroBadge: 'සැබෑ සහ වර්තමාන වට්ටම් සොයන ශ්‍රී ලාංකිකයන් සඳහා',
    heroTitle: 'තවමත් වලංගු ශ්‍රී ලංකා වට්ටම් හොයාගන්න වේගවත්ම මාර්ගය',
    heroDescription: 'Bank apps, restaurant pages, Instagram promos, සහ WhatsApp groups එකින් එක බලන්න වෙලාව වැය කරන්න එපා. DealFinder එකේ food promos, bank offers, hotel deals, electronics discounts, සහ ඔබ අසල offers එක තැනකින් බලන්න පුළුවන්.',
    primaryCta: 'අදම හොඳම වට්ටම් බලන්න',
    secondaryCta: 'සජීවී වට්ටම් බලන්න',
    pills: ['සත්‍යාපිත offer විස්තර', 'ඔබ අසල වට්ටම් සොයන්න', 'Bank offers සහ local promos'],
    searchLabel: 'ඔබට බේරාගන්න අවශ්‍ය දේ සෙවීම ආරම්භ කරන්න',
    searchPlaceholder: 'Colombo pizza deals, hotel buffet, bank offers...',
    searchButton: 'ගැළපෙන offers බලන්න',
    trendingLabel: 'ලෝකප්‍රිය සෙවුම්',
    statsEyebrow: 'සජීවී platform snapshot',
    statsTitle: 'අතිශයෝක්ති නැති සැබෑ සංඛ්‍යා',
    statsDescription: 'මෙහි දැක්වෙන්නේ සජීවී deals, merchants, සහ coverage වන නිසා platform එක ගැන විශ්වාසයක් ලැබේ.',
    positioningEyebrow: 'ශ්‍රී ලංකා deals hub',
    positioningTitle: 'Restaurant deals, bank offers, hotel promotions, සහ shopping discounts එක තැනකින්',
    positioningDescription: 'DealFinder මගින් Colombo restaurant offers, supermarket discounts, bank card promotions, hotel deals, electronics sales, සහ nearby flash offers එක තැනකින් හොයාගන්න පුළුවන්.',
    highlightTitles: ['ශ්‍රී ලංකාවේ ජනප්‍රිය deal සෙවුම්', 'ව්‍යාපාර ප්‍රවර්ධනය කළ හැකි offers'],
    highlightPoints: [
      [
        'Sri Lanka bank offers, card promotions, සහ supermarket discounts එක තැනකින් බලන්න',
        'Colombo restaurant deals, buffet offers, සහ hotel promotions apps කිහිපයක් අතර නොයමින් බලන්න',
        'Electronics deals, fashion discounts, සහ nearby offers expire වෙන්න කලින් බලන්න',
      ],
      [
        'Restaurant promotions, cafe deals, buffet discounts, සහ food delivery offers',
        'Hotel deals, weekend stay offers, spa packages, සහ travel promotions',
        'Retail discounts, mobile deals, bank card offers, සහ seasonal flash sales',
      ],
    ],
    trustEyebrow: 'විශ්වාසදායක deal විස්තර',
    trustTitle: 'මෙම Sri Lanka offers ගැන shoppersලා විශ්වාස කරන හේතුව',
    verificationSteps: [
      'සජීවී deals වල expiry timing පැහැදිලිව පෙන්වන නිසා limited-time offers ඉක්මනින් අඳුනාගන්න පුළුවන්.',
      'Nearby deals සඳහා location භාවිතා කරන්නේ ඔබ අවසර දුන්නොත් පමණි.',
      'සෑම deal එකක්ම මුල් store, restaurant, hotel, bank offer, හෝ merchant source එකට සම්බන්ධයි.',
    ],
    trustBoxTitle: 'හිස් coupon pages නොව සැබෑ deals',
    trustBoxText: 'Homepage එක live deal counts, merchant coverage, සහ Sri Lanka food deals, hotel offers, bank promotions, retail discounts වැනි categories මත පදනම් වේ.',
    compareEyebrow: 'විවිධ තැන් වල සෙවීමට වඩා හොඳයි',
    compareTitle: 'Daraz, bank apps, සහ promo pages වෙන වෙනම බලනවට වඩා Sri Lanka deals සොයන්න පහසු මාර්ගයක්',
    compareDescription: 'Sri Lanka bank offers, restaurant deals, hotel promotions, supermarket discounts, සහ nearby flash sales සොයන අයට websites සහ apps ගණනාවක් අතර යාම වෙනුවට එක තැනකින් compare කරන්න පුළුවන්.',
    comparisonTitles: ['Deals හොයන අමාරු ක්‍රමය', 'DealFinder සමඟ වට්ටම් සොයන්න'],
    comparisonItems: [
      [
        'Daraz, bank apps, restaurant Facebook pages, සහ promo groups එකින් එක සොයන්න වෙයි',
        'Sri Lanka deal එකක් හෝ buffet/card promotion එකක් තවමත් වලංගුද කියලා manually බලන්න වෙයි',
        'Nearby restaurant deals, hotel offers, සහ flash sales විවිධ තැන්වල පැතිරී තිබෙන නිසා මඟ හැරෙයි',
      ],
      [
        'Sri Lanka bank offers, food promos, hotel deals, supermarket discounts, සහ flash sales එක තැනකින් බලන්න',
        'Colombo restaurant deals හෝ nearby shopping discounts සොයන විට කෙටි shortlist එකක් ලැබේ',
        'Expire වෙන්න කලින් deals save කර compare කර නැවත බලන්න',
      ],
    ],
    previewEyebrow: 'ඇත්ත app අත්දැකීම',
    previewTitle: 'ශ්‍රී ලංකාවේ හොඳම deals සොයන්න, compare කරන්න, save කරන්න',
    previewCards: [
      { label: 'Search', title: 'Store එකෙන් හෝ category එකෙන් සොයන්න', body: 'Restaurant deals, bank offers, hotel promotions, electronics discounts, හෝ city-based offers සොයන්න.' },
      { label: 'Compare', title: 'සජීවී offers ඉක්මනින් compare කරන්න', body: 'Multiple sources open නොකර වඩා හොඳ discount එක කුමක්ද කියා තේරුම් ගන්න.' },
      { label: 'Save', title: 'Expire වෙන්න කලින් deals save කරන්න', body: 'Nearby promotions, buffet offers, සහ flash sales නැවත බලන්න හොඳට තබාගන්න.' },
    ],
    previewDetailLabel: 'Deal විස්තර',
    previewWhyLabel: 'Shoppersලා මෙය භාවිතා කරන හේතු',
    previewWhyItems: [
      'Savings, expiry timing, merchant details එක තැනකින් බලන්න',
      'Sri Lanka restaurant deals, bank offers, සහ retail discounts ඉක්මනින් සොයන්න',
      'Discovery, comparison, සහ saved offers සඳහා එක app එකක් භාවිතා කරන්න',
    ],
    liveSectionEyebrow: 'දැන්ම සජීවීව',
    liveSectionTitle: 'අද හොඳම deals',
    endingSoonEyebrow: 'ඉක්මන් වීමට',
    endingSoonTitle: 'අවසන් වීමට ආසන්නයි',
    nearbyEyebrow: 'ඔබ අසල picks',
    nearbyTitle: 'ඔබ අසල deals',
    categoryTitle: 'Category අනුව deals බලන්න',
    categoryMeta: 'Shoppersලා ජනප්‍රියව බලන මාර්ග',
    categoryFooter: 'Colombo restaurant offers, Sri Lanka bank promotions, hotel deals, buffet discounts, සහ electronics savings වැනි ප්‍රසිද්ධ deal interests බලන්න.',
    businessEyebrow: 'ව්‍යාපාර සඳහා',
    businessTitle: 'Deals සොයන shoppersලා වෙත merchantsලා ගෙනයාමට උදව් කරන්න',
    businessDescription: 'DealFinder මගින් restaurants, hotels, supermarkets, banks, සහ retail brands වල live offers, nearby deals, සහ limited-time promotions සොයන ශ්‍රී ලාංකිකයන්ට පෙන්විය හැක.',
    businessBenefits: [
      'Current offers විශ්වාසදායක deals app එකකින් promote කරන්න',
      'නොබැඳිවම මිලදී ගැනීමට සූදානම් shoppersලා වෙත ළඟා වන්න',
      'Seasonal, weekend, සහ expiring campaigns promote කරන්න',
      'Restaurant, hotel, retail, සහ bank promotions support කරන්න',
    ],
    businessPrimary: 'Merchant pages බලන්න',
    businessSecondary: 'Team එක අමතන්න',
    businessPanelTitle: 'Merchantsලාට ලැබෙන ප්‍රයෝජන',
    businessPanelItems: [
      { label: 'Offer types', value: 'Restaurant deals, hotel offers, bank promos, retail discounts' },
      { label: 'Audience intent', value: 'Nearby savings සහ active offers සොයන shoppersලා' },
      { label: 'Best use cases', value: 'Weekend campaigns, buffet promotions, flash sales, expiring deals' },
    ],
    finalEyebrow: 'App-first CTA',
    finalTitle: 'විවිධ promo channels දහයකින් වට්ටම් හොයන එක නවත්වන්න සූදානම්ද?',
    finalDescription: 'App එක download කර අද හොඳම deals බලන්න. Browse කිරීම secondary option එකක් ලෙස තබාගන්න.',
    finalPrimary: 'දැන්ම save කරන්න',
    finalSecondary: 'ඔබ අසල offers බලන්න',
  },
  ta: {
    heroBadge: 'உண்மையான மற்றும் தற்போதைய சலுகைகளை தேடும் இலங்கை பயனர்களுக்காக',
    heroTitle: 'இன்னும் செல்லுபடியாக உள்ள இலங்கை சலுகைகளை கண்டுபிடிக்க மிக வேகமான வழி',
    heroDescription: 'Bank apps, restaurant pages, Instagram promos, மற்றும் WhatsApp groups அனைத்தையும் தனித்தனியாக பார்க்க வேண்டாம். DealFinder மூலம் food promos, bank offers, hotel deals, electronics discounts, மற்றும் அருகிலுள்ள offers அனைத்தையும் ஒரே இடத்தில் காணலாம்.',
    primaryCta: 'இன்றைய சிறந்த சலுகைகளை பாருங்கள்',
    secondaryCta: 'நேரடி சலுகைகளை உலாவுங்கள்',
    pills: ['சரிபார்க்கப்பட்ட offer விவரங்கள்', 'அருகிலுள்ள சலுகைகள்', 'Bank offers மற்றும் local promos'],
    searchLabel: 'நீங்கள் சேமிக்க விரும்பும் சலுகையைத் தேடுங்கள்',
    searchPlaceholder: 'Pizza deals Colombo, hotel buffet, bank offers...',
    searchButton: 'பொருந்தும் offers பார்க்க',
    trendingLabel: 'பிரபலமான தேடல்கள்',
    statsEyebrow: 'நேரடி platform snapshot',
    statsTitle: 'அதிகப்படுத்தாத உண்மையான சான்றுகள்',
    statsDescription: 'இங்கு live deals, merchants, மற்றும் coverage காட்டப்படுவதால் platform மீது நம்பிக்கை அதிகரிக்கும்.',
    positioningEyebrow: 'இலங்கை deals hub',
    positioningTitle: 'Restaurant deals, bank offers, hotel promotions, மற்றும் shopping discounts அனைத்தும் ஒரே இடத்தில்',
    positioningDescription: 'DealFinder மூலம் Colombo restaurant offers, supermarket discounts, bank card promotions, hotel deals, electronics sales, மற்றும் அருகிலுள்ள flash offers அனைத்தையும் விரைவாக கண்டுபிடிக்கலாம்.',
    highlightTitles: ['இலங்கையில் பிரபலமான deal தேடல்கள்', 'வணிகங்கள் வெளியிடக்கூடிய offers'],
    highlightPoints: [
      [
        'Sri Lanka bank offers, card promotions, மற்றும் supermarket discounts அனைத்தையும் ஒரே இடத்தில் பாருங்கள்',
        'Colombo restaurant deals, buffet offers, மற்றும் hotel promotions பல apps இல்லாமல் பாருங்கள்',
        'Electronics deals, fashion discounts, மற்றும் nearby offers காலாவதியாகும் முன் பாருங்கள்',
      ],
      [
        'Restaurant promotions, cafe deals, buffet discounts, மற்றும் food delivery offers',
        'Hotel deals, weekend stay offers, spa packages, மற்றும் travel promotions',
        'Retail discounts, mobile deals, bank card offers, மற்றும் seasonal flash sales',
      ],
    ],
    trustEyebrow: 'நம்பகமான deal விவரங்கள்',
    trustTitle: 'இந்த Sri Lanka offers மீது shoppers நம்பிக்கை வைக்கும் காரணம்',
    verificationSteps: [
      'Live deals தெளிவான expiry timing காட்டுவதால் limited-time offers ஐ உடனே அறியலாம்.',
      'Nearby deals க்கு location உங்கள் அனுமதியுடன் மட்டுமே பயன்படுத்தப்படும்.',
      'ஒவ்வொரு deal ம் அதன் store, restaurant, hotel, bank offer, அல்லது merchant source உடன் இணைக்கப்பட்டிருக்கும்.',
    ],
    trustBoxTitle: 'காலியான coupon pages அல்ல, உண்மையான deals',
    trustBoxText: 'Homepage இல் live deal counts, merchant coverage, மற்றும் Sri Lanka food deals, hotel offers, bank promotions, retail discounts போன்ற categories க்கு முக்கியத்துவம் கொடுக்கப்படுகிறது.',
    compareEyebrow: 'சிதறிய தேடலை விட சிறந்தது',
    compareTitle: 'Daraz, bank apps, மற்றும் promo pages ஐ தனித்தனியாகப் பார்ப்பதற்கு பதிலாக Sri Lanka deals கண்டுபிடிக்கும் புத்திசாலி வழி',
    compareDescription: 'Sri Lanka bank offers, restaurant deals, hotel promotions, supermarket discounts, மற்றும் nearby flash sales தேடும் பயனர்களுக்கு பல websites மற்றும் apps களுக்கு இடையே செல்லாமல் live offers ஐ ஒப்பிடலாம்.',
    comparisonTitles: ['Deals தேடும் கடினமான முறை', 'DealFinder மூலம் offers கண்டுபிடித்தல்'],
    comparisonItems: [
      [
        'Daraz, bank apps, restaurant Facebook pages, மற்றும் promo groups ஐ ஒன்று பிறகொன்று தேட வேண்டும்',
        'ஒரு Sri Lanka deal அல்லது buffet/card promotion இன்னும் செல்லுபடியாக உள்ளதா என்பதை கைமுறையாகச் சரிபார்க்க வேண்டும்',
        'Nearby restaurant deals, hotel offers, மற்றும் flash sales பல இடங்களில் சிதறி இருப்பதால் தவறவிடலாம்',
      ],
      [
        'Sri Lanka bank offers, food promos, hotel deals, supermarket discounts, மற்றும் flash sales அனைத்தையும் ஒரே இடத்தில் பாருங்கள்',
        'Colombo restaurant deals அல்லது nearby shopping discounts தேடும் போது வேகமான shortlist கிடைக்கும்',
        'காலாவதியாகும் முன் deals ஐ save செய்து compare செய்து மீண்டும் பார்க்கலாம்',
      ],
    ],
    previewEyebrow: 'உண்மையான app அனுபவம்',
    previewTitle: 'இலங்கையின் சிறந்த deals ஐ தேடுங்கள், compare செய்யுங்கள், save செய்யுங்கள்',
    previewCards: [
      { label: 'Search', title: 'Store அல்லது category மூலம் தேடுங்கள்', body: 'Restaurant deals, bank offers, hotel promotions, electronics discounts, அல்லது city-based offers தேடுங்கள்.' },
      { label: 'Compare', title: 'Live offers ஐ வேகமாக compare செய்யுங்கள்', body: 'பல sources திறக்காமல் எந்த Sri Lanka deal சிறந்த discount தருகிறது என்பதை அறியுங்கள்.' },
      { label: 'Save', title: 'காலாவதியாகும் முன் deals ஐ save செய்யுங்கள்', body: 'Nearby promotions, buffet offers, மற்றும் flash sales ஐ பின்னர் பார்க்க சேமித்து வைத்துக்கொள்ளுங்கள்.' },
    ],
    previewDetailLabel: 'Deal விவரங்கள்',
    previewWhyLabel: 'Shoppers ஏன் இதைப் பயன்படுத்துகிறார்கள்',
    previewWhyItems: [
      'Savings, expiry timing, மற்றும் merchant details ஐ உடனே காணலாம்',
      'Sri Lanka restaurant deals, bank offers, மற்றும் retail discounts ஐ வேகமாக காணலாம்',
      'Discovery, comparison, மற்றும் saved offers க்கு ஒரே app ஐ பயன்படுத்தலாம்',
    ],
    liveSectionEyebrow: 'இப்போது live',
    liveSectionTitle: 'இன்றைய சிறந்த deals',
    endingSoonEyebrow: 'அவசரம்',
    endingSoonTitle: 'விரைவில் முடியும்',
    nearbyEyebrow: 'அருகிலுள்ள picks',
    nearbyTitle: 'அருகிலுள்ள deals',
    categoryTitle: 'Category அடிப்படையில் deals பாருங்கள்',
    categoryMeta: 'Shoppers அதிகம் பயன்படுத்தும் வழிகள்',
    categoryFooter: 'Colombo restaurant offers, Sri Lanka bank promotions, hotel deals, buffet discounts, மற்றும் electronics savings போன்ற பொதுவான deal interests ஐ ஆராயுங்கள்.',
    businessEyebrow: 'வணிகங்களுக்காக',
    businessTitle: 'Deals தேடும் shoppers களை merchants அடைய உதவுங்கள்',
    businessDescription: 'DealFinder மூலம் restaurants, hotels, supermarkets, banks, மற்றும் retail brands தங்களின் live offers, nearby deals, மற்றும் limited-time promotions ஐ இலங்கையில் தேடும் பயனர்களிடம் கொண்டு சேர்க்கலாம்.',
    businessBenefits: [
      'Current offers ஐ நம்பகமான deals app ஒன்றில் promote செய்யுங்கள்',
      'வாங்க தயாராக இருக்கும் அருகிலுள்ள shoppers களை அடையுங்கள்',
      'Seasonal, weekend, மற்றும் expiring campaigns ஐ push செய்யுங்கள்',
      'Restaurant, hotel, retail, மற்றும் bank promotions ஐ support செய்யுங்கள்',
    ],
    businessPrimary: 'Merchant pages பாருங்கள்',
    businessSecondary: 'Team ஐ தொடர்புகொள்ளுங்கள்',
    businessPanelTitle: 'Merchants க்கு கிடைக்கும் நன்மைகள்',
    businessPanelItems: [
      { label: 'Offer types', value: 'Restaurant deals, hotel offers, bank promos, retail discounts' },
      { label: 'Audience intent', value: 'Nearby savings மற்றும் active offers தேடும் shoppers' },
      { label: 'Best use cases', value: 'Weekend campaigns, buffet promotions, flash sales, expiring deals' },
    ],
    finalEyebrow: 'App-first CTA',
    finalTitle: 'பத்து promo channels முழுவதும் deals தேடுவதை நிறுத்த தயாரா?',
    finalDescription: 'App ஐப் பெற்று இன்றைய சிறந்த deals ஐ காணுங்கள். Browse செய்வதை secondary option ஆக வைத்திருக்கலாம்.',
    finalPrimary: 'இப்போது சேமிக்க தொடங்குங்கள்',
    finalSecondary: 'அருகிலுள்ள offers பாருங்கள்',
  },
};

function getPromotionId(promotion: Promotion) {
  return promotion._id || promotion.id || '';
}

function getMerchantId(promotion: Promotion) {
  return typeof promotion.merchant === 'object' ? promotion.merchant?._id || promotion.merchant?.name || '' : promotion.merchant || '';
}

function getMerchantName(promotion?: Promotion) {
  if (!promotion?.merchant) return 'Featured merchant';
  return typeof promotion.merchant === 'object' ? promotion.merchant.name || 'Featured merchant' : promotion.merchant;
}

function getDiscountValue(discount: Promotion['discount']) {
  const numeric = Number.parseFloat(String(discount ?? '').replace(/[^\d.]/g, ''));
  return Number.isFinite(numeric) ? numeric : 0;
}

function getTimestamp(value?: string) {
  const time = value ? new Date(value).getTime() : 0;
  return Number.isFinite(time) ? time : 0;
}

function getCurrencySymbol(code?: string) {
  const symbols: Record<string, string> = {
    USD: '$',
    LKR: 'Rs.',
    EUR: '€',
    GBP: '£',
    INR: '₹',
    AUD: 'A$',
    CAD: 'C$',
    SGD: 'S$',
    AED: 'AED ',
    MYR: 'RM ',
  };

  return symbols[code || 'LKR'] || `${code || 'Rs.'} `;
}

function formatMoney(amount: number, currencyCode?: string) {
  const symbol = getCurrencySymbol(currencyCode);
  const hasDecimals = !Number.isInteger(amount);
  return `${symbol}${amount.toLocaleString(undefined, {
    minimumFractionDigits: hasDecimals ? 2 : 0,
    maximumFractionDigits: 2,
  })}`;
}

function formatExpiryLabel(value?: string) {
  const time = getTimestamp(value);
  if (!time) return 'Limited time';

  return `Ends ${new Intl.DateTimeFormat('en-LK', {
    month: 'short',
    day: 'numeric',
    timeZone: 'UTC',
  }).format(new Date(time))}`;
}

function isActiveDeal(promotion: Promotion, now: number) {
  return getTimestamp(promotion.endDate) >= now;
}

function scoreRecommendation(
  promotion: Promotion,
  favoriteMerchantIds: Set<string>,
  favoriteCategories: Set<string>,
  now: number
) {
  let score = 0;

  if (promotion.featured) score += 30;
  if (favoriteCategories.has(normalizeCategoryId(promotion.category || ''))) score += 35;
  if (favoriteMerchantIds.has(getMerchantId(promotion))) score += 40;
  score += Math.min(getDiscountValue(promotion.discount), 60);

  const daysLeft = Math.ceil((getTimestamp(promotion.endDate) - now) / 86400000);
  if (daysLeft >= 0 && daysLeft <= 3) score += 16;

  return score;
}

function SectionHeader({
  eyebrow,
  title,
  icon,
  meta,
  actionLabel,
  onAction,
  accent,
}: {
  eyebrow: string;
  title: string;
  icon: string;
  meta?: string;
  actionLabel?: string;
  onAction?: () => void;
  accent?: string;
}) {
  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'end',
        gap: '1rem',
        flexWrap: 'wrap',
        marginBottom: '1.4rem',
      }}
    >
      <div>
        <div style={{ color: accent || 'var(--primary-color)', fontSize: '0.82rem', fontWeight: 800, textTransform: 'uppercase' }}>
          {eyebrow}
        </div>
        <h2 className="section-title" style={{ marginBottom: 0 }}>
          <i className={`fas ${icon}`} style={{ color: accent || 'var(--primary-color)' }}></i>
          {title}
        </h2>
      </div>
      <div className="flex items-center gap-3 flex-wrap">
        {meta ? <span style={{ color: 'var(--text-secondary)', fontSize: '0.92rem' }}>{meta}</span> : null}
        {actionLabel && onAction ? (
          <button
            onClick={onAction}
            className="btn"
            style={{
              background: 'var(--card-bg)',
              color: 'var(--text-primary)',
              border: '1px solid var(--border-color)',
            }}
          >
            {actionLabel}
          </button>
        ) : null}
      </div>
    </div>
  );
}

function DealGrid({
  deals,
  favoriteIds,
  onFavoriteToggle,
}: {
  deals: Promotion[];
  favoriteIds: Set<string>;
  onFavoriteToggle: (id: string, isFav: boolean) => void;
}) {
  return (
    <div
      style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))',
        gap: '1.5rem',
      }}
    >
      {deals.map((promotion) => (
        <div key={getPromotionId(promotion)}>
          <PromotionCard
            promotion={promotion}
            isFavorite={favoriteIds.has(getPromotionId(promotion))}
            onFavoriteToggle={onFavoriteToggle}
          />
        </div>
      ))}
    </div>
  );
}

function SkeletonGrid({ count }: { count: number }) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
      {Array.from({ length: count }).map((_, index) => (
        <SkeletonCard key={index} />
      ))}
    </div>
  );
}

export default function HomePage() {
  const router = useRouter();
  const { user } = useAuth();
  const { language: selectedLang } = useLanguage();
  const [allPromotions, setAllPromotions] = useState<Promotion[]>([]);
  const [favoriteDeals, setFavoriteDeals] = useState<FavoritePromotion[]>([]);
  const [favoriteIds, setFavoriteIds] = useState<Set<string>>(new Set());
  const [nearbyDeals, setNearbyDeals] = useState<Promotion[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [aiSearchResults, setAiSearchResults] = useState<Promotion[]>([]);
  const [loadingAiSearch, setLoadingAiSearch] = useState(false);
  const [userLocation, setUserLocation] = useState<{ latitude: number; longitude: number; radiusKm?: number } | null>(null);
  const [loadingDeals, setLoadingDeals] = useState(true);
  const [loadingNearby, setLoadingNearby] = useState(false);
  const [locationError, setLocationError] = useState('');
  const [currentTimestamp] = useState(() => Date.now());

  const currentCopy = HOME_COPY[selectedLang];

  useEffect(() => {
    const fetchData = async () => {
      try {
        invalidateCache('promotions');
        invalidateCache('bank-offers');

        const promotionsPromise = Promise.all([
          PromotionAPI.getAll({ limit: 48 }),
          BankOfferAPI.getAll({ limit: 24 }).catch(() => []),
        ]).then(([promotions, bankOffers]) => [...promotions, ...bankOffers]);

        const favoritesPromise = user ? UserAPI.getFavorites(user._id).catch(() => []) : Promise.resolve([]);
        const [promotionsData, favoritesData] = await Promise.all([promotionsPromise, favoritesPromise]);

        const sortedPromotions = [...promotionsData].sort(
          (a, b) => getTimestamp(b.createdAt) - getTimestamp(a.createdAt)
        );

        setAllPromotions(sortedPromotions);
        setFavoriteDeals(favoritesData);
        setFavoriteIds(new Set(favoritesData.map((favorite: Promotion) => getPromotionId(favorite))));
      } catch (error) {
        console.error('Failed to load homepage data:', error);
        toast.error('Failed to load deals.');
      } finally {
        setLoadingDeals(false);
      }
    };

    fetchData();
  }, [user]);

  useEffect(() => {
    if (!navigator.geolocation) return;

    setLoadingNearby(true);
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        const currentLocation = {
          latitude: coords.latitude,
          longitude: coords.longitude,
          radiusKm: 20,
        };

        setUserLocation(currentLocation);

        PromotionAPI.getNearby(coords.latitude, coords.longitude, 20)
          .then((data: Promotion[]) => {
            const sorted = [...data].sort((a, b) => getTimestamp(b.createdAt) - getTimestamp(a.createdAt));
            setNearbyDeals(sorted);
          })
          .catch(() => setLocationError('Nearby deals are not available right now.'))
          .finally(() => setLoadingNearby(false));
      },
      () => {
        setLocationError('Location is off, so we are focusing on the best platform-wide deals instead.');
        setLoadingNearby(false);
      }
    );
  }, []);

  useEffect(() => {
    const trimmed = searchTerm.trim();
    if (!trimmed) {
      setAiSearchResults([]);
      setLoadingAiSearch(false);
      return;
    }

    let cancelled = false;
    const timeoutId = window.setTimeout(async () => {
      setLoadingAiSearch(true);
      try {
        const response = await AiAPI.search({
          query: trimmed,
          location: userLocation,
          limit: 6,
        });

        if (!cancelled) {
          setAiSearchResults(response.results || []);
        }
      } catch (error) {
        console.error('AI search preview failed:', error);
        if (!cancelled) {
          setAiSearchResults([]);
        }
      } finally {
        if (!cancelled) {
          setLoadingAiSearch(false);
        }
      }
    }, 250);

    return () => {
      cancelled = true;
      window.clearTimeout(timeoutId);
    };
  }, [searchTerm, userLocation]);

  const activePromotions = useMemo(
    () => allPromotions.filter((promotion) => isActiveDeal(promotion, currentTimestamp)),
    [allPromotions, currentTimestamp]
  );

  const featuredDeals = useMemo(
    () =>
      [...activePromotions]
        .sort((a, b) => {
          if (Boolean(a.featured) !== Boolean(b.featured)) return a.featured ? -1 : 1;
          return getDiscountValue(b.discount) - getDiscountValue(a.discount);
        })
        .slice(0, 3),
    [activePromotions]
  );

  const endingSoonDeals = useMemo(
    () =>
      [...activePromotions]
        .sort((a, b) => getTimestamp(a.endDate) - getTimestamp(b.endDate))
        .slice(0, 3),
    [activePromotions]
  );

  const favoriteMerchantIds = useMemo(
    () => new Set(favoriteDeals.map((promotion) => getMerchantId(promotion))),
    [favoriteDeals]
  );

  const favoriteCategories = useMemo(
    () => new Set(favoriteDeals.map((promotion) => normalizeCategoryId(promotion.category || ''))),
    [favoriteDeals]
  );

  const recommendedDeals = useMemo(() => {
    const source = activePromotions.filter((promotion) => !favoriteIds.has(getPromotionId(promotion)));

    if (favoriteDeals.length > 0) {
      return [...source]
        .sort(
          (a, b) =>
            scoreRecommendation(b, favoriteMerchantIds, favoriteCategories, currentTimestamp) -
            scoreRecommendation(a, favoriteMerchantIds, favoriteCategories, currentTimestamp)
        )
        .slice(0, 3);
    }

    if (nearbyDeals.length > 0) return nearbyDeals.slice(0, 3);
    return featuredDeals.slice(0, 3);
  }, [activePromotions, currentTimestamp, favoriteCategories, favoriteDeals.length, favoriteIds, favoriteMerchantIds, featuredDeals, nearbyDeals]);

  const searchResults = aiSearchResults;
  const savedPreview = useMemo(() => favoriteDeals.slice(0, 2), [favoriteDeals]);

  const heroBannerDeal = useMemo(() => {
    const source = featuredDeals[0] || recommendedDeals[0] || nearbyDeals[0] || activePromotions[0];
    if (source) return source;

    return {
      title: 'Weekend buffet offer',
      merchant: { name: 'Colombo dining spot', currency: 'LKR', distance: 2400 },
      discount: '35%',
      image: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=1200&h=1600&fit=crop',
      discountedPrice: 4990,
      originalPrice: 6990,
      endDate: '2026-12-31T00:00:00.000Z',
      aiMeta: { distanceKm: 2.4 },
    } as Promotion;
  }, [activePromotions, featuredDeals, nearbyDeals, recommendedDeals]);

  const heroCurrencyCode =
    typeof heroBannerDeal?.merchant === 'object' ? heroBannerDeal.merchant?.currency : undefined;
  const heroOriginalPrice = Number.isFinite(Number(heroBannerDeal?.originalPrice)) ? Number(heroBannerDeal?.originalPrice) : null;
  const heroDiscountedPrice = Number.isFinite(Number(heroBannerDeal?.discountedPrice)) ? Number(heroBannerDeal?.discountedPrice) : null;
  const heroSavings =
    heroOriginalPrice !== null && heroDiscountedPrice !== null && heroOriginalPrice > heroDiscountedPrice
      ? heroOriginalPrice - heroDiscountedPrice
      : Number.isFinite(Number(heroBannerDeal?.maximumBenefit))
        ? Number(heroBannerDeal?.maximumBenefit)
        : null;
  const heroPriceLabel = heroDiscountedPrice !== null
    ? formatMoney(heroDiscountedPrice, heroCurrencyCode)
    : heroOriginalPrice !== null
      ? formatMoney(heroOriginalPrice, heroCurrencyCode)
      : null;
  const heroSaveLabel = heroSavings !== null ? `Save ${formatMoney(heroSavings, heroCurrencyCode)}` : null;
  const heroDistanceKm =
    heroBannerDeal?.aiMeta?.distanceKm !== null && heroBannerDeal?.aiMeta?.distanceKm !== undefined
      ? heroBannerDeal.aiMeta.distanceKm
      : typeof heroBannerDeal?.merchant === 'object' && typeof heroBannerDeal.merchant?.distance === 'number'
        ? heroBannerDeal.merchant.distance / 1000
        : null;
  const heroDistanceLabel =
    heroDistanceKm !== null
      ? heroDistanceKm < 1
        ? `${Math.round(heroDistanceKm * 1000)}m away`
        : `${heroDistanceKm.toFixed(1)}km away`
      : null;
  const heroExpiryLabel = formatExpiryLabel(heroBannerDeal?.endDate);

  const merchantCount = useMemo(
    () => new Set(activePromotions.map((promotion) => getMerchantId(promotion)).filter(Boolean)).size,
    [activePromotions]
  );

  const liveCategoryCount = useMemo(
    () => new Set(
      activePromotions
        .map((promotion) => normalizeCategoryId(promotion.category || ''))
        .filter((category) => category && category !== 'all')
    ).size,
    [activePromotions]
  );

  const dynamicStats = useMemo(
    () => [
      {
        label: selectedLang === 'en' ? 'Live deals right now' : selectedLang === 'si' ? 'දැන් සජීවී deals' : 'இப்போது live deals',
        value: loadingDeals ? '...' : `${activePromotions.length}+`,
        icon: 'fa-bolt',
        accent: '#2563eb',
        detail: selectedLang === 'en' ? 'Fresh offers shoppers can act on today' : selectedLang === 'si' ? 'අදම භාවිතා කළ හැකි නව offers' : 'இன்று பயன்படுத்தக்கூடிய புதிய offers',
      },
      {
        label: selectedLang === 'en' ? 'Merchants tracked' : selectedLang === 'si' ? 'Track කරන merchants' : 'Track செய்யப்படும் merchants',
        value: loadingDeals ? '...' : `${merchantCount}+`,
        icon: 'fa-store',
        accent: '#0f766e',
        detail: selectedLang === 'en' ? 'Restaurants, retailers, hotels, and more' : selectedLang === 'si' ? 'Restaurants, retailers, hotels, සහ තවත්' : 'Restaurants, retailers, hotels, மற்றும் பல',
      },
      {
        label: selectedLang === 'en' ? 'Live categories' : selectedLang === 'si' ? 'සජීවී categories' : 'Live categories',
        value: loadingDeals ? '...' : `${liveCategoryCount || 0}+`,
        icon: 'fa-layer-group',
        accent: '#7c3aed',
        detail: selectedLang === 'en' ? 'Bank offers, food, travel, electronics, and beyond' : selectedLang === 'si' ? 'Bank offers, food, travel, electronics සහ තවත්' : 'Bank offers, food, travel, electronics மற்றும் பல',
      },
      {
        label: selectedLang === 'en' ? 'Coverage focus' : selectedLang === 'si' ? 'Coverage focus' : 'Coverage focus',
        value: selectedLang === 'en' ? 'Colombo to Galle' : selectedLang === 'si' ? 'Colombo සිට Galle දක්වා' : 'Colombo முதல் Galle வரை',
        icon: 'fa-location-dot',
        accent: '#ea580c',
        detail: selectedLang === 'en' ? 'Built for Sri Lankan city-by-city discovery' : selectedLang === 'si' ? 'ශ්‍රී ලංකාවේ නගර අනුව deals සොයන්න' : 'இலங்கையின் நகரங்களுக்கு ஏற்ற deal discovery',
      },
    ],
    [activePromotions.length, liveCategoryCount, loadingDeals, merchantCount, selectedLang]
  );

  const handleFavoriteToggle = (id: string, isFav: boolean) => {
    setFavoriteIds((current) => {
      const next = new Set(current);
      if (isFav) next.add(id);
      else next.delete(id);
      return next;
    });
  };

  const openDeals = (query?: string) => {
    const trimmed = query?.trim();
    router.push(trimmed ? `/categories/all?q=${encodeURIComponent(trimmed)}` : '/categories/all');
  };

  const highlightCards = [
    {
      title: currentCopy.highlightTitles[0],
      points: currentCopy.highlightPoints[0],
      accent: '#22c55e',
      background: 'rgba(34,197,94,0.1)',
    },
    {
      title: currentCopy.highlightTitles[1],
      points: currentCopy.highlightPoints[1],
      accent: '#f59e0b',
      background: 'rgba(245,158,11,0.12)',
    },
  ];

  const comparisonGroups = [
    {
      title: currentCopy.comparisonTitles[0],
      icon: 'fa-layer-group',
      color: '#dc2626',
      background: 'rgba(220,38,38,0.06)',
      border: 'rgba(220,38,38,0.16)',
      items: currentCopy.comparisonItems[0],
    },
    {
      title: currentCopy.comparisonTitles[1],
      icon: 'fa-bolt',
      color: '#16a34a',
      background: 'rgba(22,163,74,0.08)',
      border: 'rgba(22,163,74,0.16)',
      items: currentCopy.comparisonItems[1],
    },
  ];

  const verificationSteps = currentCopy.verificationSteps;

  return (
    <div>
      <section
        style={{
          position: 'relative',
          overflow: 'hidden',
          background: 'linear-gradient(135deg, #081a3a 0%, #0f3a8a 45%, #1769aa 100%)',
          color: '#fff',
        }}
      >
        <div
          style={{
            position: 'absolute',
            inset: 0,
            backgroundImage: 'url(https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=1600&q=80)',
            backgroundSize: 'cover',
            backgroundPosition: 'center',
            opacity: 0.12,
          }}
        />
        <div
          style={{
            position: 'absolute',
            inset: 0,
            background:
              'radial-gradient(circle at 15% 20%, rgba(251,191,36,0.22) 0%, transparent 28%), radial-gradient(circle at 80% 0%, rgba(59,130,246,0.3) 0%, transparent 32%)',
          }}
        />

        <div className="max-w-7xl mx-auto px-4" style={{ position: 'relative', zIndex: 1, paddingTop: '3.5rem', paddingBottom: '4rem' }}>
          <div className="grid grid-cols-1 lg:grid-cols-[1.05fr_0.95fr] gap-12 items-center">
            <div>
              <div
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  marginBottom: '1rem',
                  padding: '0.5rem 1rem',
                  borderRadius: '999px',
                  background: 'rgba(255,255,255,0.12)',
                  border: '1px solid rgba(255,255,255,0.16)',
                  fontSize: '0.8rem',
                  fontWeight: 700,
                }}
              >
                <span
                  style={{
                    width: '0.5rem',
                    height: '0.5rem',
                    borderRadius: '999px',
                    background: '#22c55e',
                    boxShadow: '0 0 0 6px rgba(34,197,94,0.2)',
                  }}
                />
                {currentCopy.heroBadge}
              </div>

              <h1
                style={{
                  fontSize: 'clamp(2.4rem, 5vw, 4.2rem)',
                  lineHeight: 1.02,
                  margin: 0,
                  fontWeight: 900,
                  maxWidth: '12ch',
                }}
              >
                {currentCopy.heroTitle}
              </h1>

              <p
                style={{
                  marginTop: '1.15rem',
                  marginBottom: '1.6rem',
                  fontSize: '1.06rem',
                  lineHeight: 1.75,
                  color: 'rgba(248,250,252,0.9)',
                  maxWidth: '40rem',
                }}
              >
                {currentCopy.heroDescription}
              </p>

              <div className="flex flex-wrap gap-3" style={{ marginBottom: '1.4rem' }}>
                <a
                  href={DOWNLOAD_URL}
                  className="btn"
                  style={{
                    background: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)',
                    color: '#fff',
                    padding: '1rem 1.6rem',
                    fontWeight: 800,
                    fontSize: '1rem',
                    boxShadow: '0 12px 32px rgba(245,158,11,0.38)',
                    textDecoration: 'none',
                  }}
                >
                  <i className="fas fa-mobile-screen-button"></i>
                  {currentCopy.primaryCta}
                </a>
                <button
                  onClick={() => router.push('/categories/all')}
                  className="btn"
                  style={{
                    background: 'rgba(255,255,255,0.12)',
                    color: '#fff',
                    border: '1px solid rgba(255,255,255,0.22)',
                    padding: '1rem 1.4rem',
                    fontWeight: 700,
                    fontSize: '0.98rem',
                    backdropFilter: 'blur(10px)',
                  }}
                >
                  <i className="fas fa-compass"></i>
                  {currentCopy.secondaryCta}
                </button>
              </div>

              <div
                style={{
                  display: 'flex',
                  flexWrap: 'wrap',
                  gap: '0.8rem',
                  marginBottom: '1.5rem',
                }}
              >
                {currentCopy.pills.map((item) => (
                  <div
                    key={item}
                    style={{
                      padding: '0.55rem 0.9rem',
                      borderRadius: '999px',
                      background: 'rgba(255,255,255,0.08)',
                      border: '1px solid rgba(255,255,255,0.14)',
                      fontSize: '0.84rem',
                      fontWeight: 600,
                    }}
                  >
                    {item}
                  </div>
                ))}
              </div>

              <div
                style={{
                  background: 'rgba(8,26,58,0.38)',
                  border: '1px solid rgba(255,255,255,0.14)',
                  borderRadius: '1.4rem',
                  padding: '1rem',
                  backdropFilter: 'blur(16px)',
                  maxWidth: '44rem',
                }}
              >
                <div style={{ fontSize: '0.8rem', fontWeight: 700, color: 'rgba(255,255,255,0.76)', marginBottom: '0.6rem' }}>
                  {currentCopy.searchLabel}
                </div>
                <div className="flex flex-col sm:flex-row gap-3">
                  <div className="input-with-icon" style={{ flex: 1 }}>
                    <i className="fas fa-magnifying-glass" style={{ color: 'rgba(255,255,255,0.58)' }}></i>
                    <input
                      value={searchTerm}
                      onChange={(event) => setSearchTerm(event.target.value)}
                      placeholder={currentCopy.searchPlaceholder}
                      className="modern-input"
                      style={{
                        background: 'rgba(255,255,255,0.1)',
                        borderColor: 'rgba(255,255,255,0.18)',
                        color: '#fff',
                      }}
                    />
                  </div>
                  <button
                    onClick={() => openDeals(searchTerm)}
                    className="btn"
                    style={{
                      background: '#fff',
                      color: '#081a3a',
                      minWidth: '11rem',
                      fontWeight: 800,
                    }}
                  >
                    {currentCopy.searchButton}
                  </button>
                </div>
                <div className="flex flex-wrap gap-2" style={{ marginTop: '0.85rem' }}>
                  <div style={{ width: '100%', fontSize: '0.78rem', color: 'rgba(255,255,255,0.72)', fontWeight: 700 }}>
                    {currentCopy.trendingLabel}
                  </div>
                  {TRENDING_SEARCHES.map((term) => (
                    <button
                      key={term}
                      onClick={() => {
                        setSearchTerm(term);
                        openDeals(term);
                      }}
                      style={{
                        padding: '0.45rem 0.8rem',
                        borderRadius: '999px',
                        background: 'rgba(255,255,255,0.1)',
                        border: '1px solid rgba(255,255,255,0.12)',
                        color: '#fff',
                        fontSize: '0.8rem',
                        fontWeight: 600,
                        cursor: 'pointer',
                      }}
                    >
                      {term}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            <div className="hidden lg:block">
              <div
                style={{
                  position: 'relative',
                  width: '22rem',
                  margin: '0 auto',
                }}
              >
                <div
                  style={{
                    position: 'absolute',
                    top: '2.6rem',
                    left: '-1.1rem',
                    width: '8.6rem',
                    padding: '0.9rem',
                    borderRadius: '1.35rem',
                    background: 'linear-gradient(180deg, rgba(255,255,255,0.18) 0%, rgba(255,255,255,0.08) 100%)',
                    border: '1px solid rgba(255,255,255,0.18)',
                    backdropFilter: 'blur(18px)',
                    boxShadow: '0 22px 44px rgba(8,26,58,0.28)',
                    zIndex: 3,
                  }}
                >
                  <div style={{ fontSize: '0.72rem', textTransform: 'uppercase', letterSpacing: '0.06em', color: '#bfdbfe', fontWeight: 800 }}>
                    Nearby now
                  </div>
                  <div style={{ marginTop: '0.35rem', fontWeight: 800 }}>Buffet deals around you</div>
                  <div style={{ marginTop: '0.2rem', color: 'rgba(255,255,255,0.78)', fontSize: '0.84rem' }}>Less tab switching. Faster yes-or-no.</div>
                </div>

                <div
                  style={{
                    position: 'absolute',
                    bottom: '4.8rem',
                    right: '-1rem',
                    width: '8.8rem',
                    padding: '0.9rem',
                    borderRadius: '1.35rem',
                    background: 'linear-gradient(180deg, rgba(251,191,36,0.24) 0%, rgba(255,255,255,0.08) 100%)',
                    border: '1px solid rgba(255,255,255,0.18)',
                    backdropFilter: 'blur(18px)',
                    boxShadow: '0 22px 44px rgba(8,26,58,0.28)',
                    zIndex: 3,
                  }}
                >
                  <div style={{ fontSize: '0.72rem', textTransform: 'uppercase', letterSpacing: '0.06em', color: '#fde68a', fontWeight: 800 }}>
                    Flash alerts
                  </div>
                  <div style={{ marginTop: '0.35rem', fontWeight: 800 }}>Ending soon offers</div>
                  <div style={{ marginTop: '0.2rem', color: 'rgba(255,255,255,0.78)', fontSize: '0.84rem' }}>Catch expiring deals before they disappear.</div>
                </div>

                <div
                  style={{
                    position: 'relative',
                    background: 'linear-gradient(145deg, #0b1220 0%, #1a2233 42%, #0a0f18 100%)',
                    borderRadius: '3.2rem',
                    padding: '0.58rem',
                    boxShadow: '0 34px 72px rgba(2,6,23,0.56), inset 0 1px 0 rgba(255,255,255,0.12)',
                    border: '1px solid rgba(255,255,255,0.16)',
                    width: '100%',
                  }}
                >
                  <div
                    style={{
                      position: 'absolute',
                      inset: '0.22rem',
                      borderRadius: '3rem',
                      border: '1px solid rgba(255,255,255,0.08)',
                      pointerEvents: 'none',
                    }}
                  />
                  <div
                    style={{
                      position: 'absolute',
                      top: '7.3rem',
                      left: '-0.18rem',
                      width: '0.22rem',
                      height: '4.3rem',
                      borderRadius: '999px',
                      background: 'linear-gradient(180deg, rgba(255,255,255,0.32) 0%, rgba(148,163,184,0.2) 100%)',
                    }}
                  />
                  <div
                    style={{
                      position: 'absolute',
                      top: '12.1rem',
                      left: '-0.18rem',
                      width: '0.22rem',
                      height: '4.9rem',
                      borderRadius: '999px',
                      background: 'linear-gradient(180deg, rgba(255,255,255,0.32) 0%, rgba(148,163,184,0.2) 100%)',
                    }}
                  />
                  <div
                    style={{
                      position: 'absolute',
                      top: '18rem',
                      left: '-0.18rem',
                      width: '0.22rem',
                      height: '4.9rem',
                      borderRadius: '999px',
                      background: 'linear-gradient(180deg, rgba(255,255,255,0.32) 0%, rgba(148,163,184,0.2) 100%)',
                    }}
                  />
                  <div
                    style={{
                      position: 'absolute',
                      top: '11.5rem',
                      right: '-0.18rem',
                      width: '0.22rem',
                      height: '6.4rem',
                      borderRadius: '999px',
                      background: 'linear-gradient(180deg, rgba(255,255,255,0.28) 0%, rgba(148,163,184,0.16) 100%)',
                    }}
                  />
                  <div
                    style={{
                      background: 'linear-gradient(180deg, #f8fbff 0%, #eef5ff 100%)',
                      borderRadius: '2.65rem',
                      overflow: 'hidden',
                      position: 'relative',
                      minHeight: '38rem',
                    }}
                  >
                    <div
                      style={{
                        position: 'absolute',
                        top: '0.65rem',
                        left: '50%',
                        transform: 'translateX(-50%)',
                        width: '7.5rem',
                        height: '1.95rem',
                        borderRadius: '999px',
                        background: 'linear-gradient(180deg, #05070b 0%, #10151d 100%)',
                        boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.08), 0 6px 14px rgba(0,0,0,0.34)',
                        zIndex: 4,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        padding: '0 0.8rem',
                      }}
                    >
                      <div
                        style={{
                          width: '0.62rem',
                          height: '0.62rem',
                          borderRadius: '999px',
                          background: 'radial-gradient(circle at 35% 35%, #475569 0%, #0f172a 62%, #020617 100%)',
                          boxShadow: '0 0 0 1px rgba(255,255,255,0.04)',
                        }}
                      />
                      <div
                        style={{
                          width: '3.4rem',
                          height: '0.34rem',
                          borderRadius: '999px',
                          background: 'rgba(255,255,255,0.06)',
                        }}
                      />
                    </div>
                    <div
                      style={{
                        padding: '3rem 0.85rem 0.8rem',
                        background: 'linear-gradient(135deg, #0f3a8a 0%, #1769aa 100%)',
                        color: '#fff',
                      }}
                    >
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.9rem' }}>
                        <div>
                          <div style={{ fontSize: '0.78rem', opacity: 0.78 }}>DealFinder</div>
                          <div style={{ fontWeight: 900, fontSize: '1.1rem' }}>Best matches for today</div>
                        </div>
                        <div
                          style={{
                            padding: '0.35rem 0.65rem',
                            borderRadius: '999px',
                            background: 'rgba(255,255,255,0.12)',
                            fontSize: '0.72rem',
                            fontWeight: 700,
                          }}
                        >
                          Verified
                        </div>
                      </div>
                      <div
                        style={{
                          background: 'rgba(255,255,255,0.16)',
                          borderRadius: '1rem',
                          padding: '0.75rem 0.9rem',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '0.55rem',
                          fontSize: '0.84rem',
                        }}
                      >
                        <i className="fas fa-magnifying-glass"></i>
                        bank offers, buffet deals, nearby promos
                      </div>
                    </div>

                    <div style={{ padding: '0.85rem' }}>
                      <div
                        style={{
                          borderRadius: '1.35rem',
                          overflow: 'hidden',
                          background: '#fff',
                          boxShadow: '0 16px 32px rgba(15,23,42,0.12)',
                          marginBottom: '0.95rem',
                        }}
                      >
                        <div
                          style={{
                            minHeight: '12.8rem',
                            backgroundImage: `url(${heroBannerDeal?.image || 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=1200&h=1600&fit=crop'})`,
                            backgroundSize: 'cover',
                            backgroundPosition: 'center',
                            position: 'relative',
                          }}
                        >
                          <div
                            style={{
                              position: 'absolute',
                              inset: 0,
                              background: 'linear-gradient(180deg, rgba(8,26,58,0.04) 0%, rgba(8,26,58,0.72) 100%)',
                            }}
                          />
                          <div
                            style={{
                              position: 'absolute',
                              top: '0.8rem',
                              left: '0.8rem',
                              padding: '0.4rem 0.7rem',
                              borderRadius: '999px',
                              background: 'rgba(255,255,255,0.9)',
                              color: '#0f3a8a',
                              fontSize: '0.68rem',
                              fontWeight: 900,
                            }}
                          >
                            Featured deal
                          </div>
                          <div
                            style={{
                              position: 'absolute',
                              top: '0.8rem',
                              right: '0.8rem',
                              padding: '0.4rem 0.7rem',
                              borderRadius: '999px',
                              background: 'linear-gradient(135deg, #16a34a 0%, #4ade80 100%)',
                              color: '#fff',
                              fontSize: '0.68rem',
                              fontWeight: 900,
                            }}
                          >
                            {heroBannerDeal?.discount || '35%'} OFF
                          </div>
                          <div style={{ position: 'absolute', left: '0.9rem', right: '0.9rem', bottom: '0.9rem', color: '#fff' }}>
                            <div style={{ fontSize: '1.12rem', fontWeight: 900, lineHeight: 1.1 }}>
                              {heroBannerDeal?.title || 'Weekend buffet offer'}
                            </div>
                            <div style={{ marginTop: '0.35rem', fontSize: '0.84rem', color: 'rgba(255,255,255,0.85)' }}>
                              {getMerchantName(heroBannerDeal)} {heroDistanceLabel ? `• ${heroDistanceLabel}` : ''}
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'end', marginTop: '0.7rem' }}>
                              <div>
                                {heroPriceLabel ? <div style={{ fontSize: '1.05rem', fontWeight: 900 }}>{heroPriceLabel}</div> : null}
                                {heroSaveLabel ? <div style={{ fontSize: '0.72rem', color: '#bbf7d0', fontWeight: 800 }}>{heroSaveLabel}</div> : null}
                              </div>
                              <div style={{ fontSize: '0.72rem', fontWeight: 800, color: '#fde68a' }}>{heroExpiryLabel}</div>
                            </div>
                          </div>
                        </div>
                      </div>

                      <div className="grid grid-cols-2 gap-2.5">
                        <div
                          style={{
                            borderRadius: '1rem',
                            background: '#fff',
                            padding: '0.85rem',
                            boxShadow: '0 10px 24px rgba(15,23,42,0.08)',
                          }}
                        >
                          <div style={{ fontSize: '0.74rem', color: '#64748b', fontWeight: 700, marginBottom: '0.35rem' }}>
                            Compare quickly
                          </div>
                          <div style={{ fontWeight: 800, color: '#0f172a', marginBottom: '0.5rem' }}>Bank + merchant offers</div>
                          <div style={{ fontSize: '0.78rem', color: '#64748b', lineHeight: 1.5 }}>
                            Spot the better deal without opening five apps.
                          </div>
                        </div>
                        <div
                          style={{
                            borderRadius: '1rem',
                            background: '#fff',
                            padding: '0.85rem',
                            boxShadow: '0 10px 24px rgba(15,23,42,0.08)',
                          }}
                        >
                          <div style={{ fontSize: '0.74rem', color: '#64748b', fontWeight: 700, marginBottom: '0.35rem' }}>
                            Save for later
                          </div>
                          <div style={{ fontWeight: 800, color: '#0f172a', marginBottom: '0.5rem' }}>Track expiring offers</div>
                          <div style={{ fontSize: '0.78rem', color: '#64748b', lineHeight: 1.5 }}>
                            Keep the deals worth revisiting in one shortlist.
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section style={{ background: 'linear-gradient(180deg, #f8fbff 0%, #eef5ff 100%)', borderBottom: '1px solid rgba(148,163,184,0.16)' }}>
        <div className="max-w-7xl mx-auto px-4" style={{ paddingTop: '1.5rem', paddingBottom: '1.5rem' }}>
          <div style={{ marginBottom: '1rem', display: 'flex', justifyContent: 'space-between', gap: '1rem', alignItems: 'end', flexWrap: 'wrap' }}>
            <div>
              <div className="page-eyebrow" style={{ background: 'rgba(37,99,235,0.08)', borderColor: 'rgba(37,99,235,0.12)' }}>
                <i className="fas fa-chart-column"></i>
                {currentCopy.statsEyebrow}
              </div>
              <div style={{ marginTop: '0.8rem', fontSize: '1.2rem', fontWeight: 900, color: '#0f172a' }}>
                {currentCopy.statsTitle}
              </div>
            </div>
            <div style={{ color: '#64748b', maxWidth: '28rem', lineHeight: 1.65, fontSize: '0.94rem' }}>
              {currentCopy.statsDescription}
            </div>
          </div>
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            {dynamicStats.map((stat) => (
              <div
                key={stat.label}
                style={{
                  borderRadius: '1.4rem',
                  background: 'linear-gradient(180deg, rgba(255,255,255,0.96) 0%, rgba(248,250,252,0.98) 100%)',
                  border: '1px solid rgba(148,163,184,0.14)',
                  padding: '1.1rem',
                  boxShadow: '0 14px 32px rgba(15,23,42,0.06)',
                  minHeight: '11rem',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'space-between',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', gap: '0.8rem' }}>
                  <div>
                    <div style={{ fontSize: '1.8rem', fontWeight: 900, color: '#0f172a', lineHeight: 1 }}>{stat.value}</div>
                    <div style={{ marginTop: '0.35rem', fontSize: '0.95rem', color: '#334155', fontWeight: 800 }}>{stat.label}</div>
                  </div>
                  <div
                    style={{
                      width: '2.8rem',
                      height: '2.8rem',
                      borderRadius: '1rem',
                      background: `color-mix(in srgb, ${stat.accent} 12%, white)`,
                      color: stat.accent,
                      display: 'grid',
                      placeItems: 'center',
                      flexShrink: 0,
                    }}
                  >
                    <i className={`fas ${stat.icon}`}></i>
                  </div>
                </div>
                <div style={{ marginTop: '0.9rem', fontSize: '0.88rem', color: '#64748b', lineHeight: 1.6 }}>
                  {stat.detail}
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="max-w-7xl mx-auto px-4 py-10">
        {searchTerm.trim() ? (
          <section style={{ marginBottom: '3rem' }}>
            <SectionHeader
              eyebrow="Search results"
              title="Fast matches"
              icon="fa-magnifying-glass"
              meta={
                loadingAiSearch
                  ? 'Ranking live matches'
                  : searchResults.length > 0
                    ? 'A quick preview from current offers'
                    : 'No matching preview yet'
              }
              actionLabel="View all results"
              onAction={() => openDeals(searchTerm)}
            />
            {loadingAiSearch ? (
              <SkeletonGrid count={3} />
            ) : searchResults.length > 0 ? (
              <DealGrid deals={searchResults} favoriteIds={favoriteIds} onFavoriteToggle={handleFavoriteToggle} />
            ) : (
              <div className="empty-state">
                <div className="empty-icon">
                  <i className="fas fa-search"></i>
                </div>
                <h2 style={{ marginTop: 0, marginBottom: '0.5rem', fontWeight: 800 }}>No quick matches found</h2>
                <p style={{ color: 'var(--text-secondary)', marginBottom: '1.2rem', maxWidth: '34rem', marginInline: 'auto', lineHeight: 1.7 }}>
                  Try a broader search or open the full results page for more live offers.
                </p>
                <button onClick={() => openDeals(searchTerm)} className="btn btn-primary">
                  Search all deals
                </button>
              </div>
            )}
          </section>
        ) : null}

        <section style={{ marginBottom: '3.5rem' }}>
          <div className="grid grid-cols-1 lg:grid-cols-[1.1fr_0.9fr] gap-6">
            <div
              style={{
                borderRadius: '1.8rem',
                padding: '2rem',
                background: 'linear-gradient(180deg, #ffffff 0%, #fffaf2 100%)',
                border: '1px solid rgba(245,158,11,0.18)',
                boxShadow: '0 20px 48px rgba(15,23,42,0.07)',
              }}
            >
              <div className="page-eyebrow" style={{ background: 'rgba(245,158,11,0.1)', borderColor: 'rgba(245,158,11,0.16)', color: '#b45309' }}>
                <i className="fas fa-bullseye"></i>
                {currentCopy.positioningEyebrow}
              </div>
              <h2 style={{ marginTop: '1rem', marginBottom: '0.8rem', fontSize: 'clamp(1.9rem, 4vw, 2.8rem)', lineHeight: 1.08 }}>
                {currentCopy.positioningTitle}
              </h2>
              <p style={{ margin: 0, color: '#64748b', lineHeight: 1.8, maxWidth: '42rem' }}>
                {currentCopy.positioningDescription}
              </p>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4" style={{ marginTop: '1.5rem' }}>
                {highlightCards.map((card) => (
                  <div
                    key={card.title}
                    style={{
                      borderRadius: '1.3rem',
                      padding: '1.1rem',
                      background: card.background,
                      border: '1px solid rgba(148,163,184,0.14)',
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.55rem', marginBottom: '0.8rem' }}>
                      <div
                        style={{
                          width: '2.4rem',
                          height: '2.4rem',
                          borderRadius: '0.9rem',
                          background: '#fff',
                          color: card.accent,
                          display: 'grid',
                          placeItems: 'center',
                          boxShadow: '0 8px 18px rgba(15,23,42,0.08)',
                        }}
                      >
                        <i className="fas fa-check"></i>
                      </div>
                      <div style={{ fontWeight: 800, color: '#0f172a' }}>{card.title}</div>
                    </div>
                    <div style={{ display: 'grid', gap: '0.7rem' }}>
                      {card.points.map((point) => (
                        <div key={point} style={{ display: 'flex', gap: '0.7rem', alignItems: 'start', color: '#334155', lineHeight: 1.6 }}>
                          <i className="fas fa-arrow-right" style={{ color: card.accent, marginTop: '0.28rem', fontSize: '0.78rem' }}></i>
                          <span>{point}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div
              style={{
                borderRadius: '1.8rem',
                padding: '2rem',
                background: '#fff',
                border: '1px solid var(--border-color)',
                boxShadow: '0 20px 48px rgba(15,23,42,0.07)',
              }}
            >
              <div className="page-eyebrow">
                <i className="fas fa-shield-halved"></i>
                {currentCopy.trustEyebrow}
              </div>
              <h3 style={{ fontSize: '1.55rem', fontWeight: 900, marginTop: '1rem', marginBottom: '0.8rem', color: '#0f172a' }}>
                {currentCopy.trustTitle}
              </h3>
              <div style={{ display: 'grid', gap: '0.95rem' }}>
                {verificationSteps.map((step) => (
                  <div
                    key={step}
                    style={{
                      display: 'flex',
                      gap: '0.8rem',
                      alignItems: 'start',
                      padding: '0.95rem 1rem',
                      borderRadius: '1rem',
                      background: '#f8fafc',
                      border: '1px solid #e2e8f0',
                    }}
                  >
                    <div
                      style={{
                        width: '2rem',
                        height: '2rem',
                        borderRadius: '999px',
                        background: 'rgba(37,99,235,0.1)',
                        color: '#2563eb',
                        display: 'grid',
                        placeItems: 'center',
                        fontWeight: 900,
                        flexShrink: 0,
                      }}
                    >
                      <i className="fas fa-check"></i>
                    </div>
                    <div style={{ color: '#475569', lineHeight: 1.65 }}>{step}</div>
                  </div>
                ))}
              </div>

              <div
                style={{
                  marginTop: '1.1rem',
                  borderRadius: '1rem',
                  padding: '1rem',
                  background: 'linear-gradient(135deg, rgba(37,99,235,0.08) 0%, rgba(14,165,233,0.06) 100%)',
                  border: '1px solid rgba(37,99,235,0.12)',
                }}
              >
                <div style={{ fontWeight: 800, color: '#0f172a', marginBottom: '0.45rem' }}>{currentCopy.trustBoxTitle}</div>
                <div style={{ color: '#475569', lineHeight: 1.65 }}>
                  {currentCopy.trustBoxText}
                </div>
              </div>
            </div>
          </div>
        </section>

        <section style={{ marginBottom: '3.5rem' }}>
          <div className="grid grid-cols-1 lg:grid-cols-[0.95fr_1.05fr] gap-6">
            <div
              style={{
                borderRadius: '1.8rem',
                padding: '2rem',
                background: '#fff',
                border: '1px solid var(--border-color)',
                boxShadow: '0 20px 48px rgba(15,23,42,0.07)',
              }}
            >
              <div className="page-eyebrow">
                <i className="fas fa-scale-balanced"></i>
                {currentCopy.compareEyebrow}
              </div>
              <h2 style={{ marginTop: '1rem', marginBottom: '0.85rem', fontSize: 'clamp(1.8rem, 4vw, 2.6rem)', lineHeight: 1.08 }}>
                {currentCopy.compareTitle}
              </h2>
              <p style={{ color: '#64748b', lineHeight: 1.75, marginTop: 0, marginBottom: '1.3rem' }}>
                {currentCopy.compareDescription}
              </p>
              <div style={{ display: 'grid', gap: '1rem' }}>
                {comparisonGroups.map((group) => (
                  <div
                    key={group.title}
                    style={{
                      borderRadius: '1.35rem',
                      padding: '1.15rem',
                      background: group.background,
                      border: `1px solid ${group.border}`,
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem', marginBottom: '0.8rem' }}>
                      <div
                        style={{
                          width: '2.5rem',
                          height: '2.5rem',
                          borderRadius: '0.9rem',
                          background: '#fff',
                          color: group.color,
                          display: 'grid',
                          placeItems: 'center',
                        }}
                      >
                        <i className={`fas ${group.icon}`}></i>
                      </div>
                      <div style={{ fontWeight: 800, color: '#0f172a' }}>{group.title}</div>
                    </div>
                    <div style={{ display: 'grid', gap: '0.7rem' }}>
                      {group.items.map((item) => (
                        <div key={item} style={{ display: 'flex', gap: '0.65rem', color: '#334155', lineHeight: 1.6 }}>
                          <i className="fas fa-circle" style={{ color: group.color, fontSize: '0.42rem', marginTop: '0.6rem' }}></i>
                          <span>{item}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div
              style={{
                borderRadius: '1.8rem',
                padding: '2rem',
                background: 'linear-gradient(180deg, #ffffff 0%, #f8fbff 100%)',
                border: '1px solid rgba(59,130,246,0.14)',
                boxShadow: '0 20px 48px rgba(15,23,42,0.07)',
              }}
            >
              <div className="page-eyebrow" style={{ background: 'rgba(37,99,235,0.1)', borderColor: 'rgba(37,99,235,0.14)' }}>
                <i className="fas fa-mobile-screen"></i>
                {currentCopy.previewEyebrow}
              </div>
              <h3 style={{ fontSize: '1.55rem', fontWeight: 900, marginTop: '1rem', marginBottom: '1rem', color: '#0f172a' }}>
                {currentCopy.previewTitle}
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                {currentCopy.previewCards.map((card, index) => (
                  <div
                    key={card.title}
                    style={{
                      borderRadius: '1.25rem',
                      padding: '1rem',
                      background: '#fff',
                      border: '1px solid #e2e8f0',
                      boxShadow: '0 12px 28px rgba(15,23,42,0.06)',
                    }}
                  >
                    <div
                      style={{
                        width: '2.7rem',
                        height: '2.7rem',
                        borderRadius: '0.95rem',
                        background: 'rgba(37,99,235,0.1)',
                        color: '#2563eb',
                        display: 'grid',
                        placeItems: 'center',
                        marginBottom: '0.8rem',
                      }}
                    >
                      <i className={`fas ${index === 0 ? 'fa-magnifying-glass' : index === 1 ? 'fa-code-compare' : 'fa-bookmark'}`}></i>
                    </div>
                    <div style={{ fontSize: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.05em', color: '#64748b', fontWeight: 800 }}>
                      {card.label}
                    </div>
                    <div style={{ marginTop: '0.35rem', fontWeight: 800, color: '#0f172a' }}>{card.title}</div>
                    <div style={{ marginTop: '0.45rem', color: '#475569', lineHeight: 1.6, fontSize: '0.92rem' }}>{card.body}</div>
                  </div>
                ))}
              </div>

              <div
                style={{
                  marginTop: '1.3rem',
                  borderRadius: '1.25rem',
                  overflow: 'hidden',
                  border: '1px solid #dbeafe',
                  background: '#fff',
                  boxShadow: '0 14px 34px rgba(15,23,42,0.08)',
                }}
              >
                <div
                  style={{
                    display: 'grid',
                    gridTemplateColumns: '1.1fr 0.9fr',
                  }}
                >
                  <div style={{ padding: '1rem', borderRight: '1px solid #e2e8f0' }}>
                    <div style={{ fontSize: '0.78rem', fontWeight: 800, color: '#64748b', marginBottom: '0.6rem' }}>{currentCopy.previewDetailLabel}</div>
                    <div style={{ fontWeight: 900, color: '#0f172a', marginBottom: '0.35rem' }}>
                      {heroBannerDeal?.title || 'Weekend buffet offer'}
                    </div>
                    <div style={{ color: '#64748b', fontSize: '0.9rem', marginBottom: '0.7rem' }}>
                      {getMerchantName(heroBannerDeal)} {heroDistanceLabel ? `• ${heroDistanceLabel}` : ''}
                    </div>
                    <div className="flex flex-wrap gap-2">
                      <div className="discount-badge">{heroBannerDeal?.discount || '35%'} off</div>
                      <div
                        style={{
                          padding: '0.42rem 0.72rem',
                          borderRadius: '999px',
                          background: 'rgba(245,158,11,0.1)',
                          color: '#b45309',
                          fontWeight: 800,
                          fontSize: '0.78rem',
                        }}
                      >
                        {heroExpiryLabel}
                      </div>
                    </div>
                  </div>
                  <div style={{ padding: '1rem', background: '#f8fbff' }}>
                    <div style={{ fontSize: '0.78rem', fontWeight: 800, color: '#64748b', marginBottom: '0.6rem' }}>{currentCopy.previewWhyLabel}</div>
                    <div style={{ display: 'grid', gap: '0.55rem' }}>
                      {currentCopy.previewWhyItems.map((item) => (
                        <div key={item} style={{ display: 'flex', gap: '0.55rem', color: '#334155', lineHeight: 1.55 }}>
                          <i className="fas fa-check" style={{ color: '#2563eb', marginTop: '0.28rem', fontSize: '0.78rem' }}></i>
                          <span>{item}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <div className="grid grid-cols-1 gap-12">
          <section>
            <SectionHeader
              eyebrow={currentCopy.liveSectionEyebrow}
              title={currentCopy.liveSectionTitle}
              icon="fa-fire"
              meta="A tighter shortlist of featured offers"
              actionLabel="View more"
              onAction={() => router.push('/categories/all')}
              accent="#ea580c"
            />
            {loadingDeals ? (
              <SkeletonGrid count={3} />
            ) : (
              <DealGrid deals={featuredDeals} favoriteIds={favoriteIds} onFavoriteToggle={handleFavoriteToggle} />
            )}
          </section>

          <section>
            <div className="grid grid-cols-1 xl:grid-cols-2 gap-8">
              <div>
                <SectionHeader
                  eyebrow={currentCopy.endingSoonEyebrow}
                  title={currentCopy.endingSoonTitle}
                  icon="fa-hourglass-half"
                  meta="Good offers with a short runway"
                  actionLabel="See all deals"
                  onAction={() => router.push('/categories/all')}
                  accent="var(--warning-color)"
                />
                {loadingDeals ? (
                  <SkeletonGrid count={3} />
                ) : (
                  <DealGrid deals={endingSoonDeals} favoriteIds={favoriteIds} onFavoriteToggle={handleFavoriteToggle} />
                )}
              </div>

              <div>
                <SectionHeader
                  eyebrow={nearbyDeals.length > 0 ? currentCopy.nearbyEyebrow : 'Smart picks'}
                  title={nearbyDeals.length > 0 ? currentCopy.nearbyTitle : 'Recommended for you'}
                  icon={nearbyDeals.length > 0 ? 'fa-location-dot' : 'fa-star'}
                  meta={
                    nearbyDeals.length > 0
                      ? 'Based on your current location'
                      : user
                        ? 'Based on what you save and revisit'
                        : locationError || 'Strong starting points if you are new here'
                  }
                  actionLabel={nearbyDeals.length > 0 ? 'Open nearby' : 'Explore more'}
                  onAction={() => router.push(nearbyDeals.length > 0 ? '/nearby' : '/categories/all')}
                  accent={nearbyDeals.length > 0 ? '#16a34a' : 'var(--primary-color)'}
                />
                {loadingDeals || loadingNearby ? (
                  <SkeletonGrid count={3} />
                ) : (
                  <DealGrid
                    deals={nearbyDeals.length > 0 ? nearbyDeals.slice(0, 3) : recommendedDeals}
                    favoriteIds={favoriteIds}
                    onFavoriteToggle={handleFavoriteToggle}
                  />
                )}
              </div>
            </div>
          </section>

          <section
            style={{
              borderRadius: '1.8rem',
              padding: '2rem',
              background: 'linear-gradient(180deg, #ffffff 0%, #f8fbff 100%)',
              border: '1px solid rgba(148,163,184,0.16)',
              boxShadow: '0 20px 48px rgba(15,23,42,0.06)',
            }}
          >
            <SectionHeader
              eyebrow="Popular entry points"
              title={currentCopy.categoryTitle}
              icon="fa-compass"
              meta={currentCopy.categoryMeta}
            />
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {CATEGORIES.map((category) => (
                <button
                  key={category.id}
                  onClick={() => router.push(`/categories/${category.id}`)}
                  style={{
                    textAlign: 'left',
                    border: '1px solid var(--border-color)',
                    background: '#fff',
                    borderRadius: '1.15rem',
                    padding: '1rem',
                    boxShadow: '0 10px 24px rgba(15,23,42,0.05)',
                    cursor: 'pointer',
                  }}
                >
                  <div
                    style={{
                      width: '2.8rem',
                      height: '2.8rem',
                      borderRadius: '1rem',
                      background: 'linear-gradient(135deg, rgba(37,99,235,0.16), rgba(14,165,233,0.1))',
                      color: '#2563eb',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      marginBottom: '0.8rem',
                    }}
                  >
                    <i className={`fas ${category.icon}`}></i>
                  </div>
                  <div style={{ fontWeight: 800, color: '#0f172a' }}>{category.name}</div>
                </button>
              ))}
            </div>
            <div style={{ marginTop: '1rem', color: '#64748b', lineHeight: 1.7 }}>
              {currentCopy.categoryFooter}
            </div>
          </section>

          <section
            style={{
              borderRadius: '1.8rem',
              overflow: 'hidden',
              background: 'linear-gradient(135deg, #0f172a 0%, #0f3a8a 65%, #f59e0b 100%)',
              color: '#fff',
            }}
          >
            <div className="grid grid-cols-1 lg:grid-cols-[1fr_0.9fr] gap-0 items-stretch">
              <div style={{ padding: '2.1rem' }}>
                <div className="page-eyebrow" style={{ background: 'rgba(255,255,255,0.12)', borderColor: 'rgba(255,255,255,0.16)', color: '#fff' }}>
                  <i className="fas fa-store"></i>
                  {currentCopy.businessEyebrow}
                </div>
                <h2 style={{ marginTop: '1rem', marginBottom: '0.8rem', fontSize: 'clamp(1.9rem, 4vw, 2.7rem)', lineHeight: 1.08 }}>
                  {currentCopy.businessTitle}
                </h2>
                <p style={{ margin: 0, color: 'rgba(255,255,255,0.84)', lineHeight: 1.75, maxWidth: '34rem' }}>
                  {currentCopy.businessDescription}
                </p>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3" style={{ marginTop: '1.3rem' }}>
                  {currentCopy.businessBenefits.map((item) => (
                    <div
                      key={item}
                      style={{
                        borderRadius: '1rem',
                        padding: '0.9rem 1rem',
                        background: 'rgba(255,255,255,0.12)',
                        border: '1px solid rgba(255,255,255,0.14)',
                      }}
                    >
                      <i className="fas fa-check-circle" style={{ color: '#fde68a', marginRight: '0.45rem' }}></i>
                      {item}
                    </div>
                  ))}
                </div>
                <div className="flex flex-wrap gap-3" style={{ marginTop: '1.4rem' }}>
                  <button
                    onClick={() => router.push('/merchants')}
                    className="btn"
                    style={{
                      background: '#fff',
                      color: '#0f172a',
                      fontWeight: 800,
                    }}
                  >
                    {currentCopy.businessPrimary}
                  </button>
                  <button
                    onClick={() => router.push('/contact')}
                    className="btn"
                    style={{
                      background: 'rgba(255,255,255,0.12)',
                      color: '#fff',
                      border: '1px solid rgba(255,255,255,0.22)',
                      fontWeight: 700,
                    }}
                  >
                    {currentCopy.businessSecondary}
                  </button>
                </div>
              </div>

              <div
                style={{
                  padding: '2rem',
                  background: 'linear-gradient(180deg, rgba(255,255,255,0.12) 0%, rgba(255,255,255,0.04) 100%)',
                  display: 'flex',
                  alignItems: 'center',
                }}
              >
                <div
                  style={{
                    width: '100%',
                    borderRadius: '1.4rem',
                    padding: '1.2rem',
                    background: 'rgba(8,26,58,0.35)',
                    border: '1px solid rgba(255,255,255,0.14)',
                    backdropFilter: 'blur(14px)',
                  }}
                >
                  <div style={{ fontSize: '0.78rem', textTransform: 'uppercase', letterSpacing: '0.06em', color: '#fde68a', fontWeight: 800, marginBottom: '0.7rem' }}>
                    {currentCopy.businessPanelTitle}
                  </div>
                  <div style={{ display: 'grid', gap: '0.8rem' }}>
                    {currentCopy.businessPanelItems.map((item) => (
                      <div
                        key={item.label}
                        style={{
                          borderRadius: '1rem',
                          padding: '0.9rem',
                          background: 'rgba(255,255,255,0.1)',
                          border: '1px solid rgba(255,255,255,0.12)',
                        }}
                      >
                        <div style={{ fontSize: '0.74rem', color: 'rgba(255,255,255,0.7)', fontWeight: 700 }}>{item.label}</div>
                        <div style={{ marginTop: '0.25rem', fontWeight: 800 }}>{item.value}</div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </section>

          {user ? (
            <section
              style={{
                background: 'linear-gradient(135deg, rgba(59,130,246,0.05) 0%, rgba(14,165,233,0.05) 100%)',
                borderRadius: '1.5rem',
                padding: '2rem',
                border: '1px solid rgba(59,130,246,0.1)',
              }}
            >
              <div style={{ marginBottom: '1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'end', gap: '1rem', flexWrap: 'wrap' }}>
                <div>
                  <div className="page-eyebrow">
                    <i className="fas fa-heart"></i>
                    Saved deals
                  </div>
                  <h2 style={{ fontSize: 'clamp(1.7rem, 4vw, 2.4rem)', fontWeight: 900, color: '#0f172a', marginBottom: '0.45rem', marginTop: '1rem' }}>
                    {savedPreview.length > 0 ? 'Continue where you left off' : 'Start building your shortlist'}
                  </h2>
                  <p style={{ fontSize: '1rem', color: '#64748b', margin: 0 }}>
                    {savedPreview.length > 0
                      ? `You have ${favoriteDeals.length} saved deal${favoriteDeals.length !== 1 ? 's' : ''} ready to revisit.`
                      : 'Save the deals worth checking later so you do not have to search again.'}
                  </p>
                </div>
                <button
                  onClick={() => router.push(savedPreview.length > 0 ? '/favorites' : '/categories/all')}
                  className="btn"
                  style={{
                    background: 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)',
                    color: '#fff',
                    fontWeight: 800,
                  }}
                >
                  {savedPreview.length > 0 ? 'View saved deals' : 'Explore deals'}
                </button>
              </div>

              {savedPreview.length > 0 ? (
                <DealGrid deals={savedPreview} favoriteIds={favoriteIds} onFavoriteToggle={handleFavoriteToggle} />
              ) : (
                <div className="empty-state" style={{ background: '#fff' }}>
                  <div className="empty-icon" style={{ background: 'linear-gradient(135deg, #ef4444 0%, #fb7185 100%)' }}>
                    <i className="fas fa-heart"></i>
                  </div>
                  <h3 style={{ fontSize: '1.35rem', fontWeight: 800, color: '#0f172a', marginBottom: '0.8rem' }}>No saved deals yet</h3>
                  <p style={{ color: '#64748b', marginBottom: '1.4rem', fontSize: '1rem', maxWidth: '26rem', marginInline: 'auto' }}>
                    Tap the heart icon on any offer to keep a shortlist of the deals you may want later.
                  </p>
                  <button
                    onClick={() => router.push('/categories/all')}
                    className="btn"
                    style={{
                      background: 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)',
                      color: '#fff',
                      fontWeight: 700,
                    }}
                  >
                    Explore deals
                  </button>
                </div>
              )}
            </section>
          ) : null}

          <section
            style={{
              background: 'linear-gradient(135deg, #081a3a 0%, #0f3a8a 65%, #f59e0b 100%)',
              borderRadius: '2rem',
              padding: '3.4rem 2rem',
              textAlign: 'center',
              position: 'relative',
              overflow: 'hidden',
            }}
          >
            <div
              style={{
                position: 'absolute',
                inset: 0,
                backgroundImage:
                  'radial-gradient(circle at 20% 50%, rgba(56,189,248,0.22) 0%, transparent 40%), radial-gradient(circle at 80% 80%, rgba(251,191,36,0.2) 0%, transparent 34%)',
                opacity: 0.8,
              }}
            />

            <div style={{ position: 'relative', zIndex: 1, maxWidth: '50rem', margin: '0 auto' }}>
              <div
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  marginBottom: '1.25rem',
                  padding: '0.6rem 1.2rem',
                  borderRadius: '999px',
                  background: 'rgba(255,255,255,0.12)',
                  border: '1px solid rgba(255,255,255,0.16)',
                  fontSize: '0.8rem',
                  fontWeight: 700,
                  color: '#fff',
                  textTransform: 'uppercase',
                  letterSpacing: '0.05em',
                }}
              >
                <i className="fas fa-mobile-screen-button"></i>
                {currentCopy.finalEyebrow}
              </div>

              <h2
                style={{
                  fontSize: 'clamp(2.1rem, 5vw, 3.4rem)',
                  fontWeight: 900,
                  color: '#fff',
                  marginBottom: '1rem',
                  lineHeight: 1.15,
                }}
              >
                {currentCopy.finalTitle}
              </h2>

              <p
                style={{
                  fontSize: '1.08rem',
                  color: 'rgba(248,250,252,0.9)',
                  marginBottom: '2rem',
                  lineHeight: 1.75,
                  maxWidth: '38rem',
                  marginInline: 'auto',
                }}
              >
                {currentCopy.finalDescription}
              </p>

              <div className="flex justify-center gap-4 flex-wrap">
                <a
                  href={DOWNLOAD_URL}
                  className="btn"
                  style={{
                    background: 'linear-gradient(135deg, #fbbf24 0%, #f59e0b 100%)',
                    color: '#0f172a',
                    padding: '1.05rem 2.2rem',
                    fontSize: '1.02rem',
                    fontWeight: 900,
                    boxShadow: '0 10px 28px rgba(251,191,36,0.36)',
                    textDecoration: 'none',
                  }}
                >
                  <i className="fas fa-bolt"></i>
                  {currentCopy.finalPrimary}
                </a>
                <button
                  onClick={() => router.push('/categories/all')}
                  className="btn"
                  style={{
                    background: 'rgba(255,255,255,0.12)',
                    color: '#fff',
                    border: '1px solid rgba(255,255,255,0.22)',
                    padding: '1.05rem 2rem',
                    fontWeight: 700,
                  }}
                >
                  {currentCopy.finalSecondary}
                </button>
              </div>
            </div>
          </section>
        </div>
      </section>

      <div
        className="md:hidden"
        style={{
          position: 'fixed',
          left: '1rem',
          right: '1rem',
          bottom: '1rem',
          zIndex: 60,
        }}
      >
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(3, minmax(0, 1fr))',
            gap: '0.65rem',
            padding: '0.7rem',
            borderRadius: '1.25rem',
            background: 'color-mix(in srgb, var(--card-bg) 94%, transparent)',
            border: '1px solid var(--border-color)',
            backdropFilter: 'blur(14px)',
            boxShadow: '0 18px 36px rgba(15,23,42,0.16)',
          }}
        >
          {[
            { label: 'Explore', icon: 'fa-compass', onClick: () => router.push('/categories/all') },
            { label: 'Saved', icon: 'fa-heart', onClick: () => router.push('/favorites') },
            { label: 'Profile', icon: 'fa-user', onClick: () => router.push(user ? '/profile' : '/login') },
          ].map((item) => (
            <button
              key={item.label}
              onClick={item.onClick}
              style={{
                minHeight: '3.2rem',
                borderRadius: '1rem',
                border: 'none',
                background: item.label === 'Explore' ? 'var(--primary-gradient)' : 'var(--light-gray)',
                color: item.label === 'Explore' ? '#fff' : 'var(--text-primary)',
                fontWeight: 800,
                display: 'grid',
                placeItems: 'center',
                gap: '0.2rem',
                cursor: 'pointer',
              }}
            >
              <i className={`fas ${item.icon}`}></i>
              <span style={{ fontSize: '0.76rem' }}>{item.label}</span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
