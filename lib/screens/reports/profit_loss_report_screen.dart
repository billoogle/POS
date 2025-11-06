import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/sale_model.dart';
import '../../models/grn_model.dart';
import '../../services/auth_service.dart';
import '../../services/reports_pdf_service.dart';

class ProfitLossReportScreen extends StatefulWidget {
  const ProfitLossReportScreen({super.key});

  @override
  State<ProfitLossReportScreen> createState() => _ProfitLossReportScreenState();
}

class _ProfitLossReportScreenState extends State<ProfitLossReportScreen> {
  final AuthService _authService = AuthService();
  final ReportsPdfService _pdfService = ReportsPdfService();
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  List<Sale> _sales = [];
  Map<String, _ProductProfit> _productProfits = {};
  
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

    // Load Sales
    final salesSnapshot = await FirebaseFirestore.instance
        .collection('sales')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    final sales = salesSnapshot.docs.map((doc) => 
      Sale.fromMap(doc.data())
    ).toList();

    // Load GRNs
    final grnsSnapshot = await FirebaseFirestore.instance
        .collection('grns')
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    final grns = grnsSnapshot.docs.map((doc) => 
      GRN.fromMap(doc.data())
    ).toList();

    // Calculate profit per product
    final productProfits = <String, _ProductProfit>{};
    
    // Get purchase costs from GRNs
    final purchasePrices = <String, double>{};
    for (final grn in grns) {
      for (final item in grn.items) {
        purchasePrices[item.productId] = item.purchasePrice;
      }
    }

    // Calculate profits from sales
    for (final sale in sales) {
      for (final item in sale.items) {
        final purchasePrice = purchasePrices[item.productId] ?? 0;
        final profit = (item.salePrice - purchasePrice) * item.quantity;
        
        if (productProfits.containsKey(item.productId)) {
          productProfits[item.productId]!.totalRevenue += item.totalAmount;
          productProfits[item.productId]!.totalCost += purchasePrice * item.quantity;
          productProfits[item.productId]!.totalProfit += profit;
          productProfits[item.productId]!.quantitySold += item.quantity;
        } else {
          productProfits[item.productId] = _ProductProfit(
            productName: item.productName,
            totalRevenue: item.totalAmount,
            totalCost: purchasePrice * item.quantity,
            totalProfit: profit,
            quantitySold: item.quantity,
          );
        }
      }
    }

    setState(() {
      _sales = sales;
      _productProfits = productProfits;
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
    // ignore: avoid_types_as_parameter_names
    return _sales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
  }

  double get _totalCost {
    // ignore: avoid_types_as_parameter_names
    return _productProfits.values.fold(0.0, (sum, item) => sum + item.totalCost);
  }

  double get _totalProfit {
    return _totalRevenue - _totalCost;
  }

  double get _profitMargin {
    if (_totalRevenue == 0) return 0;
    return (_totalProfit / _totalRevenue) * 100;
  }

  Future<void> _exportPDF() async {
    final sortedProducts = _productProfits.entries.toList()
      ..sort((a, b) => b.value.totalProfit.compareTo(a.value.totalProfit));

    final productData = sortedProducts.take(20).map((entry) => {
      'name': entry.value.productName,
      'quantity': entry.value.quantitySold.toString(),
      'revenue': entry.value.totalRevenue.toStringAsFixed(0),
      'cost': entry.value.totalCost.toStringAsFixed(0),
      'profit': entry.value.totalProfit.toStringAsFixed(0),
    }).toList();

    await _pdfService.generateProfitLossReport(
      businessName: _businessName,
      startDate: _startDate,
      endDate: _endDate,
      totalRevenue: _totalRevenue,
      totalCost: _totalCost,
      totalProfit: _totalProfit,
      profitMargin: _profitMargin,
      productProfits: productData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit & Loss Report'),
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
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Revenue',
                        'Rs. ${_totalRevenue.toStringAsFixed(0)}',
                        Icons.attach_money,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Cost',
                        'Rs. ${_totalCost.toStringAsFixed(0)}',
                        Icons.shopping_cart,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Profit',
                        'Rs. ${_totalProfit.toStringAsFixed(0)}',
                        Icons.trending_up,
                        _totalProfit >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Margin',
                        '${_profitMargin.toStringAsFixed(1)}%',
                        Icons.percent,
                        _profitMargin >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Products List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _productProfits.isEmpty
                    ? const Center(
                        child: Text('No data in selected period'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _productProfits.length,
                        itemBuilder: (context, index) {
                          final entry = _productProfits.entries.toList()[index];
                          final product = entry.value;
                          final profitMargin = product.totalRevenue > 0
                              ? (product.totalProfit / product.totalRevenue) * 100
                              : 0;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: product.totalProfit >= 0
                                    // ignore: deprecated_member_use
                                    ? Colors.green.withOpacity(0.1)
                                    // ignore: deprecated_member_use
                                    : Colors.red.withOpacity(0.1),
                                child: Icon(
                                  product.totalProfit >= 0
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  color: product.totalProfit >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              title: Text(
                                product.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('Sold: ${product.quantitySold} units'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Rs. ${product.totalProfit.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: product.totalProfit >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  Text(
                                    '${profitMargin.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: product.totalProfit >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      _buildDetailRow(
                                        'Revenue',
                                        'Rs. ${product.totalRevenue.toStringAsFixed(0)}',
                                        Colors.blue,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDetailRow(
                                        'Cost',
                                        'Rs. ${product.totalCost.toStringAsFixed(0)}',
                                        Colors.orange,
                                      ),
                                      const Divider(height: 24),
                                      _buildDetailRow(
                                        'Profit',
                                        'Rs. ${product.totalProfit.toStringAsFixed(0)}',
                                        product.totalProfit >= 0
                                            ? Colors.green
                                            : Colors.red,
                                        bold: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        // ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ProductProfit {
  final String productName;
  double totalRevenue;
  double totalCost;
  double totalProfit;
  int quantitySold;

  _ProductProfit({
    required this.productName,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.quantitySold,
  });
}