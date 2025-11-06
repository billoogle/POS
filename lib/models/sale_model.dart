import 'package:cloud_firestore/cloud_firestore.dart';

// Sale Item (single product in sale)
class SaleItem {
  final String productId;
  final String productName;
  final String productImage;
  final int quantity;
  final double salePrice;
  final double totalAmount;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.salePrice,
    required this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'quantity': quantity,
      'salePrice': salePrice,
      'totalAmount': totalAmount,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      quantity: map['quantity'] ?? 0,
      salePrice: (map['salePrice'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
    );
  }
}

// Sale Invoice
class Sale {
  final String id;
  final String invoiceNumber;
  final List<SaleItem> items;
  final double subtotal;
  final double discount;
  final double totalAmount;
  final String paymentMethod;
  final DateTime createdAt;
  final String userId;
  final String createdBy;

  Sale({
    required this.id,
    required this.invoiceNumber,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.createdAt,
    required this.userId,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'createdBy': createdBy,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      items: (map['items'] as List<dynamic>)
          .map((item) => SaleItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'Cash',
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