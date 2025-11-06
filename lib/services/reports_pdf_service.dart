import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReportsPdfService {
  // ==================== SALES REPORT ====================
  Future<void> generateSalesReport({
    required String businessName,
    required DateTime startDate,
    required DateTime endDate,
    required int totalSales,
    required int totalItems,
    required double totalRevenue,
    required List<Map<String, dynamic>> topProducts,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildReportHeader(
            businessName,
            'Sales Report',
            startDate,
            endDate,
          ),
          pw.SizedBox(height: 20),
          
          // Summary
          _buildSummarySection([
            {'label': 'Total Sales', 'value': '$totalSales'},
            {'label': 'Items Sold', 'value': '$totalItems'},
            {'label': 'Total Revenue', 'value': 'Rs. ${totalRevenue.toStringAsFixed(0)}'},
          ]),
          pw.SizedBox(height: 20),

          // Products Table
          pw.Text(
            'Top Selling Products',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildProductsTable(topProducts),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _buildProductsTable(List<Map<String, dynamic>> products) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('#', isHeader: true),
            _buildTableCell('Product', isHeader: true),
            _buildTableCell('Quantity', isHeader: true),
            _buildTableCell('Revenue', isHeader: true),
          ],
        ),
        ...products.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell('${index + 1}'),
              _buildTableCell('${product['name']}', align: pw.TextAlign.left),
              _buildTableCell('${product['quantity']}'),
              _buildTableCell('Rs. ${product['amount']}'),
            ],
          );
        }).toList(),
      ],
    );
  }

  // ==================== PURCHASE REPORT ====================
  Future<void> generatePurchaseReport({
    required String businessName,
    required DateTime startDate,
    required DateTime endDate,
    required int totalGRNs,
    required int totalItems,
    required double totalPurchase,
    required List<Map<String, dynamic>> topVendors,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildReportHeader(
            businessName,
            'Purchase Report',
            startDate,
            endDate,
          ),
          pw.SizedBox(height: 20),
          
          // Summary
          _buildSummarySection([
            {'label': 'Total GRNs', 'value': '$totalGRNs'},
            {'label': 'Items Purchased', 'value': '$totalItems'},
            {'label': 'Total Amount', 'value': 'Rs. ${totalPurchase.toStringAsFixed(0)}'},
          ]),
          pw.SizedBox(height: 20),

          // Vendor Table
          pw.Text(
            'Purchase by Vendor',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildVendorTable(topVendors),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _buildVendorTable(List<Map<String, dynamic>> vendors) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('#', isHeader: true),
            _buildTableCell('Vendor', isHeader: true),
            _buildTableCell('GRNs', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        ...vendors.asMap().entries.map((entry) {
          final index = entry.key;
          final vendor = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell('${index + 1}'),
              _buildTableCell('${vendor['name']}', align: pw.TextAlign.left),
              _buildTableCell('${vendor['count']}'),
              _buildTableCell('Rs. ${vendor['amount']}'),
            ],
          );
        }).toList(),
      ],
    );
  }

  // ==================== PROFIT & LOSS REPORT ====================
  Future<void> generateProfitLossReport({
    required String businessName,
    required DateTime startDate,
    required DateTime endDate,
    required double totalRevenue,
    required double totalCost,
    required double totalProfit,
    required double profitMargin,
    required List<Map<String, dynamic>> productProfits,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildReportHeader(
            businessName,
            'Profit & Loss Report',
            startDate,
            endDate,
          ),
          pw.SizedBox(height: 20),
          
          // Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                _buildProfitRow('Total Revenue', totalRevenue, PdfColors.blue),
                pw.SizedBox(height: 8),
                _buildProfitRow('Total Cost', totalCost, PdfColors.orange),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 8),
                _buildProfitRow(
                  'Net Profit',
                  totalProfit,
                  totalProfit >= 0 ? PdfColors.green : PdfColors.red,
                  bold: true,
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Profit Margin',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${profitMargin.toStringAsFixed(1)}%',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: profitMargin >= 0 ? PdfColors.green : PdfColors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Products Table
          pw.Text(
            'Product-wise Profit',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildProfitTable(productProfits),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _buildProfitRow(String label, double amount, PdfColor color, {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          'Rs. ${amount.toStringAsFixed(0)}',
          style: pw.TextStyle(
            fontSize: bold ? 18 : 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildProfitTable(List<Map<String, dynamic>> products) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Product', isHeader: true),
            _buildTableCell('Qty', isHeader: true),
            _buildTableCell('Revenue', isHeader: true),
            _buildTableCell('Cost', isHeader: true),
            _buildTableCell('Profit', isHeader: true),
          ],
        ),
        ...products.map((product) {
          // Safe parsing
          final profitStr = product['profit']?.toString() ?? '0';
          final profit = double.tryParse(profitStr) ?? 0.0;
          
          return pw.TableRow(
            children: [
              _buildTableCell('${product['name']}', align: pw.TextAlign.left),
              _buildTableCell('${product['quantity']}'),
              _buildTableCell('Rs. ${product['revenue']}'),
              _buildTableCell('Rs. ${product['cost']}'),
              _buildTableCell(
                'Rs. ${product['profit']}',
                color: profit >= 0 ? PdfColors.green : PdfColors.red,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  // ==================== CATEGORY REPORT ====================
  Future<void> generateCategoryReport({
    required String businessName,
    required DateTime startDate,
    required DateTime endDate,
    required int totalCategories,
    required int totalQuantity,
    required double totalRevenue,
    required List<Map<String, dynamic>> categoryData,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildReportHeader(
            businessName,
            'Category Report',
            startDate,
            endDate,
          ),
          pw.SizedBox(height: 20),
          
          // Summary
          _buildSummarySection([
            {'label': 'Categories', 'value': '$totalCategories'},
            {'label': 'Items Sold', 'value': '$totalQuantity'},
            {'label': 'Total Revenue', 'value': 'Rs. ${totalRevenue.toStringAsFixed(0)}'},
          ]),
          pw.SizedBox(height: 20),

          // Category Table
          _buildCategoryTable(categoryData, totalRevenue),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _buildCategoryTable(List<Map<String, dynamic>> categories, double totalRevenue) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('#', isHeader: true),
            _buildTableCell('Category', isHeader: true),
            _buildTableCell('Quantity', isHeader: true),
            _buildTableCell('Revenue', isHeader: true),
            _buildTableCell('%', isHeader: true),
          ],
        ),
        ...categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          
          // Safe parsing
          final revenueStr = category['revenue']?.toString() ?? '0';
          final revenue = double.tryParse(revenueStr) ?? 0.0;
          final percentage = totalRevenue > 0 ? (revenue / totalRevenue) * 100 : 0;
          
          return pw.TableRow(
            children: [
              _buildTableCell('${index + 1}'),
              _buildTableCell('${category['name']}', align: pw.TextAlign.left),
              _buildTableCell('${category['quantity']}'),
              _buildTableCell('Rs. ${category['revenue']}'),
              _buildTableCell('${percentage.toStringAsFixed(1)}%'),
            ],
          );
        }).toList(),
      ],
    );
  }

  // ==================== COMMON WIDGETS ====================
  pw.Widget _buildReportHeader(
    String businessName,
    String reportTitle,
    DateTime startDate,
    DateTime endDate,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          businessName,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              reportTitle,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Period:',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  '${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  pw.Widget _buildSummarySection(List<Map<String, String>> items) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: items.map((item) {
          return pw.Column(
            children: [
              pw.Text(
                item['value']!,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                item['label']!,
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.center,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
        textAlign: align,
      ),
    );
  }
}