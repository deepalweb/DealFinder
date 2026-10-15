import 'package:flutter/material.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';

/// Compact category refinements; the directory remains reachable through More.
class DiscoverCategoryStrip extends StatelessWidget {
  const DiscoverCategoryStrip(
      {super.key,
      required this.selected,
      required this.onSelected,
      required this.onAll});
  final String? selected;
  final ValueChanged<String?> onSelected;
  final VoidCallback onAll;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    String label(String en, String si, String ta) =>
        switch (language) { 'si' => si, 'ta' => ta, _ => en };
    final items = [
      (null, l10n.allLabel),
      ('food_dining', label('Food & Dining', 'ආහාර', 'உணவு')),
      (
        'daily_essentials',
        label('Daily Essentials', 'දෛනික අත්‍යවශ්‍ය', 'அத்தியாவசியங்கள்')
      ),
      ('shopping_retail', label('Shopping', 'සාප්පු සවාරි', 'ஷாப்பிங்')),
      ('electronics', label('Electronics', 'ඉලෙක්ට්‍රොනික', 'மின்னணுவியல்')),
      ('beauty_salon', label('Beauty & Salon', 'රූපලාවණ්‍ය', 'அழகு நிலையம்')),
      ('health_wellness', label('Wellness', 'සුවතාව', 'நல்வாழ்வு')),
    ];
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(item.$2),
                selected: selected == item.$1,
                onSelected: (_) =>
                    onSelected(selected == item.$1 ? null : item.$1),
                showCheckmark: false,
                selectedColor: colors.primary,
                backgroundColor: colors.surfaceContainerHighest,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                materialTapTargetSize: MaterialTapTargetSize.padded,
                visualDensity: VisualDensity.standard,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected == item.$1
                        ? colors.onPrimary
                        : colors.onSurface),
              ),
            ),
          Tooltip(
              message: l10n.allCategories,
              child: ActionChip(
                label: Text(label('More', 'තවත්', 'மேலும்')),
                onPressed: onAll,
                backgroundColor: colors.surfaceContainerHighest,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                materialTapTargetSize: MaterialTapTargetSize.padded,
                visualDensity: VisualDensity.standard,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface),
              )),
        ]));
  }
}
