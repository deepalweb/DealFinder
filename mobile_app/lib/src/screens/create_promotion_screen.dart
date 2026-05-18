import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/image_helper.dart';
import '../models/category.dart';
import '../models/promotion.dart';
import '../utils/bank_card_promotion_support.dart';

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
  final _orderLinkController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _percentageOffController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _minimumSpendController = TextEditingController();
  final _maximumBenefitController = TextEditingController();

  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _featured = false;
  bool _isSubmitting = false;
  String? _token;
  String _dealType = 'percentage';
  String _fulfillmentType = 'visit';
  bool _visitAvailable = true;
  bool _deliveryAvailable = false;
  bool _pickupAvailable = false;
  String? _selectedBankOfferType;
  final Set<String> _selectedCardTypes = <String>{};
  final List<File> _imageFiles = [];
  final List<String> _existingImageUrls = [];
  List<String> _uploadedImageUrls = [];

  static const List<Map<String, String>> _bankOfferTypes = [
    {'value': 'discount', 'label': 'Discount'},
    {'value': 'cashback', 'label': 'Cashback'},
    {'value': 'installment', 'label': 'Installment'},
    {'value': 'dining', 'label': 'Dining'},
    {'value': 'grocery', 'label': 'Grocery'},
    {'value': 'fuel', 'label': 'Fuel'},
    {'value': 'travel', 'label': 'Travel'},
    {'value': 'electronics', 'label': 'Electronics'},
    {'value': 'online', 'label': 'Online'},
    {'value': 'other', 'label': 'Other'},
  ];

  bool get _hasValidMerchantId =>
      RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(widget.merchantId);

  bool get _isDemoMerchantSession =>
      (_token?.startsWith('demo-') ?? false) ||
      widget.merchantId.startsWith('demo-');

  bool get _isEditing => widget.existingPromotion != null;
  bool get _isBankCardCategory =>
      normalizeCategoryId(_selectedCategory) ==
      BankCardPromotionSupport.categoryId;

  int get _totalImageCount => _existingImageUrls.length + _imageFiles.length;

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
    _orderLinkController.text = promo.orderLink ?? '';
    _selectedCategory = normalizeCategoryId(promo.category);
    _featured = promo.featured ?? false;
    _dealType = _inferDealType(promo);
    _fulfillmentType = promo.fulfillmentType ?? 'visit';
    _visitAvailable = promo.visitAvailable;
    _deliveryAvailable = promo.deliveryAvailable;
    _pickupAvailable = promo.pickupAvailable;
    _startDate = isDuplicate ? DateTime.now() : (promo.startDate ?? _startDate);
    _endDate = isDuplicate
        ? DateTime.now().add(const Duration(days: 30))
        : (promo.endDate ?? _endDate);
    _existingImageUrls
      ..clear()
      ..addAll(_extractExistingImageUrls(promo, isDuplicate: isDuplicate));
    _bankNameController.text = promo.bankName ?? '';
    _minimumSpendController.text = promo.minimumSpend?.toStringAsFixed(0) ?? '';
    _maximumBenefitController.text =
        promo.maximumBenefit?.toStringAsFixed(0) ?? '';
    _selectedBankOfferType = promo.offerType;
    _selectedCardTypes
      ..clear()
      ..addAll(promo.cardTypes);

    if (promo.originalPrice != null) {
      _originalPriceController.text = promo.originalPrice.toString();
    }
    if (promo.discountedPrice != null) {
      _discountedPriceController.text = promo.discountedPrice.toString();
    }
    if (promo.price != null && promo.originalPrice == null) {
      _originalPriceController.text = promo.price.toString();
    }
    if (_dealType == 'percentage' &&
        promo.originalPrice != null &&
        promo.discountedPrice != null &&
        promo.originalPrice! > 0) {
      final percent = ((promo.originalPrice! - promo.discountedPrice!) /
          promo.originalPrice! *
          100);
      if (percent > 0) {
        _percentageOffController.text = percent.toStringAsFixed(0);
      }
    }
  }

  String _inferDealType(Promotion promo) {
    final discount = (promo.discount ?? '').toLowerCase();
    if (discount.contains('buy 1 get 1') || discount.contains('bogo')) {
      return 'bogo';
    }
    if (promo.originalPrice != null && promo.discountedPrice != null) {
      if (discount.contains('%')) {
        return 'percentage';
      }
      return 'price_drop';
    }
    if (discount.contains('bundle') || discount.contains(' for ')) {
      return 'bundle';
    }
    if (discount.contains('flash')) {
      return 'flash';
    }
    if (discount.contains('rs.') ||
        discount.contains('lkr') ||
        discount.contains(' off')) {
      return 'fixed';
    }
    return 'percentage';
  }

  List<String> _extractExistingImageUrls(Promotion promo,
      {required bool isDuplicate}) {
    if (isDuplicate) return [];
    final imageUrl = promo.imageDataString;
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return [];
    }
    return [imageUrl.trim()];
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
    if (!mounted) return;
    setState(() {
      _token = prefs.getString('userToken');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _codeController.dispose();
    _urlController.dispose();
    _orderLinkController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    _percentageOffController.dispose();
    _bankNameController.dispose();
    _minimumSpendController.dispose();
    _maximumBenefitController.dispose();
    super.dispose();
  }

  String? _validateBankOfferField(String? _) {
    if (!_isBankCardCategory) return null;
    if (_selectedCardTypes.isEmpty) {
      return 'Select at least one card type';
    }
    if ((_selectedBankOfferType ?? '').isEmpty) {
      return 'Offer type is required';
    }
    return null;
  }

  Future<void> _pickImages() async {
    if (_totalImageCount >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed')),
      );
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage();
    for (var image in images) {
      if (_totalImageCount >= 5) break;
      setState(() {
        _imageFiles.add(File(image.path));
        _uploadedImageUrls = [];
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
      _uploadedImageUrls = [];
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  String? _validateRequiredPrice(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return 'Enter a valid amount';
    return null;
  }

  String? _validateDiscountedPrice(String? value) {
    final baseError = _validateRequiredPrice(value);
    if (baseError != null) return baseError;
    final original = double.tryParse(_originalPriceController.text.trim());
    final discounted = double.tryParse(value!.trim());
    if (original != null && discounted != null && discounted >= original) {
      return 'Must be less than original price';
    }
    return null;
  }

  void _generateCode() {
    final words = _titleController.text.split(' ');
    final code =
        words.map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join('');
    final random = (10 + (90 * (DateTime.now().millisecond / 1000))).toInt();
    _codeController.text = '${code.isEmpty ? "DEAL" : code}$random';
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? today)
          : (_endDate ?? _startDate ?? today.add(const Duration(days: 30))),
      firstDate: isStartDate
          ? today
          : (_startDate != null && _startDate!.isAfter(today)
              ? _startDate!
              : today),
      lastDate: today.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            0,
            0,
            0,
          );
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = DateTime(
              picked.year,
              picked.month,
              picked.day,
              23,
              59,
              59,
            );
          }
        } else {
          if (_startDate != null && picked.isBefore(_startDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('End date cannot be earlier than start date.'),
              ),
            );
            return;
          }
          _endDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            23,
            59,
            59,
          );
        }
      });
    }
  }

  Future<void> _submitPromotion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isDemoMerchantSession) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Demo merchant accounts cannot create live promotions.',
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

    if (_isBankCardCategory) {
      final validationMessage = _validateBankOfferField(null);
      if (validationMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validationMessage)),
        );
        _tabController.animateTo(0);
        return;
      }
    }

    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Authentication required. Please login again.')),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both start and end dates.')),
      );
      _tabController.animateTo(0);
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('End date must be the same day or later than start date.'),
        ),
      );
      _tabController.animateTo(0);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      _uploadedImageUrls = [];
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

      final mergedImageUrls = [
        ..._existingImageUrls,
        ..._uploadedImageUrls,
      ];

      final promotionData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'discount': _discountController.text.trim(),
        'code': _codeController.text.trim(),
        'category': _selectedCategory,
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'featured': _featured,
        'fulfillmentType': _fulfillmentType,
        'visitAvailable': _visitAvailable,
        'deliveryAvailable': _deliveryAvailable,
        'pickupAvailable': _pickupAvailable,
        if (_urlController.text.trim().isNotEmpty)
          'url': _urlController.text.trim(),
        if (_orderLinkController.text.trim().isNotEmpty)
          'orderLink': _orderLinkController.text.trim(),
        if (_originalPriceController.text.isNotEmpty)
          'originalPrice': double.parse(_originalPriceController.text),
        if (_discountedPriceController.text.isNotEmpty)
          'discountedPrice': double.parse(_discountedPriceController.text),
        if (mergedImageUrls.isNotEmpty) 'image': mergedImageUrls.first,
        if (mergedImageUrls.isNotEmpty) 'images': mergedImageUrls,
        if (_hasValidMerchantId) 'merchantId': widget.merchantId,
        if (_isBankCardCategory) 'bankName': _bankNameController.text.trim(),
        if (_isBankCardCategory) 'cardTypes': _selectedCardTypes.toList(),
        if (_isBankCardCategory && _selectedBankOfferType != null)
          'offerType': _selectedBankOfferType,
        if (_isBankCardCategory &&
            _minimumSpendController.text.trim().isNotEmpty)
          'minimumSpend': double.parse(_minimumSpendController.text.trim()),
        if (_isBankCardCategory &&
            _maximumBenefitController.text.trim().isNotEmpty)
          'maximumBenefit':
              double.parse(_maximumBenefitController.text.trim()),
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

      await CacheService.clearAll();

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
              color: Colors.black.withValues(alpha: 0.05),
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
          DropdownButtonFormField<String>(
            initialValue: _fulfillmentType,
            decoration: const InputDecoration(
              labelText: 'How customers redeem this deal *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.storefront),
            ),
            items: const [
              DropdownMenuItem(
                value: 'visit',
                child: Text('Visit Store'),
              ),
              DropdownMenuItem(
                value: 'order',
                child: Text('Order Online'),
              ),
              DropdownMenuItem(
                value: 'hybrid',
                child: Text('Visit or Order'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _fulfillmentType = value ?? 'visit';
                if (_fulfillmentType == 'visit') {
                  _visitAvailable = true;
                  _deliveryAvailable = false;
                  _pickupAvailable = false;
                } else if (_fulfillmentType == 'order') {
                  _visitAvailable = false;
                  _deliveryAvailable = true;
                } else {
                  _visitAvailable = true;
                }
              });
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visit Store'),
                  subtitle: const Text('Customers can go to the physical shop'),
                  value: _visitAvailable,
                  onChanged: _fulfillmentType == 'order'
                      ? null
                      : (value) {
                          setState(() {
                            _visitAvailable = value;
                            if (!_visitAvailable &&
                                !_deliveryAvailable &&
                                !_pickupAvailable) {
                              _deliveryAvailable = true;
                              _fulfillmentType = 'order';
                            } else if (_visitAvailable &&
                                (_deliveryAvailable || _pickupAvailable)) {
                              _fulfillmentType = 'hybrid';
                            } else if (_visitAvailable) {
                              _fulfillmentType = 'visit';
                            }
                          });
                        },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Delivery Available'),
                  subtitle: const Text('Customers can order this deal online'),
                  value: _deliveryAvailable,
                  onChanged: (value) {
                    setState(() {
                      _deliveryAvailable = value;
                      if (_deliveryAvailable) {
                        _fulfillmentType = _visitAvailable || _pickupAvailable
                            ? 'hybrid'
                            : 'order';
                      } else if (!_pickupAvailable && !_visitAvailable) {
                        _visitAvailable = true;
                        _fulfillmentType = 'visit';
                      } else if (_visitAvailable) {
                        _fulfillmentType = 'visit';
                      }
                    });
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pickup Available'),
                  subtitle: const Text('Customers can collect after ordering'),
                  value: _pickupAvailable,
                  onChanged: (value) {
                    setState(() {
                      _pickupAvailable = value;
                      if (_pickupAvailable) {
                        _fulfillmentType = _visitAvailable || _deliveryAvailable
                            ? 'hybrid'
                            : 'order';
                      } else if (!_deliveryAvailable && !_visitAvailable) {
                        _visitAvailable = true;
                        _fulfillmentType = 'visit';
                      } else if (_visitAvailable && !_deliveryAvailable) {
                        _fulfillmentType = 'visit';
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          if (_deliveryAvailable ||
              _pickupAvailable ||
              _fulfillmentType != 'visit') ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _orderLinkController,
              decoration: const InputDecoration(
                labelText: 'Order Link',
                hintText: 'https://ubereats.com / PickMe / website link',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.delivery_dining),
              ),
            ),
          ],
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
                    validator: _validateRequiredPrice,
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
              validator: _validateRequiredPrice,
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
                    validator: _validateRequiredPrice,
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
                    validator: _validateDiscountedPrice,
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
            items: predefinedCategories
                .where((category) => category.id != 'other')
                .map((category) {
              return DropdownMenuItem(
                value: category.id,
                child: Text(category.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
                if (!_isBankCardCategory) {
                  _bankNameController.clear();
                  _minimumSpendController.clear();
                  _maximumBenefitController.clear();
                  _selectedBankOfferType = null;
                  _selectedCardTypes.clear();
                }
              });
            },
            validator: (value) {
              if (value == null) return 'Category is required';
              return null;
            },
          ),
          if (_isBankCardCategory) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD7E5FA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.credit_card_rounded,
                          color: Color(0xFF0F4C81),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bank Card Offer Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add the bank, eligible cards, and offer conditions clearly.',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bankNameController,
                    decoration: const InputDecoration(
                      labelText: 'Bank Name *',
                      hintText: 'HNB, Sampath, Commercial Bank',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                    validator: (value) {
                      if (!_isBankCardCategory) return null;
                      if (value == null || value.trim().isEmpty) {
                        return 'Bank name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBankOfferType,
                    decoration: const InputDecoration(
                      labelText: 'Offer Type *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    items: _bankOfferTypes
                        .map(
                          (option) => DropdownMenuItem(
                            value: option['value'],
                            child: Text(option['label']!),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedBankOfferType = value);
                    },
                    validator: (_) => _isBankCardCategory &&
                            (_selectedBankOfferType ?? '').isEmpty
                        ? 'Offer type is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Eligible Card Types *',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildCardTypeChip('credit', 'Credit'),
                      _buildCardTypeChip('debit', 'Debit'),
                      _buildCardTypeChip('prepaid', 'Prepaid'),
                    ],
                  ),
                  if (_selectedCardTypes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Select at least one card type.',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minimumSpendController,
                          decoration: const InputDecoration(
                            labelText: 'Minimum Spend',
                            hintText: '5000',
                            border: OutlineInputBorder(),
                            prefixText: 'Rs. ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _maximumBenefitController,
                          decoration: const InputDecoration(
                            labelText: 'Maximum Benefit',
                            hintText: '2500',
                            border: OutlineInputBorder(),
                            prefixText: 'Rs. ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
          if (_totalImageCount > 0)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _totalImageCount + (_totalImageCount < 5 ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _totalImageCount) {
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

                final isExistingImage = index < _existingImageUrls.length;
                final localImageIndex = index - _existingImageUrls.length;

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
                        child: isExistingImage
                            ? Image.network(
                                _existingImageUrls[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.broken_image),
                                  ),
                                ),
                              )
                            : Image.file(
                                _imageFiles[localImageIndex],
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
                        onTap: () => isExistingImage
                            ? _removeExistingImage(index)
                            : _removeImage(localImageIndex),
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
                  _buildSummaryRow(
                      'Redemption',
                      _fulfillmentType == 'visit'
                          ? 'Visit store'
                          : _fulfillmentType == 'order'
                              ? 'Order online'
                              : 'Visit or order'),
                  _buildSummaryRow(
                      'Category', getCategoryLabel(_selectedCategory)),
                  if (_isBankCardCategory)
                    _buildSummaryRow(
                      'Bank',
                      _bankNameController.text.trim().isEmpty
                          ? '—'
                          : _bankNameController.text.trim(),
                    ),
                  if (_isBankCardCategory)
                    _buildSummaryRow(
                      'Card Types',
                      _selectedCardTypes.isEmpty
                          ? '—'
                          : _selectedCardTypes
                              .map((type) => type[0].toUpperCase() + type.substring(1))
                              .join(', '),
                    ),
                  if (_isBankCardCategory)
                    _buildSummaryRow(
                      'Offer Type',
                      _selectedBankOfferType == null
                          ? '—'
                          : _bankOfferTypes
                                  .firstWhere(
                                    (option) =>
                                        option['value'] == _selectedBankOfferType,
                                    orElse: () => {
                                      'label': _selectedBankOfferType!,
                                    },
                                  )['label'] ??
                              _selectedBankOfferType!,
                    ),
                  _buildSummaryRow(
                      'Duration', daysLeft > 0 ? '$daysLeft days' : '—'),
                  if (_isBankCardCategory &&
                      _minimumSpendController.text.trim().isNotEmpty)
                    _buildSummaryRow(
                      'Min Spend',
                      'Rs. ${_minimumSpendController.text.trim()}',
                    ),
                  if (_isBankCardCategory &&
                      _maximumBenefitController.text.trim().isNotEmpty)
                    _buildSummaryRow(
                      'Max Benefit',
                      'Rs. ${_maximumBenefitController.text.trim()}',
                    ),
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

  Widget _buildCardTypeChip(String value, String label) {
    final selected = _selectedCardTypes.contains(value);
    return FilterChip(
      label: Text(label),
      selected: selected,
      avatar: Icon(
        Icons.credit_card_rounded,
        size: 16,
        color: selected ? Colors.white : const Color(0xFF0F4C81),
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF0F172A),
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: const Color(0xFFF3F7FF),
      selectedColor: const Color(0xFF0F4C81),
      side: BorderSide(
        color: selected ? const Color(0xFF0F4C81) : const Color(0xFFD8E4FB),
      ),
      onSelected: (next) {
        setState(() {
          if (next) {
            _selectedCardTypes.add(value);
          } else {
            _selectedCardTypes.remove(value);
          }
        });
      },
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}
