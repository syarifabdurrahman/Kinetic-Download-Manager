import '../repositories/download_repository.dart';

class RemoveDownloadUseCase {
  final DownloadRepository repository;

  RemoveDownloadUseCase(this.repository);

  Future<void> call(String id) async {
    await repository.removeTask(id);
  }
}
