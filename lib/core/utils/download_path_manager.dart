import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class DownloadPathManager {
  static const _boxName = 'app_settings';
  static const _key = 'download_path';

  static Future<String> getDefaultPath() async {
    try {
      final dir = Directory('/storage/emulated/0/Download/KFDM');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    } catch (_) {
      final dir = Directory('${(await getExternalStorageDirectory())?.path ?? (await getApplicationDocumentsDirectory()).path}/KFDM');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    }
  }

  static Future<String> getPath() async {
    final box = await Hive.openBox<String>(_boxName);
    final saved = box.get(_key);
    if (saved != null && saved.isNotEmpty) {
      final dir = Directory(saved);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return saved;
    }
    final defaultPath = await getDefaultPath();
    await box.put(_key, defaultPath);
    return defaultPath;
  }

  static Future<void> setPath(String path) async {
    final box = await Hive.openBox<String>(_boxName);
    await box.put(_key, path);
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  static Future<void> resetToDefault() async {
    final defaultPath = await getDefaultPath();
    await setPath(defaultPath);
  }
}
