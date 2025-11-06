import 'package:cloud_firestore/cloud_firestore.dart';

class Vendor {
  final String id;
  final String name;
  final String phoneNumber;
  final String address;
  final DateTime createdAt;
  final String userId;

  Vendor({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
    required this.createdAt,
    required this.userId,
  });

  // Convert Vendor to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
    };
  }

  // Create Vendor from Firestore document
  factory Vendor.fromMap(Map<String, dynamic> map) {
    return Vendor(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
    );
  }

  // Copy with method for updates
  Vendor copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? address,
    DateTime? createdAt,
    String? userId,
  }) {
    return Vendor(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}