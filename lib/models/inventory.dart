import 'package:intl/intl.dart';

class Inventory {
  final String id;
  final String name;
  final DateTime createdAt;
  DateTime? completedAt;
  final List<String> categoryIds;

  Inventory({
    required this.id,
    required this.name,
    required this.createdAt,
    this.completedAt,
    required this.categoryIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'categoryIds': categoryIds,
    };
  }

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      categoryIds: List<String>.from(json['categoryIds']),
    );
  }

  Inventory copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? completedAt,
    List<String>? categoryIds,
  }) {
    return Inventory(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      categoryIds: categoryIds ?? this.categoryIds,
    );
  }
}

