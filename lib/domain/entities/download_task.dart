import 'download_status.dart';

class DownloadTask {
  final String id;
  final String url;
  final String fileName;
  final int totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final int chunksCount;
  final double speed;
  final DateTime createdAt;

  const DownloadTask({
    required this.id,
    required this.url,
    required this.fileName,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.pending,
    this.chunksCount = 4,
    this.speed = 0,
    required this.createdAt,
  });

  DownloadTask copyWith({
    String? id,
    String? url,
    String? fileName,
    int? totalBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    int? chunksCount,
    double? speed,
    DateTime? createdAt,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      chunksCount: chunksCount ?? this.chunksCount,
      speed: speed ?? this.speed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get progress =>
      totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
}
