import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../models/promotion.dart';
import '../utils/offer_presentation.dart';
import 'discover_offer_image.dart';
import 'discover_offer_rating.dart';
import 'discover_search_hint.dart';
import 'discovery_offer_card.dart';
import 'offer_save_button.dart';

/// Compact control sizing for the marketplace screens. Colors come from AppTheme.
ThemeData stitchDiscoverTheme(ThemeData base) {
  final scheme = base.colorScheme;
  return base.copyWith(
    iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
            foregroundColor: scheme.primary, minimumSize: const Size(48, 48))),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            foregroundColor: scheme.primary,
            minimumSize: const Size(44, 44),
            textStyle: base.textTheme.labelLarge
                ?.copyWith(fontSize: 12, fontWeight: FontWeight.w600))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            foregroundColor: scheme.primary,
            side: BorderSide(color: scheme.outlineVariant),
            minimumSize: const Size(44, 44),
            textStyle: base.textTheme.labelLarge?.copyWith(fontSize: 12))),
  );
}

String stitchLabel(BuildContext context, String en, String si, String ta) =>
    switch (Localizations.localeOf(context).languageCode) {
      'si' => si,
      'ta' => ta,
      _ => en
    };

Widget stitchText(BuildContext context, String text,
        {double size = 12,
        FontWeight weight = FontWeight.w400,
        Color? color,
        int? lines}) =>
    Text(text,
        maxLines: lines,
        overflow: lines == null ? null : TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: size, height: 1.25, fontWeight: weight, color: color));

class StitchLocationHeader extends StatelessWidget {
  const StitchLocationHeader(
      {super.key,
      required this.area,
      required this.unread,
      required this.onArea,
      required this.onNotifications,
      required this.onStores});
  final String area;
  final int unread;
  final VoidCallback onArea, onNotifications, onStores;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 8, 0),
        child: Row(children: [
          Expanded(
              child: InkWell(
                  onTap: onArea,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 52),
                      child: Row(children: [
                        Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                shape: BoxShape.circle),
                            child: Icon(Icons.location_on_outlined,
                                size: 19, color: colors.primary)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Row(children: [
                                Flexible(
                                    child: stitchText(
                                        context,
                                        stitchLabel(context, 'OFFERS AROUND',
                                            'අවට දීමනා', 'அருகிலுள்ள சலுகைகள்'),
                                        size: 10,
                                        weight: FontWeight.w700,
                                        color: colors.primary)),
                                Icon(Icons.expand_more,
                                    size: 14, color: colors.primary)
                              ]),
                              stitchText(context, area,
                                  size: 13, weight: FontWeight.w600),
                            ])),
                      ])))),
          IconButton(
              tooltip: l10n.notifications,
              onPressed: onNotifications,
              icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.notifications_none, size: 21))),
          IconButton(
              tooltip: l10n.browseStores,
              onPressed: onStores,
              icon: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(20)),
                  child: Icon(Icons.storefront_outlined,
                      size: 18, color: colors.onPrimary))),
        ]));
  }
}

class StitchFulfillmentSegments extends StatelessWidget {
  const StitchFulfillmentSegments(
      {super.key, required this.selected, required this.onSelected});
  final String? selected;
  final ValueChanged<String?> onSelected;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (
        null,
        stitchLabel(context, 'All offers', 'සියලු දීමනා', 'அனைத்து சலுகைகள்')
      ),
      ('visit', l10n.inStoreLabel),
      ('online', stitchLabel(context, 'Online', 'මාර්ගගත', 'இணையம்'))
    ];
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DecoratedBox(
            decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
                padding: const EdgeInsets.all(3),
                child: IntrinsicHeight(
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: items
                            .map((item) => Expanded(
                                child: Semantics(
                                    selected: selected == item.$1,
                                    child: Material(
                                        color: selected == item.$1
                                            ? colors.surfaceContainerLowest
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(9),
                                        child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(9),
                                            onTap: () => onSelected(item.$1),
                                            child: Container(
                                                alignment: Alignment.center,
                                                constraints: const BoxConstraints(
                                                    minHeight: 40),
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 5, vertical: 6),
                                                child: Text(item.$2,
                                                    textAlign: TextAlign.center,
                                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                                        fontSize: 12,
                                                        fontWeight: selected == item.$1 ? FontWeight.w700 : FontWeight.w500,
                                                        color: selected == item.$1 ? colors.primary : colors.onSurfaceVariant))))))))
                            .toList())))));
  }
}

