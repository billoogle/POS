import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String imageUrl;
  final String barcode;
  final double purchasePrice;
  final double salePrice;
  final int stock;
  final String categoryId;
  final String categoryName;
  final DateTime createdAt;
  final String userId;

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.barcode,
    required this.purchasePrice,
    required this.salePrice,
    required this.stock,
    required this.categoryId,
    required this.categoryName,
    required this.createdAt,
    required this.userId,
  });

  // Convert Product to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'barcode': barcode,
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'stock': stock,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
    };
  }

  // Create Product from Firestore document
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      barcode: map['barcode'] ?? '',
      purchasePrice: (map['purchasePrice'] ?? 0).toDouble(),
      salePrice: (map['salePrice'] ?? 0).toDouble(),
      stock: map['stock'] ?? 0,
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
    );
  }

  // Calculate profit margin
  double get profitMargin {
    if (purchasePrice == 0) return 0;
    return ((salePrice - purchasePrice) / purchasePrice) * 100;
  }

  // Calculate profit amount
  double get profitAmount {
    return salePrice - purchasePrice;
  }

  // Copy with method for updates
  Product copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? barcode,
    double? purchasePrice,
    double? salePrice,
    int? stock,
    String? categoryId,
    String? categoryName,
    DateTime? createdAt,
    String? userId,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      stock: stock ?? this.stock,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}