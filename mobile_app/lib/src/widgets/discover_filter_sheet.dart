import 'package:flutter/material.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../models/category.dart';

class DiscoverFilterSelection {
  const DiscoverFilterSelection(
      {this.category,
      this.fulfillment,
      this.bankOnly = false,
      this.sort = 'default',
      this.endingOnly = false});
  final String? category;
  final String? fulfillment;
  final bool bankOnly;
  final String sort;
  final bool endingOnly;
}

/// Edits a draft; dismissing the sheet leaves the current feed unchanged.
class DiscoverFilterSheet extends StatefulWidget {
  const DiscoverFilterSheet(
      {super.key,
      required this.initial,
      required this.categories,
      this.allowDistance = false});
  final DiscoverFilterSelection initial;
  final List<Category> categories;
  final bool allowDistance;
  @override
  State<DiscoverFilterSheet> createState() => _DiscoverFilterSheetState();
}

class _DiscoverFilterSheetState extends State<DiscoverFilterSheet> {
  late String? _category = widget.initial.category;
  late String? _fulfillment = widget.initial.fulfillment;
  late bool _bankOnly = widget.initial.bankOnly;
  late String _sort = widget.initial.sort;
  late bool _endingOnly = widget.initial.endingOnly;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(l10n.filtersTitle,
                        style: Theme.of(context).textTheme.titleLarge)),
                const CloseButton(),
              ]),
              SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.bankOffersTab),
                  value: _bankOnly,
                  onChanged: (value) => setState(() => _bankOnly = value)),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ChoiceChip(
                    label: Text(l10n.allLabel),
                    selected: _fulfillment == null,
                    onSelected: (_) => setState(() => _fulfillment = null)),
                for (final mode in [
                  ('delivery', l10n.deliveryLabel),
                  ('visit_store', l10n.inStoreLabel),
                  ('pickup', l10n.pickupLabel),
                  (
                    'online',
                    switch (Localizations.localeOf(context).languageCode) {
                      'si' => 'මාර්ගගත',
                      'ta' => 'இணையம்',
                      _ => 'Online'
                    }
                  )
                ])
                  ChoiceChip(
                      label: Text(mode.$2),
                      selected: _fulfillment == mode.$1,
                      onSelected: (_) =>
                          setState(() => _fulfillment = mode.$1)),
              ]),
              SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.endingSoonLabel),
                  subtitle: Text(
                      switch (Localizations.localeOf(context).languageCode) {
                    'si' => 'දින 3ක් ඇතුළත අවසන් වේ',
                    'ta' => '3 நாட்களுக்குள் முடிகிறது',
                    _ => 'Ends within 3 days'
                  }),
                  value: _endingOnly,
                  onChanged: (value) => setState(() => _endingOnly = value)),
              const SizedBox(height: 16),
              Text(l10n.sortByTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final option in [
                  (
                    'default',
                    switch (Localizations.localeOf(context).languageCode) {
                      'si' => 'පෙරනිමි',
                      'ta' => 'இயல்புநிலை',
                      _ => 'Default'
                    }
                  ),
                  ('ending_soon', l10n.endingSoonLabel),
                  ('discount', l10n.highestDiscount),
                  ('recent', l10n.newest),
                  if (widget.allowDistance) ('distance', l10n.nearbyTab),
                ])
                  ChoiceChip(
                      label: Text(option.$2),
                      selected: _sort == option.$1,
                      onSelected: (_) => setState(() => _sort = option.$1)),
              ]),
              const SizedBox(height: 20),
              Text(l10n.browseCategoriesTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ChoiceChip(
                    label: Text(l10n.allCategories),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null)),
                ...widget.categories.map((c) => ChoiceChip(
                    label: Text(getCategoryLabel(c.id)),
                    selected: _category == c.id,
                    onSelected: (_) => setState(() => _category = c.id))),
              ]),
              const SizedBox(height: 20),
              Wrap(spacing: 12, runSpacing: 8, children: [
                TextButton(
                    onPressed: () => setState(() {
                          _category = null;
                          _fulfillment = null;
                          _bankOnly = false;
                          _sort = 'default';
                          _endingOnly = false;
                        }),
                    child: Text(l10n.clearFilters)),
                FilledButton(
                    onPressed: () => Navigator.pop(
                        context,
                        DiscoverFilterSelection(
                            category: _category,
                            fulfillment: _fulfillment,
                            bankOnly: _bankOnly,
                            sort: _sort,
                            endingOnly: _endingOnly)),
                    child: Text(l10n.applyFilterLabel)),
              ]),
            ])));
  }
}
