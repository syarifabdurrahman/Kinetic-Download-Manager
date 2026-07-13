import '../entities/download_task.dart';

abstract class DownloadRepository {
  Stream<List<DownloadTask>> watchQueue();
  Future<void> addTask(DownloadTask task);
  Future<void> removeTask(String id);
  Future<void> updateTask(DownloadTask task);
  Future<DownloadTask?> getTask(String id);
}
