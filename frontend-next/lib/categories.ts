export type DealFinderCategory = {
  id: string;
  name: string;
  icon: string;
  shortName?: string;
};

export const DEALFINDER_CATEGORIES: DealFinderCategory[] = [
  { id: 'all', name: 'All Deals', icon: 'fa-compass', shortName: 'All' },
  { id: 'shopping_retail', name: 'Shopping & Retail', icon: 'fa-shirt' },
  { id: 'bank_cards', name: 'Bank Cards', icon: 'fa-credit-card' },
  { id: 'electronics', name: 'Electronics', icon: 'fa-laptop' },
  { id: 'food_dining', name: 'Food & Dining', icon: 'fa-utensils' },
  { id: 'beauty_salon', name: 'Beauty & Salon', icon: 'fa-heart-pulse' },
  { id: 'daily_essentials', name: 'Groceries & Essentials', icon: 'fa-house' },
  { id: 'health_wellness', name: 'Health & Wellness', icon: 'fa-briefcase-medical' },
  { id: 'repairs_services', name: 'Repairs & Services', icon: 'fa-screwdriver-wrench' },
  { id: 'entertainment_activities', name: 'Entertainment', icon: 'fa-gamepad' },
  { id: 'education_courses', name: 'Education & Courses', icon: 'fa-school' },
  { id: 'auto_services', name: 'Auto Services', icon: 'fa-car' },
  { id: 'other', name: 'Other', icon: 'fa-ellipsis' },
];

export function normalizeCategoryId(category?: string | null) {
  const value = (category || '').trim().toLowerCase();
  switch (value) {
    case 'fashion':
    case 'shopping':
    case 'retail':
      return 'shopping_retail';
    case 'food':
    case 'food bev':
    case 'food beverage':
    case 'food_bev':
      return 'food_dining';
    case 'health':
    case 'beauty':
    case 'beauty and health':
    case 'beauty_health':
      return 'beauty_salon';
    case 'home':
    case 'garden':
    case 'home and garden':
    case 'home_garden':
    case 'supermarkets':
      return 'daily_essentials';
    case 'service':
    case 'services':
      return 'repairs_services';
    case 'travel':
      return 'entertainment_activities';
    case 'education':
      return 'education_courses';
    case 'bank card':
    case 'bank cards':
    case 'credit card':
    case 'debit card':
      return 'bank_cards';
    default:
      return value || 'other';
  }
}

export const PROMOTION_CATEGORIES = DEALFINDER_CATEGORIES.filter(
  (category) => category.id !== 'all' && category.id !== 'other',
);

export function getCategoryMeta(category?: string | null) {
  const normalized = normalizeCategoryId(category);
  return (
    DEALFINDER_CATEGORIES.find((item) => item.id === normalized) || {
      id: normalized,
      name: toTitleCase(normalized),
      icon: 'fa-tag',
    }
  );
}

export function getCategoryLabel(category?: string | null) {
  return getCategoryMeta(category).name;
}

export function getCategoryIcon(category?: string | null) {
  return getCategoryMeta(category).icon;
}

function toTitleCase(value: string) {
  return value
    .split('_')
    .map((part) => (part ? `${part[0].toUpperCase()}${part.slice(1)}` : part))
    .join(' ');
}
