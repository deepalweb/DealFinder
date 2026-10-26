import 'package:flutter/material.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import '../services/api_service.dart';
import 'merchant_profile_screen.dart';

class FollowedMerchantsScreen extends StatefulWidget {
  const FollowedMerchantsScreen({super.key, required this.userId});
  final String userId;
  @override
  State<FollowedMerchantsScreen> createState() =>
      _FollowedMerchantsScreenState();
}

class _FollowedMerchantsScreenState extends State<FollowedMerchantsScreen> {
  late Future<List<Map<String, dynamic>>> _future =
      ApiService().fetchFollowingMerchants(widget.userId);
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
        appBar: AppBar(title: Text(l10n.following)),
        body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child: TextButton(
                        onPressed: () => setState(() => _future = ApiService()
                            .fetchFollowingMerchants(widget.userId)),
                        child: Text(l10n.retry)));
              }
              final merchants = snapshot.data ?? [];
              if (merchants.isEmpty) return Center(child: Text(l10n.following));
              return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: merchants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final merchant = merchants[i],
                        id = (merchant['_id'] ?? merchant['id'])?.toString();
                    return Card(
                        child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: const Icon(Icons.storefront_outlined),
                            title: Text(merchant['name']?.toString() ?? ''),
                            subtitle: merchant['address'] == null
                                ? null
                                : Text(merchant['address'].toString()),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: id == null
                                ? null
                                : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => MerchantProfileScreen(
                                            merchantId: id)))));
                  });
            }));
  }
}
