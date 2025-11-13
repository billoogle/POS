// lib/services/sync_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../helpers/database_helper.dart';
import '../helpers/connectivity_manager.dart';
import '../models/sale_model.dart';
import '../models/grn_model.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isSyncing = false;

  // ==================== MAIN SYNC FUNCTION ====================
  
  Future<Map<String, dynamic>> syncAll() async {
    if (_isSyncing) {
      print('⏳ Sync already in progress...');
      return {'success': false, 'message': 'Sync in progress'};
    }

    if (!ConnectivityManager.currentStatus) {
      print('📴 No internet connection. Sync skipped.');
      return {'success': false, 'message': 'No internet connection'};
    }

    _isSyncing = true;
    ConnectivityManager.isSyncing.value = true;
    
    print('🔄 Starting full sync...');
    
    int syncedCount = 0;

    try {
      // Sync sales
      final salesResult = await _syncSales();
      syncedCount += salesResult['count'] as int;

      // Sync GRNs
      final grnsResult = await _syncGRNs();
      syncedCount += grnsResult['count'] as int;

      // Pull latest data from Firebase to local
      await _pullDataFromFirebase();

      _isSyncing = false;
      ConnectivityManager.isSyncing.value = false;
      
      print('✅ Sync completed! Total items synced: $syncedCount');

      return {
        'success': true,
        'message': 'Sync completed successfully',
        'count': syncedCount
      };
    } catch (e) {
      _isSyncing = false;
      ConnectivityManager.isSyncing.value = false;
      
      print('❌ Sync error: $e');
      return {
        'success': false,
        'message': 'Sync failed: ${e.toString()}'
      };
    }
  }

  // ==================== SYNC SALES ====================
  
  Future<Map<String, dynamic>> _syncSales() async {
    try {
      final unsyncedSales = await _dbHelper.getUnsyncedSales();
      
      if (unsyncedSales.isEmpty) {
        print('ℹ️ No unsynced sales found');
        return {'success': true, 'count': 0};
      }

      print('📤 Syncing ${unsyncedSales.length} sales...');

      int successCount = 0;

      for (final saleMap in unsyncedSales) {
        try {
          // Parse items from JSON string
          final items = (jsonDecode(saleMap['items']) as List)
              .map((item) => SaleItem.fromMap(item as Map<String, dynamic>))
              .toList();

          final sale = Sale(
            id: saleMap['id'],
            invoiceNumber: saleMap['invoiceNumber'],
            items: items,
            subtotal: saleMap['subtotal'],
            discount: saleMap['discount'],
            totalAmount: saleMap['totalAmount'],
            paymentMethod: saleMap['paymentMethod'],
            createdAt: DateTime.parse(saleMap['createdAt']),
            userId: saleMap['userId'],
            createdBy: saleMap['createdBy'],
          );

          // Upload to Firebase
          await _firestore
              .collection('sales')
              .doc(sale.id)
              .set(sale.toMap());

          // Update stock in Firebase
          await _updateStockInFirebase(items, isGRN: false);

          // Mark as synced in local DB
          await _dbHelper.updateSaleSyncStatus(sale.id, 1);
          
          successCount++;
          print('✅ Synced sale: ${sale.invoiceNumber}');
        } catch (e) {
          print('❌ Failed to sync sale ${saleMap['id']}: $e');
        }
      }

      print('📤 Sales sync complete: $successCount/${unsyncedSales.length}');
      return {'success': true, 'count': successCount};
    } catch (e) {
      print('❌ Sales sync error: $e');
      return {'success': false, 'count': 0};
    }
  }

  // ==================== SYNC GRNS ====================
  
  Future<Map<String, dynamic>> _syncGRNs() async {
    try {
      final unsyncedGRNs = await _dbHelper.getUnsyncedGRNs();
      
      if (unsyncedGRNs.isEmpty) {
        print('ℹ️ No unsynced GRNs found');
        return {'success': true, 'count': 0};
      }

      print('📤 Syncing ${unsyncedGRNs.length} GRNs...');

      int successCount = 0;

      for (final grnMap in unsyncedGRNs) {
        try {
          // Parse items from JSON string
          final items = (jsonDecode(grnMap['items']) as List)
              .map((item) => GRNItem.fromMap(item as Map<String, dynamic>))
              .toList();

          final grn = GRN(
            id: grnMap['id'],
            grnNumber: grnMap['grnNumber'],
            vendorId: grnMap['vendorId'],
            vendorName: grnMap['vendorName'],
            vendorPhone: grnMap['vendorPhone'],
            items: items,
            totalAmount: grnMap['totalAmount'],
            createdAt: DateTime.parse(grnMap['createdAt']),
            userId: grnMap['userId'],
            createdBy: grnMap['createdBy'],
          );

          // Upload to Firebase
          await _firestore
              .collection('grns')
              .doc(grn.id)
              .set(grn.toMap());

          // Update stock in Firebase
          await _updateStockInFirebase(items, isGRN: true);

          // Mark as synced in local DB
          await _dbHelper.updateGRNSyncStatus(grn.id, 1);
          
          successCount++;
          print('✅ Synced GRN: ${grn.grnNumber}');
        } catch (e) {
          print('❌ Failed to sync GRN ${grnMap['id']}: $e');
        }
      }

      print('📤 GRNs sync complete: $successCount/${unsyncedGRNs.length}');
      return {'success': true, 'count': successCount};
    } catch (e) {
      print('❌ GRNs sync error: $e');
      return {'success': false, 'count': 0};
    }
  }

  // ==================== UPDATE STOCK IN FIREBASE ====================
  
  Future<void> _updateStockInFirebase(List<dynamic> items, {required bool isGRN}) async {
    final batch = _firestore.batch();

    for (final item in items) {
      final productId = isGRN 
          ? (item as GRNItem).productId 
          : (item as SaleItem).productId;
      final quantity = isGRN 
          ? (item as GRNItem).quantity 
          : (item as SaleItem).quantity;

      final productRef = _firestore.collection('products').doc(productId);
      
      // Get current stock
      final productDoc = await productRef.get();
      if (productDoc.exists) {
        final currentStock = productDoc.get('stock') as int;
        final newStock = isGRN 
            ? currentStock + quantity 
            : currentStock - quantity;

        batch.update(productRef, {'stock': newStock});

        // Update prices if GRN
        if (isGRN) {
          final grnItem = item as GRNItem;
          batch.update(productRef, {
            'purchasePrice': grnItem.purchasePrice,
            'salePrice': grnItem.salePrice,
          });
        }
      }
    }

    await batch.commit();
  }

  // ==================== PULL DATA FROM FIREBASE ====================
  
  Future<void> _pullDataFromFirebase() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    print('📥 Pulling latest data from Firebase...');

    try {
      // Pull products
      final productsSnapshot = await _firestore
          .collection('products')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in productsSnapshot.docs) {
        final data = doc.data();
        data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        data['syncStatus'] = 1; // Already synced
        await _dbHelper.insertProduct(data);
      }

      print('📥 Pulled ${productsSnapshot.docs.length} products');

      // Pull categories
      final categoriesSnapshot = await _firestore
          .collection('categories')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in categoriesSnapshot.docs) {
        final data = doc.data();
        data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        data['syncStatus'] = 1;
        await _dbHelper.insertCategory(data);
      }

      print('📥 Pulled ${categoriesSnapshot.docs.length} categories');

      // Pull vendors
      final vendorsSnapshot = await _firestore
          .collection('vendors')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in vendorsSnapshot.docs) {
        final data = doc.data();
        data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        data['syncStatus'] = 1;
        await _dbHelper.insertVendor(data);
      }

      print('📥 Pulled ${vendorsSnapshot.docs.length} vendors');

      print('✅ Data pull completed');
    } catch (e) {
      print('❌ Pull data error: $e');
    }
  }

  // ==================== FORCE SYNC ====================
  
  Future<Map<String, dynamic>> forceSync() async {
    print('🔄 Force sync initiated...');
    return await syncAll();
  }

  // ==================== CHECK PENDING SYNCS ====================
  
  Future<int> getPendingSyncCount() async {
    final unsyncedSales = await _dbHelper.getUnsyncedSales();
    final unsyncedGRNs = await _dbHelper.getUnsyncedGRNs();
    return unsyncedSales.length + unsyncedGRNs.length;
  }
}