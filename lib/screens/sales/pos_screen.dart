import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product_model.dart';
import '../../models/sale_model.dart';
import '../../services/product_service.dart';
import '../../services/sale_service.dart';
import '../../services/auth_service.dart';
import '../../services/sale_pdf_service.dart';
import '../products/barcode_scanner_screen.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({Key? key}) : super(key: key);

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final ProductService _productService = ProductService();
  final SaleService _saleService = SaleService();
  final SalePdfService _pdfService = SalePdfService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0');

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  final List<CartItem> _cartItems = [];

  String _paymentMethod = 'Cash';
  bool _isLoading = false;
  String _businessName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      if (userData != null) {
        setState(() {
          _businessName = userData['businessName'] ?? 'My Business';
        });
      }
    }
    _productService.getProducts().listen((products) {
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
      });
    });
  }

  void _searchProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((product) {
          return product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.barcode.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (barcode != null) {
      final product = _allProducts.firstWhere(
        (p) => p.barcode == barcode,
        orElse: () => Product(
          id: '', name: '', imageUrl: '', barcode: '', purchasePrice: 0,
          salePrice: 0, stock: 0, categoryId: '', categoryName: '',
          createdAt: DateTime.now(), userId: '',
        ),
      );

      if (product.id.isNotEmpty) {
        _addToCart(product);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product not found!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addToCart(Product product) {
    if (product.stock < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product out of stock!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
      if (existingIndex != -1) {
        final newQuantity = _cartItems[existingIndex].quantity + 1;
        if (newQuantity <= product.stock) {
          _cartItems[existingIndex].quantity = newQuantity;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum stock available: ${product.stock}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        _cartItems.add(CartItem(product: product, quantity: 1));
      }
    });
  }

  void _updateQuantity(int index, int change) {
    setState(() {
      final newQuantity = _cartItems[index].quantity + change;
      if (newQuantity < 1) {
        // ======= FIX: Deletes item when quantity is 0 =======
        _cartItems.removeAt(index);
      } else if (newQuantity <= _cartItems[index].product.stock) {
        _cartItems[index].quantity = newQuantity;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum stock: ${_cartItems[index].product.stock}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  // (This function is no longer needed as delete icon is removed)
  // void _removeFromCart(int index) { ... }

  double get _subtotal => _cartItems.fold(0.0, (sum, item) => sum + (item.product.salePrice * item.quantity));
  double get _discount => double.tryParse(_discountController.text) ?? 0;
  double get _total => _subtotal - _discount;

  Future<void> _completeSale() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart is empty!'), backgroundColor: Colors.red));
      return;
    }
    if (_total < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discount cannot be more than subtotal!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    final saleItems = _cartItems.map((cartItem) => SaleItem(
      productId: cartItem.product.id,
      productName: cartItem.product.name,
      productImage: cartItem.product.imageUrl,
      quantity: cartItem.quantity,
      salePrice: cartItem.product.salePrice,
      totalAmount: cartItem.product.salePrice * cartItem.quantity,
    )).toList();

    final result = await _saleService.createSale(
      items: saleItems,
      subtotal: _subtotal,
      discount: _discount,
      totalAmount: _total,
      paymentMethod: _paymentMethod,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      final sale = await _saleService.getSale(result['saleId']);
      if (sale != null) _showInvoiceDialog(sale);
      setState(() {
        _cartItems.clear();
        _discountController.text = '0';
        _searchController.clear();
        _filteredProducts = _allProducts;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red));
    }
  }

  void _showInvoiceDialog(Sale sale) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green, size: 32),
          SizedBox(width: 12),
          Text('Sale Complete!'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice: ${sale.invoiceNumber}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Items: ${sale.itemsCount}'),
            Text('Total: Rs. ${sale.totalAmount.toStringAsFixed(0)}'),
            Text('Payment: ${sale.paymentMethod}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton.icon(onPressed: () async => await _pdfService.printInvoice(sale, _businessName), icon: const Icon(Icons.print), label: const Text('Print')),
          ElevatedButton.icon(onPressed: () async => await _pdfService.shareInvoice(sale, _businessName), icon: const Icon(Icons.share), label: const Text('Share')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(context)),
        title: const Text('POS System', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF0F172A)),
            onPressed: _scanBarcode,
            tooltip: 'Scan Barcode',
          ),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: const Color(0xFFE2E8F0), height: 1)),
      ),
      body: Row(
        children: [
          // Left Side - Products
          Expanded(
            flex: 6, // Products ko thori zyada jagah
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchProducts,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? const Center(child: Text('No products found'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return _buildProductListItem(product);
                          },
                        ),
                ),
              ],
            ),
          ),
          Container(width: 1, color: const Color(0xFFE2E8F0)),
          // Right Side - Cart
          Expanded(
            flex: 5, // Cart ko thori kam jagah
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart),
                      const SizedBox(width: 8),
                      const Text('Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text('(${_cartItems.length})', style: const TextStyle(fontSize: 18, color: Colors.grey)),
                      const Spacer(),
                      if (_cartItems.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_sweep, color: Colors.red),
                          onPressed: () => setState(() => _cartItems.clear()),
                          tooltip: 'Clear All',
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _cartItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('Cart is empty', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            return _buildCartItem(index);
                          },
                        ),
                ),
                _buildCheckoutSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductListItem(Product product) {
    final isOutOfStock = product.stock < 1;
    final stockColor = product.stock < 10 ? Colors.orange : Colors.green;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200)
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          product.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isOutOfStock ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Text(
          'Stock: ${product.stock}',
          style: TextStyle(color: isOutOfStock ? Colors.red : stockColor),
        ),
        trailing: Text(
          'Rs. ${product.salePrice.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isOutOfStock ? Colors.grey : const Color(0xFF10B981),
          ),
        ),
        onTap: isOutOfStock ? null : () => _addToCart(product),
      ),
    );
  }

  // ======= FIX: Redesigned Cart Item (Delete Icon Removed) =======
  Widget _buildCartItem(int index) {
    final cartItem = _cartItems[index];
    final product = cartItem.product;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200)
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Name and Total Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Rs. ${(product.salePrice * cartItem.quantity).toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bottom Row: Quantity Controls
            Row(
              children: [
                SizedBox(
                  height: 32,
                  width: 40,
                  child: OutlinedButton(
                    onPressed: () => _updateQuantity(index, -1),
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Icon(Icons.remove, size: 16),
                  ),
                ),
                Container(
                  width: 45,
                  alignment: Alignment.center,
                  child: Text('${cartItem.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 32,
                  width: 40,
                  child: OutlinedButton(
                    onPressed: () => _updateQuantity(index, 1),
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Icon(Icons.add, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ======= FIX: Redesigned Checkout Section (Fonts & Button) =======
  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal:', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
              Text('Rs. ${_subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Discount:', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                        prefixText: 'Rs. ',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12)),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                'Rs. ${_total.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _completeSale,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  // ======= FIX: Reduced vertical padding to fix text cut-off =======
                  padding: const EdgeInsets.symmetric(vertical: 14), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Text('Complete Sale', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// Cart Item Helper Class
class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, required this.quantity});
}