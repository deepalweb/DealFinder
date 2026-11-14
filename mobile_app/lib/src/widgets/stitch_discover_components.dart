import 'dart:async';
import 'dart:ui' show ImageFilter;

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

/// Shared visual tokens for the Discovery surface.
/// Keep structure reusable while resolving colors and typography from ThemeData.
class StitchDiscoverTokens {
  StitchDiscoverTokens._();

  static const pageGutter = 16.0;
  static const sectionTop = 20.0;
  static const sectionBottom = 10.0;
  static const cardRadius = 16.0;
  static const pillRadius = 24.0;
}

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
                ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            foregroundColor: scheme.primary,
            side: BorderSide(color: scheme.outlineVariant),
            minimumSize: const Size(44, 44),
            textStyle: base.textTheme.labelLarge?.copyWith(fontSize: 14))),
  );
}

String stitchLabel(BuildContext context, String en, String si, String ta) =>
    switch (Localizations.localeOf(context).languageCode) {
      'si' => si,
      'ta' => ta,
      _ => en
    };

/// Lightly frosted treatment for small controls that float above scrolling or
/// map content. Android uses a restrained blur and stronger fill for legibility.
class StitchGlassSurface extends StatelessWidget {
  const StitchGlassSurface(
      {super.key, required this.child, required this.borderRadius});
  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final highContrast = MediaQuery.highContrastOf(context);
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final opacity = highContrast ? 1.0 : (isAndroid ? 0.88 : 0.78);
    final decoration = BoxDecoration(
        color: colors.surface.withValues(alpha: opacity),
        border: Border.all(
            color: highContrast
                ? colors.outline
                : colors.outlineVariant.withValues(alpha: 0.72)),
        borderRadius: borderRadius,
        boxShadow: highContrast
            ? null
            : [
                BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ]);
    final surface = DecoratedBox(decoration: decoration, child: child);
    return ClipRRect(
        borderRadius: borderRadius,
        child: highContrast
            ? surface
            : BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: isAndroid ? 8 : 14, sigmaY: isAndroid ? 8 : 14),
                child: surface));
  }
}

Widget stitchText(BuildContext context, String text,
        {double size = 12,
        FontWeight weight = FontWeight.w400,
        Color? color,
        int? lines}) =>
    Text(text,
        maxLines: lines,
        overflow: lines == null ? null : TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            // Keep compact labels readable while Text still honors text scaling.
            fontSize: size < 13 ? 13 : size,
            height: 1.25,
            fontWeight: weight,
            color: color));

/// Composable section heading with a predictable hierarchy and an accessible
/// heading role for screen readers.
class StitchSectionHeading extends StatelessWidget {
  const StitchSectionHeading(
      {super.key,
      required this.title,
      this.subtitle,
      this.action,
      this.actionLabel,
      this.icon});

  final String title;
  final String? subtitle;
  final VoidCallback? action;
  final String? actionLabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final large = MediaQuery.textScalerOf(context).scale(16) > 24;
    final heading = Semantics(
        header: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (icon != null) Icon(icon, size: 18, color: colors.primary),
                stitchText(context, title, size: 15, weight: FontWeight.w700),
              ]),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            stitchText(context, subtitle!,
                size: 11, color: colors.onSurfaceVariant)
          ],
        ]));

    return Padding(
        padding: const EdgeInsets.fromLTRB(
            StitchDiscoverTokens.pageGutter,
            StitchDiscoverTokens.sectionTop,
            12,
            StitchDiscoverTokens.sectionBottom),
        child: Flex(
            direction: large ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment:
                large ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              if (large) heading else Expanded(child: heading),
              if (action != null)
                TextButton(
                    onPressed: action,
                    child: Text(actionLabel ??
                        AppLocalizations.of(context)!.viewAll))
            ]));
  }
}

