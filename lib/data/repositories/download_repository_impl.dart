import 'dart:async';
import '../../domain/entities/download_status.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/repositories/download_repository.dart';
import '../datasources/local/download_local_datasource.dart';
import '../models/download_task_model.dart';

class DownloadRepositoryImpl implements DownloadRepository {
  final DownloadLocalDatasource _local;

  DownloadRepositoryImpl(this._local);

  @override
  Future<void> addTask(DownloadTask task) async {
    await _local.addTask(DownloadTaskModel.fromEntity(task));
  }

  @override
  Future<void> removeTask(String id) async {
    await _local.removeTask(id);
  }

  @override
  Future<void> updateTask(DownloadTask task) async {
    await _local.updateTask(DownloadTaskModel.fromEntity(task));
  }

  @override
  Future<DownloadTask?> getTask(String id) async {
    final model = _local.getTask(id);
    return model?.toEntity();
  }

  @override
  Stream<List<DownloadTask>> watchQueue() async* {
    yield _local.getAllTasks().map((m) => m.toEntity()).toList();
    await for (final _ in _local.watch()) {
      yield _local.getAllTasks().map((m) => m.toEntity()).toList();
    }
  }

  Future<void> updateTaskBytes(String id, int downloadedBytes, int totalBytes, double speed) async {
    final task = await getTask(id);
    if (task != null) {
      await updateTask(task.copyWith(
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes,
        speed: speed,
        status: downloadedBytes >= totalBytes ? DownloadStatus.completed : DownloadStatus.downloading,
      ));
    }
  }
}
