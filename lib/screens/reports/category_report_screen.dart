import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/sale_model.dart';
import '../../services/auth_service.dart';
import '../../services/reports_pdf_service.dart';

class CategoryReportScreen extends StatefulWidget {
  const CategoryReportScreen({super.key});

  @override
  State<CategoryReportScreen> createState() => _CategoryReportScreenState();
}

class _CategoryReportScreenState extends State<CategoryReportScreen> {
  final AuthService _authService = AuthService();
  final ReportsPdfService _pdfService = ReportsPdfService();
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  Map<String, _CategoryData> _categoryData = {};
  
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

    // Get product categories
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('userId', isEqualTo: userId)
        .get();

    final productCategories = <String, String>{};
    for (final doc in productsSnapshot.docs) {
      final data = doc.data();
      productCategories[data['id']] = data['categoryName'] ?? 'Uncategorized';
    }

    // Calculate category-wise sales
    final categoryData = <String, _CategoryData>{};
    
    for (final sale in sales) {
      for (final item in sale.items) {
        final categoryName = productCategories[item.productId] ?? 'Uncategorized';
        
        if (categoryData.containsKey(categoryName)) {
          categoryData[categoryName]!.totalRevenue += item.totalAmount;
          categoryData[categoryName]!.totalQuantity += item.quantity;
          categoryData[categoryName]!.itemCount += 1;
        } else {
          categoryData[categoryName] = _CategoryData(
            categoryName: categoryName,
            totalRevenue: item.totalAmount,
            totalQuantity: item.quantity,
            itemCount: 1,
          );
        }
      }
    }

    setState(() {
      _categoryData = categoryData;
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
    return _categoryData.values.fold(0.0, (sum, cat) => sum + cat.totalRevenue);
  }

  int get _totalQuantity {
    // ignore: avoid_types_as_parameter_names
    return _categoryData.values.fold(0, (sum, cat) => sum + cat.totalQuantity);
  }

  Future<void> _exportPDF() async {
    final sortedCategories = _categoryData.entries.toList()
      ..sort((a, b) => b.value.totalRevenue.compareTo(a.value.totalRevenue));

    final categoryList = sortedCategories.map((entry) => {
      'name': entry.value.categoryName,
      'quantity': entry.value.totalQuantity.toString(),
      'revenue': entry.value.totalRevenue.toStringAsFixed(0),
    }).toList();

    await _pdfService.generateCategoryReport(
      businessName: _businessName,
      startDate: _startDate,
      endDate: _endDate,
      totalCategories: _categoryData.length,
      totalQuantity: _totalQuantity,
      totalRevenue: _totalRevenue,
      categoryData: categoryList,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _categoryData.isEmpty ? null : _exportPDF,
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
                        'Categories',
                        '${_categoryData.length}',
                        Icons.category,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Items Sold',
                        '$_totalQuantity',
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

          // Categories List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _categoryData.isEmpty
                    ? const Center(
                        child: Text('No data in selected period'),
                      )
                    : Column(
                        children: [
                          // Chart/Visual Representation
                          Container(
                            height: 200,
                            padding: const EdgeInsets.all(16),
                            color: Colors.white,
                            child: _buildCategoryChart(),
                          ),
                          const Divider(height: 1),
                          // List
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _categoryData.length,
                              itemBuilder: (context, index) {
                                final entry = _categoryData.entries.toList()[index];
                                final category = entry.value;
                                final percentage = _totalRevenue > 0
                                    ? (category.totalRevenue / _totalRevenue) * 100
                                    : 0;
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                // ignore: deprecated_member_use
                                                color: _getColorForIndex(index).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.category,
                                                color: _getColorForIndex(index),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    category.categoryName,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${category.itemCount} products',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '${percentage.toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: _getColorForIndex(index),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildInfoChip(
                                                'Qty: ${category.totalQuantity}',
                                                Icons.shopping_bag,
                                                Colors.blue,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildInfoChip(
                                                'Rs. ${category.totalRevenue.toStringAsFixed(0)}',
                                                Icons.attach_money,
                                                Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
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
        // ignore: deprecated_member_use
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

  Widget _buildCategoryChart() {
    final sortedData = _categoryData.entries.toList()
      ..sort((a, b) => b.value.totalRevenue.compareTo(a.value.totalRevenue));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revenue Distribution',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: sortedData.asMap().entries.map((entry) {
              final index = entry.key;
              final categoryEntry = entry.value;
              final percentage = _totalRevenue > 0
                  ? (categoryEntry.value.totalRevenue / _totalRevenue)
                  : 0;
              
              return Expanded(
                flex: (percentage * 100).round(),
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: _getColorForIndex(index),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: percentage > 0.05
                        ? Text(
                            '${(percentage * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }
}

class _CategoryData {
  final String categoryName;
  double totalRevenue;
  int totalQuantity;
  int itemCount;

  _CategoryData({
    required this.categoryName,
    required this.totalRevenue,
    required this.totalQuantity,
    required this.itemCount,
  });
}