class StitchDiscoverSearchBar extends StatelessWidget {
  const StitchDiscoverSearchBar(
      {super.key,
      required this.onSearch,
      required this.onFilters,
      required this.count});
  final VoidCallback onSearch, onFilters;
  final int count;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Material(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            child: Row(children: [
              Expanded(
                  child: InkWell(
                      onTap: onSearch,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          child: Row(children: [
                            Icon(Icons.search,
                                size: 19, color: colors.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(
                                child: DiscoverSearchHint(
                                    fontSize: 12,
                                    maxLines: 1,
                                    searchLabel: stitchLabel(
                                        context,
                                        'Search deals, stores, or banks',
                                        'දීමනා, වෙළඳසැල් හෝ බැංකු සොයන්න',
                                        'சலுகைகள், கடைகள் அல்லது வங்கிகளைத் தேடுங்கள்'),
                                    suggestions: [
                                  stitchLabel(
                                      context,
                                      'Search food, deals, stores or banks',
                                      'ආහාර, දීමනා හෝ බැංකු සොයන්න',
                                      'உணவு, சலுகைகள் அல்லது வங்கிகளைத் தேடுங்கள்'),
                                  stitchLabel(context, 'Try “pizza”',
                                      '“පීසා” සොයන්න', '“பீட்சா” தேடுங்கள்'),
                                  stitchLabel(
                                      context,
                                      'Try “groceries”',
                                      '“සිල්ලර බඩු” සොයන්න',
                                      '“மளிகை” தேடுங்கள்'),
                                ]))
                          ])))),
              IconButton(
                  tooltip: AppLocalizations.of(context)!.filtersTitle,
                  onPressed: onFilters,
                  icon: Badge(
                      isLabelVisible: count > 0,
                      label: Text('$count'),
                      child: const Icon(Icons.tune, size: 19))),
            ])));
  }
}

class StitchQuickFilters extends StatelessWidget {
  const StitchQuickFilters(
      {super.key,
      required this.ending,
      required this.bankOnly,
      required this.filtered,
      required this.onReset,
      required this.onEnding,
      required this.onBank,
      required this.onCategories,
      this.categoryLabel});
  final String? categoryLabel;
  final bool ending, bankOnly, filtered;
  final VoidCallback onReset, onEnding, onBank, onCategories;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final options = [
      (
        Icons.local_offer_outlined,
        stitchLabel(context, 'All offers', 'සියලු දීමනා', 'அனைத்து சலுகைகள்'),
        !filtered,
        onReset
      ),
      (
        Icons.timer_outlined,
        AppLocalizations.of(context)!.endingSoonLabel,
        ending,
        onEnding
      ),
      (
        Icons.category_outlined,
        categoryLabel ?? AppLocalizations.of(context)!.allCategories,
        categoryLabel != null,
        onCategories
      ),
      (
        Icons.credit_card,
        AppLocalizations.of(context)!.bankOffersTab,
        bankOnly,
        onBank
      ),
    ];
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
            children: options
                .map((item) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: Semantics(
                        selected: item.$3,
                        button: true,
                        child: InkWell(
                            onTap: item.$4,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                                constraints:
                                    const BoxConstraints(minHeight: 44),
                                alignment: Alignment.center,
                                child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 11, vertical: 5),
                                    decoration: BoxDecoration(
                                        color: item.$3
                                            ? colors.primary
                                            : colors.surfaceContainerHighest,
                                        borderRadius:
                                            BorderRadius.circular(24)),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(item.$1,
                                              size: 14,
                                              color: item.$3
                                                  ? colors.onPrimary
                                                  : colors.onSurfaceVariant),
                                          const SizedBox(width: 4),
                                          stitchText(context, item.$2,
                                              size: 11,
                                              weight: FontWeight.w600,
                                              color: item.$3
                                                  ? colors.onPrimary
                                                  : colors.onSurfaceVariant)
                                        ])))))))
                .toList()));
  }
}

