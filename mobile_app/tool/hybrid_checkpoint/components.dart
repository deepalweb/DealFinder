import 'package:deal_finder_mobile/src/widgets/hybrid_offer_layout.dart';
// Fixture-only visual checkpoint. Not imported by the production app.
import 'package:flutter/material.dart';
import 'package:deal_finder_mobile/src/widgets/discover_category_artwork.dart';

void previewMessage(BuildContext context) =>
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Visual prototype only. No account, location or API action was performed.')));

class ConceptOffer {
  const ConceptOffer(
      {required this.id,
      required this.merchant,
      required this.title,
      required this.benefit,
      required this.image,
      required this.conditions,
      this.bank,
      this.category = 'food_dining',
      this.online = false,
      this.distance = '650 m',
      this.expiry = 'Ends 25 Oct',
      this.endingSoon = false});
  final String id, merchant, title, benefit, image, category, distance, expiry;
  final List<String> conditions;
  final String? bank;
  final bool online, endingSoon;
}

const checkpointOffers = [
  ConceptOffer(
      id: 'bill',
      merchant: 'Ceylon Dining · Colombo 03',
      title: 'Weekend dining offer',
      benefit: '25% off your food bill',
      image: 'assets/discover/stitch-1.jpg',
      bank: 'Sample Bank · Selected credit cards',
      conditions: ['Minimum spend LKR 3,000', 'Maximum discount LKR 1,000']),
  ConceptOffer(
      id: 'package',
      merchant: 'Street Burger · Colombo 03',
      title: 'Burger & coffee package',
      benefit: 'LKR 1,900',
      image: 'assets/discover/stitch-2.jpg',
      distance: '850 m',
      conditions: [
        'Fixed package price · No card restriction',
        'One burger and one coffee'
      ]),
  ConceptOffer(
      id: 'bank',
      merchant: 'Harbour Table · Colombo 03',
      title: 'Weekday dining offer',
      benefit: '20% off your food bill',
      image: 'assets/discover/stitch-1.jpg',
      bank: 'Sample Bank · Selected debit cards',
      conditions: ['Minimum spend LKR 2,000', 'Maximum discount LKR 750'],
      distance: '1.2 km'),
  ConceptOffer(
      id: 'bank-two',
      merchant: 'City Bistro · Colombo 03',
      title: 'Selected lunch menu',
      benefit: '15% off your food bill',
      image: 'assets/discover/stitch-2.jpg',
      bank: 'Example Bank · Selected credit cards',
      conditions: ['Minimum spend LKR 2,500', 'Maximum discount LKR 600'],
      distance: '1.4 km'),
  ConceptOffer(
      id: 'grocery',
      merchant: 'Fresh Market · Online',
      title: 'Online grocery offer',
      benefit: 'Save LKR 500',
      image: 'assets/discover/stitch-3.jpg',
      category: 'daily_essentials',
      online: true,
      conditions: [
        'Minimum spend LKR 5,000',
        'Use the code on the merchant website'
      ],
      endingSoon: true),
];

Widget copy(BuildContext context, String value,
        {double size = 14,
        FontWeight weight = FontWeight.w400,
        Color? color}) =>
    Text(value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: size, fontWeight: weight, height: 1.3, color: color));

class CheckpointCard extends StatelessWidget {
  const CheckpointCard({super.key, required this.offer, required this.onOpen});
  final ConceptOffer offer;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return HybridOfferCardLayout(
        image: Image.asset(offer.image,
            fit: BoxFit.cover, excludeFromSemantics: true),
        save: Material(
            color: colors.surface,
            shape: const CircleBorder(),
            child: IconButton(
                tooltip: 'Saving unavailable in this visual prototype',
                onPressed: () => previewMessage(context),
                icon: Icon(Icons.bookmark_border, color: colors.onSurface))),
        imageLabel: DecoratedBox(
            decoration: BoxDecoration(
                color: colors.surface, borderRadius: BorderRadius.circular(6)),
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child:
                    copy(context, 'DEMO', size: 11, weight: FontWeight.w700))),
        merchant: offer.merchant,
        benefit: offer.benefit,
        title: offer.title,
        eligibility: offer.bank,
        conditions: offer.conditions.join(' · '),
        metadata:
            '${offer.online ? 'Online · Merchant website' : 'Dine-in · ≈ ${offer.distance} from selected area'} · ${offer.expiry}',
        onOpen: onOpen);
  }
}

