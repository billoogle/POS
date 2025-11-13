import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../services/product_service.dart';
import '../../services/category_service.dart';
import '../../services/image_service.dart';
import 'barcode_scanner_screen.dart';
import '../../helpers/currency_manager.dart';


class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockController = TextEditingController();
  
  final _productService = ProductService();
  final _categoryService = CategoryService();
  final _imageService = ImageService();

  bool _isLoading = false;
  bool _isUploadingImage = false;
  String _imageUrl = '';
  File? _selectedImage;
  Category? _selectedCategory;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _barcodeController.text = widget.product!.barcode;
      _purchasePriceController.text = widget.product!.purchasePrice.toString();
      _salePriceController.text = widget.product!.salePrice.toString();
      _stockController.text = widget.product!.stock.toString();
      _imageUrl = widget.product!.imageUrl;
    }
  }

  Future<void> _loadCategories() async {
    _categoryService.getCategories().listen((categories) {
      setState(() {
        _categories = categories;
        
        if (widget.product != null && _selectedCategory == null) {
          _selectedCategory = categories.firstWhere(
            (cat) => cat.id == widget.product!.categoryId,
            orElse: () => categories.isNotEmpty ? categories.first : Category(
              id: '', name: '', description: '', iconName: '', 
              color: '', createdAt: DateTime.now(), userId: '',
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final imageFile = await _imageService.showImageSourceDialog(context);
    
    if (imageFile != null) {
      setState(() {
        _selectedImage = imageFile;
        _isUploadingImage = true;
      });

      final result = await _imageService.uploadImage(imageFile);

      setState(() => _isUploadingImage = false);

      if (result['success']) {
        setState(() => _imageUrl = result['imageUrl']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (barcode != null) {
      setState(() => _barcodeController.text = barcode);
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a category'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      // Check if barcode exists
      final barcodeExists = await _productService.isBarcodeExists(
        _barcodeController.text,
        excludeProductId: widget.product?.id,
      );

      if (barcodeExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('This barcode already exists'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      Map<String, dynamic> result;

      if (widget.product != null) {
        result = await _productService.updateProduct(
          productId: widget.product!.id,
          name: _nameController.text.trim(),
          imageUrl: _imageUrl,
          barcode: _barcodeController.text.trim(),
          purchasePrice: double.parse(_purchasePriceController.text),
          salePrice: double.parse(_salePriceController.text),
          stock: int.parse(_stockController.text),
          categoryId: _selectedCategory!.id,
          categoryName: _selectedCategory!.name,
        );
      } else {
        result = await _productService.addProduct(
          name: _nameController.text.trim(),
          imageUrl: _imageUrl,
          barcode: _barcodeController.text.trim(),
          purchasePrice: double.parse(_purchasePriceController.text),
          salePrice: double.parse(_salePriceController.text),
          stock: int.parse(_stockController.text),
          categoryId: _selectedCategory!.id,
          categoryName: _selectedCategory!.name,
        );
      }

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? AppTheme.success : AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        if (result['success']) {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.darkNavy,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Edit Product' : 'Add Product',
          style: const TextStyle(
            color: AppTheme.darkNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Upload Section
              _buildImageSection().animate().fadeIn(duration: 400.ms).scale(),
              const SizedBox(height: 24),

              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'e.g., Coca Cola 500ml',
                  prefixIcon: _buildIconContainer(
                    Icons.shopping_bag_outlined,
                    AppTheme.primaryCyan,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.2),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<Category>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: _buildIconContainer(
                    Icons.category_outlined,
                    AppTheme.primaryGold,
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: -0.2),
              const SizedBox(height: 16),

              // Barcode Section
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: InputDecoration(
                        labelText: 'Barcode *',
                        hintText: 'Enter or scan barcode',
                        prefixIcon: _buildIconContainer(
                          Icons.qr_code_rounded,
                          AppTheme.info,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter barcode';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 56,
                    decoration: AppTheme.gradientContainer(
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: ElevatedButton(
                      onPressed: _scanBarcode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppTheme.white,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideX(begin: -0.2),
              const SizedBox(height: 16),

              // Purchase Price
              ValueListenableBuilder<String>(
  valueListenable: CurrencyManager.currencySymbol,
  builder: (context, currency, child) {
    return TextFormField(
      controller: _purchasePriceController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: 'Purchase Price *',
        hintText: '0',
        prefixIcon: _buildIconContainer(
          Icons.monetization_on_outlined,
          AppTheme.warning,
        ),
        prefixText: '$currency ', // Dynamic prefix
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter purchase price';
        }
        return null;
      },
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideX(begin: -0.2);
  },
),
const SizedBox(height: 16),

              // Sale Price
              ValueListenableBuilder<String>(
  valueListenable: CurrencyManager.currencySymbol,
  builder: (context, currency, child) {
    return TextFormField(
      controller: _salePriceController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: 'Sale Price *',
        hintText: '0',
        prefixIcon: _buildIconContainer(
          Icons.payments_outlined,
          AppTheme.success,
        ),
        prefixText: '$currency ', // Dynamic prefix
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter sale price';
        }
        if (int.tryParse(value) != null && 
            _purchasePriceController.text.isNotEmpty &&
            int.parse(value) < int.parse(_purchasePriceController.text)) {
          return 'Sale price should be greater than purchase price';
        }
        return null;
      },
    ).animate().fadeIn(duration: 400.ms, delay: 500.ms).slideX(begin: -0.2);
  },
),
const SizedBox(height: 16),


              // Stock
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Stock Quantity *',
                  hintText: '0',
                  prefixIcon: _buildIconContainer(
                    Icons.inventory_outlined,
                    AppTheme.error,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter stock quantity';
                  }
                  return null;
                },
              ).animate().fadeIn(duration: 400.ms, delay: 600.ms).slideX(begin: -0.2),
              const SizedBox(height: 32),

              // Save Button
              Container(
                height: 56,
                decoration: AppTheme.gradientContainer(
                  gradient: AppTheme.goldGradient,
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.darkNavy,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isEdit ? 'Update Product' : 'Add Product',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkNavy,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.check_rounded,
                              size: 22,
                              color: AppTheme.darkNavy,
                            ),
                          ],
                        ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 700.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow(),
      ),
      child: Column(
        children: [
          if (_isUploadingImage)
            const SizedBox(
              height: 180,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryCyan),
                    SizedBox(height: 16),
                    Text('Uploading image...'),
                  ],
                ),
              ),
            )
          else if (_imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                _imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
              ),
            )
          else if (_selectedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                _selectedImage!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            _buildPlaceholder(),
          const SizedBox(height: 16),
          Container(
            decoration: AppTheme.gradientContainer(),
            child: ElevatedButton.icon(
              onPressed: _isUploadingImage ? null : _pickAndUploadImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: Text(_imageUrl.isEmpty ? 'Add Image' : 'Change Image'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_rounded,
            size: 60,
            color: AppTheme.darkGray,
          ),
          SizedBox(height: 8),
          Text(
            'No image selected',
            style: TextStyle(
              color: AppTheme.darkGray,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconContainer(IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }
}