import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../products/barcode_scanner_screen.dart';
import 'product_detail_screen.dart';

class ProductFinderScreen extends StatefulWidget {
  const ProductFinderScreen({Key? key}) : super(key: key);

  @override
  State<ProductFinderScreen> createState() => _ProductFinderScreenState();
}

class _ProductFinderScreenState extends State<ProductFinderScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (barcode != null) {
      _searchByBarcode(barcode);
    }
  }

  Future<void> _searchByBarcode(String barcode) async {
    setState(() => _isSearching = true);

    final products = await _productService.getProducts().first;
    final product = products.firstWhere(
      (p) => p.barcode == barcode,
      orElse: () => Product(
        id: '', name: '', imageUrl: '', barcode: '', 
        purchasePrice: 0, salePrice: 0, stock: 0, 
        categoryId: '', categoryName: '', 
        createdAt: DateTime.now(), userId: '',
      ),
    );

    setState(() => _isSearching = false);

    if (product.id.isNotEmpty) {
      _navigateToDetail(product);
    } else {
      _showNotFoundDialog('Barcode: $barcode');
    }
  }

  Future<void> _searchByName() async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter product name'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isSearching = true);

    final products = await _productService.getProducts().first;
    final query = _searchController.text.toLowerCase();
    final results = products.where((p) => 
      p.name.toLowerCase().contains(query)
    ).toList();

    setState(() => _isSearching = false);

    if (results.isEmpty) {
      _showNotFoundDialog(_searchController.text);
    } else if (results.length == 1) {
      _navigateToDetail(results.first);
    } else {
      _showMultipleResults(results);
    }
  }

  void _navigateToDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _showNotFoundDialog(String searchTerm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Not Found'),
          ],
        ),
        content: Text('No product found for "$searchTerm"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMultipleResults(List<Product> products) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('${products.length} Products Found'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: product.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.inventory_2_rounded),
                      ),
                title: Text(product.name),
                subtitle: Text('Stock: ${product.stock}'),
                trailing: Text(
                  'Rs. ${product.salePrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.success,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToDetail(product);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Find Product',
          style: TextStyle(
            color: AppTheme.darkNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryCyan.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 60,
                    color: AppTheme.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Search Product',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find product details & history',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).scale(),
            const SizedBox(height: 32),

            // Search Options
            _buildSectionHeader('Search By', Icons.filter_list_rounded),
            const SizedBox(height: 16),

            // Option 1: Scan Barcode
            _buildSearchOption(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Scan Barcode',
              subtitle: 'Use camera to scan product barcode',
              color: AppTheme.primaryCyan,
              onTap: _scanBarcode,
              delay: 0,
            ),
            const SizedBox(height: 12),

            // Option 2: Manual Barcode
            _buildSearchOption(
              icon: Icons.pin_outlined,
              title: 'Enter Barcode',
              subtitle: 'Type barcode manually',
              color: AppTheme.primaryGold,
              onTap: () => _showBarcodeInputDialog(),
              delay: 100,
            ),
            const SizedBox(height: 12),

            // Option 3: Search by Name
            _buildSearchOption(
              icon: Icons.text_fields_rounded,
              title: 'Search by Name',
              subtitle: 'Find product by name',
              color: AppTheme.success,
              onTap: () => _showNameSearchDialog(),
              delay: 200,
            ),

            if (_isSearching) ...[
              const SizedBox(height: 32),
              const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryCyan,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkNavy,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2);
  }

  Widget _buildSearchOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow(),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.darkGray,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: AppTheme.darkGray,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: delay.ms).slideX(begin: -0.2);
  }

  void _showBarcodeInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.pin_outlined,
                color: AppTheme.primaryGold,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Enter Barcode'),
          ],
        ),
        content: TextField(
          controller: _barcodeController,
          decoration: const InputDecoration(
            labelText: 'Barcode',
            hintText: 'Enter product barcode',
            prefixIcon: Icon(Icons.qr_code_rounded),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: AppTheme.gradientContainer(
              gradient: AppTheme.goldGradient,
            ),
            child: ElevatedButton(
              onPressed: () {
                if (_barcodeController.text.isNotEmpty) {
                  Navigator.pop(context);
                  _searchByBarcode(_barcodeController.text);
                  _barcodeController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: const Text('Search'),
            ),
          ),
        ],
      ),
    );
  }

  void _showNameSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.text_fields_rounded,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Search by Name'),
          ],
        ),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Product Name',
            hintText: 'Enter product name',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.success, Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _searchByName();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: const Text('Search'),
            ),
          ),
        ],
      ),
    );
  }
}