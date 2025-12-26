import 'dart:convert';
import '../models/inventory.dart';
import '../models/category.dart';
import '../models/category_status.dart';
import 'storage_service.dart';

class ImportService {
  // Импорт всех данных
  static Future<ImportResult> importAll(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final inventories = (data['inventories'] as List?)
          ?.map((item) => Inventory.fromJson(item as Map<String, dynamic>))
          .toList() ?? [];

      final categories = (data['categories'] as List?)
          ?.map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList() ?? [];

      final statusesMap = (data['categoryStatuses'] as Map?)?.map((key, value) {
        final statuses = (value as List)
            .map((item) => CategoryStatus.fromJson(item as Map<String, dynamic>))
            .toList();
        return MapEntry(key.toString(), statuses);
      }) ?? <String, List<CategoryStatus>>{};

      // Сохраняем данные
      await StorageService.saveInventories(inventories);
      await StorageService.saveCategories(categories);
      await StorageService.saveCategoryStatuses(statusesMap);

      return ImportResult(
        success: true,
        inventoriesCount: inventories.length,
        categoriesCount: categories.length,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Импорт только категорий
  static Future<ImportResult> importCategories(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final categories = (data['categories'] as List?)
          ?.map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList() ?? [];

      if (categories.isEmpty) {
        return ImportResult(
          success: false,
          error: 'Файл не содержит категорий',
        );
      }

      // Сохраняем категории
      await StorageService.saveCategories(categories);

      return ImportResult(
        success: true,
        categoriesCount: categories.length,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Импорт только записей (инвентаризаций)
  static Future<ImportResult> importInventories(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final inventories = (data['inventories'] as List?)
          ?.map((item) => Inventory.fromJson(item as Map<String, dynamic>))
          .toList() ?? [];

      final statusesMap = (data['categoryStatuses'] as Map?)?.map((key, value) {
        final statuses = (value as List)
            .map((item) => CategoryStatus.fromJson(item as Map<String, dynamic>))
            .toList();
        return MapEntry(key.toString(), statuses);
      }) ?? <String, List<CategoryStatus>>{};

      if (inventories.isEmpty) {
        return ImportResult(
          success: false,
          error: 'Файл не содержит инвентаризаций',
        );
      }

      // Сохраняем данные
      await StorageService.saveInventories(inventories);
      await StorageService.saveCategoryStatuses(statusesMap);

      return ImportResult(
        success: true,
        inventoriesCount: inventories.length,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}

class ImportResult {
  final bool success;
  final int? inventoriesCount;
  final int? categoriesCount;
  final String? error;

  ImportResult({
    required this.success,
    this.inventoriesCount,
    this.categoriesCount,
    this.error,
  });
}

