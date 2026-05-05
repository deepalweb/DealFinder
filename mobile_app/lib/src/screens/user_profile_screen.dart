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
    _tabController = TabController(length: 5, vsync: this);
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
      // Save locally first
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
      final followingIds = await MerchantFollowingManager.getFollowingMerchants();
      if (followingIds.isEmpty) {
        setState(() {
          _followingMerchants = [];
          _loadingFollowing = false;
        });
        return;
      }
      
      final allMerchants = await ApiService().fetchMerchants();
      final following = allMerchants.where((merchant) => followingIds.contains(merchant['_id'] ?? merchant['id'])).toList();
      
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

  Future<void> _changePassword() async {
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

  Widget _buildProfileTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickProfilePicture,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage: _profilePicture != null 
                        ? MemoryImage(base64Decode(_profilePicture!.split(',')[1]))
                        : null,
                    child: _profilePicture == null
                        ? Icon(
                            _role == 'merchant' ? Icons.store : Icons.person,
                            size: 50,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
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
                        helperText: 'Email cannot be changed',
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
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Merchant Dashboard Button
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
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Store profile coming soon!')),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
  

  Widget _buildFollowingTab() {
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
                  Text('No merchants followed yet'),
                  Text('Start following merchants to see them here!'),
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
          
          return Card(
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => _unfollowMerchant(merchantId),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Merchant profile coming soon!')),
                      );
                    },
                  ),
                ],
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
            Tab(text: 'Following'),
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
                _buildFollowingTab(),
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