class StitchLocationHeader extends StatelessWidget {
  const StitchLocationHeader(
      {super.key,
      required this.area,
      required this.unread,
      required this.onArea,
      required this.onNotifications});
  final String area;
  final int unread;
  final VoidCallback onArea, onNotifications;
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
                                                        fontSize: 14,
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
        child: StitchGlassSurface(
            borderRadius:
                BorderRadius.circular(StitchDiscoverTokens.pillRadius),
            child: Material(
                type: MaterialType.transparency,
                child: Row(children: [
                  Expanded(
                      child: InkWell(
                          onTap: onSearch,
                          borderRadius:
                              BorderRadius.circular(StitchDiscoverTokens.pillRadius),
                          child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              child: Row(children: [
                                Icon(Icons.search,
                                    size: 19, color: colors.onSurfaceVariant),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: DiscoverSearchHint(
                                        fontSize: 15,
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
                                      stitchLabel(
                                          context,
                                          'Try “pizza”',
                                          '“පීසා” සොයන්න',
                                          '“பீட்சா” தேடுங்கள்'),
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
                ]))));
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
      required this.onBank});
  final bool ending, bankOnly, filtered;
  final VoidCallback onReset, onEnding, onBank;
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
                            borderRadius: BorderRadius.circular(
                                StitchDiscoverTokens.pillRadius),
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
                                        borderRadius: BorderRadius.circular(
                                            StitchDiscoverTokens.pillRadius)),
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
  String get discountBadge => offer.discount?.trim() ?? '';
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
      this.showBenefit = true,
      this.heart = false});
  final Promotion offer;
  final VoidCallback onOpen;
  final double ratio;
  final bool bankOnImage, heart, showBenefit;
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
            if (showBenefit &&
                !benefitAtBottom &&
                copy.discountBadge.isNotEmpty)
              _badge(context, copy.discountBadge),
            if (bankOnImage && offer.bankName?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              _badge(context, offer.bankName!, green: false)
            ],
          ])),
      if (showBenefit && benefitAtBottom && copy.discountBadge.isNotEmpty)
        Positioned(
            left: 7,
            right: 7,
            bottom: 7,
            child: Align(
                alignment: Alignment.centerLeft,
                child: _badge(context, copy.discountBadge))),
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
    final headline = copy.discountBadge.isNotEmpty
        ? '${copy.discountBadge} · ${copy.merchant}'
        : copy.benefit.isNotEmpty
            ? '${copy.benefit} · ${copy.merchant}'
            : copy.merchant;
    return Material(
        color: const Color(0xFF077F5B),
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onOpen,
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  LayoutBuilder(builder: (context, constraints) {
                    final imageHeight = (constraints.maxWidth * .52)
                        .clamp(128.0, 180.0)
                        .toDouble();
                    return ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: SizedBox(
                            width: double.infinity,
                            height: imageHeight,
                            child: Stack(fit: StackFit.expand, children: [
                              DiscoverOfferImage(offer: offer),
                              const DecoratedBox(
                                  decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                    Colors.transparent,
                                    Color(0xCC002A1D),
                                  ],
                                          stops: [
                                    0.42,
                                    1
                                  ]))),
                              Positioned(
                                  left: 10,
                                  top: 10,
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 9, vertical: 5),
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
                                          color: const Color(0xFF533C1A)))),
                              Positioned(
                                  left: 12,
                                  right: 12,
                                  bottom: 11,
                                  child: stitchText(context, headline,
                                      size: 16,
                                      weight: FontWeight.w800,
                                      color: Colors.white,
                                      lines: 2)),
                            ])));
                  }),
                  _StitchActionLine(
                      leading: copy.view.price == null
                          ? null
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                  Text(offerMoney(offer, copy.view.price!),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800)),
                                  if (copy.view.previous != null)
                                    Wrap(spacing: 7, runSpacing: 2, children: [
                                      Text(
                                          offerMoney(
                                              offer, copy.view.previous!),
                                          style: const TextStyle(
                                              color: Color(0xFFD5EEE5),
                                              fontSize: 10,
                                              decoration:
                                                  TextDecoration.lineThrough)),
                                      if (copy.view.savings != null)
                                        Text(
                                            '${stitchLabel(context, 'Save', 'ඉතිරි', 'சேமி')} ${offerMoney(offer, copy.view.savings!)}',
                                            style: const TextStyle(
                                                color: Color(0xFFD5EEE5),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700)),
                                    ]),
                                ]),
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

class StitchFeaturedBannerCarousel extends StatefulWidget {
  const StitchFeaturedBannerCarousel(
      {super.key, required this.offers, required this.onOpen});

  final List<Promotion> offers;
  final ValueChanged<Promotion> onOpen;

  @override
  State<StitchFeaturedBannerCarousel> createState() =>
      _StitchFeaturedBannerCarouselState();
}

