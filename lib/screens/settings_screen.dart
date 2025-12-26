import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/theme_service.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';

class SettingsScreen extends StatefulWidget {
  final Function(AppThemeMode)? onThemeModeChanged;

  const SettingsScreen({super.key, this.onThemeModeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppThemeMode _themeMode = AppThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final mode = await ThemeService.getThemeMode();
    setState(() {
      _themeMode = mode;
    });
  }

  Future<void> _changeThemeMode(AppThemeMode mode) async {
    await ThemeService.setThemeMode(mode);
    setState(() {
      _themeMode = mode;
    });
    widget.onThemeModeChanged?.call(mode);
  }

  void _exportAll() {
    final data = ExportService.exportAll();
    final jsonString = ExportService.toJsonString(data);
    _downloadFile(jsonString, 'inventory_backup_all.json');
    _showSnackBar('Все данные экспортированы');
  }

  void _exportCategories() {
    final data = ExportService.exportCategories();
    final jsonString = ExportService.toJsonString(data);
    _downloadFile(jsonString, 'inventory_backup_categories.json');
    _showSnackBar('Категории экспортированы');
  }

  void _exportInventories() {
    final data = ExportService.exportInventories();
    final jsonString = ExportService.toJsonString(data);
    _downloadFile(jsonString, 'inventory_backup_inventories.json');
    _showSnackBar('Инвентаризации экспортированы');
  }

  void _downloadFile(String content, String filename) {
    // Для всех платформ копируем в буфер обмена
    // На Android пользователь может вставить данные в файл
    Clipboard.setData(ClipboardData(text: content));
    _showSnackBar('Данные скопированы в буфер обмена. Сохраните их в файл $filename');
  }

  Future<void> _importAll() async {
    if (kIsWeb) {
      _showSnackBar('Импорт файлов доступен только через веб-интерфейс. Используйте веб-версию приложения.', isError: true);
    } else {
      _showSnackBar('Импорт доступен только в веб-версии', isError: true);
    }
  }

  Future<void> _importCategories() async {
    if (kIsWeb) {
      _showSnackBar('Импорт файлов доступен только через веб-интерфейс. Используйте веб-версию приложения.', isError: true);
    } else {
      _showSnackBar('Импорт доступен только в веб-версии', isError: true);
    }
  }

  Future<void> _importInventories() async {
    if (kIsWeb) {
      _showSnackBar('Импорт файлов доступен только через веб-интерфейс. Используйте веб-версию приложения.', isError: true);
    } else {
      _showSnackBar('Импорт доступен только в веб-версии', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Тема
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.palette),
              title: const Text('Тема'),
              subtitle: Text(_getThemeModeName(_themeMode)),
              children: [
                RadioListTile<AppThemeMode>(
                  title: const Text('Системная'),
                  value: AppThemeMode.system,
                  groupValue: _themeMode,
                  onChanged: (value) {
                    if (value != null) _changeThemeMode(value);
                  },
                ),
                RadioListTile<AppThemeMode>(
                  title: const Text('Светлая'),
                  value: AppThemeMode.light,
                  groupValue: _themeMode,
                  onChanged: (value) {
                    if (value != null) _changeThemeMode(value);
                  },
                ),
                RadioListTile<AppThemeMode>(
                  title: const Text('Темная'),
                  value: AppThemeMode.dark,
                  groupValue: _themeMode,
                  onChanged: (value) {
                    if (value != null) _changeThemeMode(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Интеграции
          Card(
            child: ListTile(
              leading: const Icon(Icons.integration_instructions),
              title: const Text('Интеграции'),
              subtitle: const Text('В разработке'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Функция в разработке'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Импорт/Экспорт
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.import_export),
              title: const Text('Импорт / Экспорт'),
              children: [
                // Экспорт
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Экспорт',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Экспортировать все'),
                  subtitle: const Text('Все данные в одном файле'),
                  onTap: _exportAll,
                ),
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Экспортировать категории'),
                  subtitle: const Text('Только категории'),
                  onTap: _exportCategories,
                ),
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Экспортировать записи'),
                  subtitle: const Text('Только инвентаризации'),
                  onTap: _exportInventories,
                ),
                const Divider(),
                // Импорт
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Импорт',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text('Импортировать все'),
                  subtitle: const Text('Импорт всех данных'),
                  onTap: _importAll,
                ),
                ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text('Импортировать категории'),
                  subtitle: const Text('Импорт только категорий'),
                  onTap: _importCategories,
                ),
                ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text('Импортировать записи'),
                  subtitle: const Text('Импорт только инвентаризаций'),
                  onTap: _importInventories,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeModeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'Системная';
      case AppThemeMode.light:
        return 'Светлая';
      case AppThemeMode.dark:
        return 'Темная';
    }
  }
}

