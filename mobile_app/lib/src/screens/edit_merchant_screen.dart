import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:io';
import '../services/api_service.dart';

class EditMerchantScreen extends StatefulWidget {
  final String merchantId;
  final Map<String, dynamic>? merchantData;

  const EditMerchantScreen({
    super.key,
    required this.merchantId,
    this.merchantData,
  });

  @override
  State<EditMerchantScreen> createState() => _EditMerchantScreenState();
}

class _EditMerchantScreenState extends State<EditMerchantScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  late TabController _tabController;
  
  final _nameController = TextEditingController();
  final _profileController = TextEditingController();
  final _categoryController = TextEditingController();
  final _websiteController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _bannerUrlController = TextEditingController();
  
  // Social media controllers
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  final _tiktokController = TextEditingController();
  
  bool _isSubmitting = false;
  String? _token;
  String? _logoBase64;
  String? _bannerBase64;
  double? _latitude;
  double? _longitude;

  final List<String> _categories = [
    'Fashion', 'Electronics', 'Travel', 'Health', 'Entertainment',
    'Home', 'Pets', 'Food', 'Education', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadToken();
    _loadMerchantData();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('userToken');
  }

  void _loadMerchantData() {
    if (widget.merchantData != null) {
      _nameController.text = widget.merchantData!['name'] ?? '';
      _profileController.text = widget.merchantData!['profile'] ?? '';
      _categoryController.text = widget.merchantData!['category'] ?? '';
      _websiteController.text = widget.merchantData!['website'] ?? '';
      _contactInfoController.text = widget.merchantData!['contactInfo'] ?? '';
      _contactNumberController.text = widget.merchantData!['contactNumber'] ?? '';
      _addressController.text = widget.merchantData!['address'] ?? '';
      _logoUrlController.text = widget.merchantData!['logo'] ?? '';
      _bannerUrlController.text = widget.merchantData!['banner'] ?? '';
      
      // Load location
      final location = widget.merchantData!['location'] as Map<String, dynamic>?;
      if (location != null && location['coordinates'] != null) {
        final coords = location['coordinates'] as List;
        if (coords.length >= 2) {
          _longitude = coords[0].toDouble();
          _latitude = coords[1].toDouble();
        }
      }
      
      // Load social media
      final socialMedia = widget.merchantData!['socialMedia'] as Map<String, dynamic>?;
      if (socialMedia != null) {
        _facebookController.text = socialMedia['facebook'] ?? '';
        _instagramController.text = socialMedia['instagram'] ?? '';
        _twitterController.text = socialMedia['twitter'] ?? '';
        _tiktokController.text = socialMedia['tiktok'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _profileController.dispose();
    _categoryController.dispose();
    _websiteController.dispose();
    _contactInfoController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _logoUrlController.dispose();
    _bannerUrlController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _tiktokController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isLogo) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      setState(() {
        if (isLogo) {
          _logoBase64 = base64Image;
          _logoUrlController.text = base64Image;
        } else {
          _bannerBase64 = base64Image;
          _bannerUrlController.text = base64Image;
        }
      });
    }
  }

  Future<void> _submitChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication required. Please login again.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final merchantData = {
        'name': _nameController.text.trim(),
        'profile': _profileController.text.trim(),
        'category': _categoryController.text.trim(),
        'website': _websiteController.text.trim(),
        'contactInfo': _contactInfoController.text.trim(),
        'contactNumber': _contactNumberController.text.trim(),
        'address': _addressController.text.trim(),
        if (_logoUrlController.text.trim().isNotEmpty)
          'logo': _logoUrlController.text.trim(),
        if (_bannerUrlController.text.trim().isNotEmpty)
          'banner': _bannerUrlController.text.trim(),
        'socialMedia': {
          'facebook': _facebookController.text.trim(),
          'instagram': _instagramController.text.trim(),
          'twitter': _twitterController.text.trim(),
          'tiktok': _tiktokController.text.trim(),
        },
        if (_latitude != null && _longitude != null)
          'location': {
            'type': 'Point',
            'coordinates': [_longitude, _latitude],
          },
      };

      await _apiService.updateMerchant(widget.merchantId, merchantData, _token!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update store: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Store Profile'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.store), text: 'Basic Info'),
            Tab(icon: Icon(Icons.phone), text: 'Contact'),
            Tab(icon: Icon(Icons.share), text: 'Social'),
            Tab(icon: Icon(Icons.image), text: 'Branding'),
            Tab(icon: Icon(Icons.location_on), text: 'Location'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicInfoTab(),
            _buildContactTab(),
            _buildSocialTab(),
            _buildBrandingTab(),
            _buildLocationTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitChanges,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Business Name *',
              hintText: 'Your Store Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.store),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Business name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _categoryController.text.isEmpty ? null : _categoryController.text,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _categoryController.text = value ?? '');
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _profileController,
            decoration: const InputDecoration(
              labelText: 'Store Description',
              hintText: 'Tell customers about your store...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 4,
          ),
          Text(
            '${_profileController.text.length}/500 characters',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _websiteController,
            decoration: const InputDecoration(
              labelText: 'Website',
              hintText: 'https://yourstore.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.language),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _contactInfoController,
            decoration: const InputDecoration(
              labelText: 'Contact Email',
              hintText: 'contact@yourstore.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Contact email is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _contactNumberController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+1 (555) 000-0000',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Store Address',
              hintText: '123 Main Street, City, Country',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Address is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSocialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Social Media',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Connect your social media accounts',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          
          _buildSocialField(
            controller: _facebookController,
            label: 'Facebook',
            icon: Icons.facebook,
            color: const Color(0xFF1877f2),
            hint: 'your.page',
          ),
          const SizedBox(height: 16),
          
          _buildSocialField(
            controller: _instagramController,
            label: 'Instagram',
            icon: Icons.camera_alt,
            color: const Color(0xFFe1306c),
            hint: '@yourhandle',
          ),
          const SizedBox(height: 16),
          
          _buildSocialField(
            controller: _twitterController,
            label: 'Twitter / X',
            icon: Icons.alternate_email,
            color: const Color(0xFF1da1f2),
            hint: '@yourhandle',
          ),
          const SizedBox(height: 16),
          
          _buildSocialField(
            controller: _tiktokController,
            label: 'TikTok',
            icon: Icons.music_note,
            color: Colors.black,
            hint: '@yourhandle',
          ),
        ],
      ),
    );
  }

  Widget _buildSocialField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        suffixIcon: controller.text.isNotEmpty
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
      ),
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildBrandingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Branding',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your store logo and banner',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          
          // Logo Section
          Text(
            'Store Logo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    ),
                    image: _logoUrlController.text.isNotEmpty
                        ? DecorationImage(
                            image: _logoUrlController.text.startsWith('data:')
                                ? MemoryImage(base64Decode(_logoUrlController.text.split(',')[1]))
                                : NetworkImage(_logoUrlController.text) as ImageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _logoUrlController.text.isEmpty
                      ? const Icon(Icons.store, size: 40)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(true),
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload Logo'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PNG, JPG up to 5MB',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          TextFormField(
            controller: _logoUrlController,
            decoration: const InputDecoration(
              labelText: 'Or paste logo URL',
              hintText: 'https://...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
          
          // Banner Section
          Text(
            'Store Banner',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              image: _bannerUrlController.text.isNotEmpty
                  ? DecorationImage(
                      image: _bannerUrlController.text.startsWith('data:')
                          ? MemoryImage(base64Decode(_bannerUrlController.text.split(',')[1]))
                          : NetworkImage(_bannerUrlController.text) as ImageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.grey[200],
            ),
            child: Stack(
              children: [
                if (_bannerUrlController.text.isEmpty)
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 50, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No banner set'),
                      ],
                    ),
                  ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(false),
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          TextFormField(
            controller: _bannerUrlController,
            decoration: const InputDecoration(
              labelText: 'Or paste banner URL',
              hintText: 'https://...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Recommended: 1200×400px',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Store Location',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Set your store location so customers can find nearby deals',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          
          if (_latitude != null && _longitude != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location Set',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _latitude = null;
                        _longitude = null;
                      });
                    },
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No location set. Use current location or enter coordinates manually.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final permission = await Geolocator.checkPermission();
                if (permission == LocationPermission.denied) {
                  final requested = await Geolocator.requestPermission();
                  if (requested == LocationPermission.denied) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Location permission denied')),
                      );
                    }
                    return;
                  }
                }
                
                final position = await Geolocator.getCurrentPosition();
                setState(() {
                  _latitude = position.latitude;
                  _longitude = position.longitude;
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Location updated!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to get location: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.my_location),
            label: const Text('Use My Current Location'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 24),
          
          const Divider(),
          const SizedBox(height: 16),
          
          Text(
            'Or Enter Manually',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    hintText: '6.9271',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  initialValue: _latitude?.toString() ?? '',
                  onChanged: (value) {
                    final lat = double.tryParse(value);
                    if (lat != null) {
                      setState(() => _latitude = lat);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    hintText: '79.8612',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  initialValue: _longitude?.toString() ?? '',
                  onChanged: (value) {
                    final lng = double.tryParse(value);
                    if (lng != null) {
                      setState(() => _longitude = lng);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter coordinates in decimal degrees format',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
