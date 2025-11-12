import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pos/helpers/currency_manager.dart';
import '../../theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../models/grn_model.dart';
import '../../services/auth_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final AuthService _authService = AuthService();
  
  List<_PurchaseHistory> _purchaseHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    // Load Purchase History from GRNs
    final grnsSnapshot = await FirebaseFirestore.instance
        .collection('grns')
        .where('userId', isEqualTo: userId)
        .get();

    final purchases = <_PurchaseHistory>[];
    for (final doc in grnsSnapshot.docs) {
      final grn = GRN.fromMap(doc.data());
      for (final item in grn.items) {
        if (item.productId == widget.product.id) {
          purchases.add(_PurchaseHistory(
            date: grn.createdAt,
            vendorName: grn.vendorName,
            quantity: item.quantity,
            purchasePrice: item.purchasePrice,
          ));
        }
      }
    }

    // Sort by date descending
    purchases.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _purchaseHistory = purchases;
      _isLoading = false;
    });
  }

  int get _totalPurchased {
    return _purchaseHistory.fold(0, (sum, item) => sum + item.quantity);
  }

  int get _totalSold {
    // Calculate from current stock
    return _totalPurchased - widget.product.stock;
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
          'Product Details',
          style: TextStyle(
            color: AppTheme.darkNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryCyan),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product Info Card
                  _buildProductInfoCard(),
                  const SizedBox(height: 20),

                  // Stats Cards
                  _buildStatsCards(),
                  const SizedBox(height: 24),

                  // Purchase History
                  _buildSectionHeader('Purchase History', Icons.shopping_cart_rounded),
                  const SizedBox(height: 12),
                  _buildPurchaseHistory(),
                ],
              ),
            ),
    );
  }

  Widget _buildProductInfoCard() {
    final product = widget.product;
    return Container(
      padding: const EdgeInsets.all(20),
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
          // Product Image
          if (product.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                product.imageUrl,
                height: 150,
                width: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage();
                },
              ),
            )
          else
            _buildPlaceholderImage(),
          const SizedBox(height: 16),

          // Product Name
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Category
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              product.categoryName,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Details Grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildDetailRow('Barcode', product.barcode),
                const Divider(color: Colors.white30, height: 16),
                _buildDetailRow('Current Stock', '${product.stock} units'),
                const Divider(color: Colors.white30, height: 16),
                _buildDetailRow('Purchase Price', CurrencyManager.format(product.purchasePrice)),
                const Divider(color: Colors.white30, height: 16),
                _buildDetailRow('Sale Price', CurrencyManager.format(product.salePrice)),
                const Divider(color: Colors.white30, height: 16),
                _buildDetailRow(
                  'Profit Margin',
                  '${product.profitMargin.toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 150,
      width: 150,
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.inventory_2_rounded,
        size: 60,
        color: AppTheme.white,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Purchased',
            '$_totalPurchased',
            Icons.shopping_bag_rounded,
            AppTheme.primaryGold,
            0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Sold',
            '$_totalSold',
            Icons.sell_rounded,
            AppTheme.success,
            100,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    int delay,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow(),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: delay.ms).slideY(begin: 0.2);
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

  Widget _buildPurchaseHistory() {
    if (_purchaseHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow(),
        ),
        child: Column(
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              'No Purchase History',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _purchaseHistory.asMap().entries.map((entry) {
        final index = entry.key;
        final purchase = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.softShadow(),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: AppTheme.primaryGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.vendorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(purchase.date),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.darkGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty: ${purchase.quantity}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.darkGray,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Price
              Text(
                CurrencyManager.format(purchase.purchasePrice),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms).slideX(begin: -0.2);
      }).toList(),
    );
  }
}

// Helper Class
class _PurchaseHistory {
  final DateTime date;
  final String vendorName;
  final int quantity;
  final double purchasePrice;

  _PurchaseHistory({
    required this.date,
    required this.vendorName,
    required this.quantity,
    required this.purchasePrice,
  });
}