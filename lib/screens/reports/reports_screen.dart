import 'package:flutter/material.dart';
import 'package:pos/helpers/currency_manager.dart';
import '../../services/sale_service.dart';
import 'sales_report_screen.dart';
import 'purchase_report_screen.dart';
import 'profit_loss_report_screen.dart';
import 'category_report_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final SaleService _saleService = SaleService();

  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final salesStats = await _saleService.getSalesStats();
    
    setState(() {
      _stats = salesStats;
    });
  }

  @override
      Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Reports & Analytics'),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ValueListenableBuilder<String>(
        valueListenable: CurrencyManager.currencySymbol,
        builder: (context, currency, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Sales',
                      '${_stats['totalSales'] ?? 0}',
                      Icons.shopping_cart,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Revenue',
                      CurrencyManager.format(_stats['totalRevenue'] ?? 0.0), // Dynamic
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Today Sales',
                      '${_stats['todaySales'] ?? 0}',
                      Icons.today,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Today Revenue',
                      CurrencyManager.format(_stats['todayRevenue'] ?? 0.0), // Dynamic
                      Icons.payments,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Reports Section
              const Text(
                'Reports',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Report Cards (no changes needed - they navigate to detail screens)
              _buildReportCard(
                title: 'Sales Report',
                subtitle: 'View sales by date range',
                icon: Icons.receipt_long,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SalesReportScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildReportCard(
                title: 'Purchase Report',
                subtitle: 'View GRN & purchases',
                icon: Icons.shopping_bag,
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PurchaseReportScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildReportCard(
                title: 'Profit & Loss',
                subtitle: 'View profit analysis',
                icon: Icons.trending_up,
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfitLossReportScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildReportCard(
                title: 'Category Report',
                subtitle: 'Category-wise sales',
                icon: Icons.category,
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoryReportScreen(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    ),
  );
}

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}