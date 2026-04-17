import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
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
  Map<String, dynamic> _analytics = {
    'totalViews': 0,
    'totalClicks': 0,
    'totalSaves': 0,
    'followers': 0,
  };

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
      _calculateAnalytics();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load promotions: $e')),
        );
      }
    }
  }

  void _calculateAnalytics() {
    int totalViews = 0;
    int totalClicks = 0;
    int totalSaves = 0;
    
    for (var promo in _myPromotions) {
      // Mock data - in production, fetch from backend
      totalViews += (promo.id.hashCode % 1000).abs();
      totalClicks += (promo.id.hashCode % 500).abs();
      totalSaves += (promo.id.hashCode % 100).abs();
    }
    
    setState(() {
      _analytics = {
        'totalViews': totalViews,
        'totalClicks': totalClicks,
        'totalSaves': totalSaves,
        'followers': _merchantData?['followers'] ?? 0,
      };
    });
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

  void _showQRCode(Promotion promo) {
    final dealUrl = 'https://dealfinder-h0hnh3emahabaahw.southindia-01.azurewebsites.net/deal/${promo.id}';
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'QR Code',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                promo.title,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: QrImageView(
                  data: dealUrl,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Scan to view deal',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Share.share('Check out this deal: ${promo.title}\n$dealUrl');
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _duplicateDeal(Promotion promo) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePromotionScreen(
          merchantId: _merchantId!,
          duplicateFrom: promo,
        ),
      ),
    );
    if (result == true) {
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deal duplicated! Edit and save to create.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showDealOptions(Promotion promo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Generate QR Code'),
              onTap: () {
                Navigator.pop(context);
                _showQRCode(promo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate Deal'),
              onTap: () {
                Navigator.pop(context);
                _duplicateDeal(promo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Deal'),
              onTap: () {
                Navigator.pop(context);
                final dealUrl = 'https://dealfinder-h0hnh3emahabaahw.southindia-01.azurewebsites.net/deal/${promo.id}';
                Share.share('Check out this deal: ${promo.title}\n$dealUrl');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('View Analytics'),
              onTap: () {
                Navigator.pop(context);
                _showDealAnalytics(promo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Deal'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DealDetailScreen(promotion: promo),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDealAnalytics(Promotion promo) {
    // Mock analytics data
    final views = (promo.id.hashCode % 1000).abs();
    final clicks = (promo.id.hashCode % 500).abs();
    final saves = (promo.id.hashCode % 100).abs();
    final ctr = clicks > 0 ? (clicks / views * 100).toStringAsFixed(1) : '0.0';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(promo.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalyticRow(Icons.visibility, 'Views', '$views'),
            const SizedBox(height: 12),
            _buildAnalyticRow(Icons.touch_app, 'Clicks', '$clicks'),
            const SizedBox(height: 12),
            _buildAnalyticRow(Icons.favorite, 'Saves', '$saves'),
            const SizedBox(height: 12),
            _buildAnalyticRow(Icons.trending_up, 'CTR', '$ctr%'),
            const Divider(height: 24),
            Text(
              'Note: Analytics data is simulated for demo purposes.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
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
                      '${_analytics['totalViews']}',
                      Icons.visibility,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Clicks',
                      '${_analytics['totalClicks']}',
                      Icons.touch_app,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Saves',
                      '${_analytics['totalSaves']}',
                      Icons.favorite,
                      Colors.red,
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promo.discount ?? 'No discount',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${(promo.id.hashCode % 1000).abs()} views',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showDealOptions(promo),
                        ),
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