class StitchOfferCopy {
  StitchOfferCopy(this.context, this.offer);
  final BuildContext context;
  final Promotion offer;
  OfferPresentation get view => OfferPresentation(offer);
  String get merchant => offer.merchantName?.trim().isNotEmpty == true
      ? offer.merchantName!
      : offer.title;
  bool get hasDescriptiveTitle =>
      offer.title.trim() != merchant.trim() &&
      offer.title
              .replaceFirst(RegExp(r'^\[(?:FIXTURE|DEMO)\]\s*'), '')
              .trim()
              .toLowerCase() !=
          benefit.trim().toLowerCase();
  String get benefit => view.useDiscountHeadline
      ? offer.discount!.trim()
      : view.price != null
          ? offerMoney(offer, view.price!)
          : offer.discount?.trim() ?? '';
  String get bank => [
        if (offer.bankName?.isNotEmpty == true) offer.bankName!,
        ...offer.cardTypes.map((type) => switch (type) {
              'credit' => AppLocalizations.of(context)!.creditCardLabel,
              'debit' => AppLocalizations.of(context)!.debitCardLabel,
              _ => type
            })
      ].join(' · ');
  String get conditions => [
        if (OfferPresentation.validAmount(offer.minimumSpend) != null)
          AppLocalizations.of(context)!
              .minimumSpendLabel(offerMoney(offer, offer.minimumSpend!)),
        if (OfferPresentation.validAmount(offer.maximumBenefit) != null)
          '${stitchLabel(context, 'Max discount', 'උපරිම වට්ටම', 'அதிகபட்ச தள்ளுபடி')} ${offerMoney(offer, offer.maximumBenefit!)}',
      ].join(' · ');
  String get expiry => offer.endDate == null
      ? ''
      : AppLocalizations.of(context)!.offerEndsOn(
          DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag())
              .format(offer.endDate!
                  .toUtc()
                  .add(const Duration(hours: 5, minutes: 30))));
  String get metadata => [
        if (view.onlineOnly)
          stitchLabel(context, 'Online', 'මාර්ගගත', 'இணையம்')
        else ...[
          if (offer.supportsVisit) AppLocalizations.of(context)!.inStoreLabel,
          if (offer.supportsDelivery)
            AppLocalizations.of(context)!.deliveryLabel,
          if (offer.supportsPickup) AppLocalizations.of(context)!.pickupLabel,
          if (view.distance != null)
            '≈ ${view.distance! < 1000 ? '${view.distance!.round()} m' : '${(view.distance! / 1000).toStringAsFixed(1)} km'}',
        ],
        if (expiry.isNotEmpty) expiry,
      ].join(' · ');
}

Widget _badge(BuildContext context, String text, {bool green = true}) =>
    Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
            color: green
                ? const Color(0xFF006748)
                : Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(5)),
        child: stitchText(context, text,
            size: 10,
            weight: FontWeight.w700,
            color: green
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface));

