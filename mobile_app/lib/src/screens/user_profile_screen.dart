import '../config/app_theme.dart';
import '../widgets/profile_section.dart';
import 'package:flutter/material.dart';
import 'package:deal_finder_mobile/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../services/api_service.dart';
import '../services/app_language_controller.dart';
import '../services/favorites_manager.dart';
import '../services/merchant_following_manager.dart';
import '../models/promotion.dart';
import '../widgets/deal_card.dart';
import 'deal_detail_screen.dart';
import '../services/auth_service.dart';
import 'merchant_profile_screen.dart';
import 'merchant_dashboard_screen.dart';
import 'notification_settings_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, this.api});
  final ApiService? api;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  String _name = 'Loading...';
  String _email = 'Loading...';
  String _role = 'Loading...';
  String? _businessName;
  String? _userId;
  String? _token;
  bool _isLoading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;
  ApiService get _api => widget.api ?? ApiService();
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
    _tabController.addListener(_sectionChanged);
    _loadUserData();
  }

  void _openSection(int index) => _tabController.animateTo(index,
      duration: AppMotion.duration(context, 220));

  void _sectionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_sectionChanged);
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

    if (_userId != null && _token != null) {
      _refreshUserProfileFromServer(_userId!, _token!);
    }

    _loadFavorites();
    _loadFollowingMerchants();
  }

  Future<void> _refreshUserProfileFromServer(
      String userId, String token) async {
    try {
      final profile = await _api.fetchUserProfile(userId, token);
      await _persistUserProfile(profile);
      if (!mounted) return;
      setState(() {
        _name = profile['name'] as String? ?? _name;
        _email = profile['email'] as String? ?? _email;
        _role = profile['role'] as String? ?? _role;
        _businessName = profile['businessName'] as String? ?? _businessName;
        _profilePicture =
            profile['profilePicture'] as String? ?? _profilePicture;
        if (_tabController.index != 4) _nameController.text = _name;
        _emailController.text = _email;
        _roleController.text = _role.capitalize();
        if (_role == 'merchant') {
          _businessController.text = _businessName ?? '';
        }
      });
    } catch (_) {}
  }

  Future<void> _persistUserProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    final name = profile['name'] as String?;
    final email = profile['email'] as String?;
    final role = profile['role'] as String?;
    final businessName = profile['businessName'] as String?;
    final profilePicture = profile['profilePicture'] as String?;

    if (name != null) await prefs.setString('userName', name);
    if (email != null) await prefs.setString('userEmail', email);
    if (role != null) await prefs.setString('userRole', role);
    if (businessName != null) {
      await prefs.setString('userBusinessName', businessName);
    }
    if (profilePicture != null) {
      await prefs.setString('userProfilePicture', profilePicture);
    }
  }

  Future<void> _pickProfilePicture() async {
    if (_uploadingPhoto) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      // Show dialog to choose between camera and gallery
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(l10n.chooseImageSource),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: Text(l10n.camera),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text(l10n.gallery),
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
        setState(() => _uploadingPhoto = true);

        if (_userId != null && _token != null) {
          final profile = await _api.updateUserProfile(
            _userId!,
            _token!,
            profilePicture: base64Image,
          );
          await _persistUserProfile(profile);
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userProfilePicture', base64Image);
        }
        if (!mounted) return;
        setState(() => _profilePicture = base64Image);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profilePictureUpdated)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.failedToUpdatePicture}: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.nameCannotBeEmpty)),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final name = _nameController.text.trim();
      final profile = _userId != null && _token != null
          ? await _api.updateUserProfile(
              _userId!,
              _token!,
              name: name,
              businessName:
                  _role == 'merchant' ? _businessController.text.trim() : null,
            )
          : {'name': name};
      await _persistUserProfile(profile);
      if (!mounted) return;

      setState(() {
        _name = profile['name'] as String? ?? name;
        _businessName = profile['businessName'] as String? ?? _businessName;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileUpdatedSuccessfully)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.failedToUpdateProfile}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _loadFavorites() async {
    setState(() => _loadingFavorites = true);

    try {
      final api = ApiService();
      final localRecords = await FavoritesManager.getFavoriteRecords();
      final localIds = localRecords.map((record) => record.id).toList();
      final snapshotFavorites = localRecords
          .map((record) => record.promotion)
          .whereType<Promotion>()
          .toList();
      final snapshotIds =
          snapshotFavorites.map((promotion) => promotion.id).toSet();
      final resolvedLocalFavorites = await api
          .resolveFavoritePromotionsByIds(
            localIds.where((id) => !snapshotIds.contains(id)),
          )
          .timeout(
            const Duration(seconds: 6),
            onTimeout: () => <Promotion>[],
          );
      final localFavorites = [
        ...snapshotFavorites,
        ...resolvedLocalFavorites,
      ];
      final remoteFavorites = <Promotion>[];

      if (_userId != null && _token != null) {
        try {
          remoteFavorites.addAll(
            await api.fetchFavorites(_userId!, _token!).timeout(
                  const Duration(seconds: 6),
                  onTimeout: () => <Promotion>[],
                ),
          );
        } catch (_) {}
      }

      final knownIds = localFavorites.map((promotion) => promotion.id).toSet();
      final favorites = <Promotion>[...localFavorites];
      for (final promotion in remoteFavorites) {
        if (knownIds.add(promotion.id)) {
          favorites.add(promotion);
        }
      }
      favorites
          .sort((a, b) => b.latestActivityAt.compareTo(a.latestActivityAt));

      for (final promotion in favorites) {
        await FavoritesManager.addFavoritePromotion(promotion);
      }

      if (!mounted) return;
      setState(() {
        _favoriteDeals = favorites;
        _loadingFavorites = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _favoriteDeals = [];
        _loadingFavorites = false;
      });
    }
  }

  Future<void> _removeFavorite(String dealId) async {
    if (_userId != null && _token != null) {
      try {
        await _api.removeFavorite(_userId!, dealId, _token!);
      } catch (_) {}
    }
    await FavoritesManager.removeFavorite(dealId);
    if (!mounted) return;
    setState(() {
      _favoriteDeals.removeWhere((deal) => deal.id == dealId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(AppLocalizations.of(context)!.removedFromFavorites)),
    );
  }

  Future<void> _loadFollowingMerchants() async {
    setState(() => _loadingFollowing = true);

    try {
      if (_userId == null || _userId!.isEmpty) {
        if (!mounted) return;
        setState(() {
          _followingMerchants = [];
          _loadingFollowing = false;
        });
        return;
      }

      final following = await _api.fetchFollowingMerchants(_userId!);

      if (!mounted) return;
      setState(() {
        _followingMerchants = following;
        _loadingFollowing = false;
      });
    } catch (e) {
      if (!mounted) return;
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
      _followingMerchants.removeWhere(
          (merchant) => (merchant['_id'] ?? merchant['id']) == merchantId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unfollowed merchant')),
    );
  }

  void _openMerchantProfile(String merchantId) {
    if (merchantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Store details are unavailable right now.')),
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
    if (_saving) return;
    if (_userId == null ||
        _token == null ||
        _userId!.isEmpty ||
        _token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please log in again before changing password')),
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
    setState(() => _saving = true);
    try {
      await _api.changePassword(
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
          const SnackBar(
              content: Text('Password changed successfully!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.signOut();
  }

  ImageProvider? _profileImageProvider() {
    final raw = _profilePicture;
    if (raw == null || raw.isEmpty) return null;
    try {
      if (raw.startsWith('https://') || raw.startsWith('http://')) {
        return NetworkImage(raw);
      }
      if (!raw.contains(',')) return null;
      return MemoryImage(base64Decode(raw.split(',')[1]));
    } catch (_) {
      return null;
    }
  }

  Widget _buildProfileHero() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outlineVariant)),
        child: Column(children: [
          Semantics(
              button: true,
              label: l10n.chooseImageSource,
              child: InkWell(
                  onTap: _uploadingPhoto ? null : _pickProfilePicture,
                  borderRadius: BorderRadius.circular(40),
                  child: Stack(children: [
                    CircleAvatar(
                        radius: 38,
                        backgroundImage: _profileImageProvider(),
                        backgroundColor: scheme.primaryContainer,
                        child: _profileImageProvider() == null
                            ? Icon(Icons.person_outline_rounded,
                                color: scheme.primary, size: 34)
                            : null),
                    Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                color: scheme.primary, shape: BoxShape.circle),
                            child: Icon(Icons.camera_alt_outlined,
                                size: 15, color: scheme.onPrimary))),
                  ]))),
          const SizedBox(height: 14),
          Text(_name,
              textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(_email,
              textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                    label: Text(
                        '${_loadingFavorites ? '…' : _favoriteDeals.length} ${l10n.savedTab}'),
                    avatar:
                        const Icon(Icons.favorite_border_rounded, size: 16)),
                Chip(
                    label: Text(
                        '${_loadingFollowing ? '…' : _followingMerchants.length} ${l10n.following}'),
                    avatar: const Icon(Icons.storefront_outlined, size: 16)),
              ]),
        ]));
  }

  Future<void> _chooseLanguage() async {
    final l10n = AppLocalizations.of(context)!;
    final code = await showDialog<String>(
        context: context,
        builder: (context) =>
            SimpleDialog(title: Text(l10n.selectLanguage), children: [
              for (final entry in {
                'en': l10n.languageEnglish,
                'si': l10n.languageSinhala,
                'ta': l10n.languageTamil
              }.entries)
                SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, entry.key),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(children: [
                          Expanded(child: Text(entry.value)),
                          if (appLanguageController.languageCode == entry.key)
                            const Icon(Icons.check),
                        ]))),
            ]));
    if (code != null) await appLanguageController.setLanguageCode(code);
    if (mounted) setState(() {});
  }

  Widget _buildProfileTab() {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
        onRefresh: _loadUserData,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildProfileHero(),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: () => _openSection(4),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.profileEditLabel)),
              if (_role == 'merchant') ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MerchantDashboardScreen())),
                    icon: const Icon(Icons.storefront),
                    label: Text(l10n.merchantDashboard)),
              ],
              ProfileSection(title: l10n.savedTab, children: [
                ProfileActionTile(
                    icon: Icons.bookmark_border,
                    title: l10n.savedDealsAndStores,
                    subtitle: l10n.savedDealsStoresSubtitle,
                    onTap: () => _openSection(3)),
                ProfileActionTile(
                    icon: Icons.storefront_outlined,
                    title: l10n.followingStores,
                    onTap: () {
                      _favoritesTabController.index = 1;
                      _openSection(3);
                    }),
              ]),
              ProfileSection(title: l10n.accountTab, children: [
                ProfileActionTile(
                    icon: Icons.notifications_none,
                    title: l10n.notificationSettingsTitle,
                    subtitle: l10n.notificationSettingsSubtitle,
                    onTap: () => _openSection(2)),
                ProfileActionTile(
                    icon: Icons.lock_outline,
                    title: l10n.securityTab,
                    subtitle: l10n.changePassword,
                    onTap: () => _openSection(1)),
                ProfileActionTile(
                    icon: Icons.language,
                    title: l10n.appLanguage,
                    subtitle: {
                      'en': l10n.languageEnglish,
                      'si': l10n.languageSinhala,
                      'ta': l10n.languageTamil
                    }[appLanguageController.languageCode],
                    onTap: _chooseLanguage),
              ]),
              const SizedBox(height: 24),
              TextButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.logout),
                  style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error)),
            ]));
  }

  Widget _buildAccountEditor() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.accountDetails,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text(context),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.fullName,
                    prefixIcon: const Icon(Icons.person),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    prefixIcon: const Icon(Icons.email),
                    helperText: l10n.emailCannotBeChangedYet,
                    filled: true,
                    fillColor: AppColors.canvas(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _roleController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: l10n.role,
                    prefixIcon: const Icon(Icons.badge),
                    filled: true,
                    fillColor: AppColors.canvas(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border(context)),
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
                        labelText: l10n.businessName,
                        prefixIcon: const Icon(Icons.business),
                        filled: true,
                        fillColor: AppColors.canvas(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: AppColors.border(context)),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(_saving
                        ? l10n.profileSavingLabel
                        : l10n.profileSaveLabel),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildSecurityTab() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.changePassword,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.profileCurrentPasswordLabel,
                  prefixIcon: const Icon(Icons.lock_outline),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.profileNewPasswordLabel,
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.profileConfirmPasswordLabel,
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border(context)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                      _saving ? l10n.profileSavingLabel : l10n.changePassword),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsTab() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.notifications,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.notificationsDescription,
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
                  label: Text(l10n.openNotificationSettings),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.notificationsHelp,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Container(
          color: AppColors.card(context),
          child: TabBar(
            controller: _favoritesTabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: [
              Tab(text: l10n.deals),
              Tab(text: l10n.stores),
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
    final l10n = AppLocalizations.of(context)!;
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.noFavoriteDealsYet),
                  Text(l10n.startFavoritingDeals),
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
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: 320,
                  child: DealCard(promotion: deal),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteStoresView() {
    final l10n = AppLocalizations.of(context)!;
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.store_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.noFavoriteStoresYet),
                  Text(l10n.startFollowingStores),
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
                  backgroundImage:
                      merchantLogo != null && merchantLogo.toString().isNotEmpty
                          ? NetworkImage(merchantLogo)
                          : null,
                  child: merchantLogo == null || merchantLogo.toString().isEmpty
                      ? const Icon(Icons.store)
                      : null,
                ),
                title: Text(merchantName),
                subtitle: Text(merchant['contactInfo'] ?? l10n.noContactInfo),
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
    final l10n = AppLocalizations.of(context)!;
    final titles = [
      l10n.accountTab,
      l10n.securityTab,
      l10n.notifications,
      l10n.savedDealsAndStores,
      l10n.accountDetails
    ];
    return PopScope(
      canPop: _tabController.index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _openSection(0);
      },
      child: Scaffold(
          appBar: AppBar(
              title: Text(titles[_tabController.index]),
              leading: _tabController.index == 0
                  ? null
                  : BackButton(onPressed: () => _openSection(0))),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                      _buildProfileTab(),
                      _buildSecurityTab(),
                      _buildNotificationsTab(),
                      _buildFavoritesTab(),
                      _buildAccountEditor()
                    ])),
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
