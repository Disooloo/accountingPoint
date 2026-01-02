// Утилиты для работы с файлами на вебе
import 'dart:async';
import 'dart:html' as html;

class WebFileUtils {
  static void downloadFile(String content, String filename) {
    final blob = html.Blob([content], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static Future<String?> pickFile() async {
    final input = html.FileUploadInputElement()..accept = '.json';
    input.click();

    final completer = Completer<String?>();

    input.onChange.listen((e) async {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete(null);
        return;
      }

      final file = files[0];
      final reader = html.FileReader();

      reader.onLoadEnd.listen((e) {
        final content = reader.result as String;
        completer.complete(content);
      });

      reader.readAsText(file);
    });

    return completer.future;
  }
}

