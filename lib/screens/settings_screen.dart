import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import '../services/theme_service.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../utils/web_file_utils_stub.dart' if (dart.library.html) '../utils/web_file_utils.dart';

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

  Future<void> _exportAll() async {
    final data = ExportService.exportAll();
    final jsonString = ExportService.toJsonString(data);
    await _downloadFile(jsonString, 'inventory_backup_all.json');
    _showSnackBar('Все данные экспортированы');
  }

  Future<void> _exportCategories() async {
    final data = ExportService.exportCategories();
    final jsonString = ExportService.toJsonString(data);
    await _downloadFile(jsonString, 'inventory_backup_categories.json');
    _showSnackBar('Категории экспортированы');
  }

  Future<void> _exportInventories() async {
    final data = ExportService.exportInventories();
    final jsonString = ExportService.toJsonString(data);
    await _downloadFile(jsonString, 'inventory_backup_inventories.json');
    _showSnackBar('Инвентаризации экспортированы');
  }

  Future<void> _downloadFile(String content, String filename) async {
    if (kIsWeb) {
      // Для веба используем dart:html
      _downloadFileWeb(content, filename);
    } else {
      // Для мобильных платформ используем share_plus
      final bytes = Uint8List.fromList(utf8.encode(content));
      final xFile = XFile.fromData(
        bytes,
        name: filename,
        mimeType: 'application/json',
      );
      await Share.shareXFiles([xFile], text: 'Экспорт данных инвентаризации');
    }
  }

  void _downloadFileWeb(String content, String filename) {
    if (kIsWeb) {
      WebFileUtils.downloadFile(content, filename);
    }
  }

  Future<void> _importAll() async {
    final content = await _pickFile();
    if (content == null) return;

    final result = await ImportService.importAll(content);

    if (result.success) {
      _showSnackBar(
        'Импортировано: ${result.inventoriesCount ?? 0} инвентаризаций, ${result.categoriesCount ?? 0} категорий',
        isError: false,
      );
      // Обновляем главный экран
      Navigator.pop(context, true);
    } else {
      _showSnackBar('Ошибка импорта: ${result.error}', isError: true);
    }
  }

  Future<void> _importCategories() async {
    final content = await _pickFile();
    if (content == null) return;

    final result = await ImportService.importCategories(content);

    if (result.success) {
      _showSnackBar(
        'Импортировано: ${result.categoriesCount ?? 0} категорий',
        isError: false,
      );
    } else {
      _showSnackBar('Ошибка импорта: ${result.error}', isError: true);
    }
  }

  Future<void> _importInventories() async {
    final content = await _pickFile();
    if (content == null) return;

    final result = await ImportService.importInventories(content);

    if (result.success) {
      _showSnackBar(
        'Импортировано: ${result.inventoriesCount ?? 0} инвентаризаций',
        isError: false,
      );
      // Обновляем главный экран
      Navigator.pop(context, true);
    } else {
      _showSnackBar('Ошибка импорта: ${result.error}', isError: true);
    }
  }

  Future<String?> _pickFile() async {
    if (kIsWeb) {
      return await _pickFileWeb();
    } else {
      return await _pickFileMobile();
    }
  }

  Future<String?> _pickFileWeb() async {
    if (kIsWeb) {
      return await WebFileUtils.pickFile();
    }
    return null;
  }

  Future<String?> _pickFileMobile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      _showSnackBar('Ошибка при выборе файла: $e', isError: true);
      return null;
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
          const SizedBox(height: 16),

          // Об авторе
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Об авторе'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const Text('Разработчик: Disooloo'),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _openTelegram(),
                    child: Text(
                      't.me/disooloo',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openTelegram() async {
    final url = Uri.parse('https://t.me/disooloo');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Не удалось открыть ссылку', isError: true);
      }
    } catch (e) {
      _showSnackBar('Ошибка: $e', isError: true);
    }
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

