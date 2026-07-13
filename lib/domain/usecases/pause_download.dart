import '../entities/download_status.dart';
import '../repositories/download_repository.dart';

class PauseDownloadUseCase {
  final DownloadRepository repository;

  PauseDownloadUseCase(this.repository);

  Future<void> call(String id) async {
    final task = await repository.getTask(id);
    if (task != null && task.status == DownloadStatus.downloading) {
      await repository.updateTask(task.copyWith(
        status: DownloadStatus.paused,
      ));
    }
  }
}
