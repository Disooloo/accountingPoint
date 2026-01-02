import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory.dart';
import '../models/category_status.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import 'categories_screen.dart';
import 'create_inventory_screen.dart';
import 'inventory_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(AppThemeMode)? onThemeModeChanged;

  const HomeScreen({super.key, this.onThemeModeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Inventory> _inventories = [];

  @override
  void initState() {
    super.initState();
    _loadInventories();
  }

  void _loadInventories() {
    setState(() {
      _inventories = StorageService.getInventories();
    });
  }

  double _getProgress(String inventoryId) {
    final statuses = StorageService.getCategoryStatuses();
    final inventoryStatuses = statuses[inventoryId] ?? [];
    if (inventoryStatuses.isEmpty) return 0.0;
    final completed = inventoryStatuses.where((s) => s.isCompleted).length;
    return completed / inventoryStatuses.length;
  }

  Color _getProgressColor(double progress) {
    if (progress == 1.0) return Colors.green;
    if (progress >= 0.5) return Colors.orange;
    return Colors.red;
  }

  void _deleteInventory(String inventoryId) {
    // Удаляем инвентаризацию
    final inventories = StorageService.getInventories();
    inventories.removeWhere((inv) => inv.id == inventoryId);
    StorageService.saveInventories(inventories);

    // Удаляем статусы категорий
    final statuses = StorageService.getCategoryStatuses();
    statuses.remove(inventoryId);
    StorageService.saveCategoryStatuses(statuses);

    // Обновляем список
    _loadInventories();

    // Показываем уведомление
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Инвентаризация удалена'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Инвентаризации'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoriesScreen()),
              );
            },
            tooltip: 'Категории',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    onThemeModeChanged: widget.onThemeModeChanged,
                  ),
                ),
              );
              if (result == true) {
                _loadInventories();
              }
            },
            tooltip: 'Настройки',
          ),
        ],
      ),
      body: _inventories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет инвентаризаций',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Нажмите + чтобы создать новую',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _inventories.length,
              itemBuilder: (context, index) {
                final inventory = _inventories[index];
                final progress = _getProgress(inventory.id);
                final progressColor = _getProgressColor(progress);

                return Dismissible(
                  key: Key(inventory.id),
                  direction: DismissDirection.endToStart, // Свайп вправо (endToStart)
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                        SizedBox(height: 8),
                        Text(
                          'Удалить',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    // Показываем диалог подтверждения
                    return await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Удалить инвентаризацию?'),
                          content: Text(
                            'Вы уверены, что хотите удалить "${inventory.name}"?\n\nЭто действие нельзя отменить.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Отмена'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Удалить'),
                            ),
                          ],
                        );
                      },
                    ) ?? false;
                  },
                  onDismissed: (direction) {
                    _deleteInventory(inventory.id);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                InventoryDetailScreen(inventoryId: inventory.id),
                          ),
                        );
                        _loadInventories();
                      },
                      borderRadius: BorderRadius.circular(16),
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
                                    inventory.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (inventory.completedAt != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Завершена',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('dd.MM.yyyy HH:mm')
                                  .format(inventory.createdAt),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (inventory.completedAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Завершена: ${DateFormat('dd.MM.yyyy HH:mm').format(inventory.completedAt!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progressColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateInventoryScreen(),
            ),
          );
          _loadInventories();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

