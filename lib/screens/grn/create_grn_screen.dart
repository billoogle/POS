import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Animation ke liye import
import '../../models/vendor_model.dart';
import '../../models/product_model.dart';
import '../../models/grn_model.dart';
import '../../services/vendor_service.dart';
import '../../services/product_service.dart';
import '../../services/grn_service.dart';
import '../products/barcode_scanner_screen.dart';

class CreateGRNScreen extends StatefulWidget {
  const CreateGRNScreen({Key? key}) : super(key: key);

  @override
  State<CreateGRNScreen> createState() => _CreateGRNScreenState();
}

class _CreateGRNScreenState extends State<CreateGRNScreen> {
  final _vendorService = VendorService();
  final _productService = ProductService();
  final _grnService = GRNService();
  
  // Autocomplete ke liye FocusNode aur GlobalKey
  final FocusNode _autocompleteFocusNode = FocusNode();
  final GlobalKey _autocompleteKey = GlobalKey();
  final _searchController = TextEditingController(); // Ye Autocomplete use karega

  List<Vendor> _vendors = [];
  List<Product> _allProducts = [];
  Vendor? _selectedVendor;
  
  final List<GRNItemInput> _grnItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _autocompleteFocusNode.dispose(); // Focus node ko dispose karein
    super.dispose();
  }

  Future<void> _loadData() async {
    _vendorService.getVendors().listen((vendors) {
      setState(() => _vendors = vendors);
    });

    _productService.getProducts().listen((products) {
      setState(() => _allProducts = products);
    });
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (barcode != null) {
      _findProductByBarcode(barcode);
    }
  }

  void _findProductByBarcode(String barcode) {
    final product = _allProducts.firstWhere(
      (p) => p.barcode == barcode,
      orElse: () => Product(
        id: '', name: '', imageUrl: '', barcode: '', purchasePrice: 0,
        salePrice: 0, stock: 0, categoryId: '', categoryName: '',
        createdAt: DateTime.now(), userId: '',
      ),
    );

    if (product.id.isNotEmpty) {
      _showAddProductDialog(product);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product not found with this barcode!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // YE FUNCTION AB AUTACOMPLETE OPTIONS BUILDER ISTEMAL KAREGA
  // void _searchProduct() { ... }

  // YE BHI AB AUTACOMPLETE LISTVIEW ISTEMAL KAREGA
  // void _showProductSelectionDialog(List<Product> products) { ... }

  void _showAddProductDialog(Product product) {
    final quantityController = TextEditingController();
    final purchaseController = TextEditingController(
      text: product.purchasePrice.toString(),
    );
    final saleController = TextEditingController(
      text: product.salePrice.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(product.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                autofocus: true, // Quantity par auto focus
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Quantity *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: purchaseController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Purchase Price *',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: saleController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Sale Price *',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (quantityController.text.isEmpty ||
                  purchaseController.text.isEmpty ||
                  saleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fill all fields')),
                );
                return;
              }

              setState(() {
                _grnItems.add(GRNItemInput(
                  product: product,
                  quantity: int.parse(quantityController.text),
                  purchasePrice: double.parse(purchaseController.text),
                  salePrice: double.parse(saleController.text),
                ));
              });

              _searchController.clear();
              _autocompleteFocusNode.unfocus(); // Focus hatayein
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeItem(int index) {
    setState(() => _grnItems.removeAt(index));
  }

  double get _totalAmount {
    return _grnItems.fold(0.0, (sum, item) => sum + item.totalAmount);
  }

  Future<void> _postGRN() async {
    if (_selectedVendor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select vendor first')),
      );
      return;
    }

    if (_grnItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final items = _grnItems.map((item) => GRNItem(
      productId: item.product.id,
      productName: item.product.name,
      productImage: item.product.imageUrl,
      quantity: item.quantity,
      purchasePrice: item.purchasePrice,
      salePrice: item.salePrice,
      totalAmount: item.totalAmount,
    )).toList();

    final result = await _grnService.createGRN(
      vendorId: _selectedVendor!.id,
      vendorName: _selectedVendor!.name,
      vendorPhone: _selectedVendor!.phoneNumber,
      items: items,
      totalAmount: _totalAmount,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result['message']}\nGRN: ${result['grnNumber']}'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // === NEW: Autocomplete Options Builder Function ===
  Iterable<Product> _buildAutocompleteOptions(TextEditingValue textEditingValue) {
    if (textEditingValue.text.isEmpty) {
      return const Iterable<Product>.empty();
    }
    final query = textEditingValue.text.toLowerCase();
    // Naam ya barcode se search karein
    return _allProducts.where((Product product) {
      return product.name.toLowerCase().contains(query) ||
          product.barcode.toLowerCase().contains(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create GRN'),
      ),
      body: Column(
        children: [
          // Vendor Selection
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: DropdownButtonFormField<Vendor>(
              value: _selectedVendor,
              decoration: const InputDecoration(
                labelText: 'Select Vendor',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              items: _vendors.map((v) => DropdownMenuItem(
                value: v,
                child: Text(v.name),
              )).toList(),
              onChanged: (v) => setState(() => _selectedVendor = v),
            ),
          ),

          // Search/Scan Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // === UPDATED: Replaced TextField+Button with Autocomplete ===
                Autocomplete<Product>(
                  key: _autocompleteKey,
                  focusNode: _autocompleteFocusNode,
                  textEditingController: _searchController, // Controller yahan use karein
                  optionsBuilder: _buildAutocompleteOptions,
                  displayStringForOption: (Product option) => option.name,
                  onSelected: (Product selection) {
                    // Jab product select ho, dialog dikhayein
                    _showAddProductDialog(selection);
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController fieldTextEditingController,
                      FocusNode fieldFocusNode,
                      VoidCallback onFieldSubmitted) {
                    
                    // _searchController ko field controller se link karein
                    // Humne ye state controller mein pass kar diya hai
                    
                    return TextField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Search product by name or barcode...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none, // Border hata di
                        ),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: fieldTextEditingController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                fieldTextEditingController.clear();
                              },
                            )
                          : null,
                      ),
                      onSubmitted: (value) {
                         // Enter dabane par submit (optional, kyunki list se select hoga)
                         onFieldSubmitted();
                      },
                    );
                  },
                  optionsViewBuilder: (BuildContext context,
                      AutocompleteOnSelected<Product> onSelected,
                      Iterable<Product> options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: 250, // List ki max height
                            // Screen width se thora kam, padding ke liye
                            maxWidth: MediaQuery.of(context).size.width - 32, 
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final Product option = options.elementAt(index);
                              return InkWell(
                                onTap: () {
                                  onSelected(option);
                                },
                                child: ListTile(
                                  leading: option.imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            option.imageUrl,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, st) => const Icon(Icons.inventory_2_outlined),
                                          ),
                                        )
                                      : const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                                  title: Text(option.name),
                                  subtitle: Text('Stock: ${option.stock} | Barcode: ${option.barcode}'),
                                ),
                              ).animate().fadeIn(duration: 200.ms, delay: (index * 20).ms);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // === End of Autocomplete ===
                
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _scanBarcode,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan Barcode'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: _grnItems.isEmpty
                ? const Center(
                    child: Text('No products added\nSearch or scan to add'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _grnItems.length,
                    itemBuilder: (context, index) {
                      final item = _grnItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: item.product.imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.product.imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.inventory_2),
                          title: Text(item.product.name),
                          subtitle: Text(
                            'Qty: ${item.quantity} × Rs.${item.purchasePrice.toStringAsFixed(0)}\n'
                            'Sale: Rs.${item.salePrice.toStringAsFixed(0)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Rs.${item.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeItem(index),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Total & Post
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rs. ${_totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _postGRN,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: const Color(0xFF8B5CF6),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Post GRN',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GRNItemInput {
  final Product product;
  final int quantity;
  final double purchasePrice;
  final double salePrice;
  final double totalAmount;

  GRNItemInput({
    required this.product,
    required this.quantity,
    required this.purchasePrice,
    required this.salePrice,
  }) : totalAmount = quantity * purchasePrice;
}