class CheckpointDiscover extends StatefulWidget {
  const CheckpointDiscover({super.key});
  @override
  State<CheckpointDiscover> createState() => _CheckpointDiscoverState();
}

class _CheckpointDiscoverState extends State<CheckpointDiscover> {
  String? category;
  String fulfillment = 'all';
  bool endingSoon = false;
  String sort = 'default';
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  int get filterCount =>
      (fulfillment == 'all' ? 0 : 1) +
      (endingSoon ? 1 : 0) +
      (sort == 'default' ? 0 : 1);
  List<ConceptOffer> get matches => checkpointOffers
      .where((o) =>
          (category == null || o.category == category) &&
          (fulfillment == 'all' ||
              (fulfillment == 'online' ? o.online : !o.online)) &&
          (!endingSoon || o.endingSoon))
      .toList();
  void open(ConceptOffer o) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => CheckpointDetails(offer: o)));
  Future<void> filters() async {
    var nextFulfillment = fulfillment, nextSort = sort;
    var nextEnding = endingSoon;
    final accepted = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => StatefulBuilder(
            builder: (context, update) => SafeArea(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(children: [
                            Expanded(
                                child: copy(context, 'Filters · demo',
                                    size: 22, weight: FontWeight.w700)),
                            IconButton(
                                tooltip: 'Cancel filters',
                                onPressed: () => Navigator.pop(context, false),
                                icon: const Icon(Icons.close))
                          ]),
                          copy(context, 'Sort',
                              size: 16, weight: FontWeight.w600),
                          Wrap(spacing: 8, children: [
                            for (final entry in {
                              'default': 'Default',
                              'ending': 'Ending first'
                            }.entries)
                              ChoiceChip(
                                  label: Text(entry.value),
                                  selected: nextSort == entry.key,
                                  onSelected: (_) =>
                                      update(() => nextSort = entry.key))
                          ]),
                          const SizedBox(height: 12),
                          copy(context, 'How to use the offer',
                              size: 16, weight: FontWeight.w600),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final entry in {
                              'all': 'All',
                              'in_store': 'In-store',
                              'online': 'Online'
                            }.entries)
                              ChoiceChip(
                                  label: Text(entry.value),
                                  selected: nextFulfillment == entry.key,
                                  onSelected: (_) =>
                                      update(() => nextFulfillment = entry.key))
                          ]),
                          SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Ending soon'),
                              value: nextEnding,
                              onChanged: (v) => update(() => nextEnding = v)),
                          FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Apply filters')),
                          const SizedBox(height: 8),
                          copy(context,
                              'Fixture controls only. Live filtering requires separate verification.',
                              size: 13),
                        ])))));
    if (accepted == true && mounted) {
      setState(() {
        fulfillment = nextFulfillment;
        sort = nextSort;
        endingSoon = nextEnding;
      });
    }
  }

  Widget title(String value) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: copy(context, value, size: 20, weight: FontWeight.w700));
  Widget card(ConceptOffer o) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: CheckpointCard(offer: o, onOpen: () => open(o)));
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final large = MediaQuery.textScalerOf(context).scale(16) > 24;
    final rows = matches;
    if (sort == 'ending') {
      rows.sort(
          (a, b) => (b.endingSoon ? 1 : 0).compareTo(a.endingSoon ? 1 : 0));
    }
    final lead = rows.take(2).toList();
    final rest = rows.skip(2).toList();
    final banks = rest.where((o) => o.bank != null).toList();
    final more = rest.where((o) => !banks.contains(o)).toList();
    return Scaffold(
        backgroundColor: colors.surfaceContainerLow,
        bottomNavigationBar:
            NavigationBar(selectedIndex: 0, destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Discover'),
          NavigationDestination(
              icon: Icon(Icons.near_me_outlined), label: 'Nearby'),
          NavigationDestination(
              icon: Icon(Icons.credit_card), label: 'Bank Offers'),
          NavigationDestination(
              icon: Icon(Icons.bookmark_border), label: 'Saved'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Account'),
        ]),
        body: SafeArea(
            child: CustomScrollView(controller: scroll, slivers: [
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
                  child: Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          copy(context, 'Explore offers · DEMO',
                              size: 12, color: colors.onSurfaceVariant),
                          Row(children: [
                            Flexible(
                                child: copy(context, 'Colombo 03',
                                    size: 20, weight: FontWeight.w700)),
                            const Icon(Icons.expand_more, size: 20)
                          ])
                        ])),
                    IconButton(
                        tooltip: 'Notifications unavailable in this prototype',
                        onPressed: null,
                        icon: Icon(Icons.notifications_none,
                            color: colors.onSurface))
                  ]))),
          SliverPersistentHeader(
              pinned: true,
              delegate: HybridSearchHeader(
                  height: large ? 116 : 68,
                  child: ColoredBox(
                      color: colors.surfaceContainerLow,
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: DecoratedBox(
                              decoration: BoxDecoration(
                                  color: colors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(26)),
                              child: Row(children: [
                                const SizedBox(width: 14),
                                const Icon(Icons.search, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: copy(
                                        context,
                                        large
                                            ? 'Search offers'
                                            : 'Search deals, stores, or banks',
                                        size: 14,
                                        color: colors.onSurfaceVariant)),
                                IconButton(
                                    tooltip: 'Filters',
                                    onPressed: filters,
                                    icon: Badge(
                                        isLabelVisible: filterCount > 0,
                                        label: Text('$filterCount'),
                                        child: const Icon(Icons.tune))),
                              ])))))),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                      height: large ? 170 : 102,
                      child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          children: [
                            for (final entry in {
                              'food_dining': 'Food & Dining',
                              'daily_essentials': 'Essentials',
                              'shopping_retail': 'Shopping',
                              'electronics': 'Electronics',
                              'beauty_salon': 'Beauty',
                              'health_wellness': 'Wellness',
                              'all': 'All categories'
                            }.entries)
                              SizedBox(
                                  width: large ? 126 : 82,
                                  child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          onTap: () => setState(() => category =
                                              entry.key == 'all' ||
                                                      entry.key == category
                                                  ? null
                                                  : entry.key),
                                          child: Column(children: [
                                            DiscoverCategoryArtwork(
                                                category: entry.key == 'all'
                                                    ? 'filters'
                                                    : entry.key),
                                            const SizedBox(height: 4),
                                            copy(context, entry.value,
                                                size: 12,
                                                weight: category == entry.key
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: category == entry.key
                                                    ? colors.primary
                                                    : colors.onSurface),
                                            const SizedBox(height: 5),
                                            if (category == entry.key)
                                              Container(
                                                  width: 22,
                                                  height: 3,
                                                  color: colors.primary)
                                          ]))))
                          ])))),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        copy(context, 'Explore offers',
                            size: 20, weight: FontWeight.w700),
                        const SizedBox(height: 3),
                        copy(context, 'Matching offers loaded so far',
                            size: 13, color: colors.onSurfaceVariant),
                        if (filterCount > 0 || category != null)
                          TextButton(
                              onPressed: () => setState(() {
                                    category = null;
                                    fulfillment = 'all';
                                    endingSoon = false;
                                    sort = 'default';
                                  }),
                              child: const Text('Clear filters'))
                      ]))),
          for (final o in lead) SliverToBoxAdapter(child: card(o)),
          if (rows.isEmpty)
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: copy(context,
                        'No matches in loaded results. Clear filters or load another page.'))),
          if (banks.isNotEmpty) ...[
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 10),
                    child: Row(children: [
                      Expanded(
                          child: copy(context, 'Explore bank offers',
                              size: 20, weight: FontWeight.w700)),
                      TextButton(
                          onPressed: () => previewMessage(context),
                          child: const Text('See all'))
                    ]))),
            // Variable-height, wrapping cards: use a bounded horizontal collection only at normal text size.
            if (large)
              for (final o in banks) SliverToBoxAdapter(child: card(o))
            else
              SliverToBoxAdapter(
                  child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(left: 16, bottom: 18),
                      child: IntrinsicHeight(
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            for (final o in banks)
                              Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: SizedBox(
                                      width: MediaQuery.sizeOf(context).width *
                                          .82,
                                      child: CheckpointCard(
                                          offer: o, onOpen: () => open(o))))
                          ])))),
          ] else
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: copy(context, 'Explore bank offers',
                        color: colors.primary))),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child:
                      copy(context, 'Browse stores', color: colors.primary))),
          if (more.isNotEmpty) SliverToBoxAdapter(child: title('More offers')),
          for (final o in more) SliverToBoxAdapter(child: card(o)),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const OutlinedButton(
                            onPressed: null,
                            child: Text('Load more · demo only')),
                        const SizedBox(height: 8),
                        copy(context,
                            'Visual prototype · sample inventory, not live offers.',
                            size: 12, color: colors.onSurfaceVariant)
                      ]))),
        ])));
  }
}

