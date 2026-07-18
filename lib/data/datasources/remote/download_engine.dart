import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

class DownloadEngine {
  final Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, Timer> _progressTimers = {};

  DownloadEngine()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          },
        ));

  Stream<DownloadProgress> downloadFile({
    required String taskId,
    required String url,
    required String savePath,
    Map<String, String>? extraHeaders,
  }) {
    final controller = StreamController<DownloadProgress>();
    _startDownload(controller, taskId, url, savePath, extraHeaders: extraHeaders);
    return controller.stream;
  }

  Future<void> _startDownload(
    StreamController<DownloadProgress> controller,
    String taskId,
    String url,
    String savePath, {
    Map<String, String>? extraHeaders,
  }) async {
    final cancelToken = CancelToken();
    _cancelTokens[taskId] = cancelToken;

    final startTime = DateTime.now();

    try {
      int? totalBytes;
      try {
        final headResp = await _dio.head(url,
            options: extraHeaders != null
                ? Options(headers: extraHeaders)
                : null);
        final cl = headResp.headers.value('content-length');
        if (cl != null) totalBytes = int.tryParse(cl);
      } catch (_) {}

      final file = File(savePath);

      final timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!controller.isClosed) {
          try {
            final size = file.lengthSync();
            final elapsed = DateTime.now().difference(startTime).inSeconds;
            final speed = elapsed > 0 ? size / elapsed : 0.0;
            controller.add(DownloadProgress(
              taskId: taskId,
              downloadedBytes: size,
              totalBytes: totalBytes ?? -1,
              speed: speed,
            ));
          } catch (_) {}
        }
      });
      _progressTimers[taskId] = timer;

      await _dio.download(
        url,
        savePath,
        cancelToken: cancelToken,
        deleteOnError: true,
        options: extraHeaders != null
            ? Options(headers: extraHeaders)
            : null,
      );

      timer.cancel();
      _progressTimers.remove(taskId);

      final finalSize = await file.length();
      if (!controller.isClosed) {
        if (totalBytes != null && finalSize >= totalBytes) {
          controller.add(DownloadProgress(
            taskId: taskId,
            downloadedBytes: totalBytes,
            totalBytes: totalBytes,
            speed: 0,
          ));
        } else {
          controller.add(DownloadProgress(
            taskId: taskId,
            downloadedBytes: finalSize,
            totalBytes: totalBytes ?? finalSize,
            speed: 0,
          ));
        }
        await controller.close();
      }
    } on DioException catch (e) {
      _progressTimers[taskId]?.cancel();
      _progressTimers.remove(taskId);
      if (e.type == DioExceptionType.cancel) {
        if (!controller.isClosed) {
          controller.add(DownloadProgress(
            taskId: taskId,
            downloadedBytes: 0,
            totalBytes: 0,
            speed: 0,
          ));
          await controller.close();
        }
      } else {
        if (!controller.isClosed) {
          controller.addError(e);
          await controller.close();
        }
      }
    } catch (e) {
      _progressTimers[taskId]?.cancel();
      _progressTimers.remove(taskId);
      if (!controller.isClosed) {
        controller.addError(e);
        await controller.close();
      }
    } finally {
      _cancelTokens.remove(taskId);
    }
  }

  void cancel(String taskId) {
    _progressTimers[taskId]?.cancel();
    _progressTimers.remove(taskId);
    _cancelTokens[taskId]?.cancel();
    _cancelTokens.remove(taskId);
  }

  void cancelAll() {
    for (final t in _progressTimers.values) {
      t.cancel();
    }
    _progressTimers.clear();
    for (final token in _cancelTokens.values) {
      token.cancel();
    }
    _cancelTokens.clear();
  }
}

class DownloadProgress {
  final String taskId;
  final int downloadedBytes;
  final int totalBytes;
  final double speed;

  const DownloadProgress({
    required this.taskId,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.speed,
  });
}