class _StitchFeaturedBannerCarouselState
    extends State<StitchFeaturedBannerCarousel> {
  static const _slideInterval = Duration(seconds: 2);
  static const _transitionDuration = Duration(milliseconds: 350);

  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant StitchFeaturedBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offers.length != widget.offers.length) _page = 0;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.offers.length < 2) return;
    _timer = Timer.periodic(_slideInterval, (_) {
      if (mounted) _showPage((_page + 1) % widget.offers.length);
    });
  }

  void _showPage(int index) => setState(() => _page = index);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.offers.isEmpty) return const SizedBox.shrink();
    final offer = widget.offers[_page.clamp(0, widget.offers.length - 1)];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity.abs() < 100 || widget.offers.length < 2) return;
          final delta = velocity < 0 ? 1 : -1;
          _showPage(
              (_page + delta + widget.offers.length) % widget.offers.length);
        },
        child: AnimatedSize(
          alignment: Alignment.topCenter,
          duration: _transitionDuration,
          curve: Curves.easeInOut,
          child: AnimatedSwitcher(
            duration: _transitionDuration,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: StitchFeaturedBanner(
              key: ValueKey('featured-banner:${offer.id}'),
              offer: offer,
              onOpen: () => widget.onOpen(offer),
            ),
          ),
        ),
      ),
      if (widget.offers.length > 1) ...[
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < widget.offers.length; index++)
              Semantics(
                label: 'Banner ${index + 1} of ${widget.offers.length}',
                selected: index == _page,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: index == _page ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == _page
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ],
        ),
      ],
    ]);
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
                                  size: 15, weight: FontWeight.w700),
                              if (copy.merchant != offer.title) ...[
                                const SizedBox(height: 5),
                                stitchText(context, offer.title,
                                    size: 14, lines: 2),
                              ],
                              const SizedBox(height: 5),
                              stitchText(context, copy.benefit,
                                  size: 16,
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

class StitchExpiringOfferCard extends StatelessWidget {
  const StitchExpiringOfferCard(
      {super.key, required this.offer, required this.onOpen, this.now});
  final Promotion offer;
  final DateTime? now;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => _StitchOfferCard(
      offer: offer, onOpen: onOpen, kind: 'expiring', now: now);
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
      {required this.offer,
      required this.onOpen,
      required this.kind,
      this.now});
  final Promotion offer;
  final VoidCallback onOpen;
  final String kind;
  final DateTime? now;
  @override
  Widget build(BuildContext context) {
    final copy = StitchOfferCopy(context, offer);
    final colors = Theme.of(context).colorScheme;
    final feed = kind == 'feed', bank = kind == 'bank';
    final expiring = kind == 'expiring';
    final large = MediaQuery.textScalerOf(context).scale(16) > 24;
    final screenWidth = MediaQuery.sizeOf(context).width;
    if ((feed || kind == 'nearby') &&
        !large &&
        screenWidth >= 320 &&
        screenWidth < 620) {
      return _StitchHorizontalFeedCard(
          offer: offer, onOpen: onOpen, copy: copy);
    }
    return Material(
        color: colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(StitchDiscoverTokens.cardRadius),
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
                      bankOnImage: true,
                      benefitAtBottom: true,
                      showBenefit: true,
                      heart: bank))),
          InkWell(
              onTap: onOpen,
              child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      feed ? 13 : 9, feed ? 0 : 9, feed ? 13 : 9, 9),
                  child: !feed
                      ? _StitchCompactSummary(
                          offer: offer, showExpiry: expiring, now: now)
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
                                            fontSize: 14,
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

/// Full-width discovery rows keep the offer photo and key details visible together.
class _StitchHorizontalFeedCard extends StatelessWidget {
  const _StitchHorizontalFeedCard(
      {required this.offer, required this.onOpen, required this.copy});
  final Promotion offer;
  final VoidCallback onOpen;
  final StitchOfferCopy copy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageWidth = (MediaQuery.sizeOf(context).width * .36)
        .clamp(116.0, 148.0)
        .toDouble();
    final price = copy.view.price;
    final priceText = copy.view.useDiscountHeadline
        ? copy.benefit
        : price != null
            ? offerMoney(offer, price)
            : copy.benefit;
    final description = offer.description.trim();
    final showDescription = description.isNotEmpty &&
        description.toLowerCase() != 'no description' &&
        description.trim() != offer.title.trim();

