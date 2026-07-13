import '../entities/download_task.dart';
import '../repositories/download_repository.dart';

class StartDownload {
  final DownloadRepository repository;

  StartDownload(this.repository);

  Future<void> call(String url, String fileName) async {
    final task = DownloadTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      fileName: fileName,
      createdAt: DateTime.now(),
    );
    await repository.addTask(task);
  }
}
