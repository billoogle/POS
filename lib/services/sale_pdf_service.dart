// sale_pdf_service.dart - Update all price displays:

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/sale_model.dart';
import '../helpers/currency_manager.dart'; // Import

class SalePdfService {
  // Get current currency symbol
  String get _currency => CurrencyManager.currentCurrency;

  // Format amount with current currency
  String _formatAmount(double amount, {int decimals = 0}) {
    return CurrencyManager.format(amount, decimals: decimals);
  }

  // Generate Sale Invoice PDF
  Future<pw.Document> generateInvoicePdf(Sale sale, String businessName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader(businessName, sale),
          pw.SizedBox(height: 20),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 20),

          // Items Table
          _buildItemsTable(sale),
          pw.SizedBox(height: 20),

          // Total Section
          _buildTotalSection(sale),
          pw.SizedBox(height: 30),

          // Footer
          _buildFooter(sale),
        ],
      ),
    );

    return pdf;
  }

  // Header Section (no changes needed)
  pw.Widget _buildHeader(String businessName, Sale sale) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              businessName,
              style: pw.TextStyle(
                fontSize: 26,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'SALES INVOICE',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                sale.invoiceNumber,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange900,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Date: ${DateFormat('dd MMM yyyy').format(sale.createdAt)}',
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              'Time: ${DateFormat('hh:mm a').format(sale.createdAt)}',
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Items Table Section - UPDATED with dynamic currency
  pw.Widget _buildItemsTable(Sale sale) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey200,
          ),
          children: [
            _buildTableHeader('#'),
            _buildTableHeader('Product Name'),
            _buildTableHeader('Qty'),
            _buildTableHeader('Price'),
            _buildTableHeader('Total'),
          ],
        ),
        // Data Rows - UPDATED
        ...sale.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell('${index + 1}'),
              _buildTableCell(item.productName, align: pw.TextAlign.left),
              _buildTableCell('${item.quantity}'),
              _buildTableCell(_formatAmount(item.salePrice)), // Dynamic
              _buildTableCell(
                _formatAmount(item.totalAmount), // Dynamic
                bold: true,
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool bold = false, pw.TextAlign? align}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align ?? pw.TextAlign.center,
      ),
    );
  }

  // Total Section - UPDATED with dynamic currency
  pw.Widget _buildTotalSection(Sale sale) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _buildTotalRow('Subtotal', sale.subtotal),
          if (sale.discount > 0) ...[
            pw.SizedBox(height: 8),
            _buildTotalRow('Discount', -sale.discount, color: PdfColors.red),
          ],
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TOTAL',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                _formatAmount(sale.totalAmount), // Dynamic
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: pw.BoxDecoration(
              color: PdfColors.green100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'Payment Method: ${sale.paymentMethod}',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED with dynamic currency
  pw.Widget _buildTotalRow(String label, double amount, {PdfColor? color}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 14,
            color: PdfColors.grey700,
          ),
        ),
        pw.Text(
          _formatAmount(amount.abs()), // Dynamic
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  // Footer Section (no changes)
  pw.Widget _buildFooter(Sale sale) {
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Items: ${sale.itemsCount} | Quantity: ${sale.totalQuantity}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Cashier: ${sale.createdBy}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
            pw.Text(
              'Printed: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Print Invoice
  Future<void> printInvoice(Sale sale, String businessName) async {
    final pdf = await generateInvoicePdf(sale, businessName);
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Invoice_${sale.invoiceNumber}.pdf',
    );
  }

  // Share Invoice as PDF
  Future<void> shareInvoice(Sale sale, String businessName) async {
    final pdf = await generateInvoicePdf(sale, businessName);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Invoice_${sale.invoiceNumber}.pdf',
    );
  }

  // Save Invoice to device
  Future<String> saveInvoice(Sale sale, String businessName) async {
    final pdf = await generateInvoicePdf(sale, businessName);
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/Invoice_${sale.invoiceNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}