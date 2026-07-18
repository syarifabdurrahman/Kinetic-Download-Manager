import 'package:equatable/equatable.dart';
import '../../domain/entities/download_task.dart';

abstract class DownloadEvent extends Equatable {
  const DownloadEvent();

  @override
  List<Object?> get props => [];
}

class AddDownload extends DownloadEvent {
  final String url;
  final String fileName;
  final Map<String, String>? headers;

  const AddDownload(this.url, this.fileName, {this.headers});

  @override
  List<Object?> get props => [url, fileName, headers];
}

class PauseDownload extends DownloadEvent {
  final String taskId;

  const PauseDownload(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class ResumeDownload extends DownloadEvent {
  final String taskId;

  const ResumeDownload(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class RemoveDownload extends DownloadEvent {
  final String taskId;

  const RemoveDownload(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class UpdateProgress extends DownloadEvent {
  final String taskId;
  final int downloadedBytes;
  final int totalBytes;
  final double speed;

  const UpdateProgress({
    required this.taskId,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.speed,
  });

  @override
  List<Object?> get props => [taskId, downloadedBytes, totalBytes, speed];
}

class LoadDownloads extends DownloadEvent {}

class DownloadCompleted extends DownloadEvent {
  final String taskId;
  final String savePath;
  final String fileName;

  const DownloadCompleted({
    required this.taskId,
    required this.savePath,
    required this.fileName,
  });

  @override
  List<Object?> get props => [taskId, savePath, fileName];
}

class DismissCompleted extends DownloadEvent {}

class DownloadQueueUpdated extends DownloadEvent {
  final List<DownloadTask> tasks;

  const DownloadQueueUpdated(this.tasks);

  @override
  List<Object?> get props => [tasks];
}
