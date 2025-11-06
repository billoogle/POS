import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Get products collection reference
  CollectionReference get _productsRef => _firestore.collection('products');

  // Add new product
  Future<Map<String, dynamic>> addProduct({
    required String name,
    required String imageUrl,
    required String barcode,
    required double purchasePrice,
    required double salePrice,
    required int stock,
    required String categoryId,
    required String categoryName,
  }) async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final productId = _productsRef.doc().id;
      final product = Product(
        id: productId,
        name: name,
        imageUrl: imageUrl,
        barcode: barcode,
        purchasePrice: purchasePrice,
        salePrice: salePrice,
        stock: stock,
        categoryId: categoryId,
        categoryName: categoryName,
        createdAt: DateTime.now(),
        userId: _userId!,
      );

      await _productsRef.doc(productId).set(product.toMap());

      return {'success': true, 'message': 'Product added successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Update product
  Future<Map<String, dynamic>> updateProduct({
    required String productId,
    required String name,
    required String imageUrl,
    required String barcode,
    required double purchasePrice,
    required double salePrice,
    required int stock,
    required String categoryId,
    required String categoryName,
  }) async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      await _productsRef.doc(productId).update({
        'name': name,
        'imageUrl': imageUrl,
        'barcode': barcode,
        'purchasePrice': purchasePrice,
        'salePrice': salePrice,
        'stock': stock,
        'categoryId': categoryId,
        'categoryName': categoryName,
      });

      return {'success': true, 'message': 'Product updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Delete product
  Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      await _productsRef.doc(productId).delete();

      return {'success': true, 'message': 'Product deleted successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Update stock
  Future<Map<String, dynamic>> updateStock(String productId, int newStock) async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      await _productsRef.doc(productId).update({'stock': newStock});

      return {'success': true, 'message': 'Stock updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Get all products for current user (Stream)
  Stream<List<Product>> getProducts() {
    if (_userId == null) return Stream.value([]);

    return _productsRef
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
      
      // Sort by createdAt descending
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    });
  }

  // Get products by category
  Stream<List<Product>> getProductsByCategory(String categoryId) {
    if (_userId == null) return Stream.value([]);

    return _productsRef
        .where('userId', isEqualTo: _userId)
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
      
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    });
  }

  // Get single product
  Future<Product?> getProduct(String productId) async {
    try {
      DocumentSnapshot doc = await _productsRef.doc(productId).get();
      if (doc.exists) {
        return Product.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Search products
  Stream<List<Product>> searchProducts(String query) {
    if (_userId == null) return Stream.value([]);

    return _productsRef
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (query.isEmpty) return products;
      
      return products.where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.barcode.toLowerCase().contains(query.toLowerCase()) ||
            product.categoryName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  // Check if barcode already exists
  Future<bool> isBarcodeExists(String barcode, {String? excludeProductId}) async {
    try {
      if (_userId == null) return false;

      final query = await _productsRef
          .where('userId', isEqualTo: _userId)
          .where('barcode', isEqualTo: barcode)
          .get();

      if (excludeProductId != null) {
        return query.docs.any((doc) => doc.id != excludeProductId);
      }

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get low stock products (stock < 10)
  Stream<List<Product>> getLowStockProducts() {
    if (_userId == null) return Stream.value([]);

    return _productsRef
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final products = snapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

      return products.where((product) => product.stock < 10).toList();
    });
  }
}