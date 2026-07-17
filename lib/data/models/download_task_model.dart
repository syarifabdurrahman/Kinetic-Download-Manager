import 'package:hive/hive.dart';
import '../../domain/entities/download_status.dart';
import '../../domain/entities/download_task.dart';

@HiveType(typeId: 0)
class DownloadTaskModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final String fileName;

  @HiveField(3)
  final int totalBytes;

  @HiveField(4)
  final int downloadedBytes;

  @HiveField(5)
  final String status;

  @HiveField(6)
  final int chunksCount;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final String? savePath;

  DownloadTaskModel({
    required this.id,
    required this.url,
    required this.fileName,
    required this.totalBytes,
    required this.downloadedBytes,
    required this.status,
    required this.chunksCount,
    required this.createdAt,
    this.savePath,
  });

  factory DownloadTaskModel.fromEntity(DownloadTask task) {
    return DownloadTaskModel(
      id: task.id,
      url: task.url,
      fileName: task.fileName,
      totalBytes: task.totalBytes,
      downloadedBytes: task.downloadedBytes,
      status: task.status.name,
      chunksCount: task.chunksCount,
      createdAt: task.createdAt,
      savePath: task.savePath,
    );
  }

  DownloadTask toEntity() {
    return DownloadTask(
      id: id,
      url: url,
      fileName: fileName,
      savePath: savePath,
      totalBytes: totalBytes,
      downloadedBytes: downloadedBytes,
      status: DownloadStatus.values.firstWhere((e) => e.name == status),
      chunksCount: chunksCount,
      createdAt: createdAt,
    );
  }
}
