import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/grn_model.dart';

class PDFService {
  // Generate GRN PDF
  Future<pw.Document> generateGRNPDF(GRN grn, String businessName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader(grn, businessName),
          pw.SizedBox(height: 20),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 20),

          // Vendor Info
          _buildVendorInfo(grn),
          pw.SizedBox(height: 20),

          // Items Table
          _buildItemsTable(grn),
          pw.SizedBox(height: 20),

          // Total
          _buildTotal(grn),
          pw.SizedBox(height: 30),

          // Footer
          _buildFooter(),
        ],
      ),
    );

    return pdf;
  }

  // Header Section
  pw.Widget _buildHeader(GRN grn, String businessName) {
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
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Goods Received Note',
              style: const pw.TextStyle(
                fontSize: 16,
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
                color: PdfColors.purple100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                grn.grnNumber,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.purple800,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(grn.createdAt),
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

  // Vendor Info Section
  pw.Widget _buildVendorInfo(GRN grn) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Vendor Information',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Text(
                'Name: ',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                grn.vendorName,
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Text(
                'Phone: ',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                grn.vendorPhone,
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Items Table
  pw.Widget _buildItemsTable(GRN grn) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Product', isHeader: true),
            _buildTableCell('Qty', isHeader: true, align: pw.TextAlign.center),
            _buildTableCell('Purchase Price', isHeader: true, align: pw.TextAlign.right),
            _buildTableCell('Sale Price', isHeader: true, align: pw.TextAlign.right),
            _buildTableCell('Total', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        // Data Rows
        ...grn.items.map((item) {
          return pw.TableRow(
            children: [
              _buildTableCell(item.productName),
              _buildTableCell(item.quantity.toString(), align: pw.TextAlign.center),
              _buildTableCell('Rs. ${item.purchasePrice.toStringAsFixed(0)}', align: pw.TextAlign.right),
              _buildTableCell('Rs. ${item.salePrice.toStringAsFixed(0)}', align: pw.TextAlign.right),
              _buildTableCell('Rs. ${item.totalAmount.toStringAsFixed(0)}', align: pw.TextAlign.right),
            ],
          );
        }),
      ],
    );
  }

  // Table Cell
  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  // Total Section
  pw.Widget _buildTotal(GRN grn) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 250,
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.purple50,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.purple200, width: 2),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Items:',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  grn.itemsCount.toString(),
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Quantity:',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  grn.totalQuantity.toString(),
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.purple200),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Amount:',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Rs. ${grn.totalAmount.toStringAsFixed(0)}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Footer
  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Received By',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  width: 150,
                  height: 1,
                  color: PdfColors.grey400,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Signature',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Authorized By',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  width: 150,
                  height: 1,
                  color: PdfColors.grey400,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Signature',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'This is a computer-generated document',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  // Print GRN
  Future<void> printGRN(GRN grn, String businessName) async {
    final pdf = await generateGRNPDF(grn, businessName);
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  // Save PDF to device
  Future<String?> saveGRNPDF(GRN grn, String businessName) async {
    try {
      final pdf = await generateGRNPDF(grn, businessName);
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/GRN_${grn.grnNumber}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      print('Error saving PDF: $e');
      return null;
    }
  }

  // Share PDF
  Future<void> shareGRN(GRN grn, String businessName) async {
    final pdf = await generateGRNPDF(grn, businessName);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'GRN_${grn.grnNumber}.pdf',
    );
  }
}