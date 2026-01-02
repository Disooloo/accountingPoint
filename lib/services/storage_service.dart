import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inventory.dart';
import '../models/category.dart';
import '../models/category_status.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Инвентаризации
  static List<Inventory> getInventories() {
    final json = _prefs?.getString('inventories') ?? '[]';
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((item) => Inventory.fromJson(item)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Новые сверху
  }

  static Future<void> saveInventories(List<Inventory> inventories) async {
    final json = jsonEncode(inventories.map((i) => i.toJson()).toList());
    await _prefs?.setString('inventories', json);
  }

  // Категории
  static List<Category> getCategories() {
    final json = _prefs?.getString('categories') ?? '[]';
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((item) => Category.fromJson(item)).toList();
  }

  static Future<void> saveCategories(List<Category> categories) async {
    final json = jsonEncode(categories.map((c) => c.toJson()).toList());
    await _prefs?.setString('categories', json);
  }

  // Статусы категорий для инвентаризаций
  static Map<String, List<CategoryStatus>> getCategoryStatuses() {
    final json = _prefs?.getString('category_statuses') ?? '{}';
    final Map<String, dynamic> decoded = jsonDecode(json);
    return decoded.map((key, value) => MapEntry(
          key,
          (value as List).map((item) => CategoryStatus.fromJson(item)).toList(),
        ));
  }

  static Future<void> saveCategoryStatuses(
      Map<String, List<CategoryStatus>> statuses) async {
    final json = jsonEncode(statuses.map((key, value) => MapEntry(
          key,
          value.map((s) => s.toJson()).toList(),
        )));
    await _prefs?.setString('category_statuses', json);
  }
}