class StitchOfferPhoto extends StatelessWidget {
  const StitchOfferPhoto(
      {super.key,
      required this.offer,
      required this.onOpen,
      this.ratio = 1.8,
      this.bankOnImage = false,
      this.benefitAtBottom = false,
      this.heart = false});
  final Promotion offer;
  final VoidCallback onOpen;
  final double ratio;
  final bool bankOnImage, heart;
  final bool benefitAtBottom;
  @override
  Widget build(BuildContext context) {
    final copy = StitchOfferCopy(context, offer);
    return Stack(children: [
      Semantics(
          button: true,
          label: offer.title,
          child: InkWell(
              onTap: onOpen,
              child: AspectRatio(
                  aspectRatio: ratio,
                  child: DiscoverOfferImage(offer: offer)))),
      Positioned(
          left: 8,
          top: 8,
          right: 50,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!benefitAtBottom && copy.benefit.isNotEmpty)
              _badge(context, copy.benefit),
            if (bankOnImage && offer.bankName?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              _badge(context, offer.bankName!, green: false)
            ],
          ])),
      if (benefitAtBottom && copy.benefit.isNotEmpty)
        Positioned(
            left: 7,
            right: 7,
            bottom: 7,
            child: Align(
                alignment: Alignment.centerLeft,
                child: _badge(context, copy.benefit))),
      Positioned(
          right: 1,
          top: 1,
          child: OfferSaveButton(offer: offer, compact: true, heart: heart)),
    ]);
  }
}

class _StitchActionLine extends StatelessWidget {
  const _StitchActionLine({this.leading, required this.action});
  final Widget? leading;
  final Widget action;
  @override
  Widget build(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(16) > 24
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [if (leading != null) leading!, action])
          : Row(children: [
              Expanded(child: leading ?? const SizedBox.shrink()),
              const SizedBox(width: 8),
              action
            ]);
}

class StitchFeaturedBanner extends StatelessWidget {
  const StitchFeaturedBanner(
      {super.key, required this.offer, required this.onOpen});
  final Promotion offer;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final copy = StitchOfferCopy(context, offer);
    return Material(
        color: const Color(0xFF077F5B),
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onOpen,
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFFFE6AC),
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: stitchText(
                                          context,
                                          stitchLabel(
                                              context,
                                              'FEATURED OFFER',
                                              'විශේෂ දීමනාව',
                                              'சிறப்புச் சலுகை'),
                                          size: 9,
                                          weight: FontWeight.w700,
                                          color: const Color(0xFF533C1A))),
                                  const SizedBox(height: 8),
                                  stitchText(
                                      context,
                                      copy.benefit.isEmpty
                                          ? offer.title
                                          : '${copy.benefit} · ${copy.merchant}',
                                      size: 16,
                                      weight: FontWeight.w800,
                                      color: Colors.white),
                                  const SizedBox(height: 5),
                                  stitchText(
                                      context,
                                      copy.bank.isNotEmpty
                                          ? copy.bank
                                          : offer.title,
                                      size: 11,
                                      color: Colors.white,
                                      lines: 2),
                                ])),
                            const SizedBox(width: 12),
                            ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                    width: 58,
                                    height: 58,
                                    child: DiscoverOfferImage(offer: offer))),
                          ]),
                      const Divider(height: 16, color: Color(0xFF50A58B)),
                      _StitchActionLine(
                          leading: copy.conditions.isEmpty
                              ? null
                              : stitchText(context, copy.conditions,
                                  size: 11, color: Colors.white),
                          action: TextButton(
                              style: TextButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: const Color(0xFF006748),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9))),
                              onPressed: onOpen,
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(AppLocalizations.of(context)!
                                      .viewOfferLabel)))),
                    ]))));
  }
}

