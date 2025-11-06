import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sale_model.dart';

class SaleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference get _salesRef => _firestore.collection('sales');
  CollectionReference get _productsRef => _firestore.collection('products');

  // Generate Invoice Number
  String generateInvoiceNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    return 'INV${timestamp.toString().substring(7)}';
  }

  // Create Sale and Deduct Stock
  Future<Map<String, dynamic>> createSale({
    required List<SaleItem> items,
    required double subtotal,
    required double discount,
    required double totalAmount,
    required String paymentMethod,
  }) async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      if (items.isEmpty) {
        return {'success': false, 'message': 'No items in cart'};
      }

      print('📝 Creating sale...');

      // Check stock availability first
      for (final item in items) {
        final productDoc = await _productsRef.doc(item.productId).get();
        if (!productDoc.exists) {
          return {
            'success': false,
            'message': 'Product ${item.productName} not found'
          };
        }

        final currentStock = productDoc.get('stock') as int;
        if (currentStock < item.quantity) {
          return {
            'success': false,
            'message': '${item.productName} has insufficient stock!\nAvailable: $currentStock, Required: ${item.quantity}'
          };
        }
      }

      // Generate invoice
      final saleId = _salesRef.doc().id;
      final invoiceNumber = generateInvoiceNumber();

      final sale = Sale(
        id: saleId,
        invoiceNumber: invoiceNumber,
        items: items,
        subtotal: subtotal,
        discount: discount,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
        userId: _userId!,
        createdBy: _auth.currentUser!.email ?? 'Unknown',
      );

      // Use batch write for atomic operations
      final batch = _firestore.batch();

      // Add sale document
      batch.set(_salesRef.doc(saleId), sale.toMap());

      print('📦 Deducting stock for ${items.length} products...');

      // Deduct stock for each product
      for (final item in items) {
        final productRef = _productsRef.doc(item.productId);
        final productDoc = await productRef.get();
        
        final currentStock = productDoc.get('stock') as int;
        final newStock = currentStock - item.quantity;

        print('  Product: ${item.productName}');
        print('  Current Stock: $currentStock');
        print('  Selling: ${item.quantity}');
        print('  New Stock: $newStock');

        batch.update(productRef, {'stock': newStock});
      }

      // Commit batch
      await batch.commit();

      print('✅ Sale created successfully: $invoiceNumber');

      return {
        'success': true,
        'message': 'Sale completed successfully',
        'saleId': saleId,
        'invoiceNumber': invoiceNumber,
      };
    } catch (e) {
      print('❌ Error creating sale: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Get all sales
  Stream<List<Sale>> getSales() {
    if (_userId == null) return Stream.value([]);

    return _salesRef
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final sales = snapshot.docs.map((doc) {
        return Sale.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
      
      sales.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sales;
    });
  }

  // Get single sale
  Future<Sale?> getSale(String saleId) async {
    try {
      final doc = await _salesRef.doc(saleId).get();
      if (doc.exists) {
        return Sale.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting sale: $e');
      return null;
    }
  }

  // Search sales
  Stream<List<Sale>> searchSales(String query) {
    if (_userId == null) return Stream.value([]);

    return _salesRef
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final sales = snapshot.docs.map((doc) {
        return Sale.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

      sales.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (query.isEmpty) return sales;
      
      return sales.where((sale) {
        return sale.invoiceNumber.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  // Get today's sales
  Stream<List<Sale>> getTodaySales() {
    if (_userId == null) return Stream.value([]);

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return _salesRef
        .where('userId', isEqualTo: _userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
      final sales = snapshot.docs.map((doc) {
        return Sale.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
      
      sales.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sales;
    });
  }

  // Get sales stats
  Future<Map<String, dynamic>> getSalesStats() async {
    if (_userId == null) return {};

    final salesSnapshot = await _salesRef
        .where('userId', isEqualTo: _userId)
        .get();

    double totalRevenue = 0;
    int totalSales = salesSnapshot.docs.length;

    for (var doc in salesSnapshot.docs) {
      final sale = Sale.fromMap(doc.data() as Map<String, dynamic>);
      totalRevenue += sale.totalAmount;
    }

    // Today's sales
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final todaySalesSnapshot = await _salesRef
        .where('userId', isEqualTo: _userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    double todayRevenue = 0;
    for (var doc in todaySalesSnapshot.docs) {
      final sale = Sale.fromMap(doc.data() as Map<String, dynamic>);
      todayRevenue += sale.totalAmount;
    }

    return {
      'totalRevenue': totalRevenue,
      'totalSales': totalSales,
      'todayRevenue': todayRevenue,
      'todaySales': todaySalesSnapshot.docs.length,
    };
  }
}