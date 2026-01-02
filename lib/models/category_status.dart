enum CategoryState {
  notStarted, // Не начата
  started,    // Начата
  completed,  // Выполнена
}

class CategoryStatus {
  final String categoryId;
  CategoryState state;

  CategoryStatus({
    required this.categoryId,
    this.state = CategoryState.notStarted,
  });

  bool get isCompleted => state == CategoryState.completed;
  bool get isStarted => state == CategoryState.started;
  bool get isNotStarted => state == CategoryState.notStarted;

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'state': state.name, // Сохраняем имя enum
    };
  }

  factory CategoryStatus.fromJson(Map<String, dynamic> json) {
    // Поддержка старого формата для обратной совместимости
    if (json.containsKey('isCompleted')) {
      return CategoryStatus(
        categoryId: json['categoryId'],
        state: json['isCompleted'] == true 
            ? CategoryState.completed 
            : CategoryState.notStarted,
      );
    }
    // Новый формат
    return CategoryStatus(
      categoryId: json['categoryId'],
      state: CategoryState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => CategoryState.notStarted,
      ),
    );
  } 

  CategoryStatus copyWith({
    String? categoryId,
    CategoryState? state,
  }) {
    return CategoryStatus(
      categoryId: categoryId ?? this.categoryId,
      state: state ?? this.state,
    );
  }
}

