import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/image_helper.dart';
import '../models/promotion.dart';

const List<String> _merchantCategories = [
  'fashion',
  'electronics',
  'travel',
  'health',
  'entertainment',
  'home',
  'pets',
  'food',
  'education',
];

class CreatePromotionScreen extends StatefulWidget {
  final String merchantId;
  final Promotion? duplicateFrom;
  final Promotion? existingPromotion;

  const CreatePromotionScreen({
    super.key,
    required this.merchantId,
    this.duplicateFrom,
    this.existingPromotion,
  });

  @override
  State<CreatePromotionScreen> createState() => _CreatePromotionScreenState();
}

class _CreatePromotionScreenState extends State<CreatePromotionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  late TabController _tabController;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _codeController = TextEditingController();
  final _urlController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _percentageOffController = TextEditingController();

  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _featured = false;
  bool _isSubmitting = false;
  String? _token;
  String _dealType = 'percentage';
  final List<File> _imageFiles = [];
  List<String> _uploadedImageUrls = [];

  bool get _hasValidMerchantId =>
      RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(widget.merchantId);

  bool get _isDemoMerchantSession =>
      (_token?.startsWith('demo-') ?? false) ||
      widget.merchantId.startsWith('demo-');

  bool get _isEditing => widget.existingPromotion != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadToken();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 30));

    if (_isEditing) {
      _loadPromotionData(widget.existingPromotion!, isDuplicate: false);
    } else if (widget.duplicateFrom != null) {
      _loadPromotionData(widget.duplicateFrom!, isDuplicate: true);
    }

    _percentageOffController.addListener(_calculateDiscountedPrice);
    _originalPriceController.addListener(_calculateDiscountedPrice);
  }

  void _loadPromotionData(Promotion promo, {required bool isDuplicate}) {
    _titleController.text = isDuplicate ? '${promo.title} (Copy)' : promo.title;
    _descriptionController.text = promo.description;
    _discountController.text = promo.discount ?? '';
    _codeController.text = promo.code ?? '';
    _urlController.text = promo.url ?? '';
    _selectedCategory = promo.category;
    _featured = promo.featured ?? false;
    _startDate = isDuplicate ? DateTime.now() : (promo.startDate ?? _startDate);
    _endDate = isDuplicate
        ? DateTime.now().add(const Duration(days: 30))
        : (promo.endDate ?? _endDate);

    if (promo.originalPrice != null) {
      _originalPriceController.text = promo.originalPrice.toString();
    }
    if (promo.discountedPrice != null) {
      _discountedPriceController.text = promo.discountedPrice.toString();
    }
    if (promo.price != null && promo.originalPrice == null) {
      _originalPriceController.text = promo.price.toString();
    }
  }

  void _calculateDiscountedPrice() {
    if (_dealType == 'percentage' &&
        _originalPriceController.text.isNotEmpty &&
        _percentageOffController.text.isNotEmpty) {
      try {
        final original = double.parse(_originalPriceController.text);
        final percent = double.parse(_percentageOffController.text);
        if (percent > 0 && percent <= 100) {
          final discounted = original * (1 - percent / 100);
          _discountedPriceController.text = discounted.toStringAsFixed(2);
          _discountController.text = '$percent%';
        }
      } catch (e) {
        // Invalid input
      }
    }
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('userToken');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _codeController.dispose();
    _urlController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    _percentageOffController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_imageFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed')),
      );
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage();
    for (var image in images) {
      if (_imageFiles.length >= 5) break;
      setState(() {
        _imageFiles.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  void _generateCode() {
    final words = _titleController.text.split(' ');
    final code =
        words.map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join('');
    final random = (10 + (90 * (DateTime.now().millisecond / 1000))).toInt();
    _codeController.text = '${code.isEmpty ? "DEAL" : code}$random';
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitPromotion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_hasValidMerchantId || _isDemoMerchantSession) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isDemoMerchantSession
                ? 'Demo merchant accounts cannot create live promotions.'
                : 'Merchant profile is invalid. Please sign out and sign back in.',
          ),
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      _tabController.animateTo(0);
      return;
    }

    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Authentication required. Please login again.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload images to Azure first
      if (_imageFiles.isNotEmpty) {
        final compressedFiles = <File>[];
        for (final file in _imageFiles) {
          final compressed = await ImageHelper.compressImageFile(
            file.path,
            quality: 70,
            maxWidth: 1024,
          );
          compressedFiles.add(compressed ?? file);
        }

        _uploadedImageUrls = await _apiService.uploadMultipleImages(
          compressedFiles,
          _token!,
          folder: 'promotions',
        );
      }

      final promotionData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'discount': _discountController.text.trim(),
        'code': _codeController.text.trim(),
        'category': _selectedCategory,
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'merchantId': widget.merchantId,
        'featured': _featured,
        if (_urlController.text.trim().isNotEmpty)
          'url': _urlController.text.trim(),
        if (_originalPriceController.text.isNotEmpty)
          'originalPrice': double.parse(_originalPriceController.text),
        if (_discountedPriceController.text.isNotEmpty)
          'discountedPrice': double.parse(_discountedPriceController.text),
        if (_uploadedImageUrls.isNotEmpty) 'image': _uploadedImageUrls.first,
        if (_uploadedImageUrls.isNotEmpty) 'images': _uploadedImageUrls,
      };

      if (_isEditing) {
        await _apiService.updatePromotion(
          widget.existingPromotion!.id,
          promotionData,
          _token!,
        );
      } else {
        await _apiService.createPromotion(promotionData, _token!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Promotion updated successfully!'
                  : 'Promotion created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Failed to update promotion: $e'
                  : 'Failed to create promotion: $e',
            ),
          ),
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
    final daysLeft = _endDate != null && _startDate != null
        ? _endDate!.difference(_startDate!).inDays
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? 'Edit Promotion'
            : widget.duplicateFrom != null
                ? 'Duplicate Deal'
                : 'Create New Deal'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Details'),
            Tab(icon: Icon(Icons.image_outlined), text: 'Media'),
            Tab(icon: Icon(Icons.settings_outlined), text: 'Settings'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDetailsTab(),
            _buildMediaTab(),
            _buildSettingsTab(daysLeft),
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
                  onPressed: _isSubmitting ? null : _submitPromotion,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEditing ? 'Update Promotion' : 'Create Deal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title *',
              hintText: 'e.g., Summer Sale — 20% Off Everything',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Title is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description *',
              hintText: 'Describe your deal...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Description is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _dealType,
            decoration: const InputDecoration(
              labelText: 'Deal Type *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.local_offer),
            ),
            items: const [
              DropdownMenuItem(
                  value: 'percentage', child: Text('Percentage Discount')),
              DropdownMenuItem(value: 'bogo', child: Text('Buy 1 Get 1 Free')),
              DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount Off')),
              DropdownMenuItem(value: 'price_drop', child: Text('Price Drop')),
              DropdownMenuItem(value: 'bundle', child: Text('Bundle Deal')),
              DropdownMenuItem(value: 'flash', child: Text('Flash Sale')),
            ],
            onChanged: (value) {
              setState(() {
                _dealType = value!;
                _discountController.clear();
                _originalPriceController.clear();
                _discountedPriceController.clear();
                _percentageOffController.clear();
              });
            },
          ),
          const SizedBox(height: 16),
          if (_dealType == 'percentage') ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _originalPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Original Price *',
                      hintText: '100.00',
                      border: OutlineInputBorder(),
                      prefixText: 'Rs. ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _percentageOffController,
                    decoration: const InputDecoration(
                      labelText: 'Discount % *',
                      hintText: '20',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final num = double.tryParse(value);
                      if (num == null || num <= 0 || num > 100) {
                        return '1-100';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _discountedPriceController,
              decoration: const InputDecoration(
                labelText: 'Final Price',
                hintText: 'Auto-calculated',
                border: OutlineInputBorder(),
                prefixText: 'Rs. ',
                enabled: false,
              ),
              readOnly: true,
            ),
          ],
          if (_dealType == 'bogo') ...[
            TextFormField(
              controller: _originalPriceController,
              decoration: const InputDecoration(
                labelText: 'Product Price *',
                hintText: '50.00',
                border: OutlineInputBorder(),
                prefixText: 'Rs. ',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _discountController.text = 'Buy 1 Get 1 Free';
              },
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                return null;
              },
            ),
          ],
          if (_dealType == 'price_drop') ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _originalPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Was *',
                      hintText: '100.00',
                      border: OutlineInputBorder(),
                      prefixText: 'Rs. ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _discountedPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Now *',
                      hintText: '70.00',
                      border: OutlineInputBorder(),
                      prefixText: 'Rs. ',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      if (_originalPriceController.text.isNotEmpty &&
                          value.isNotEmpty) {
                        final original =
                            double.tryParse(_originalPriceController.text);
                        final now = double.tryParse(value);
                        if (original != null &&
                            original > 0 &&
                            now != null &&
                            now < original) {
                          final percent = ((original - now) / original * 100)
                              .toStringAsFixed(0);
                          _discountController.text = '$percent%';
                        }
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
          if (_dealType == 'bundle' ||
              _dealType == 'flash' ||
              _dealType == 'fixed') ...[
            TextFormField(
              controller: _discountController,
              decoration: InputDecoration(
                labelText: 'Discount *',
                hintText: _dealType == 'bundle' ? '3 for Rs.99' : '50% off',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                return null;
              },
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Promo Code *',
                    hintText: 'SAVE20',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.auto_awesome),
                      onPressed: _generateCode,
                      tooltip: 'Generate',
                    ),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Code is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: _merchantCategories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(_formatCategoryLabel(category)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedCategory = value);
            },
            validator: (value) {
              if (value == null) return 'Category is required';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Deal URL',
              hintText: 'https://...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start Date'),
                  subtitle: Text(_startDate != null
                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                      : 'Not set'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, true),
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End Date'),
                  subtitle: Text(_endDate != null
                      ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                      : 'Not set'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Promotion Images',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Upload up to 5 images (max 5MB each)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          if (_imageFiles.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _imageFiles.length + (_imageFiles.length < 5 ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _imageFiles.length) {
                  return GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 40),
                          SizedBox(height: 4),
                          Text('Add', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }

                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: index == 0
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          width: index == 0 ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _imageFiles[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'MAIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            )
          else
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload, size: 60, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Click to upload images',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'PNG, JPG up to 5MB each · Max 5 images',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(int daysLeft) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('⭐ Featured Deal'),
            subtitle: const Text(
                'Featured deals appear on the homepage and get more visibility'),
            value: _featured,
            onChanged: (value) {
              setState(() => _featured = value);
            },
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Promotion Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Divider(),
                  _buildSummaryRow(
                      'Title',
                      _titleController.text.isEmpty
                          ? '—'
                          : _titleController.text),
                  _buildSummaryRow(
                      'Discount',
                      _discountController.text.isEmpty
                          ? '—'
                          : _discountController.text),
                  _buildSummaryRow(
                      'Code',
                      _codeController.text.isEmpty
                          ? '—'
                          : _codeController.text),
                  _buildSummaryRow('Category', _selectedCategory ?? '—'),
                  _buildSummaryRow(
                      'Duration', daysLeft > 0 ? '$daysLeft days' : '—'),
                  _buildSummaryRow('Featured', _featured ? 'Yes ⭐' : 'No'),
                  _buildSummaryRow('Images', '${_imageFiles.length}/5'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatCategoryLabel(String value) {
    return value
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
