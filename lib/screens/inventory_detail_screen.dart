import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/inventory.dart';
import '../models/category.dart';
import '../models/category_status.dart';
import '../services/storage_service.dart';

class InventoryDetailScreen extends StatefulWidget {
  final String inventoryId;

  const InventoryDetailScreen({
    super.key,
    required this.inventoryId,
  });

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  Inventory? _inventory;
  List<CategoryStatus> _statuses = [];
  List<Category> _categories = [];
  String? _deletedCategoryId;
  Timer? _restoreTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _restoreTimer?.cancel();
    super.dispose();
  }

  void _loadData() {
    final inventories = StorageService.getInventories();
    _inventory = inventories.firstWhere(
      (inv) => inv.id == widget.inventoryId,
      orElse: () => inventories.first,
    );

    final statusesMap = StorageService.getCategoryStatuses();
    _statuses = statusesMap[widget.inventoryId] ?? [];

    _categories = StorageService.getCategories();

    setState(() {});
  }

  double _getProgress() {
    if (_inventory == null || _inventory!.categoryIds.isEmpty) return 0.0;
    // Учитываем только статусы для категорий, которые есть в инвентаризации
    final relevantStatuses = _statuses
        .where((s) => _inventory!.categoryIds.contains(s.categoryId))
        .toList();
    if (relevantStatuses.isEmpty) return 0.0;
    final completed = relevantStatuses.where((s) => s.isCompleted).length;
    return completed / relevantStatuses.length;
  }

  Color _getProgressColor(double progress) {
    if (progress == 1.0) return Colors.green;
    if (progress >= 0.5) return Colors.orange;
    return Colors.red;
  }

  void _toggleCategoryStatus(String categoryId) {
    setState(() {
      final status = _statuses.firstWhere(
        (s) => s.categoryId == categoryId,
        orElse: () => CategoryStatus(categoryId: categoryId),
      );
      
      // Циклическое переключение: не начата -> начата -> выполнена -> не начата
      switch (status.state) {
        case CategoryState.notStarted:
          status.state = CategoryState.started;
          break;
        case CategoryState.started:
          status.state = CategoryState.completed;
          break;
        case CategoryState.completed:
          status.state = CategoryState.notStarted;
          break;
      }

      if (!_statuses.contains(status)) {
        _statuses.add(status);
      }

      _saveStatuses();
      _checkCompletion();
    });
  }

  void _onLongPress(String categoryId) {
    // Удержание сбрасывает в начальное состояние
    final status = _statuses.firstWhere(
      (s) => s.categoryId == categoryId,
      orElse: () => CategoryStatus(categoryId: categoryId),
    );

    setState(() {
      status.state = CategoryState.notStarted;
      if (!_statuses.contains(status)) {
        _statuses.add(status);
      }
      _saveStatuses();
      _checkCompletion();
    });
  }

  void _onSwipeLeft(String categoryId) {
    // Свайп влево - переключение состояния
    _toggleCategoryStatus(categoryId);
  }

  void _onSwipeRight(String categoryId) {
    // Свайп вправо - удалить
    if (_deletedCategoryId != null && _deletedCategoryId != categoryId) {
      // Если уже есть удаленная категория, окончательно удаляем её
      _confirmDelete(_deletedCategoryId!);
    }

    setState(() {
      _deletedCategoryId = categoryId;
    });

    _restoreTimer?.cancel();
    _restoreTimer = Timer(const Duration(seconds: 3), () {
      if (_deletedCategoryId == categoryId) {
        _confirmDelete(categoryId);
        setState(() {
          _deletedCategoryId = null;
        });
      }
    });

    _showRestoreNotification();
  }

  void _showRestoreNotification() {
    if (_deletedCategoryId == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Категория удалена. Нажмите для восстановления'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Восстановить',
          textColor: Colors.white,
          onPressed: _restoreDeletedCategory,
        ),
      ),
    );
  }

  void _restoreDeletedCategory() {
    if (_deletedCategoryId != null) {
      final categoryId = _deletedCategoryId!;
      setState(() {
        _deletedCategoryId = null;
        // Восстанавливаем категорию в список
        if (_inventory != null && !_inventory!.categoryIds.contains(categoryId)) {
          _inventory = _inventory!.copyWith(
            categoryIds: [..._inventory!.categoryIds, categoryId],
          );
          // Восстанавливаем статус если его нет
          if (!_statuses.any((s) => s.categoryId == categoryId)) {
            _statuses.add(CategoryStatus(categoryId: categoryId));
          }
        }
      });
      _restoreTimer?.cancel();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _saveStatuses();
      _saveInventory();
    }
  }

  void _confirmDelete(String categoryId) {
    _restoreTimer?.cancel();
    setState(() {
      _statuses.removeWhere((s) => s.categoryId == categoryId);
      if (_inventory != null) {
        _inventory = _inventory!.copyWith(
          categoryIds: _inventory!.categoryIds
              .where((id) => id != categoryId)
              .toList(),
        );
      }
      if (_deletedCategoryId == categoryId) {
        _deletedCategoryId = null;
      }
    });

    _saveStatuses();
    _saveInventory();
    _checkCompletion();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  void _saveStatuses() {
    final statusesMap = StorageService.getCategoryStatuses();
    statusesMap[widget.inventoryId] = _statuses;
    StorageService.saveCategoryStatuses(statusesMap);
  }

  void _saveInventory() {
    if (_inventory == null) return;
    final inventories = StorageService.getInventories();
    final index = inventories.indexWhere((inv) => inv.id == _inventory!.id);
    if (index != -1) {
      inventories[index] = _inventory!;
      StorageService.saveInventories(inventories);
    }
  }

  void _checkCompletion() {
    if (_inventory == null || _inventory!.categoryIds.isEmpty) return;

    // Учитываем только статусы для категорий, которые есть в инвентаризации
    final relevantStatuses = _statuses
        .where((s) => _inventory!.categoryIds.contains(s.categoryId))
        .toList();
    
    if (relevantStatuses.isEmpty) return;

    final allCompleted = relevantStatuses.every((s) => s.isCompleted) &&
        relevantStatuses.length == _inventory!.categoryIds.length;
    final wasCompleted = _inventory!.completedAt != null;

    if (allCompleted && !wasCompleted) {
      setState(() {
        _inventory = _inventory!.copyWith(completedAt: DateTime.now());
      });
      _saveInventory();
    } else if (!allCompleted && wasCompleted) {
      setState(() {
        _inventory = _inventory!.copyWith(completedAt: null);
      });
      _saveInventory();
    }
  }

  Category? _getCategory(String categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  CategoryState _getCategoryState(String categoryId) {
    final status = _statuses.firstWhere(
      (s) => s.categoryId == categoryId,
      orElse: () => CategoryStatus(categoryId: categoryId),
    );
    return status.state;
  }

  @override
  Widget build(BuildContext context) {
    if (_inventory == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final progress = _getProgress();
    final progressColor = _getProgressColor(progress);
    
    // Все категории, отсортированные по коду
    final categoryItems = _inventory!.categoryIds
        .where((id) => id != _deletedCategoryId)
        .map((id) => _getCategory(id))
        .whereType<Category>()
        .toList()
      ..sort((a, b) => a.code.compareTo(b.code));

    return Scaffold(
      appBar: AppBar(
        title: Text(_inventory!.name),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _inventory!.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_inventory!.completedAt != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Завершена',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Создана: ${DateFormat('dd.MM.yyyy HH:mm').format(_inventory!.createdAt)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_inventory!.completedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Завершена: ${DateFormat('dd.MM.yyyy HH:mm').format(_inventory!.completedAt!)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final relevantStatuses = _statuses
                          .where((s) => _inventory!.categoryIds.contains(s.categoryId))
                          .toList();
                      final completed = relevantStatuses.where((s) => s.isCompleted).length;
                      final total = relevantStatuses.length;
                      return Text(
                        '${(progress * 100).toInt()}% ($completed/$total)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: categoryItems.isEmpty
                ? Center(
                    child: Text(
                      'Нет категорий',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categoryItems.length,
                    itemBuilder: (context, index) {
                      return _buildCategoryCard(categoryItems[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    final state = _getCategoryState(category.id);
    
    // Определяем цвета и иконки для каждого состояния
    Color? cardColor;
    Color iconBgColor;
    IconData iconData;
    Color iconColor;
    String? statusText;
    Color? statusTextColor;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    switch (state) {
      case CategoryState.notStarted:
        cardColor = null;
        iconBgColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
        iconData = Icons.radio_button_unchecked;
        iconColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
        statusText = null;
        break;
      case CategoryState.started:
        cardColor = isDark 
            ? Colors.orange.withOpacity(0.2) 
            : Colors.orange[50];
        iconBgColor = Colors.orange;
        iconData = Icons.play_circle_outline;
        iconColor = Colors.white;
        statusText = 'Начата';
        statusTextColor = Colors.orange[700];
        break;
      case CategoryState.completed:
        cardColor = isDark 
            ? Colors.green.withOpacity(0.2) 
            : Colors.green[50];
        iconBgColor = Colors.green;
        iconData = Icons.check_circle;
        iconColor = Colors.white;
        statusText = 'Выполнена';
        statusTextColor = Colors.green[700];
        break;
    }

    return Dismissible(
                        key: Key(category.id),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 32,
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
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        onDismissed: (direction) {
                          if (direction == DismissDirection.endToStart) {
                            // Свайп вправо - удалить (элемент уже скрыт)
                            _confirmDelete(category.id);
                          }
                        },
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // Свайп влево - переключение состояния
                            _onSwipeLeft(category.id);
                            return false; // Не удаляем из списка
                          } else {
                            // Свайп вправо - удалить
                            _onSwipeRight(category.id);
                            return true; // Удаляем из списка, показываем уведомление
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: cardColor,
                          elevation: state == CategoryState.completed ? 3 : 1,
                          child: InkWell(
                            onTap: () => _toggleCategoryStatus(category.id),
                            onLongPress: () => _onLongPress(category.id),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: iconBgColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      iconData,
                                      color: iconColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            decoration: state == CategoryState.completed
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: state == CategoryState.completed
                                                ? (isDark ? Colors.grey[400] : Colors.grey[600])
                                                : (isDark ? Colors.grey[100] : null),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              'Код: ${category.code}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark 
                                                    ? Colors.grey[400] 
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                            if (statusText != null) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: statusTextColor?.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  statusText,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: statusTextColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (state == CategoryState.completed)
                                    Icon(
                                      Icons.check_circle,
                                      color: isDark 
                                          ? Colors.green[400] 
                                          : Colors.green[700],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
  }
}

