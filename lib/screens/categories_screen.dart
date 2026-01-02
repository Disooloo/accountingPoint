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
    });
  }

  void _showAddCategoryDialog() {
    _controller.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить категорию'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '00 - 01 КБТ',
                labelText: 'Код - наименование',
                helperText: 'Формат: код - наименование (00 - 01 КБТ ...)',
              ),
              autofocus: true,
            ),
          ],
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

  void _showEditCategoryDialog(Category category) {
    _controller.text = '${category.code} - ${category.name}';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать категорию'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '00 - 01 КБТ',
                labelText: 'Код - наименование',
                helperText: 'Формат: код - наименование (00 - 01 КБТ ...)',
              ),
              autofocus: true,
            ),
          ],
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
                _updateCategory(category, text);
                Navigator.pop(context);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _updateCategory(Category category, String text) {
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
        code = category.code; // Сохраняем старый код
      }
    }

    // Если код пустой, используем старый
    if (code.isEmpty) code = category.code;

    final updatedCategory = category.copyWith(
      name: name,
      code: code,
    );

    final categories = StorageService.getCategories();
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      categories[index] = updatedCategory;
      StorageService.saveCategories(categories);
      _loadCategories();
    }
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
                // Выпадающий список для подкатегорий "00"
                if (specialCategories.isNotEmpty) ...[
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: const Text(
                        'Подкатегории (00)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text('${specialCategories.length} категорий'),
                      childrenPadding: const EdgeInsets.only(
                        left: 8,
                        right: 8,
                        bottom: 8,
                      ),
                      children: specialCategories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _buildCategoryCard(category),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                // Остальные категории, отсортированные по коду
                if (regularCategories.isNotEmpty) ...[
                  Text(
                    'Категории',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(regularCategories..sort((a, b) => a.code.compareTo(b.code)))
                      .map((category) => _buildCategoryCard(category)),
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
    return Dismissible(
      key: Key(category.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit,
              color: Colors.white,
              size: 32,
            ),
            SizedBox(height: 4),
            Text(
              'Редактировать',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 32,
            ),
            SizedBox(height: 4),
            Text(
              'Удалить',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Свайп вправо - редактирование
          _showEditCategoryDialog(category);
          return false; // Не удаляем из списка
        } else {
          // Свайп влево - удаление
          return await _confirmDelete(category);
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          // Удаляем категорию
          final categories = StorageService.getCategories();
          categories.removeWhere((c) => c.id == category.id);
          StorageService.saveCategories(categories);
          _loadCategories();
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(category.name),
          subtitle: Text('Код: ${category.code}'),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(Category category) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить категорию?'),
        content: Text('Категория "${category.name}" будет удалена'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    ) ?? false;
  }
}
