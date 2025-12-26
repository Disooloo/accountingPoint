class Category {
  final String id;
  final String name;
  final String code; // Код категории (например "20", "00", "01")

  Category({
    required this.id,
    required this.name,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      code: json['code'],
    );
  }

  Category copyWith({
    String? id,
    String? name,
    String? code,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
    );
  }

  // Проверка, является ли категория специальной (00 или 01)
  bool get isSpecial => code == '00' || code == '01';
}

