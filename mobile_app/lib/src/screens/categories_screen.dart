import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../models/category.dart';
import 'all_deals_screen.dart';

IconData categoryIcon(String id) => switch (id) {
      'food_dining' => Icons.restaurant_outlined,
      'daily_essentials' => Icons.local_grocery_store_outlined,
      'shopping_retail' => Icons.shopping_bag_outlined,
      'electronics' => Icons.devices_outlined,
      'beauty_salon' => Icons.spa_outlined,
      'health_wellness' => Icons.favorite_outline,
      'bank_cards' => Icons.credit_card_outlined,
      'entertainment_activities' => Icons.confirmation_number_outlined,
      'education_courses' => Icons.school_outlined,
      'repairs_services' => Icons.build_outlined,
      'auto_services' => Icons.directions_car_outlined,
      _ => Icons.category_outlined
    };

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key, this.api});
  final ApiService? api;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final categories = [
      Category(id: 'all', name: l10n.allLabel),
      ...predefinedCategories
    ];
    final language = Localizations.localeOf(context).languageCode;
    const translated = {
      'food_dining': ['ආහාර සහ භෝජන', 'உணவு மற்றும் உணவகங்கள்'],
      'beauty_salon': ['රූපලාවන්‍ය', 'அழகு நிலையங்கள்'],
      'repairs_services': ['අලුත්වැඩියා සහ සේවා', 'பழுது மற்றும் சேவைகள்'],
      'electronics': ['ඉලෙක්ට්‍රොනික උපකරණ', 'மின்னணு சாதனங்கள்'],
      'shopping_retail': ['සාප්පු සවාරි', 'கடைப்பொருட்கள்'],
      'health_wellness': ['සෞඛ්‍ය සහ සුවතාව', 'உடல்நலம்'],
      'daily_essentials': ['දෛනික අත්‍යවශ්‍ය දෑ', 'அன்றாட அத்தியாவசியங்கள்'],
      'auto_services': ['රථවාහන සේවා', 'வாகனச் சேவைகள்'],
      'education_courses': ['අධ්‍යාපනය සහ පාඨමාලා', 'கல்வி மற்றும் பாடநெறிகள்'],
      'entertainment_activities': ['විනෝදාස්වාදය', 'பொழுதுபோக்கு'],
      'other': ['වෙනත්', 'ஏனையவை'],
    };
    String name(Category category) {
      if (category.id == 'all') return l10n.allLabel;
      if (category.id == 'bank_cards') return l10n.bankOffersTab;
      final labels = translated[category.id];
      return labels == null || language == 'en'
          ? category.name
          : labels[language == 'si' ? 0 : 1];
    }

    return Scaffold(
        appBar: AppBar(title: Text(l10n.allCategories)),
        body: LayoutBuilder(builder: (context, size) {
          final scaler = MediaQuery.textScalerOf(context);
          final enlarged = scaler.scale(16) > 24;
          final columns =
              size.maxWidth > 700 ? (enlarged ? 2 : 3) : (enlarged ? 1 : 2);
          final textWidth =
              (size.maxWidth - 32 - (columns - 1) * 12) / columns - 24;
          var textHeight = 0.0;
          for (final category in categories) {
            final painter = TextPainter(
                text: TextSpan(
                    text: name(category),
                    style: Theme.of(context).textTheme.titleSmall),
                textScaler: scaler,
                textDirection: Directionality.of(context))
              ..layout(maxWidth: textWidth);
            if (painter.height > textHeight) textHeight = painter.height;
            painter.dispose();
          }
          return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 86 + textHeight),
              itemCount: categories.length,
              itemBuilder: (context, i) {
                final category = categories[i];
                return Material(
                    color: colors.surfaceContainerLowest,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colors.outlineVariant)),
                    child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => AllDealsScreen(
                                    api: api,
                                    initialCategoryId: category.id == 'all' ||
                                            category.id == 'bank_cards'
                                        ? null
                                        : category.id,
                                    bankOffersOnly: category.id == 'bank_cards',
                                    initialContextTitle: name(category)))),
                        child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                      category.id == 'all'
                                          ? Icons.apps_outlined
                                          : categoryIcon(category.id),
                                      size: 30,
                                      color: colors.primary),
                                  const SizedBox(height: 12),
                                  Text(name(category),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall)
                                ]))));
              });
        }));
  }
}
