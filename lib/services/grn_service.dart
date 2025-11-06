import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/grn_model.dart';

class GRNService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference get _grnsRef => _firestore.collection('grns');
  CollectionReference get _productsRef => _firestore.collection('products');

  // Generate GRN Number
  String generateGRNNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    return 'GRN${timestamp.toString().substring(7)}';
  }

  // Create GRN and Update Product Stocks & Prices
  Future<Map<String, dynamic>> createGRN({
    required String vendorId,
    required String vendorName,
    required String vendorPhone,
    required List<GRNItem> items,
    required double totalAmount,
  }) async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      if (items.isEmpty) {
        return {'success': false, 'message': 'No items added to GRN'};
      }

      print('📝 Creating GRN...');

      // Generate GRN
      final grnId = _grnsRef.doc().id;
      final grnNumber = generateGRNNumber();
      
      final grn = GRN(
        id: grnId,
        grnNumber: grnNumber,
        vendorId: vendorId,
        vendorName: vendorName,
        vendorPhone: vendorPhone,
        items: items,
        totalAmount: totalAmount,
        createdAt: DateTime.now(),
        userId: _userId!,
        createdBy: _auth.currentUser!.email ?? 'Unknown',
      );

      // Use batch write for atomic operations
      final batch = _firestore.batch();

      // Add GRN document
      batch.set(_grnsRef.doc(grnId), grn.toMap());

      print('📦 Updating ${items.length} products...');

      // Update each product's stock and prices
      for (final item in items) {
        final productRef = _productsRef.doc(item.productId);
        
        // Get current product data
        final productDoc = await productRef.get();
        if (!productDoc.exists) {
          return {
            'success': false,
            'message': 'Product ${item.productName} not found'
          };
        }

        final currentStock = productDoc.get('stock') as int;
        final newStock = currentStock + item.quantity;

        print('  Product: ${item.productName}');
        print('  Current Stock: $currentStock');
        print('  Adding: ${item.quantity}');
        print('  New Stock: $newStock');

        // Update product
        batch.update(productRef, {
          'stock': newStock,
          'purchasePrice': item.purchasePrice,
          'salePrice': item.salePrice,
        });
      }

      // Commit batch
      await batch.commit();

      print('✅ GRN created successfully: $grnNumber');

      return {
        'success': true,
        'message': 'GRN created successfully',
        'grnId': grnId,
        'grnNumber': grnNumber,
      };
    } catch (e) {
      print('❌ Error creating GRN: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Get all GRNs
  Stream<List<GRN>> getGRNs() {
    if (_userId == null) return Stream.value([]);

    return _grnsRef
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final grns = snapshot.docs.map((doc) {
        return GRN.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
      
      grns.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return grns;
    });
  }

  // Get single GRN
  Future<GRN?> getGRN(String grnId) async {
    try {
      final doc = await _grnsRef.doc(grnId).get();
      if (doc.exists) {
        return GRN.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting GRN: $e');
      return null;
    }
  }

  // Get GRNs by vendor
  Stream<List<GRN>> getGRNsByVendor(String vendorId) {
    if (_userId == null) return Stream.value([]);

    return _grnsRef
        .where('userId', isEqualTo: _userId)
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) {
      final grns = snapshot.docs.map((doc) {
        return GRN.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
      
      grns.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return grns;
    });
  }

  // Search GRNs
  Stream<List<GRN>> searchGRNs(String query) {
    if (_userId == null) return Stream.value([]);

    return _grnsRef
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final grns = snapshot.docs.map((doc) {
        return GRN.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

      grns.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (query.isEmpty) return grns;
      
      return grns.where((grn) {
        return grn.grnNumber.toLowerCase().contains(query.toLowerCase()) ||
            grn.vendorName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  // Delete GRN (Note: This won't revert stock changes)
  Future<Map<String, dynamic>> deleteGRN(String grnId) async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      await _grnsRef.doc(grnId).delete();

      return {
        'success': true,
        'message': 'GRN deleted successfully (Stock not reverted)'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}