import 'dart:convert';
import '../models/inventory.dart';
import '../models/category.dart';
import '../models/category_status.dart';
import 'storage_service.dart';

class ExportService {
  // Экспорт всех данных
  static Map<String, dynamic> exportAll() {
    final inventories = StorageService.getInventories();
    final categories = StorageService.getCategories();
    final statuses = StorageService.getCategoryStatuses();

    return {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'inventories': inventories.map((i) => i.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'categoryStatuses': statuses.map((key, value) => MapEntry(
            key,
            value.map((s) => s.toJson()).toList(),
          )),
    };
  }

  // Экспорт только категорий
  static Map<String, dynamic> exportCategories() {
    final categories = StorageService.getCategories();

    return {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'type': 'categories',
      'categories': categories.map((c) => c.toJson()).toList(),
    };
  }

  // Экспорт только записей (инвентаризаций)
  static Map<String, dynamic> exportInventories() {
    final inventories = StorageService.getInventories();
    final statuses = StorageService.getCategoryStatuses();

    return {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'type': 'inventories',
      'inventories': inventories.map((i) => i.toJson()).toList(),
      'categoryStatuses': statuses.map((key, value) => MapEntry(
            key,
            value.map((s) => s.toJson()).toList(),
          )),
    };
  }

  // Конвертация в JSON строку
  static String toJsonString(Map<String, dynamic> data) {
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}

