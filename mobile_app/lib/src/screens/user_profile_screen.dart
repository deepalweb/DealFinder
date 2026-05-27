import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../services/api_service.dart';
import '../services/favorites_manager.dart';
import '../services/merchant_following_manager.dart';
import '../models/promotion.dart';
import '../widgets/deal_card.dart';
import 'deal_detail_screen.dart';
import 'login_screen.dart';
import 'merchant_profile_screen.dart';
import 'merchant_dashboard_screen.dart';
import 'notification_settings_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with TickerProviderStateMixin {
  String _name = 'Loading...';
  String _email = 'Loading...';
  String _role = 'Loading...';
  String? _businessName;
  String? _userId;
  String? _token;
  bool _isLoading = true;
  late TabController _tabController;
  late TabController _favoritesTabController;
  List<Promotion> _favoriteDeals = [];
  bool _loadingFavorites = false;
  String? _profilePicture;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _followingMerchants = [];
  bool _loadingFollowing = false;

  // Password change
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _roleController = TextEditingController();
  final _businessController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _favoritesTabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _favoritesTabController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _businessController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _name = prefs.getString('userName') ?? 'N/A';
    _email = prefs.getString('userEmail') ?? 'N/A';
    _role = prefs.getString('userRole') ?? 'user';
    _userId = prefs.getString('userId');
    _token = prefs.getString('userToken');
    _profilePicture = prefs.getString('userProfilePicture');
    _nameController.text = _name;
    _emailController.text = _email;
    _roleController.text = _role.capitalize();
    
    if (_role == 'merchant') {
      _businessName = prefs.getString('userBusinessName');
      _businessController.text = _businessName ?? '';
    }
    
    setState(() {
      _isLoading = false;
    });
    
    _loadFavorites();
    _loadFollowingMerchants();
  }

  Future<void> _pickProfilePicture() async {
    try {
      // Show dialog to choose between camera and gallery
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Choose Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      if (!mounted) return;
      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        if (!mounted) return;
        setState(() {
          _profilePicture = base64Image;
        });
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userProfilePicture', base64Image);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update picture: $e')),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Persist locally until a dedicated profile update endpoint is wired.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _nameController.text.trim());
      if (!mounted) return;

      setState(() {
        _name = _nameController.text.trim();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _loadFavorites() async {
    setState(() => _loadingFavorites = true);
    
    try {
      final favoriteIds = await FavoritesManager.getFavorites();
      if (favoriteIds.isEmpty) {
        setState(() {
          _favoriteDeals = [];
          _loadingFavorites = false;
        });
        return;
      }
      
      final allPromotions = await ApiService().fetchPromotions();
      final favorites = allPromotions.where((promo) => favoriteIds.contains(promo.id)).toList();
      
      setState(() {
        _favoriteDeals = favorites;
        _loadingFavorites = false;
      });
    } catch (e) {
      setState(() {
        _favoriteDeals = [];
        _loadingFavorites = false;
      });
    }
  }
  
  Future<void> _removeFavorite(String dealId) async {
    await FavoritesManager.removeFavorite(dealId);
    if (!mounted) return;
    setState(() {
      _favoriteDeals.removeWhere((deal) => deal.id == dealId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Removed from favorites')),
    );
  }
  
  Future<void> _loadFollowingMerchants() async {
    setState(() => _loadingFollowing = true);
    
    try {
      if (_userId == null || _userId!.isEmpty) {
        setState(() {
          _followingMerchants = [];
          _loadingFollowing = false;
        });
        return;
      }

      final following = await ApiService().fetchFollowingMerchants(_userId!);
      
      setState(() {
        _followingMerchants = following;
        _loadingFollowing = false;
      });
    } catch (e) {
      setState(() {
        _followingMerchants = [];
        _loadingFollowing = false;
      });
    }
  }
  
  Future<void> _unfollowMerchant(String merchantId) async {
    await MerchantFollowingManager.unfollowMerchant(merchantId);
    if (!mounted) return;
    setState(() {
      _followingMerchants.removeWhere((merchant) => (merchant['_id'] ?? merchant['id']) == merchantId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unfollowed merchant')),
    );
  }

  void _openMerchantProfile(String merchantId) {
    if (merchantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store details are unavailable right now.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MerchantProfileScreen(merchantId: merchantId),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (_userId == null || _token == null || _userId!.isEmpty || _token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again before changing password')),
      );
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }
    if (_newPasswordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }
    if (_currentPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your current password')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService().changePassword(
        userId: _userId!,
        token: _token!,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  ImageProvider? _profileImageProvider() {
    final raw = _profilePicture;
    if (raw == null || raw.isEmpty) return null;
    try {
      if (!raw.contains(',')) return null;
      return MemoryImage(base64Decode(raw.split(',')[1]));
    } catch (_) {
      return null;
    }
  }

  Widget _buildProfileHero() {
    final profileImage = _profileImageProvider();
    final followingCount = _followingMerchants.length;
    final favoriteCount = _favoriteDeals.length;
    final roleLabel = _role.capitalize();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F4C81),
            Color(0xFF2563EB),
            Color(0xFF5EA6FF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _pickProfilePicture,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      backgroundImage: profileImage,
                      child: profileImage == null
                          ? Icon(
                              _role == 'merchant' ? Icons.storefront_rounded : Icons.person_rounded,
                              size: 34,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 15,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildProfileBadge(Icons.badge_outlined, roleLabel),
                        if (_role == 'merchant' && (_businessName?.isNotEmpty ?? false))
                          _buildProfileBadge(Icons.business_outlined, _businessName!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeroStat('$favoriteCount', 'Saved deals'),
              _buildHeroStat('$followingCount', 'Following'),
              _buildHeroStat(_role == 'merchant' ? 'Merchant' : 'Account', 'Plan'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6EBF2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF14213D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 112 + bottomInset),
        child: Column(
          children: [
            _buildProfileHero(),
            const SizedBox(height: 16),
            _buildQuickActionCard(
              icon: Icons.favorite_outline_rounded,
              title: 'Saved Deals & Stores',
              subtitle: 'Review your favorites and followed stores in one place.',
              onTap: () => _tabController.animateTo(3),
            ),
            const SizedBox(height: 12),
            _buildQuickActionCard(
              icon: Icons.notifications_active_outlined,
              title: 'Notification Settings',
              subtitle: 'Control push alerts, categories, and quiet hours.',
              onTap: () => _tabController.animateTo(2),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF14213D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        helperText: 'Email cannot be changed from the app yet',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _roleController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        prefixIcon: const Icon(Icons.badge),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    if (_role == 'merchant' && _businessName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: TextField(
                          controller: _businessController,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: 'Business Name',
                            prefixIcon: const Icon(Icons.business),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Save Local Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_role == 'merchant')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MerchantDashboardScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.dashboard),
                  label: const Text('Merchant Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (_role == 'merchant')
              const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Logout'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Password',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Change Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              Text(
                'Manage push notifications, email alerts, categories, quiet hours, and device testing from the full notification settings screen.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.tune),
                  label: const Text('Open Notification Settings'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use that screen to enable push on this device and send test notifications.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFavoritesTab() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _favoritesTabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Deals'),
              Tab(text: 'Stores'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _favoritesTabController,
            children: [
              _buildFavoriteDealsView(),
              _buildFavoriteStoresView(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildFavoriteDealsView() {
    if (_loadingFavorites) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_favoriteDeals.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFavorites,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No favorite deals yet'),
                  Text('Start favoriting deals to see them here!'),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _favoriteDeals.length,
        itemBuilder: (context, index) {
          final deal = _favoriteDeals[index];
          return Dismissible(
            key: ValueKey(deal.id),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _removeFavorite(deal.id),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DealDetailScreen(promotion: deal),
                  ),
                );
              },
              child: DealCard(promotion: deal),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildFavoriteStoresView() {
    if (_loadingFollowing) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_followingMerchants.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFollowingMerchants,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No favorite stores yet'),
                  Text('Start following stores to see them here!'),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadFollowingMerchants,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _followingMerchants.length,
        itemBuilder: (context, index) {
          final merchant = _followingMerchants[index];
          final merchantId = merchant['_id'] ?? merchant['id'] ?? '';
          final merchantName = merchant['name'] ?? 'Unknown Merchant';
          final merchantLogo = merchant['logo'];
          
          return Dismissible(
            key: ValueKey(merchantId),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _unfollowMerchant(merchantId),
            child: Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: merchantLogo != null && merchantLogo.toString().isNotEmpty
                      ? NetworkImage(merchantLogo)
                      : null,
                  child: merchantLogo == null || merchantLogo.toString().isEmpty
                      ? const Icon(Icons.store)
                      : null,
                ),
                title: Text(merchantName),
                subtitle: Text(merchant['contactInfo'] ?? 'No contact info'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _openMerchantProfile(merchantId),
              ),
            ),
          );
        },
      ),
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('My Profile'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Security'),
            Tab(text: 'Notifications'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildSecurityTab(),
                _buildNotificationsTab(),
                _buildFavoritesTab(),
              ],
            ),
    );
  }
}

// Helper extension to capitalize strings
extension StringExtension on String {
    String capitalize() {
      if (isEmpty) return this;
      return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
    }
}