class CheckpointDetails extends StatelessWidget {
  const CheckpointDetails({super.key, this.offer = checkpointBill});
  static const checkpointBill = ConceptOffer(
      id: 'bill',
      merchant: 'Ceylon Dining · Colombo 03',
      title: 'Weekend dining offer',
      benefit: '25% off your food bill',
      image: 'assets/discover/stitch-1.jpg',
      bank: 'Sample Bank · Selected credit cards',
      conditions: ['Minimum spend LKR 3,000', 'Maximum discount LKR 1,000']);
  final ConceptOffer offer;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
        backgroundColor: colors.surfaceContainerLow,
        appBar: AppBar(
            title: const Text('Offer details'),
            leading: IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: Navigator.of(context).canPop()
                    ? () => Navigator.pop(context)
                    : null),
            actions: [
              IconButton(
                  tooltip: 'Share unavailable in this prototype',
                  onPressed: null,
                  icon: Icon(Icons.ios_share, color: colors.onSurface))
            ]),
        bottomNavigationBar: SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: FilledButton.icon(
                    onPressed: () => previewMessage(context),
                    icon: const Icon(Icons.directions_outlined),
                    label: Text(offer.online
                        ? 'Open merchant website'
                        : 'Get directions')))),
        body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                          aspectRatio: 1.8,
                          child: Image.asset(offer.image,
                              fit: BoxFit.cover, excludeFromSemantics: true))),
                  const SizedBox(height: 16),
                  copy(context, 'DEMO · Design fixture',
                      size: 12, color: colors.onSurfaceVariant),
                  const SizedBox(height: 6),
                  copy(context, offer.merchant,
                      size: 15, color: colors.onSurfaceVariant),
                  const SizedBox(height: 6),
                  copy(context, offer.benefit,
                      size: 26, weight: FontWeight.w700, color: colors.primary),
                  const SizedBox(height: 6),
                  copy(context, offer.title, size: 18, weight: FontWeight.w600),
                  const SizedBox(height: 18),
                  _panel(context, 'Before you use this offer', [
                    if (offer.bank != null) offer.bank!,
                    ...offer.conditions,
                    offer.online ? 'Online · Merchant website' : 'Dine-in only',
                    offer.expiry
                  ]),
                  const SizedBox(height: 12),
                  if (offer.id == 'bill')
                    copy(context,
                        '25% is applied to an eligible food bill, not an individual item price. A qualifying LKR 3,000 food bill saves LKR 750; the discount is capped at LKR 1,000. Other charges are excluded in this fixture.',
                        size: 14),
                  const SizedBox(height: 22),
                  copy(context, 'Highlights',
                      size: 20, weight: FontWeight.w700),
                  const SizedBox(height: 8),
                  copy(context,
                      'Explore a local dining offer and check the conditions before visiting. Reservations are recommended in this fixture.'),
                  const SizedBox(height: 22),
                  copy(context, 'Full conditions',
                      size: 20, weight: FontWeight.w700),
                  const SizedBox(height: 8),
                  copy(context,
                      'One eligible card per bill. Cannot be combined with another promotion. Contact the merchant to confirm availability. These terms are design fixtures, not a real bank promotion.'),
                  const SizedBox(height: 22),
                  copy(context, 'Merchant information',
                      size: 20, weight: FontWeight.w700),
                  const SizedBox(height: 8),
                  copy(context,
                      'Colombo 03 · Approximate distance is measured from the selected browsing area. No location permission is used by this prototype.'),
                ])));
  }

  Widget _panel(BuildContext context, String title, List<String> facts) =>
      HybridConditionsPanel(title: title, facts: facts);
}
