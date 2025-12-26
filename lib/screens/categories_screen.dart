import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category.dart';
import '../services/storage_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _categories = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadCategories() {
    setState(() {
      _categories = StorageService.getCategories();
      _categories.sort((a, b) {
        // Специальные категории (00, 01) в начале
        if (a.isSpecial && !b.isSpecial) return -1;
        if (!a.isSpecial && b.isSpecial) return 1;
        if (a.isSpecial && b.isSpecial) {
          return a.code.compareTo(b.code);
        }
        return a.code.compareTo(b.code);
      });
    });
  }

  void _showAddCategoryDialog() {
    _controller.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить категорию'),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Например: 20 - автотовары',
            labelText: 'Название категории',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final text = _controller.text.trim();
              if (text.isNotEmpty) {
                _addCategory(text);
                Navigator.pop(context);
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _addCategory(String text) {
    // Парсим код и название из строки вида "20 - автотовары" или просто "20"
    String code = '';
    String name = text;

    if (text.contains(' - ')) {
      final parts = text.split(' - ');
      code = parts[0].trim();
      name = parts.length > 1 ? parts[1].trim() : text;
    } else if (text.contains('-')) {
      final parts = text.split('-');
      code = parts[0].trim();
      name = parts.length > 1 ? parts[1].trim() : text;
    } else {
      // Если нет разделителя, пытаемся извлечь код из начала
      final match = RegExp(r'^(\d+)').firstMatch(text);
      if (match != null) {
        code = match.group(1)!;
        name = text.substring(code.length).trim();
        if (name.isEmpty) name = text;
      } else {
        code = '00'; // По умолчанию
      }
    }

    // Если код пустой, используем 00
    if (code.isEmpty) code = '00';

    final category = Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      code: code,
    );

    final categories = StorageService.getCategories();
    categories.add(category);
    StorageService.saveCategories(categories);
    _loadCategories();
  }

  void _deleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить категорию?'),
        content: Text('Категория "${category.name}" будет удалена'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final categories = StorageService.getCategories();
              categories.removeWhere((c) => c.id == category.id);
              StorageService.saveCategories(categories);
              _loadCategories();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Группируем категории
    final specialCategories = _categories.where((c) => c.isSpecial).toList();
    final regularCategories = _categories.where((c) => !c.isSpecial).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Категории'),
        elevation: 0,
      ),
      body: _categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет категорий',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Нажмите + чтобы добавить',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (specialCategories.isNotEmpty) ...[
                  Text(
                    'Специальные категории (00, 01)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...specialCategories.map((category) => _buildCategoryCard(category)),
                  const SizedBox(height: 24),
                ],
                if (regularCategories.isNotEmpty) ...[
                  Text(
                    'Обычные категории',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...regularCategories.map((category) => _buildCategoryCard(category)),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(category.name),
        subtitle: Text('Код: ${category.code}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteCategory(category),
          color: Colors.red,
        ),
      ),
    );
  }
}

