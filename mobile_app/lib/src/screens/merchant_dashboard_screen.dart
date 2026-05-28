import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/promotion.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
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

  String _t(String en, String si, String ta) {
    final code = Localizations.localeOf(context).languageCode;
    if (code == 'si') return si;
    if (code == 'ta') return ta;
    return en;
  }

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
            SnackBar(
              content: Text(
                '${_t('Failed to load merchant dashboard', 'වෙළඳසැල් පුවරුව පූරණය කිරීමට නොහැකි විය', 'வணிகர் டாஷ்போர்டை ஏற்ற முடியவில்லை')}: $e',
              ),
            ),
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
        SnackBar(
          content: Text(
            _t(
              'Business name and login are required.',
              'ව්‍යාපාර නාමය සහ පිවිසුම් තොරතුරු අවශ්‍යයි.',
              'வணிகப் பெயரும் உள்நுழைவு தகவலும் அவசியம்.',
            ),
          ),
        ),
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
          SnackBar(
            content: Text(
              _t(
                'Store profile initialized successfully!',
                'වෙළඳසැල් පැතිකඩ සාර්ථකව සකස් කරන ලදී!',
                'கடை சுயவிவரம் வெற்றிகரமாக அமைக்கப்பட்டது!',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadDashboard();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_t('Failed to initialize store profile', 'වෙළඳසැල් පැතිකඩ ආරම්භ කිරීමට නොහැකි විය', 'கடை சுயவிவரத்தைத் தொடங்க முடியவில்லை')}: $e',
            ),
          ),
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
            title: Text(_t('Delete Promotion', 'ප්‍රවර්ධනය මකන්න', 'சலுகையை நீக்கு')),
            content: Text(
                '${_t('Delete', 'මකන්න', 'நீக்கு')} "${promotion.title}"? ${_t('This action cannot be undone.', 'මෙම ක්‍රියාව ආපසු හැරවිය නොහැක.', 'இந்த செயலை மீண்டும் மாற்ற முடியாது.')}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(_t('Cancel', 'අවලංගු කරන්න', 'ரத்து செய்')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(_t('Delete', 'මකන්න', 'நீக்கு')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await _apiService.deletePromotion(promotion.id, _token!);
      await CacheService.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'Promotion deleted.',
                'ප්‍රවර්ධනය මකා දමන ලදී.',
                'சலுகை நீக்கப்பட்டது.',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadDashboard();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_t('Failed to delete promotion', 'ප්‍රවර්ධනය මකා දැමීමට නොහැකි විය', 'சலுகையை நீக்க முடியவில்லை')}: $e',
            ),
          ),
        );
      }
    }
  }

  bool _ensureValidMerchantSession() {
    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Please sign in again to manage promotions.',
              'ප්‍රවර්ධන කළමනාකරණයට නැවත පිවිසෙන්න.',
              'சலுகைகளை நிர்வகிக்க மீண்டும் உள்நுழையவும்.',
            ),
          ),
        ),
      );
      return false;
    }
    if (_isDemoMerchantSession) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Demo merchant accounts are read-only. Use a real merchant login to manage promotions.',
              'ඩෙමෝ වෙළෙන්දාගේ ගිණුම් කියවීමට පමණි. ප්‍රවර්ධන කළමනාකරණයට සැබෑ වෙළෙන්දාගේ පිවිසුමක් භාවිතා කරන්න.',
              'டெமோ வணிகர் கணக்குகள் படிக்க மட்டும். சலுகைகளை நிர்வகிக்க உண்மையான வணிகர் உள்நுழைவை பயன்படுத்தவும்.',
            ),
          ),
        ),
      );
      return false;
    }
    if (!_hasValidMerchantId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Merchant profile is not linked correctly. Sign out and sign back in, then try again.',
              'වෙළෙන්දාගේ පැතිකඩ නිවැරදිව සම්බන්ධ වී නොමැත. පිටවී නැවත පිවිස උත්සාහ කරන්න.',
              'வணிகர் சுயவிவரம் சரியாக இணைக்கப்படவில்லை. வெளியேறி மீண்டும் உள்நுழைந்து முயற்சிக்கவும்.',
            ),
          ),
        ),
      );
      return false;
    }
    return true;
  }

  bool _isActiveLikeStatus(String? status) =>
      ['active', 'scheduled', 'approved', 'pending_approval'].contains(status);

  bool _isExpiredLikeStatus(String? status) =>
      ['expired', 'rejected', 'admin_paused'].contains(status);

  String _statusLabel(String? status) {
    if (status == null || status.isEmpty) {
      return _t('Unknown', 'නොදනී', 'தெரியாது');
    }
    if (status == 'approved' || status == 'pending_approval') {
      return _t('Active', 'සක්‍රීය', 'செயலில்');
    }
    if (status == 'expired') return _t('Expired', 'කල් ඉකුත් වූ', 'காலாவதியான');
    if (status == 'all') return _t('All', 'සියල්ල', 'அனைத்தும்');
    return status
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  Color _statusColor(String? status) {
    if (_isActiveLikeStatus(status)) {
      return Colors.green;
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
        appBar: AppBar(title: Text(_t('Merchant Dashboard', 'වෙළෙන්දාගේ පුවරුව', 'வணிகர் டாஷ்போர்ட்'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  _t('Merchant Profile Not Ready', 'වෙළෙන්දාගේ පැතිකඩ තවම සූදානම් නැහැ', 'வணிகர் சுயவிவரம் இன்னும் தயாராக இல்லை'),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _t(
                    'Initialize your store profile first so the mobile dashboard can match the web merchant flow.',
                    'ජංගම පුවරුව වෙබ් වෙළෙන්දාගේ ගමනට ගැලපෙන ලෙස ඔබගේ වෙළඳසැල් පැතිකඩ පළමුව සකසන්න.',
                    'மொபைல் டாஷ்போர்டு இணைய வணிகர் அனுபவத்துடன் பொருந்த உங்கள் கடை சுயவிவரத்தை முதலில் அமைக்கவும்.',
                  ),
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _initializeMerchantProfile,
                  icon: const Icon(Icons.store),
                  label: Text(_t('Initialize Store Profile', 'වෙළඳසැල් පැතිකඩ සකසන්න', 'கடை சுயவிவரத்தை அமைக்கவும்')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Merchant Dashboard', 'වෙළෙන්දාගේ පුවරුව', 'வணிகர் டாஷ்போர்ட்')),
        actions: [
          IconButton(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh),
            tooltip: _t('Refresh', 'නැවුම් කරන්න', 'புதுப்பிக்கவும்'),
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
                message: _t(
                  'Demo merchant mode is read-only. Sign in with a real merchant account to create, edit, or delete promotions.',
                  'ඩෙමෝ වෙළෙන්දාගේ මෝඩය කියවීමට පමණි. ප්‍රවර්ධන සෑදීමට, සංස්කරණයට, හෝ මකා දැමීමට සැබෑ වෙළෙන්දාගේ ගිණුමකින් පිවිසෙන්න.',
                  'டெமோ வணிகர் நிலை படிக்க மட்டும். சலுகைகளை உருவாக்க, திருத்த, அல்லது நீக்க உண்மையான வணிகர் கணக்கில் உள்நுழையவும்.',
                ),
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
        label: Text(_t('Add Promotion', 'ප්‍රවර්ධනය එක් කරන්න', 'சலுகையைச் சேர்')),
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
                  color: Colors.white.withValues(alpha: 0.18),
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
                      (_merchantData?['name'] ?? _merchantName ?? _t('My Store', 'මගේ වෙළඳසැල', 'என் கடை'))
                          .toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_activeCount ${_t('active deals', 'සක්‍රීය ඩීල්', 'செயலில் உள்ள சலுகைகள்')}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
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
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(_t('Edit Profile', 'පැතිකඩ සංස්කරණය', 'சுயவிவரத்தைத் திருத்து')),
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
                  label: Text(_t('Add Promotion', 'ප්‍රවර්ධනය එක් කරන්න', 'சலுகையைச் சேர்')),
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
                  _buildStatCard(_t('Total', 'එකතුව', 'மொத்தம்'), '${_promotions.length}', Icons.sell),
            ),
            const SizedBox(width: 12),
            Expanded(
              child:
                  _buildStatCard(_t('Active', 'සක්‍රීය', 'செயலில்'), '$_activeCount', Icons.check_circle),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(_t('Expired', 'කල් ඉකුත් වූ', 'காலாவதியான'), '$_expiredCount', Icons.history),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox.shrink()),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t("Welcome! Let's set up your store", 'සාදරයෙන් පිළිගනිමු! ඔබගේ වෙළඳසැල සකස් කරමු', 'வரவேற்கிறோம்! உங்கள் கடையை அமைப்போம்'),
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      SizedBox(height: 2),
                      Text(
                        _t(
                          'Follow the same merchant checklist used on the web dashboard.',
                          'වෙබ් පුවරුවේ භාවිතා කරන එම වෙළෙන්දාගේ පිරික්සුම් ලැයිස්තුව අනුගමනය කරන්න.',
                          'இணைய டாஷ்போர்டில் பயன்படுத்தும் அதே வணிகர் பட்டியலைப் பின்பற்றவும்.',
                        ),
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildChecklistItem(
              label: _t('Complete your store profile', 'ඔබගේ වෙළඳසැල් පැතිකඩ සම්පූර්ණ කරන්න', 'உங்கள் கடை சுயவிவரத்தை முடிக்கவும்'),
              done: _hasProfileContent,
              icon: Icons.person_outline,
              actionLabel: _t('Set Up Profile', 'පැතිකඩ සකසන්න', 'சுயவிவரத்தை அமைக்கவும்'),
              onTap: _openEditProfile,
            ),
            const SizedBox(height: 10),
            _buildChecklistItem(
              label: _t('Add your location so customers can find nearby deals', 'පාරිභෝගිකයින්ට අසල ඩීල් සොයාගැනීමට ඔබගේ ස්ථානය එක් කරන්න', 'அருகிலுள்ள சலுகைகளை வாடிக்கையாளர்கள் காண உங்கள் இருப்பிடத்தைச் சேர்க்கவும்'),
              done: _hasLocation,
              icon: Icons.location_on_outlined,
              actionLabel: _t('Add Location', 'ස්ථානය එක් කරන්න', 'இருப்பிடத்தைச் சேர்'),
              onTap: _openEditProfile,
            ),
            const SizedBox(height: 10),
            _buildChecklistItem(
              label: _t('Create your first promotion', 'ඔබගේ පළමු ප්‍රවර්ධනය සෑදිය', 'உங்கள் முதல் சலுகையை உருவாக்கவும்'),
              done: _promotions.isNotEmpty,
              icon: Icons.local_offer_outlined,
              actionLabel: _t('Create Deal', 'ඩීල් එකක් සෑදිය', 'சலுகையை உருவாக்கு'),
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
        color: done ? Colors.green.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              done ? Colors.green.withValues(alpha: 0.2) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: done
                ? Colors.green.withValues(alpha: 0.12)
                : Colors.grey.shade100,
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
            _t('Promotions', 'ප්‍රවර්ධන', 'சலுகைகள்'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        TextButton(
          onPressed: _loadDashboard,
          child: Text(_t('Refresh', 'නැවුම් කරන්න', 'புதுப்பிக்கவும்')),
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    const tabs = [
      ('active', 'active'),
      ('expired', 'expired'),
      ('all', 'all'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final selected = _activeTab == tab.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_statusLabel(tab.$2)),
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
                  ? _t('No promotions yet', 'තවම ප්‍රවර්ධන නැහැ', 'இன்னும் சலுகைகள் இல்லை')
                  : _t('No promotions in this view', 'මෙම දසුනේ ප්‍රවර්ධන නොමැත', 'இந்த காட்சியில் சலுகைகள் இல்லை'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _promotions.isEmpty
                  ? _t('Create your first promotion to start attracting customers.', 'පාරිභෝගිකයින් ආකර්ෂණය කිරීමට ඔබගේ පළමු ප්‍රවර්ධනය සෑදිය.', 'வாடிக்கையாளர்களை ஈர்க்க உங்கள் முதல் சலுகையை உருவாக்கவும்.')
                  : _t('Try a different filter or refresh the dashboard.', 'වෙනත් පෙරහනක් උත්සාහ කරන්න හෝ පුවරුව නැවත පූරණය කරන්න.', 'வேறு வடிகட்டியை முயற்சிக்கவும் அல்லது டாஷ்போர்டை புதுப்பிக்கவும்.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openCreatePromotion,
              icon: const Icon(Icons.add),
              label: Text(_t('Create Promotion', 'ප්‍රවර්ධනය සෑදිය', 'சலுகையை உருவாக்கு')),
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
                                    .withValues(alpha: 0.1),
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
                              background: statusColor.withValues(alpha: 0.12),
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
                      label: Text(_t('Edit', 'සංස්කරණය', 'திருத்து')),
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
                      label: Text(_t('Delete', 'මකන්න', 'நீக்கு')),
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color.withValues(alpha: 0.95)),
            ),
          ),
        ],
      ),
    );
  }
}
