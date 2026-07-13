import '../entities/download_status.dart';
import '../repositories/download_repository.dart';

class ResumeDownloadUseCase {
  final DownloadRepository repository;

  ResumeDownloadUseCase(this.repository);

  Future<void> call(String id) async {
    final task = await repository.getTask(id);
    if (task != null && task.status == DownloadStatus.paused) {
      await repository.updateTask(task.copyWith(
        status: DownloadStatus.downloading,
      ));
    }
  }
}