class StitchExpiringOfferStrip extends StatelessWidget {
  const StitchExpiringOfferStrip(
      {super.key, required this.offer, required this.onOpen, this.now});
  final Promotion offer;
  final DateTime? now;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final copy = StitchOfferCopy(context, offer);
    final remaining = offer.endDate!.difference(now ?? DateTime.now());
    final label = remaining.inHours >= 24
        ? '${remaining.inDays} d'
        : remaining.inHours >= 1
            ? '${remaining.inHours} h ${remaining.inMinutes % 60} m'
            : '${remaining.inMinutes.clamp(0, 59)} m';
    final colors = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.timer_outlined, size: 18, color: colors.error),
            stitchText(
                context,
                stitchLabel(context, 'Offers ending soon',
                    'ළඟදීම අවසන් වන දීමනා', 'விரைவில் முடியும் சலுகைகள்'),
                size: 14,
                weight: FontWeight.w700),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(5)),
                child: stitchText(context,
                    '${stitchLabel(context, 'Ends in', 'අවසන් වීමට', 'முடிய இன்னும்')} $label',
                    size: 10,
                    weight: FontWeight.w600,
                    color: colors.onErrorContainer)),
          ]),
      const SizedBox(height: 8),
      Material(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
              padding: const EdgeInsets.all(10),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Semantics(
                    button: true,
                    label: offer.title,
                    child: InkWell(
                        onTap: onOpen,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                                width: 80,
                                height: 76,
                                child: DiscoverOfferImage(offer: offer))))),
                const SizedBox(width: 10),
                Expanded(
                    child: InkWell(
                        onTap: onOpen,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              stitchText(context, copy.merchant,
                                  size: 12, weight: FontWeight.w700),
                              if (copy.merchant != offer.title) ...[
                                const SizedBox(height: 5),
                                stitchText(context, offer.title,
                                    size: 11, lines: 2),
                              ],
                              const SizedBox(height: 5),
                              stitchText(context, copy.benefit,
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: colors.primary),
                              if (copy.bank.isNotEmpty)
                                stitchText(context, copy.bank, size: 11),
                              if (copy.conditions.isNotEmpty)
                                stitchText(context, copy.conditions, size: 11),
                            ]))),
                OfferSaveButton(offer: offer, compact: true, heart: true),
              ]))),
    ]);
  }
}

/// Distinct information density for the horizontal preview, bank grid and main feed.
class StitchHorizontalOfferCard extends StatelessWidget {
  const StitchHorizontalOfferCard(
      {super.key, required this.offer, required this.onOpen});
  final Promotion offer;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) =>
      _StitchOfferCard(offer: offer, onOpen: onOpen, kind: 'rail');
}

class StitchNearbyOfferCard extends StatelessWidget {
  const StitchNearbyOfferCard(
      {super.key, required this.offer, required this.onOpen});
  final Promotion offer;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) =>
      _StitchOfferCard(offer: offer, onOpen: onOpen, kind: 'nearby');
}

class StitchBankGridCard extends StatelessWidget {
  const StitchBankGridCard(
      {super.key, required this.offer, required this.onOpen});
  final Promotion offer;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) =>
      _StitchOfferCard(offer: offer, onOpen: onOpen, kind: 'bank');
}

class StitchFullWidthOfferCard extends StatelessWidget {
  const StitchFullWidthOfferCard(
      {super.key, required this.offer, required this.onOpen});
  final Promotion offer;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) =>
      _StitchOfferCard(offer: offer, onOpen: onOpen, kind: 'feed');
}

