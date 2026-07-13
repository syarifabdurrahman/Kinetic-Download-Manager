import 'package:equatable/equatable.dart';
import '../../domain/entities/download_task.dart';

abstract class DownloadState extends Equatable {
  const DownloadState();

  @override
  List<Object?> get props => [];
}

class DownloadInitial extends DownloadState {}

class DownloadLoading extends DownloadState {}

class DownloadLoaded extends DownloadState {
  final List<DownloadTask> tasks;

  const DownloadLoaded(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class DownloadError extends DownloadState {
  final String message;

  const DownloadError(this.message);

  @override
  List<Object?> get props => [message];
}
