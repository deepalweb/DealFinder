import 'package:flutter/material.dart';
import '../models/promotion.dart';
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
    setState(() {
      _comparisonDeals = deals;
      _isLoading = false;
    });
  }

  Future<void> _removeFromComparison(String dealId) async {
    await DealComparisonService.removeFromComparison(dealId);
    _loadComparisonDeals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Deals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () async {
              await DealComparisonService.clearComparison();
              _loadComparisonDeals();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _comparisonDeals.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.compare_arrows, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No deals to compare'),
                      Text('Add deals to comparison from deal details'),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Comparison table
                      Card(
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Comparison',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              _buildComparisonTable(),
                            ],
                          ),
                        ),
                      ),
                      
                      // Individual deal cards
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _comparisonDeals.length,
                        itemBuilder: (context, index) {
                          final deal = _comparisonDeals[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(deal.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(deal.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (deal.discountedPrice != null)
                                        Text(
                                          'Rs.${deal.discountedPrice!.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                        ),
                                      if (deal.originalPrice != null)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8),
                                          child: Text(
                                            'Rs.${deal.originalPrice!.toStringAsFixed(2)}',
                                            style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
                                          ),
                                        ),
                                      if (deal.discount != null)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red[100],
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              deal.discount!,
                                              style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DealDetailScreen(promotion: deal),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () => _removeFromComparison(deal.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildComparisonTable() {
    if (_comparisonDeals.length < 2) {
      return const Text('Add at least 2 deals to compare');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Feature')),
          DataColumn(label: Text('Deal 1')),
          DataColumn(label: Text('Deal 2')),
        ],
        rows: [
          DataRow(cells: [
            const DataCell(Text('Title')),
            DataCell(Text(_comparisonDeals[0].title, style: const TextStyle(fontSize: 12))),
            DataCell(Text(_comparisonDeals[1].title, style: const TextStyle(fontSize: 12))),
          ]),
          DataRow(cells: [
            const DataCell(Text('Price')),
            DataCell(Text('Rs.${(_comparisonDeals[0].discountedPrice ?? _comparisonDeals[0].price ?? 0).toStringAsFixed(2)}')),
            DataCell(Text('Rs.${(_comparisonDeals[1].discountedPrice ?? _comparisonDeals[1].price ?? 0).toStringAsFixed(2)}')),
          ]),
          DataRow(cells: [
            const DataCell(Text('Discount')),
            DataCell(Text(_comparisonDeals[0].discount ?? 'N/A')),
            DataCell(Text(_comparisonDeals[1].discount ?? 'N/A')),
          ]),
          DataRow(cells: [
            const DataCell(Text('Merchant')),
            DataCell(Text(_comparisonDeals[0].merchantName ?? 'N/A', style: const TextStyle(fontSize: 12))),
            DataCell(Text(_comparisonDeals[1].merchantName ?? 'N/A', style: const TextStyle(fontSize: 12))),
          ]),
          if (_comparisonDeals[0].endDate != null || _comparisonDeals[1].endDate != null)
            DataRow(cells: [
              const DataCell(Text('Expires')),
              DataCell(Text(_comparisonDeals[0].endDate?.toString().split(' ')[0] ?? 'N/A', style: const TextStyle(fontSize: 12))),
              DataCell(Text(_comparisonDeals[1].endDate?.toString().split(' ')[0] ?? 'N/A', style: const TextStyle(fontSize: 12))),
            ]),
        ],
      ),
    );
  }
}