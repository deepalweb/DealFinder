export const SITE_NAME = 'DealFinder';
export const SITE_URL = 'https://dealfinderapp.lk';
export const DEFAULT_TITLE = "DealFinder - Sri Lanka's Smartest Way to Find Deals";
export const DEFAULT_DESCRIPTION =
  'Discover exclusive discounts from top stores near you. Smart search, real-time updates, personalized recommendations. Find the best deals in Sri Lanka.';
export const DEFAULT_OG_IMAGE = `${SITE_URL}/favicon.ico`;

export const PUBLIC_ROUTES = [
  '/',
  '/about',
  '/contact',
  '/privacy',
  '/login',
  '/register',
  '/reset-password',
  '/favorites',
  '/nearby',
  '/notifications',
  '/profile',
  '/merchants',
] as const;

export const DEAL_CATEGORIES = [
  'fashion',
  'electronics',
  'food',
  'travel',
  'health',
  'home',
  'entertainment',
] as const;

export const CATEGORY_DETAILS: Record<
  string,
  { name: string; description: string }
> = {
  all: {
    name: 'All Deals',
    description:
      'Browse all live deals, discounts, and promotions across Sri Lanka on DealFinder.',
  },
  fashion: {
    name: 'Fashion Deals',
    description:
      'Explore fashion deals, clothing discounts, and style promotions from Sri Lankan stores.',
  },
  electronics: {
    name: 'Electronics Deals',
    description:
      'Find electronics discounts, gadget offers, and tech promotions from leading merchants in Sri Lanka.',
  },
  food: {
    name: 'Food Deals',
    description:
      'Discover restaurant offers, food promotions, and dining discounts near you in Sri Lanka.',
  },
  travel: {
    name: 'Travel Deals',
    description:
      'Compare travel deals, getaway offers, and tourism promotions from trusted merchants.',
  },
  health: {
    name: 'Health Deals',
    description:
      'Browse health, wellness, and pharmacy-related offers available through DealFinder.',
  },
  home: {
    name: 'Home Deals',
    description:
      'Find home, furniture, and household product promotions from Sri Lankan stores.',
  },
  entertainment: {
    name: 'Entertainment Deals',
    description:
      'See entertainment offers, activity discounts, and fun promotions available now.',
  },
};

export function absoluteUrl(path = '/') {
  return new URL(path, SITE_URL).toString();
}

export function getCategorySeo(categoryId: string) {
  return CATEGORY_DETAILS[categoryId] || CATEGORY_DETAILS.all;
}
