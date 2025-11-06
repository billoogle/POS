import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/sale_model.dart';
import '../../services/auth_service.dart';
import '../../services/reports_pdf_service.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({Key? key}) : super(key: key);

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  final AuthService _authService = AuthService();
  final ReportsPdfService _pdfService = ReportsPdfService();
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<Sale> _sales = [];
  Map<String, _ItemSummary> _itemSummary = {};
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
        .collection('sales')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    final sales = snapshot.docs.map((doc) => 
      Sale.fromMap(doc.data())
    ).toList();

    // Calculate item summary
    final itemSummary = <String, _ItemSummary>{};
    for (final sale in sales) {
      for (final item in sale.items) {
        if (itemSummary.containsKey(item.productId)) {
          itemSummary[item.productId]!.quantity += item.quantity;
          itemSummary[item.productId]!.totalAmount += item.totalAmount;
        } else {
          itemSummary[item.productId] = _ItemSummary(
            productName: item.productName,
            quantity: item.quantity,
            totalAmount: item.totalAmount,
          );
        }
      }
    }

    setState(() {
      _sales = sales;
      _itemSummary = itemSummary;
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

  double get _totalRevenue {
    return _sales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
  }

  int get _totalItems {
    return _itemSummary.values.fold(0, (sum, item) => sum + item.quantity);
  }

  Future<void> _exportPDF() async {
    final sortedItems = _itemSummary.entries.toList()
      ..sort((a, b) => b.value.quantity.compareTo(a.value.quantity));

    final topProducts = sortedItems.take(20).map((entry) => {
      'name': entry.value.productName,
      'quantity': entry.value.quantity.toString(),
      'amount': entry.value.totalAmount.toStringAsFixed(0),
    }).toList();

    await _pdfService.generateSalesReport(
      businessName: _businessName,
      startDate: _startDate,
      endDate: _endDate,
      totalSales: _sales.length,
      totalItems: _totalItems,
      totalRevenue: _totalRevenue,
      topProducts: topProducts,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _sales.isEmpty ? null : _exportPDF,
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
                        'Total Sales',
                        '${_sales.length}',
                        Icons.receipt_long,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Items Sold',
                        '$_totalItems',
                        Icons.shopping_bag,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Revenue',
                        'Rs. ${_totalRevenue.toStringAsFixed(0)}',
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
                : _sales.isEmpty
                    ? const Center(
                        child: Text('No sales in selected period'),
                      )
                    : DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            const TabBar(
                              tabs: [
                                Tab(text: 'By Product'),
                                Tab(text: 'By Invoice'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildProductList(),
                                  _buildSalesList(),
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

  Widget _buildProductList() {
    final sortedItems = _itemSummary.entries.toList()
      ..sort((a, b) => b.value.quantity.compareTo(a.value.quantity));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedItems.length,
      itemBuilder: (context, index) {
        final entry = sortedItems[index];
        final item = entry.value;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            title: Text(
              item.productName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Quantity: ${item.quantity}'),
            trailing: Text(
              'Rs. ${item.totalAmount.toStringAsFixed(0)}',
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

  Widget _buildSalesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sales.length,
      itemBuilder: (context, index) {
        final sale = _sales[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt, color: Colors.orange),
            ),
            title: Text(
              sale.invoiceNumber,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${DateFormat('dd MMM yyyy, hh:mm a').format(sale.createdAt)}\n'
              '${sale.itemsCount} items (${sale.totalQuantity} qty)',
            ),
            isThreeLine: true,
            trailing: Text(
              'Rs. ${sale.totalAmount.toStringAsFixed(0)}',
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

class _ItemSummary {
  final String productName;
  int quantity;
  double totalAmount;

  _ItemSummary({
    required this.productName,
    required this.quantity,
    required this.totalAmount,
  });
}