class _StitchOfferCard extends StatelessWidget {
  const _StitchOfferCard(
      {required this.offer, required this.onOpen, required this.kind});
  final Promotion offer;
  final VoidCallback onOpen;
  final String kind;
  @override
  Widget build(BuildContext context) {
    final copy = StitchOfferCopy(context, offer);
    final colors = Theme.of(context).colorScheme;
    final feed = kind == 'feed', bank = kind == 'bank';
    final large = MediaQuery.textScalerOf(context).scale(16) > 24;
    return Material(
        color: colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
            side: BorderSide(color: colors.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
              padding: EdgeInsets.all(feed ? 10 : 0),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(feed ? 9 : 0),
                  child: StitchOfferPhoto(
                      offer: offer,
                      onOpen: onOpen,
                      ratio: feed
                          ? 2.15
                          : bank
                              ? 1.8
                              : 2.0,
                      bankOnImage: !bank,
                      benefitAtBottom: bank,
                      heart: bank))),
          InkWell(
              onTap: onOpen,
              child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      feed ? 13 : 9, feed ? 0 : 9, feed ? 13 : 9, 9),
                  child: !feed
                      ? _StitchCompactSummary(offer: offer)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    stitchText(context, copy.merchant,
                                        size: feed ? 15 : 13,
                                        weight: FontWeight.w700),
                                    if (feed) DiscoverOfferRating(offer: offer),
                                  ]),
                              if ((feed && copy.merchant != offer.title) ||
                                  copy.hasDescriptiveTitle) ...[
                                const SizedBox(height: 4),
                                stitchText(context, offer.title,
                                    size: 11,
                                    color: colors.onSurfaceVariant,
                                    lines: large ? null : 2)
                              ],
                              if (copy.bank.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                stitchText(context, copy.bank,
                                    size: 11,
                                    color: colors.primary,
                                    weight: FontWeight.w600)
                              ],
                              if (!copy.view.useDiscountHeadline &&
                                  copy.view.previous != null)
                                Text(offerMoney(offer, copy.view.previous!),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            fontSize: 11,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: colors.onSurfaceVariant)),
                              if (!feed && copy.conditions.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                stitchText(context, copy.conditions,
                                    size: 11, color: colors.onSurfaceVariant)
                              ],
                              if (copy.metadata.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                stitchText(context, copy.metadata,
                                    size: 11, color: colors.onSurfaceVariant)
                              ],
                              if (!feed &&
                                  offer.averageRating != null &&
                                  offer.ratingsCount > 0) ...[
                                const Divider(height: 14),
                                DiscoverOfferRating(offer: offer)
                              ],
                            ]))),
          if (feed) ...[
            Divider(
                height: 1,
                indent: 12,
                endIndent: 12,
                color: colors.outlineVariant),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: _StitchActionLine(
                    leading: copy.conditions.isEmpty
                        ? null
                        : stitchText(context, copy.conditions,
                            size: 11,
                            weight: FontWeight.w600,
                            color: colors.primary),
                    action: TextButton(
                        onPressed: onOpen,
                        style: TextButton.styleFrom(
                            foregroundColor: colors.onPrimaryContainer,
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.zero),
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(AppLocalizations.of(context)!
                                .viewOfferLabel))))),
          ],
        ]));
  }
}

/// Shared compact content geometry; full-width feed cards retain their own layout.
class _StitchCompactSummary extends StatelessWidget {
  const _StitchCompactSummary({required this.offer});
  final Promotion offer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scaler = MediaQuery.textScalerOf(context);
    final copy = StitchOfferCopy(context, offer);
    final rating = offer.averageRating;
    final rated = rating != null &&
        rating.isFinite &&
        rating >= 0 &&
        rating <= 5 &&
        offer.ratingsCount > 0;
    final distance = copy.view.distance;
    final ratingText = rated
        ? '${rating.toStringAsFixed(1)} (${offer.ratingsCount})'
        : stitchLabel(context, 'Not rated', 'ඇගයීම් නැත', 'மதிப்பீடு இல்லை');
    final distanceText = distance == null
        ? '—'
        : '≈ ${distance < 1000 ? '${distance.round()} m' : '${(distance / 1000).toStringAsFixed(1)} km'}';
    Widget slot(String value, double size,
            {int lines = 1,
            FontWeight weight = FontWeight.w400,
            Color? color}) =>
        SizedBox(
            height: scaler.scale(size) * 1.3 * lines,
            width: double.infinity,
            child: Tooltip(
                message: value,
                child: Text(value,
                    maxLines: lines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: size,
                        height: 1.3,
                        fontWeight: weight,
                        color: color ?? colors.onSurface))));
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          slot(offer.title, 13, lines: 2, weight: FontWeight.w700),
          const SizedBox(height: 4),
          slot(
              offer.merchantName?.trim().isNotEmpty == true
                  ? offer.merchantName!
                  : '—',
              12,
              color: colors.onSurfaceVariant),
          const SizedBox(height: 4),
          slot(ratingText, 11, color: colors.onSurfaceVariant),
          slot(distanceText, 11, color: colors.onSurfaceVariant),
          const SizedBox(height: 4),
          slot(copy.benefit.isNotEmpty ? copy.benefit : '—', 14,
              lines: 2, weight: FontWeight.w700, color: colors.primary),
        ]);
  }
}
