import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';
import 'create_promotion_screen.dart';
import 'deal_detail_screen.dart';
import 'edit_merchant_screen.dart';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() =>
      _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  final ApiService _apiService = ApiService();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  String? _merchantId;
  String? _token;
  String? _merchantName;
  String? _userId;
  bool _isLoading = true;
  String _activeTab = 'active';

  Map<String, dynamic>? _merchantData;
  List<Promotion> _promotions = [];

  bool get _hasValidMerchantId =>
      _merchantId != null &&
      RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(_merchantId!);

  bool get _isDemoMerchantSession =>
      (_token?.startsWith('demo-') ?? false) ||
      (_merchantId?.startsWith('demo-') ?? false);

  bool get _hasProfileContent {
    final profile = (_merchantData?['profile'] ?? '').toString().trim();
    final contactInfo = (_merchantData?['contactInfo'] ?? '').toString().trim();
    return profile.isNotEmpty && contactInfo.isNotEmpty;
  }

  bool get _hasLocation {
    final location = _merchantData?['location'];
    return location is Map &&
        location['coordinates'] is List &&
        (location['coordinates'] as List).length == 2;
  }

  int get _activeCount => _promotions
      .where((promotion) => _isActiveLikeStatus(promotion.status))
      .length;

  int get _pendingCount => _promotions
      .where((promotion) => promotion.status == 'pending_approval')
      .length;

  int get _expiredCount => _promotions
      .where((promotion) => _isExpiredLikeStatus(promotion.status))
      .length;

  List<Promotion> get _filteredPromotions {
    final filtered = _promotions.where((promotion) {
      switch (_activeTab) {
        case 'active':
          return _isActiveLikeStatus(promotion.status);
        case 'expired':
          return _isExpiredLikeStatus(promotion.status);
        default:
          return true;
      }
    }).toList();

    filtered.sort((a, b) {
      final aDate = a.createdAt ?? a.startDate ?? DateTime(1970);
      final bDate = b.createdAt ?? b.startDate ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final prefs = await SharedPreferences.getInstance();
    _merchantId = prefs.getString('merchantId');
    _token = prefs.getString('userToken');
    _merchantName = prefs.getString('userBusinessName');
    _userId = prefs.getString('userId');

    if ((_merchantId == null || !_hasValidMerchantId) &&
        _userId != null &&
        _token != null &&
        !_isDemoMerchantSession) {
      try {
        final userProfile =
            await _apiService.fetchUserProfile(_userId!, _token!);
        final fetchedMerchantId = userProfile['merchantId'] as String?;
        if (fetchedMerchantId != null) {
          await prefs.setString('merchantId', fetchedMerchantId);
          _merchantId = fetchedMerchantId;
        }
      } catch (_) {}
    }

    if (_hasValidMerchantId) {
      try {
        final results = await Future.wait([
          _apiService.fetchMerchantById(_merchantId!),
          _apiService.fetchMerchantPromotions(_merchantId!),
        ]);
        _merchantData = results[0] as Map<String, dynamic>;
        _promotions = results[1] as List<Promotion>;
        final liveName = (_merchantData?['name'] ?? '').toString().trim();
        if (liveName.isNotEmpty) {
          _merchantName = liveName;
          await prefs.setString('userBusinessName', liveName);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load merchant dashboard: $e')),
          );
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeMerchantProfile() async {
    if (_merchantName == null ||
        _merchantName!.trim().isEmpty ||
        _token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business name and login are required.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await _apiService.initializeMerchantProfile(
        businessName: _merchantName!.trim(),
        token: _token!,
      );

      final refreshedToken = response['token'] as String?;
      final refreshedMerchantId = response['merchantId'] as String?;
      final refreshedBusinessName = response['businessName'] as String?;

      if (refreshedToken != null) {
        await prefs.setString('userToken', refreshedToken);
        _token = refreshedToken;
      }
      if (refreshedMerchantId != null) {
        await prefs.setString('merchantId', refreshedMerchantId);
        _merchantId = refreshedMerchantId;
      }
      if (refreshedBusinessName != null && refreshedBusinessName.isNotEmpty) {
        await prefs.setString('userBusinessName', refreshedBusinessName);
        _merchantName = refreshedBusinessName;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store profile initialized successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadDashboard();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize store profile: $e')),
        );
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openEditProfile() async {
    if (!_hasValidMerchantId) return;
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
      await _loadDashboard();
    }
  }

  Future<void> _openCreatePromotion() async {
    if (!_ensureValidMerchantSession()) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePromotionScreen(merchantId: _merchantId!),
      ),
    );
    if (result == true) {
      await _loadDashboard();
    }
  }

  Future<void> _openEditPromotion(Promotion promotion) async {
    if (!_ensureValidMerchantSession()) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePromotionScreen(
          merchantId: _merchantId!,
          existingPromotion: promotion,
        ),
      ),
    );
    if (result == true) {
      await _loadDashboard();
    }
  }

  Future<void> _deletePromotion(Promotion promotion) async {
    if (_token == null) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Promotion'),
            content: Text(
                'Delete "${promotion.title}"? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await _apiService.deletePromotion(promotion.id, _token!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Promotion deleted.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadDashboard();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete promotion: $e')),
        );
      }
    }
  }

  bool _ensureValidMerchantSession() {
    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please sign in again to manage promotions.')),
      );
      return false;
    }
    if (_isDemoMerchantSession) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Demo merchant accounts are read-only. Use a real merchant login to manage promotions.'),
        ),
      );
      return false;
    }
    if (!_hasValidMerchantId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Merchant profile is not linked correctly. Sign out and sign back in, then try again.'),
        ),
      );
      return false;
    }
    return true;
  }

  bool _isActiveLikeStatus(String? status) =>
      ['active', 'approved', 'pending_approval', 'scheduled'].contains(status);

  bool _isExpiredLikeStatus(String? status) =>
      ['expired', 'rejected', 'admin_paused'].contains(status);

  String _statusLabel(String? status) {
    if (status == null || status.isEmpty) return 'Unknown';
    return status
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  Color _statusColor(String? status) {
    if (_isActiveLikeStatus(status)) {
      return status == 'pending_approval' ? Colors.orange : Colors.green;
    }
    if (_isExpiredLikeStatus(status)) {
      return status == 'rejected' ? Colors.red : Colors.grey;
    }
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_merchantId == null ||
        (_merchantId != null &&
            !_hasValidMerchantId &&
            !_isDemoMerchantSession)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Merchant Dashboard')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 20),
                const Text(
                  'Merchant Profile Not Ready',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Initialize your store profile first so the mobile dashboard can match the web merchant flow.',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _initializeMerchantProfile,
                  icon: const Icon(Icons.store),
                  label: const Text('Initialize Store Profile'),
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
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 16),
            if (_isDemoMerchantSession)
              _buildBannerCard(
                context,
                icon: Icons.info_outline,
                color: Colors.orange,
                message:
                    'Demo merchant mode is read-only. Sign in with a real merchant account to create, edit, or delete promotions.',
              ),
            if (_isDemoMerchantSession) const SizedBox(height: 16),
            _buildStatsGrid(context),
            const SizedBox(height: 20),
            if (_promotions.isEmpty) ...[
              _buildOnboardingCard(context),
              const SizedBox(height: 20),
            ],
            _buildSectionHeader(context),
            const SizedBox(height: 12),
            _buildTabSelector(),
            const SizedBox(height: 16),
            if (_filteredPromotions.isEmpty)
              _buildEmptyState(context)
            else
              ..._filteredPromotions.map((promotion) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildPromotionCard(context, promotion),
                  )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePromotion,
        icon: const Icon(Icons.add),
        label: const Text('Add Promotion'),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFF43F5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child:
                    const Icon(Icons.storefront, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (_merchantData?['name'] ?? _merchantName ?? 'My Store')
                          .toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_activeCount active deals',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.84),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openEditProfile,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.35)),
                    backgroundColor: Colors.white.withOpacity(0.12),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profile'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openCreatePromotion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4F46E5),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Promotion'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child:
                  _buildStatCard('Total', '${_promotions.length}', Icons.sell),
            ),
            const SizedBox(width: 12),
            Expanded(
              child:
                  _buildStatCard('Active', '$_activeCount', Icons.check_circle),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child:
                  _buildStatCard('Pending', '$_pendingCount', Icons.schedule),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('Expired', '$_expiredCount', Icons.history),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.rocket_launch, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome! Let's set up your store",
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Follow the same merchant checklist used on the web dashboard.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildChecklistItem(
              label: 'Complete your store profile',
              done: _hasProfileContent,
              icon: Icons.person_outline,
              actionLabel: 'Set Up Profile',
              onTap: _openEditProfile,
            ),
            const SizedBox(height: 10),
            _buildChecklistItem(
              label: 'Add your location so customers can find nearby deals',
              done: _hasLocation,
              icon: Icons.location_on_outlined,
              actionLabel: 'Add Location',
              onTap: _openEditProfile,
            ),
            const SizedBox(height: 10),
            _buildChecklistItem(
              label: 'Create your first promotion',
              done: _promotions.isNotEmpty,
              icon: Icons.local_offer_outlined,
              actionLabel: 'Create Deal',
              onTap: _openCreatePromotion,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem({
    required String label,
    required bool done,
    required IconData icon,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: done ? Colors.green.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done ? Colors.green.withOpacity(0.2) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                done ? Colors.green.withOpacity(0.12) : Colors.grey.shade100,
            foregroundColor:
                done ? Colors.green : Theme.of(context).colorScheme.primary,
            child: Icon(done ? Icons.check : icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: done ? Colors.green.shade700 : null,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (!done)
            TextButton(
              onPressed: onTap,
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Promotions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        TextButton(
          onPressed: _loadDashboard,
          child: const Text('Refresh'),
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    const tabs = [
      ('active', 'Active'),
      ('expired', 'Expired'),
      ('all', 'All'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final selected = _activeTab == tab.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(tab.$2),
              selected: selected,
              onSelected: (_) => setState(() => _activeTab = tab.$1),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.local_offer_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _promotions.isEmpty
                  ? 'No promotions yet'
                  : 'No promotions in this view',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _promotions.isEmpty
                  ? 'Create your first promotion to start attracting customers.'
                  : 'Try a different filter or refresh the dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openCreatePromotion,
              icon: const Icon(Icons.add),
              label: const Text('Create Promotion'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionCard(BuildContext context, Promotion promotion) {
    final statusColor = _statusColor(promotion.status);
    final image = promotion.imageDataString;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DealDetailScreen(promotion: promotion),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey.shade200,
                      child: image != null && image.isNotEmpty
                          ? Image.network(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.local_offer),
                            )
                          : const Icon(Icons.local_offer),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promotion.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if ((promotion.discount ?? '').isNotEmpty)
                              _buildMiniPill(
                                promotion.discount!,
                                background: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                foreground:
                                    Theme.of(context).colorScheme.primary,
                              ),
                            if ((promotion.code ?? '').isNotEmpty)
                              _buildMiniPill(
                                promotion.code!,
                                background: Colors.grey.shade100,
                                foreground: Colors.grey.shade800,
                              ),
                            _buildMiniPill(
                              _statusLabel(promotion.status),
                              background: statusColor.withOpacity(0.12),
                              foreground: statusColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                promotion.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.category_outlined,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _statusLabel(promotion.category),
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.event_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${promotion.startDate != null ? _dateFormat.format(promotion.startDate!) : '—'} - ${promotion.endDate != null ? _dateFormat.format(promotion.endDate!) : '—'}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openEditPromotion(promotion),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deletePromotion(promotion),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
              if ((promotion.url ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  promotion.url!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPill(
    String label, {
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildBannerCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color.withOpacity(0.95)),
            ),
          ),
        ],
      ),
    );
  }
}
