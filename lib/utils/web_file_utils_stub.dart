// Заглушка для платформ, где dart:html недоступен
import 'dart:async';

class WebFileUtils {
  static void downloadFile(String content, String filename) {
    // Заглушка - не используется на мобильных платформах
  }

  static Future<String?> pickFile() async {
    // Заглушка - не используется на мобильных платформах
    return null;
  }
}



