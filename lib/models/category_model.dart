import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String color;
  final DateTime createdAt;
  final String userId;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.color,
    required this.createdAt,
    required this.userId,
  });

  // Convert Category to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
    };
  }

  // Create Category from Firestore document
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      iconName: map['iconName'] ?? 'category',
      color: map['color'] ?? '#2563EB',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
    );
  }

  // Copy with method for updates
  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    String? color,
    DateTime? createdAt,
    String? userId,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}