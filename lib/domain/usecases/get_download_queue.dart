import '../entities/download_task.dart';
import '../repositories/download_repository.dart';

class GetDownloadQueue {
  final DownloadRepository repository;

  GetDownloadQueue(this.repository);

  Stream<List<DownloadTask>> call() => repository.watchQueue();
}
