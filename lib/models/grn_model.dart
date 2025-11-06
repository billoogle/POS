import 'package:cloud_firestore/cloud_firestore.dart';

// GRN Item (single product in GRN)
class GRNItem {
  final String productId;
  final String productName;
  final String productImage;
  final int quantity;
  final double purchasePrice;
  final double salePrice;
  final double totalAmount;

  GRNItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.purchasePrice,
    required this.salePrice,
    required this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'totalAmount': totalAmount,
    };
  }

  factory GRNItem.fromMap(Map<String, dynamic> map) {
    return GRNItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      quantity: map['quantity'] ?? 0,
      purchasePrice: (map['purchasePrice'] ?? 0).toDouble(),
      salePrice: (map['salePrice'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
    );
  }
}

// GRN (Goods Received Note)
class GRN {
  final String id;
  final String grnNumber;
  final String vendorId;
  final String vendorName;
  final String vendorPhone;
  final List<GRNItem> items;
  final double totalAmount;
  final DateTime createdAt;
  final String userId;
  final String createdBy;

  GRN({
    required this.id,
    required this.grnNumber,
    required this.vendorId,
    required this.vendorName,
    required this.vendorPhone,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    required this.userId,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grnNumber': grnNumber,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'vendorPhone': vendorPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'createdBy': createdBy,
    };
  }

  factory GRN.fromMap(Map<String, dynamic> map) {
    return GRN(
      id: map['id'] ?? '',
      grnNumber: map['grnNumber'] ?? '',
      vendorId: map['vendorId'] ?? '',
      vendorName: map['vendorName'] ?? '',
      vendorPhone: map['vendorPhone'] ?? '',
      items: (map['items'] as List<dynamic>)
          .map((item) => GRNItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
      createdBy: map['createdBy'] ?? '',
    );
  }

  // Get total quantity
  int get totalQuantity {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Get total items count
  int get itemsCount => items.length;
}