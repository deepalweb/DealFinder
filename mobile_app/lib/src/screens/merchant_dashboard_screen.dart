import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/promotion.dart';
import 'create_promotion_screen.dart';
import 'edit_merchant_screen.dart';
import 'deal_detail_screen.dart';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  final ApiService _apiService = ApiService();
  String? _merchantId;
  String? _token;
  String? _merchantName;
  bool _isLoading = true;
  List<Promotion> _myPromotions = [];
  Map<String, dynamic>? _merchantData;

  @override
  void initState() {
    super.initState();
    _loadMerchantData();
  }

  Future<void> _loadMerchantData() async {
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    _merchantId = prefs.getString('merchantId');
    _token = prefs.getString('userToken');
    _merchantName = prefs.getString('userBusinessName');
    final userId = prefs.getString('userId');
    
    print('🔍 Merchant Dashboard - Loading data:');
    print('   merchantId: $_merchantId');
    print('   token: ${_token != null ? "exists" : "null"}');
    print('   merchantName: $_merchantName');
    print('   userId: $userId');
    print('   All keys: ${prefs.getKeys()}');

    // If merchantId is null, try to fetch it from the backend
    if (_merchantId == null && userId != null && _token != null) {
      print('🔄 Fetching user profile to get merchantId...');
      try {
        final userProfile = await _apiService.fetchUserProfile(userId, _token!);
        final fetchedMerchantId = userProfile['merchantId'] as String?;
        if (fetchedMerchantId != null) {
          print('✅ Found merchantId in user profile: $fetchedMerchantId');
          await prefs.setString('merchantId', fetchedMerchantId);
          _merchantId = fetchedMerchantId;
        } else {
          print('❌ No merchantId in user profile');
        }
      } catch (e) {
        print('❌ Error fetching user profile: $e');
      }
    }

    if (_merchantId != null) {
      await _fetchMerchantDetails();
      await _fetchMyPromotions();
    } else {
      print('❌ No merchantId found in SharedPreferences or backend');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _fetchMerchantDetails() async {
    try {
      final data = await _apiService.fetchMerchantById(_merchantId!);
      setState(() => _merchantData = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load merchant details: $e')),
        );
      }
    }
  }

  Future<void> _fetchMyPromotions() async {
    try {
      final allPromotions = await _apiService.fetchPromotions();
      setState(() {
        _myPromotions = allPromotions
            .where((p) => p.merchantId == _merchantId)
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load promotions: $e')),
        );
      }
    }
  }

  Future<void> _refresh() async {
    await _loadMerchantData();
  }

  Future<void> _initializeMerchantProfile() async {
    if (_merchantName == null || _merchantName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business name is required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await _apiService.initializeMerchantProfile(
        businessName: _merchantName!,
        token: _token!,
      );

      // Save the new merchantId
      final merchantId = response['merchantId'] as String?;
      if (merchantId != null) {
        await prefs.setString('merchantId', merchantId);
        setState(() => _merchantId = merchantId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store profile initialized successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        await _loadMerchantData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_merchantId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Merchant Dashboard')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 24),
                const Text(
                  'Merchant Profile Not Set Up',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your account is registered as a merchant, but your store profile needs to be initialized.',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _initializeMerchantProfile();
                  },
                  icon: const Icon(Icons.store),
                  label: const Text('Initialize Store Profile'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Store',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditMerchantScreen(
                    merchantId: _merchantId!,
                    merchantData: _merchantData,
                  ),
                ),
              );
              if (result == true) {
                _refresh();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Info Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            child: Icon(
                              Icons.store,
                              size: 30,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _merchantName ?? 'My Store',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_merchantData != null && _merchantData!['contactInfo'] != null)
                                  Text(
                                    _merchantData!['contactInfo'],
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Active Deals',
                      '${_myPromotions.length}',
                      Icons.local_offer,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Total Views',
                      '0',
                      Icons.visibility,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreatePromotionScreen(merchantId: _merchantId!),
                          ),
                        );
                        if (result == true) {
                          _refresh();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Deal'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditMerchantScreen(
                              merchantId: _merchantId!,
                              merchantData: _merchantData,
                            ),
                          ),
                        );
                        if (result == true) {
                          _refresh();
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Store'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // My Promotions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Deals',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (_myPromotions.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('No deals yet'),
                          const SizedBox(height: 8),
                          const Text(
                            'Create your first deal to attract customers!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _myPromotions.length,
                  itemBuilder: (context, index) {
                    final promo = _myPromotions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.local_offer),
                        ),
                        title: Text(
                          promo.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          promo.discount ?? 'No discount',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DealDetailScreen(promotion: promo),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
