// Defines the structure for a category object

class Category {
  final String id;
  final String name;
  final String? iconUrl; // Optional: for a remote icon
  final String?
      localIconPath; // Optional: for a local asset icon (e.g., 'assets/icons/food.svg')
  // Add other relevant fields like color, etc., if needed

  Category({
    required this.id,
    required this.name,
    this.iconUrl,
    this.localIconPath,
  });
}

const List<String> launchCategoryIds = [
  'food_dining',
  'beauty_salon',
  'repairs_services',
  'electronics',
  'shopping_retail',
  'health_wellness',
];

String normalizeCategoryId(String? rawCategory) {
  final value = (rawCategory ?? '').trim().toLowerCase();
  switch (value) {
    case 'food_dining':
    case 'food_bev':
    case 'food':
    case 'food and dining':
    case 'food bev':
    case 'food beverage':
    case 'cafe':
    case 'cafes':
    case 'coffee':
    case 'coffee shop':
    case 'hangout':
      return 'food_dining';
    case 'beauty_salon':
    case 'health':
    case 'beauty':
    case 'beauty and health':
    case 'beauty_health':
    case 'salon':
    case 'spa':
    case 'grooming':
      return 'beauty_salon';
    case 'daily_essentials':
    case 'home':
    case 'garden':
    case 'home and garden':
    case 'home_garden':
    case 'grocery':
    case 'groceries':
    case 'pharmacy':
    case 'daily essentials':
      return 'daily_essentials';
    case 'repairs_services':
    case 'service':
    case 'services':
    case 'repair':
    case 'repairs':
      return 'repairs_services';
    case 'shopping':
    case 'shopping_retail':
    case 'retail':
    case 'fashion':
    case 'accessories':
    case 'clothing':
      return 'shopping_retail';
    case 'electronics':
    case 'electronic':
    case 'tech':
    case 'gadget':
    case 'mobile':
    case 'phone':
    case 'smartphone':
    case 'laptop':
    case 'computer':
      return 'electronics';
    case 'health_wellness':
    case 'wellness':
    case 'fitness':
    case 'clinic':
    case 'dental':
      return 'health_wellness';
    case 'auto':
    case 'auto_services':
      return 'auto_services';
    case 'education_courses':
    case 'course':
    case 'courses':
    case 'education':
    case 'tuition':
    case 'training':
      return 'education_courses';
    case 'entertainment':
    case 'entertainment_activities':
    case 'activities':
    case 'travel':
      return 'entertainment_activities';
    case 'pets':
      return 'other';
    default:
      return value;
  }
}

final List<Category> predefinedCategories = [
  Category(
      id: 'food_dining',
      name: 'Food & Dining',
      localIconPath: 'assets/icons/food_bev.svg'), // Example path
  Category(
      id: 'beauty_salon',
      name: 'Beauty & Salon',
      localIconPath: 'assets/icons/health.svg'),
  Category(
      id: 'repairs_services',
      name: 'Repairs & Services',
      localIconPath: 'assets/icons/services.svg'),
  Category(
      id: 'electronics',
      name: 'Electronics',
      localIconPath: 'assets/icons/electronics.svg'),
  Category(
      id: 'shopping_retail',
      name: 'Shopping & Retail',
      localIconPath: 'assets/icons/electronics.svg'),
  Category(
      id: 'health_wellness',
      name: 'Health & Wellness',
      localIconPath: 'assets/icons/health.svg'),
  Category(
      id: 'daily_essentials',
      name: 'Daily Essentials',
      localIconPath: 'assets/icons/home.svg'),
  Category(
      id: 'auto_services',
      name: 'Auto Services',
      localIconPath: 'assets/icons/services.svg'),
  Category(
      id: 'education_courses',
      name: 'Education & Courses',
      localIconPath: 'assets/icons/other.svg'),
  Category(
      id: 'entertainment_activities',
      name: 'Entertainment & Activities',
      localIconPath: 'assets/icons/entertainment.svg'),
  Category(id: 'other', name: 'Other', localIconPath: 'assets/icons/other.svg'),
];

final List<Category> launchCategories = predefinedCategories
    .where((category) => launchCategoryIds.contains(category.id))
    .toList();

Category? findCategory(String? categoryId) {
  final normalized = normalizeCategoryId(categoryId);
  for (final category in predefinedCategories) {
    if (category.id == normalized) {
      return category;
    }
  }
  return null;
}

String getCategoryLabel(String? categoryId) {
  final category = findCategory(categoryId);
  if (category != null) {
    return category.name;
  }

  final normalized = normalizeCategoryId(categoryId);
  if (normalized.isEmpty) {
    return 'Other';
  }

  return normalized
      .split('_')
      .map((part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

// Note: For localIconPath to work, you'd need to:
// 1. Create an `assets/icons/` folder in your Flutter project root.
// 2. Add the SVG/PNG icon files there.
// 3. Declare the assets folder in your `pubspec.yaml`:
//    flutter:
//      assets:
//        - assets/icons/
// For now, we will display text if icons are not available.
