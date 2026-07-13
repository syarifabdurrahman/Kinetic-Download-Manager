import 'package:hive/hive.dart';
import '../../models/download_task_model.dart';

class DownloadLocalDatasource {
  static const _boxName = 'download_tasks';
  late Box<DownloadTaskModel> _box;

  Future<void> init() async {
    _box = await Hive.openBox<DownloadTaskModel>(_boxName);
  }

  Box<DownloadTaskModel> get box => _box;

  Future<void> addTask(DownloadTaskModel task) async {
    await _box.put(task.id, task);
  }

  Future<void> removeTask(String id) async {
    await _box.delete(id);
  }

  Future<void> updateTask(DownloadTaskModel task) async {
    await _box.put(task.id, task);
  }

  DownloadTaskModel? getTask(String id) => _box.get(id);

  List<DownloadTaskModel> getAllTasks() => _box.values.toList();

  Stream<BoxEvent> watch() => _box.watch();
}
