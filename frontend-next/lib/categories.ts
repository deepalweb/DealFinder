export type DealFinderCategory = {
  id: string;
  name: string;
  icon: string;
  shortName?: string;
};

export const DEALFINDER_CATEGORIES: DealFinderCategory[] = [
  { id: 'all', name: 'All Deals', icon: 'fa-compass', shortName: 'All' },
  { id: 'fashion', name: 'Fashion', icon: 'fa-shirt' },
  { id: 'electronics', name: 'Electronics', icon: 'fa-laptop' },
  { id: 'food_bev', name: 'Food & Bev', icon: 'fa-utensils' },
  { id: 'travel', name: 'Travel', icon: 'fa-plane' },
  { id: 'beauty_health', name: 'Beauty & Health', icon: 'fa-heart-pulse' },
  { id: 'home_garden', name: 'Home & Garden', icon: 'fa-house' },
  { id: 'entertainment', name: 'Entertainment', icon: 'fa-gamepad' },
  { id: 'services', name: 'Services', icon: 'fa-screwdriver-wrench' },
  { id: 'pets', name: 'Pets', icon: 'fa-paw' },
  { id: 'education', name: 'Education', icon: 'fa-school' },
  { id: 'other', name: 'Other', icon: 'fa-ellipsis' },
];

export function normalizeCategoryId(category?: string | null) {
  const value = (category || '').trim().toLowerCase();
  switch (value) {
    case 'food':
    case 'food bev':
    case 'food beverage':
      return 'food_bev';
    case 'health':
    case 'beauty':
    case 'beauty and health':
      return 'beauty_health';
    case 'home':
    case 'garden':
    case 'home and garden':
      return 'home_garden';
    case 'service':
      return 'services';
    default:
      return value || 'other';
  }
}

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
