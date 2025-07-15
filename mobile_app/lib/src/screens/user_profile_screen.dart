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

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  String _name = 'Loading...';
  String _email = 'Loading...';
  String _role = 'Loading...';
  String? _businessName;
  String? _userId;
  String? _token;
  bool _isLoading = true;
  late TabController _tabController;
  List<Promotion> _favoriteDeals = [];
  bool _loadingFavorites = false;
  String? _profilePicture;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _followingMerchants = [];
  bool _loadingFollowing = false;
  
  // Notification preferences
  Map<String, bool> _notifications = {
    'email': true,
    'expiringDeals': true,
    'favoriteStores': true,
    'recommendations': true,
  };
  
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
    _loadUserData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
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
    
    // Load notification preferences
    _notifications = {
      'email': prefs.getBool('notif_email') ?? true,
      'expiringDeals': prefs.getBool('notif_expiring') ?? true,
      'favoriteStores': prefs.getBool('notif_favorites') ?? true,
      'recommendations': prefs.getBool('notif_recommendations') ?? true,
    };
    
    setState(() {
      _isLoading = false;
    });
    
    _loadFavorites();
    _loadFollowingMerchants();
  }

  Future<void> _pickProfilePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      
      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        
        setState(() {
          _profilePicture = base64Image;
        });
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userProfilePicture', base64Image);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } catch (e) {
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
      
      // Save notification preferences
      for (var entry in _notifications.entries) {
        await prefs.setBool('notif_${entry.key}', entry.value);
      }
      
      setState(() {
        _name = _nameController.text.trim();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
    
    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // In a real app, call API to change password
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change password: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        helperText: 'Email cannot be changed',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _roleController,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                    if (_role == 'merchant' && _businessName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: TextField(
                          controller: _businessController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Business Name',
                            prefixIcon: Icon(Icons.business),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _changePassword,
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
                'Notification Preferences',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Nearby Deals'),
                subtitle: const Text('Get notified when deals are available near you'),
                value: _notifications['nearbyDeals'] ?? true,
                onChanged: (value) {
                  setState(() {
                    _notifications['nearbyDeals'] = value;
                  });
                },
              ),
              ..._notifications.entries.map((entry) => SwitchListTile(
                title: Text(_formatNotificationTitle(entry.key)),
                subtitle: Text(_getNotificationDescription(entry.key)),
                value: entry.value,
                onChanged: (value) {
                  setState(() {
                    _notifications[entry.key] = value;
                  });
                },
              )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  child: const Text('Save Preferences'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFavoritesTab() {
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
  
  String _formatNotificationTitle(String key) {
    switch (key) {
      case 'email': return 'Email Notifications';
      case 'expiringDeals': return 'Expiring Deals';
      case 'favoriteStores': return 'Favorite Stores';
      case 'recommendations': return 'Recommendations';
      default: return key;
    }
  }
  
  String _getNotificationDescription(String key) {
    switch (key) {
      case 'email': return 'Receive notifications via email';
      case 'expiringDeals': return 'Get notified when deals are about to expire';
      case 'favoriteStores': return 'Updates from your favorite stores';
      case 'recommendations': return 'Personalized deal recommendations';
      default: return '';
    }
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
        title: const Text('Profile'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profile'),
            Tab(icon: Icon(Icons.lock), text: 'Security'),
            Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
            Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
            Tab(icon: Icon(Icons.store), text: 'Following'),
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
