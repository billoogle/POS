import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Get categories collection reference
  CollectionReference get _categoriesRef => _firestore.collection('categories');

  // Add new category
  Future<Map<String, dynamic>> addCategory({
    required String name,
    required String description,
    required String iconName,
    required String color,
  }) async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final categoryId = _categoriesRef.doc().id;
      final category = Category(
        id: categoryId,
        name: name,
        description: description,
        iconName: iconName,
        color: color,
        createdAt: DateTime.now(),
        userId: _userId!,
      );

      await _categoriesRef.doc(categoryId).set(category.toMap());

      return {'success': true, 'message': 'Category added successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Update category
  Future<Map<String, dynamic>> updateCategory({
    required String categoryId,
    required String name,
    required String description,
    required String iconName,
    required String color,
  }) async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      await _categoriesRef.doc(categoryId).update({
        'name': name,
        'description': description,
        'iconName': iconName,
        'color': color,
      });

      return {'success': true, 'message': 'Category updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Delete category
  Future<Map<String, dynamic>> deleteCategory(String categoryId) async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      await _categoriesRef.doc(categoryId).delete();

      return {'success': true, 'message': 'Category deleted successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Get all categories for current user (Stream)
  Stream<List<Category>> getCategories() {
    if (_userId == null) return Stream.value([]);

    return _categoriesRef
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final categories = snapshot.docs.map((doc) {
        return Category.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
      
      // Sort manually by createdAt descending
      categories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return categories;
    });
  }

  // Get single category
  Future<Category?> getCategory(String categoryId) async {
    try {
      DocumentSnapshot doc = await _categoriesRef.doc(categoryId).get();
      if (doc.exists) {
        return Category.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Search categories
  Stream<List<Category>> searchCategories(String query) {
    if (_userId == null) return Stream.value([]);

    return _categoriesRef
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final categories = snapshot.docs.map((doc) {
        return Category.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

      // Sort by createdAt descending
      categories.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Filter by search query
      if (query.isEmpty) return categories;
      
      return categories.where((category) {
        return category.name.toLowerCase().contains(query.toLowerCase()) ||
            category.description.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }
}