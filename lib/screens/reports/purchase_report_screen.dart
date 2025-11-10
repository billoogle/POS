import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/grn_model.dart';
import '../../services/auth_service.dart';
import '../../services/reports_pdf_service.dart';

class PurchaseReportScreen extends StatefulWidget {
  const PurchaseReportScreen({super.key});

  @override
  State<PurchaseReportScreen> createState() => _PurchaseReportScreenState();
}

class _PurchaseReportScreenState extends State<PurchaseReportScreen> {
  final AuthService _authService = AuthService();
  final ReportsPdfService _pdfService = ReportsPdfService();
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<GRN> _grns = [];
  Map<String, _VendorSummary> _vendorSummary = {};
  Map<String, _ProductSummary> _productSummary = {};
  bool _isLoading = false;
  String _businessName = '';

  @override
  void initState() {
    super.initState();
    _loadBusinessName();
    _loadReport();
  }

  Future<void> _loadBusinessName() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      if (userData != null) {
        setState(() {
          _businessName = userData['businessName'] ?? 'My Business';
        });
      }
    }
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);

    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    final startOfDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final endOfDay = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

    final snapshot = await FirebaseFirestore.instance
        .collection('grns')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    final grns = snapshot.docs.map((doc) => 
      GRN.fromMap(doc.data())
    ).toList();

    // Calculate vendor summary
    final vendorSummary = <String, _VendorSummary>{};
    final productSummary = <String, _ProductSummary>{};
    
    for (final grn in grns) {
      // Vendor summary
      if (vendorSummary.containsKey(grn.vendorId)) {
        vendorSummary[grn.vendorId]!.totalAmount += grn.totalAmount;
        vendorSummary[grn.vendorId]!.grnCount += 1;
      } else {
        vendorSummary[grn.vendorId] = _VendorSummary(
          vendorName: grn.vendorName,
          totalAmount: grn.totalAmount,
          grnCount: 1,
        );
      }

      // Product summary
      for (final item in grn.items) {
        if (productSummary.containsKey(item.productId)) {
          productSummary[item.productId]!.quantity += item.quantity;
          productSummary[item.productId]!.totalAmount += item.totalAmount;
        } else {
          productSummary[item.productId] = _ProductSummary(
            productName: item.productName,
            quantity: item.quantity,
            totalAmount: item.totalAmount,
          );
        }
      }
    }

    setState(() {
      _grns = grns;
      _vendorSummary = vendorSummary;
      _productSummary = productSummary;
      _isLoading = false;
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReport();
    }
  }

  double get _totalPurchase {
    return _grns.fold(0.0, (sum, grn) => sum + grn.totalAmount);
  }

  int get _totalItems {
    return _productSummary.values.fold(0, (sum, item) => sum + item.quantity);
  }

  Future<void> _exportPDF() async {
    final sortedVendors = _vendorSummary.entries.toList()
      ..sort((a, b) => b.value.totalAmount.compareTo(a.value.totalAmount));

    final topVendors = sortedVendors.take(20).map((entry) => {
      'name': entry.value.vendorName,
      'count': entry.value.grnCount.toString(),
      'amount': entry.value.totalAmount.toStringAsFixed(0),
    }).toList();

    await _pdfService.generatePurchaseReport(
      businessName: _businessName,
      startDate: _startDate,
      endDate: _endDate,
      totalGRNs: _grns.length,
      totalItems: _totalItems,
      totalPurchase: _totalPurchase,
      topVendors: topVendors,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _grns.isEmpty ? null : _exportPDF,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Range Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date Range',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Summary
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total GRNs',
                        '${_grns.length}',
                        Icons.receipt_long,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Items',
                        '$_totalItems',
                        Icons.shopping_bag,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total',
                        'Rs. ${_totalPurchase.toStringAsFixed(0)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Report Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _grns.isEmpty
                    ? const Center(
                        child: Text('No purchases in selected period'),
                      )
                    : DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            const TabBar(
                              tabs: [
                                Tab(text: 'By Vendor'),
                                Tab(text: 'By Product'),
                                Tab(text: 'By GRN'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildVendorList(),
                                  _buildProductList(),
                                  _buildGRNList(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVendorList() {
    final sortedVendors = _vendorSummary.entries.toList()
      ..sort((a, b) => b.value.totalAmount.compareTo(a.value.totalAmount));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedVendors.length,
      itemBuilder: (context, index) {
        final entry = sortedVendors[index];
        final vendor = entry.value;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.withOpacity(0.1),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ),
            title: Text(
              vendor.vendorName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('GRNs: ${vendor.grnCount}'),
            trailing: Text(
              'Rs. ${vendor.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductList() {
    final sortedProducts = _productSummary.entries.toList()
      ..sort((a, b) => b.value.quantity.compareTo(a.value.quantity));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedProducts.length,
      itemBuilder: (context, index) {
        final entry = sortedProducts[index];
        final product = entry.value;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.1),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
            title: Text(
              product.productName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Quantity: ${product.quantity}'),
            trailing: Text(
              'Rs. ${product.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGRNList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _grns.length,
      itemBuilder: (context, index) {
        final grn = _grns[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt, color: Colors.purple),
            ),
            title: Text(
              grn.grnNumber,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${grn.vendorName}\n'
              '${DateFormat('dd MMM yyyy').format(grn.createdAt)}',
            ),
            isThreeLine: true,
            trailing: Text(
              'Rs. ${grn.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VendorSummary {
  final String vendorName;
  double totalAmount;
  int grnCount;

  _VendorSummary({
    required this.vendorName,
    required this.totalAmount,
    required this.grnCount,
  });
}

class _ProductSummary {
  final String productName;
  int quantity;
  double totalAmount;

  _ProductSummary({
    required this.productName,
    required this.quantity,
    required this.totalAmount,
  });
}