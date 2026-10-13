import 'package:flutter/material.dart';
import '../models/promotion.dart';
import '../widgets/app_empty_state.dart';
import '../services/image_helper.dart';
import '../services/deal_comparison_service.dart';
import 'deal_detail_screen.dart';

class DealComparisonScreen extends StatefulWidget {
  const DealComparisonScreen({super.key});

  @override
  State<DealComparisonScreen> createState() => _DealComparisonScreenState();
}

class _DealComparisonScreenState extends State<DealComparisonScreen> {
  List<Promotion> _comparisonDeals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComparisonDeals();
  }

  Future<void> _loadComparisonDeals() async {
    final deals = await DealComparisonService.getComparisonDeals();
    if (!mounted) return;
    setState(() {
      _comparisonDeals = deals;
      _isLoading = false;
    });
  }

  Future<void> _removeFromComparison(String dealId) async {
    await DealComparisonService.removeFromComparison(dealId);
    _loadComparisonDeals();
  }

  String _price(Promotion deal) {
    final amount = deal.discountedPrice ?? deal.price ?? deal.originalPrice;
    return amount == null
        ? 'Unavailable'
        : '${deal.merchantCurrency ?? 'LKR'} ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
        appBar: AppBar(title: const Text('Compare deals'), actions: [
          IconButton(
              tooltip: 'Clear comparison',
              icon: const Icon(Icons.clear_all_rounded),
              onPressed: _comparisonDeals.isEmpty
                  ? null
                  : () async {
                      await DealComparisonService.clearComparison();
                      _loadComparisonDeals();
                    }),
        ]),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _comparisonDeals.isEmpty
                ? const AppEmptyState(
                    icon: Icons.compare_arrows_rounded,
                    title: 'Find your best option',
                    message:
                        'Add deals from their detail pages to compare prices and discounts here.')
                : ListView(padding: const EdgeInsets.all(20), children: [
                    Text('A closer look', style: theme.textTheme.displayMedium),
                    const SizedBox(height: 8),
                    Text(
                        'Compare ${_comparisonDeals.length} saved options side by side.',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 18),
                    Card(child: _buildComparisonTable()),
                    const SizedBox(height: 20),
                    for (final deal in _comparisonDeals)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                              child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => DealDetailScreen(
                                              promotion: deal))),
                                  child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                child:
                                                    ImageHelper.buildThumbnail(
                                                        deal.imageDataString,
                                                        size: 64)),
                                            const SizedBox(width: 14),
                                            Expanded(
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                  Text(deal.title,
                                                      style: theme.textTheme
                                                          .titleMedium),
                                                  const SizedBox(height: 6),
                                                  Text(_price(deal),
                                                      style: theme
                                                          .textTheme.bodyMedium
                                                          ?.copyWith(
                                                              color: theme
                                                                  .colorScheme
                                                                  .primary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600)),
                                                ])),
                                            IconButton(
                                                tooltip:
                                                    'Remove from comparison',
                                                icon: const Icon(
                                                    Icons.close_rounded),
                                                onPressed: () =>
                                                    _removeFromComparison(
                                                        deal.id)),
                                          ]))))),
                  ]));
  }

  Widget _buildComparisonTable() {
    if (_comparisonDeals.length < 2) {
      return const Padding(
          padding: EdgeInsets.all(20),
          child: Text('Add another deal to compare.'));
    }
    final fields = <String, String Function(Promotion)>{
      'Title': (p) => p.title,
      'Price': _price,
      'Discount': (p) => p.discount ?? 'Unavailable',
      'Store': (p) => p.merchantName ?? 'Unavailable',
      'Expires': (p) =>
          p.endDate?.toIso8601String().split('T').first ?? 'Unavailable',
    };
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
            dataRowMinHeight: 60,
            dataRowMaxHeight:
                140 * MediaQuery.textScalerOf(context).scale(16) / 16,
            columns: [
              const DataColumn(label: Text('Feature')),
              for (var i = 0; i < _comparisonDeals.length; i++)
                DataColumn(label: Text('Deal ${i + 1}'))
            ],
            rows: fields.entries
                .map((field) => DataRow(cells: [
                      DataCell(Text(field.key)),
                      for (final deal in _comparisonDeals)
                        DataCell(SizedBox(
                            width: 180,
                            child: Text(field.value(deal),
                                maxLines: 4, overflow: TextOverflow.ellipsis))),
                    ]))
                .toList()));
  }
}
