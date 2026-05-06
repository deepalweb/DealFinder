// Defines the structure for a category object

class Category {
  final String id;
  final String name;
  final String? iconUrl; // Optional: for a remote icon
  final String? localIconPath; // Optional: for a local asset icon (e.g., 'assets/icons/food.svg')
  // Add other relevant fields like color, etc., if needed

  Category({
    required this.id,
    required this.name,
    this.iconUrl,
    this.localIconPath,
  });
}

String normalizeCategoryId(String? rawCategory) {
  final value = (rawCategory ?? '').trim().toLowerCase();
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
      return value;
  }
}

// Predefined list of categories (as per user decision)
// In a real app, this might come from an API or a more dynamic source.
final List<Category> predefinedCategories = [
  Category(id: 'food_bev', name: 'Food & Bev', localIconPath: 'assets/icons/food_bev.svg'), // Example path
  Category(id: 'electronics', name: 'Electronics', localIconPath: 'assets/icons/electronics.svg'),
  Category(id: 'fashion', name: 'Fashion', localIconPath: 'assets/icons/fashion.svg'),
  Category(id: 'travel', name: 'Travel', localIconPath: 'assets/icons/travel.svg'),
  Category(id: 'home_garden', name: 'Home & Garden', localIconPath: 'assets/icons/home.svg'),
  Category(id: 'beauty_health', name: 'Beauty & Health', localIconPath: 'assets/icons/health.svg'),
  Category(id: 'entertainment', name: 'Entertainment', localIconPath: 'assets/icons/entertainment.svg'),
  Category(id: 'services', name: 'Services', localIconPath: 'assets/icons/services.svg'),
  Category(id: 'pets', name: 'Pets', localIconPath: 'assets/icons/other.svg'),
  Category(id: 'education', name: 'Education', localIconPath: 'assets/icons/other.svg'),
  Category(id: 'other', name: 'Other', localIconPath: 'assets/icons/other.svg'),
];

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
      .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
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
