import 'package:flutter/material.dart';
import '../models/inventory.dart';
import '../models/category.dart';
import '../models/category_status.dart';
import '../services/storage_service.dart';

class CreateInventoryScreen extends StatefulWidget {
  const CreateInventoryScreen({super.key});

  @override
  State<CreateInventoryScreen> createState() => _CreateInventoryScreenState();
}

class _CreateInventoryScreenState extends State<CreateInventoryScreen> {
  final List<String> _selectedCategoryIds = [];
  List<Category> _allCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _allCategories = StorageService.getCategories();
    });
  }

  String _generateInventoryName() {
    final now = DateTime.now();
    final monthNames = [
      'январь', 'февраль', 'март', 'апрель', 'май', 'июнь',
      'июль', 'август', 'сентябрь', 'октябрь', 'ноябрь', 'декабрь'
    ];
    final monthName = monthNames[now.month - 1];
    final year = now.year;
    return 'Инвентаризация $monthName $year';
  }

  void _createInventory() {
    if (_selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите хотя бы одну категорию'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final inventory = Inventory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _generateInventoryName(),
      createdAt: DateTime.now(),
      categoryIds: _selectedCategoryIds,
    );

    final inventories = StorageService.getInventories();
    inventories.add(inventory);
    StorageService.saveInventories(inventories);

    // Создаем статусы для категорий
    final statuses = StorageService.getCategoryStatuses();
    statuses[inventory.id] = _selectedCategoryIds
        .map((id) => CategoryStatus(categoryId: id))
        .toList();
    StorageService.saveCategoryStatuses(statuses);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_allCategories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Создать инвентаризацию'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.category_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Нет категорий',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Сначала создайте категории',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать инвентаризацию'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Название:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _generateInventoryName(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const Text(
                  'Выберите категории:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ..._allCategories.map((category) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        title: Text(category.name),
                        subtitle: Text('Код: ${category.code}'),
                        value: _selectedCategoryIds.contains(category.id),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedCategoryIds.add(category.id);
                            } else {
                              _selectedCategoryIds.remove(category.id);
                            }
                          });
                        },
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _createInventory,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Создать инвентаризацию'),
          ),
        ),
      ),
    );
  }
}

