class CategoryStatus {
  final String categoryId;
  bool isCompleted;

  CategoryStatus({
    required this.categoryId,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'isCompleted': isCompleted,
    };
  }

  factory CategoryStatus.fromJson(Map<String, dynamic> json) {
    return CategoryStatus(
      categoryId: json['categoryId'],
      isCompleted: json['isCompleted'] ?? false,
    );
  } 

  CategoryStatus copyWith({
    String? categoryId,
    bool? isCompleted,
  }) {
    return CategoryStatus(
      categoryId: categoryId ?? this.categoryId,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