    return Material(
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(StitchDiscoverTokens.cardRadius),
          side: BorderSide(color: colors.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: imageWidth,
            height: 160,
            child: StitchOfferPhoto(
                offer: offer,
                onOpen: onOpen,
                ratio: imageWidth / 160,
                bankOnImage: true,
                benefitAtBottom: true,
                heart: true)),
        Expanded(
            child: SizedBox(
                height: 160,
                child: InkWell(
                    onTap: onOpen,
                    child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (copy.merchant != offer.title.trim()) ...[
                            Text(copy.merchant,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                        fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                          ],
                          Text(offer.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          if (showDescription) ...[
                            const SizedBox(height: 3),
                            Text(description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: colors.onSurfaceVariant)),
                          ],
                          if (priceText.isNotEmpty) ...[
                            const SizedBox(height: 7),
                            Wrap(
                                spacing: 7,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(priceText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              color: colors.primary,
                                              fontWeight: FontWeight.w800)),
                                  if (copy.view.previous != null)
                                    Text(
                                        offerMoney(
                                            offer, copy.view.previous!),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                decoration: TextDecoration
                                                    .lineThrough,
                                                color:
                                                    colors.onSurfaceVariant)),
                                ]),
                          ],
                          if (copy.bank.isNotEmpty ||
                              copy.metadata.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                                [
                                  if (copy.bank.isNotEmpty) copy.bank,
                                  if (copy.metadata.isNotEmpty) copy.metadata,
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(color: colors.onSurfaceVariant)),
                          ],
                        ])))))
      ]),
    );
  }
}

/// Shared compact content geometry; full-width feed cards retain their own layout.
class _StitchCompactSummary extends StatelessWidget {
  const _StitchCompactSummary(
      {required this.offer, this.showExpiry = false, this.now});
  final Promotion offer;
  final bool showExpiry;
  final DateTime? now;

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
    final remaining = offer.endDate?.difference(now ?? DateTime.now());
    final expiryText = remaining == null
        ? null
        : remaining.inDays >= 1
            ? '${remaining.inDays} d'
            : remaining.inHours >= 1
                ? '${remaining.inHours} h ${remaining.inMinutes % 60} m'
                : '${remaining.inMinutes.clamp(0, 59)} m';
    final merchant = offer.merchantName?.trim() ?? '';
    final distanceText = distance == null
        ? null
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
          slot(offer.title, 16, lines: 2, weight: FontWeight.w700),
          if (merchant.isNotEmpty && merchant != offer.title.trim()) ...[
            const SizedBox(height: 4),
            slot(merchant, 14, color: colors.onSurfaceVariant),
          ],
          if (rated || distanceText != null) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 10, runSpacing: 4, children: [
              if (rated)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded,
                      size: 14, color: Color(0xFFE3A51A)),
                  const SizedBox(width: 3),
                  Text('${rating.toStringAsFixed(1)} (${offer.ratingsCount})',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: colors.onSurfaceVariant))
                ]),
              if (distanceText != null)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.place_outlined,
                      size: 14, color: colors.onSurfaceVariant),
                  const SizedBox(width: 3),
                  Text(distanceText,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: colors.onSurfaceVariant))
                ]),
            ]),
          ],
          if (showExpiry && expiryText != null) ...[
            const SizedBox(height: 7),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(7)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.schedule_rounded,
                      size: 14, color: colors.onErrorContainer),
                  const SizedBox(width: 5),
                  Flexible(
                      child: Text(
                          '${stitchLabel(context, 'Ends in', 'අවසන් වීමට', 'முடிய இன்னும்')} $expiryText',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                  color: colors.onErrorContainer,
                                  fontWeight: FontWeight.w700)))
                ])),
          ],
          const SizedBox(height: 7),
          Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 7,
              runSpacing: 3,
              children: [
                Text(
                    copy.view.price != null
                        ? offerMoney(offer, copy.view.price!)
                        : copy.benefit.isNotEmpty
                            ? copy.benefit
                            : '—',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800, color: colors.primary)),
                if (copy.view.previous != null)
                  Text(offerMoney(offer, copy.view.previous!),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: colors.onSurfaceVariant)),
                if (copy.view.savings != null)
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                          color: colors.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color:
                                  colors.outlineVariant.withValues(alpha: .7))),
                      child: Text(
                          '${stitchLabel(context, 'Save', 'ඉතිරි', 'சேமி')} ${offerMoney(offer, copy.view.savings!)}',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  color: colors.onSecondaryContainer,
                                  fontWeight: FontWeight.w700))),
              ]),
        ]);
  }
}
