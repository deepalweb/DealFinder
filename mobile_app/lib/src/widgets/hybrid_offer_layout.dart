import 'package:flutter/material.dart';

/// Dense discovery preview. Conditions wrap; only the descriptive title is abbreviated.
class CompactDiscoverCardLayout extends StatelessWidget {
  const CompactDiscoverCardLayout(
      {super.key,
      required this.image,
      required this.save,
      required this.merchant,
      required this.title,
      required this.benefit,
      required this.eligibility,
      required this.conditions,
      required this.metadata,
      required this.onOpen,
      this.previousPrice});
  final Widget image, save;
  final String merchant, title, benefit, eligibility, conditions, metadata;
  final String? previousPrice;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Stack(children: [
          Semantics(
              button: true,
              label: title,
              child: InkWell(
                  onTap: onOpen,
                  child: AspectRatio(aspectRatio: 1.9, child: image))),
          Positioned(top: 2, right: 2, child: save),
        ]),
        InkWell(
            onTap: onOpen,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (merchant.isNotEmpty)
                        Text(merchant,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface)),
                      if (benefit.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        hybridCopy(context, benefit,
                            size: 16,
                            weight: FontWeight.w800,
                            color: colors.primary),
                      ],
                      if (previousPrice != null)
                        Text(previousPrice!,
                            style: TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: colors.onSurfaceVariant)),
                      if (title.trim().toLowerCase() !=
                          benefit.trim().toLowerCase()) ...[
                        const SizedBox(height: 3),
                        Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                height: 1.25,
                                fontWeight: FontWeight.w500)),
                      ],
                      for (final value in [eligibility, conditions, metadata])
                        if (value.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          hybridCopy(context, value,
                              size: 12, color: colors.onSurfaceVariant),
                        ],
                    ]))),
      ]),
    );
  }
}

/// Approved checkpoint geometry, shared by live offers and fixture renders.
Widget hybridCopy(BuildContext context, String value,
        {double size = 14,
        FontWeight weight = FontWeight.w400,
        Color? color}) =>
    Text(value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: size, fontWeight: weight, height: 1.3, color: color));

class HybridOfferCardLayout extends StatelessWidget {
  const HybridOfferCardLayout(
      {super.key,
      required this.image,
      required this.save,
      required this.merchant,
      required this.benefit,
      required this.title,
      required this.conditions,
      required this.metadata,
      required this.onOpen,
      this.eligibility,
      this.previousPrice,
      this.trailing,
      this.imageLabel});
  final Widget image, save;
  final String merchant, benefit, title, conditions, metadata;
  final String? eligibility, previousPrice;
  final Widget? trailing, imageLabel;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Material(
                color: colors.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colors.outlineVariant)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(children: [
                        Semantics(
                            button: true,
                            label: title,
                            child: InkWell(
                                onTap: onOpen,
                                child: AspectRatio(
                                    aspectRatio: 1.8, child: image))),
                        Positioned(right: 10, top: 10, child: save),
                        if (imageLabel != null)
                          Positioned(left: 10, top: 10, child: imageLabel!),
                      ]),
                      InkWell(
                          onTap: onOpen,
                          child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (merchant.isNotEmpty)
                                      hybridCopy(context, merchant,
                                          color: colors.onSurfaceVariant),
                                    const SizedBox(height: 5),
                                    if (benefit.isNotEmpty)
                                      Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            hybridCopy(context, benefit,
                                                size: 22,
                                                weight: FontWeight.w700,
                                                color: colors.primary),
                                            if (previousPrice != null)
                                              Text(previousPrice!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                          decoration:
                                                              TextDecoration
                                                                  .lineThrough,
                                                          color: colors
                                                              .onSurfaceVariant))
                                          ]),
                                    if (title.isNotEmpty &&
                                        title.trim().toLowerCase() !=
                                            benefit.trim().toLowerCase()) ...[
                                      const SizedBox(height: 5),
                                      hybridCopy(context, title,
                                          size: 16, weight: FontWeight.w600)
                                    ],
                                    if (eligibility?.isNotEmpty == true ||
                                        conditions.isNotEmpty)
                                      const SizedBox(height: 10),
                                    if (eligibility?.isNotEmpty == true) ...[
                                      hybridCopy(context, eligibility!,
                                          weight: FontWeight.w500),
                                      const SizedBox(height: 5)
                                    ],
                                    if (conditions.isNotEmpty)
                                      hybridCopy(context, conditions),
                                    if (metadata.isNotEmpty) ...[
                                      const SizedBox(height: 9),
                                      hybridCopy(context, metadata,
                                          size: 13,
                                          color: colors.onSurfaceVariant)
                                    ],
                                  ]))),
                      if (trailing != null)
                        Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                            child: trailing!),
                    ]))));
  }
}

class HybridConditionsPanel extends StatelessWidget {
  const HybridConditionsPanel(
      {super.key, required this.title, required this.facts});
  final String title;
  final List<String> facts;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
        decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant)),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline, color: colors.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                    child: hybridCopy(context, title,
                        size: 17, weight: FontWeight.w700))
              ]),
              const SizedBox(height: 12),
              for (final fact in facts)
                Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: hybridCopy(context, fact, size: 15)),
            ])));
  }
}

class HybridSearchHeader extends SliverPersistentHeaderDelegate {
  const HybridSearchHeader({required this.height, required this.child});
  final double height;
  final Widget child;
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox(height: height, child: child);
  @override
  bool shouldRebuild(HybridSearchHeader oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}
