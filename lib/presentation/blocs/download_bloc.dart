import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/utils/download_path_manager.dart';
import '../../data/datasources/remote/background_download_service.dart';
import '../../data/datasources/remote/download_engine.dart';
import '../../domain/entities/download_status.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/repositories/download_repository.dart';
import '../../domain/usecases/get_download_queue.dart';
import '../../domain/usecases/pause_download.dart';
import '../../domain/usecases/resume_download.dart';
import '../../domain/usecases/remove_download.dart';
import 'download_event.dart';
import 'download_state.dart';

class DownloadBloc extends Bloc<DownloadEvent, DownloadState> {
  final PauseDownloadUseCase _pauseDownload;
  final ResumeDownloadUseCase _resumeDownload;
  final GetDownloadQueue _getDownloadQueue;
  final RemoveDownloadUseCase _removeDownload;
  final DownloadEngine _engine;
  final BackgroundDownloadService _notificationService;
  final DownloadRepository _repository;
  final Map<String, StreamSubscription> _progressSubs = {};
  final _speedFormat = NumberFormat.compact();
  StreamSubscription? _queueSubscription;

  DownloadBloc({
    required PauseDownloadUseCase pauseDownload,
    required ResumeDownloadUseCase resumeDownload,
    required GetDownloadQueue getDownloadQueue,
    required RemoveDownloadUseCase removeDownload,
    required DownloadEngine engine,
    required DownloadRepository repository,
    BackgroundDownloadService? notificationService,
  })  : _pauseDownload = pauseDownload,
        _resumeDownload = resumeDownload,
        _getDownloadQueue = getDownloadQueue,
        _removeDownload = removeDownload,
        _engine = engine,
        _repository = repository,
        _notificationService = notificationService ?? BackgroundDownloadService(),
        super(DownloadInitial()) {
    on<AddDownload>(_onAddDownload);
    on<PauseDownload>(_onPauseDownload);
    on<ResumeDownload>(_onResumeDownload);
    on<RemoveDownload>(_onRemoveDownload);
    on<UpdateProgress>(_onUpdateProgress);
    on<LoadDownloads>(_onLoadDownloads);
    on<DownloadQueueUpdated>(_onQueueUpdated);
  }

  Future<void> _onAddDownload(
      AddDownload event, Emitter<DownloadState> emit) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();

    await _repository.addTask(DownloadTask(
      id: taskId,
      url: event.url,
      fileName: event.fileName,
      createdAt: DateTime.now(),
    ));

    _startEngine(taskId, event.url, event.fileName, 4);
  }

  Future<void> _startEngine(String taskId, String url, String fileName, int chunks) async {
    final dir = await DownloadPathManager.getPath();
    final savePath = '$dir/$fileName';

    final stream = _engine.downloadFile(
      taskId: taskId, url: url, savePath: savePath, chunks: chunks,
    );

    _progressSubs[taskId] = stream.listen(
      (progress) {
        add(UpdateProgress(
          taskId: progress.taskId,
          downloadedBytes: progress.downloadedBytes,
          totalBytes: progress.totalBytes,
          speed: progress.speed,
        ));
      },
      onError: (_) {
        _pauseDownload(taskId);
        _progressSubs.remove(taskId);
      },
      onDone: () {
        _progressSubs.remove(taskId);
        add(LoadDownloads());
      },
    );
  }

  Future<void> _onPauseDownload(
      PauseDownload event, Emitter<DownloadState> emit) async {
    _engine.cancel(event.taskId);
    _progressSubs[event.taskId]?.cancel();
    _progressSubs.remove(event.taskId);
    await _pauseDownload(event.taskId);
  }

  Future<void> _onResumeDownload(
      ResumeDownload event, Emitter<DownloadState> emit) async {
    await _resumeDownload(event.taskId);

    if (state is DownloadLoaded) {
      final tasks = (state as DownloadLoaded).tasks;
      final task = tasks.where((t) => t.id == event.taskId).lastOrNull;
      if (task != null) {
        _startEngine(task.id, task.url, task.fileName, task.chunksCount);
      }
    }
  }

  Future<void> _onRemoveDownload(
      RemoveDownload event, Emitter<DownloadState> emit) async {
    _engine.cancel(event.taskId);
    _progressSubs[event.taskId]?.cancel();
    _progressSubs.remove(event.taskId);
    await _removeDownload(event.taskId);
  }

  void _onUpdateProgress(
      UpdateProgress event, Emitter<DownloadState> emit) {
    if (state is DownloadLoaded) {
      final tasks = (state as DownloadLoaded).tasks.map((t) {
        if (t.id == event.taskId) {
          return t.copyWith(
            downloadedBytes: event.downloadedBytes,
            totalBytes: event.totalBytes,
            speed: event.speed,
            status: event.totalBytes > 0 && event.downloadedBytes >= event.totalBytes
                ? DownloadStatus.completed
                : DownloadStatus.downloading,
          );
        }
        return t;
      }).toList();
      emit(DownloadLoaded(tasks));
      _updateNotification(tasks);
    }
  }

  void _onLoadDownloads(
      LoadDownloads event, Emitter<DownloadState> emit) {
    emit(DownloadLoading());
    _queueSubscription?.cancel();
    _queueSubscription = _getDownloadQueue().listen((tasks) {
      add(DownloadQueueUpdated(tasks));
    });
  }

  void _onQueueUpdated(
      DownloadQueueUpdated event, Emitter<DownloadState> emit) {
    emit(DownloadLoaded(event.tasks));
    _updateNotification(event.tasks);
  }

  void _updateNotification(List<DownloadTask> tasks) {
    final active = tasks.where((t) => t.status == DownloadStatus.downloading).toList();
    final speed = active.fold<double>(0, (s, t) => s + t.speed);
    final speedText = speed > 0 ? '${_speedFormat.format(speed.toInt())}/s' : null;

    _notificationService.updateNotification(
      activeCount: active.length,
      statusText: active.isNotEmpty ? 'Downloading' : 'Idle',
      speedText: speedText,
    );
  }

  @override
  Future<void> close() {
    _engine.cancelAll();
    for (final sub in _progressSubs.values) {
      sub.cancel();
    }
    _progressSubs.clear();
    _queueSubscription?.cancel();
    return super.close();
  }
}
