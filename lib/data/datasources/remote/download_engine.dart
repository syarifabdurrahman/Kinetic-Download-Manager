import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

class DownloadEngine {
  final Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};

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
    required int chunks,
  }) {
    final controller = StreamController<DownloadProgress>();
    _startDownload(controller, taskId, url, savePath, chunks);
    return controller.stream;
  }

  Future<void> _startDownload(
    StreamController<DownloadProgress> controller,
    String taskId,
    String url,
    String savePath,
    int chunks,
  ) async {
    final cancelToken = CancelToken();
    _cancelTokens[taskId] = cancelToken;

    try {
      final file = File(savePath);
      final raf = await file.open(mode: FileMode.write);

      try {
        final response = await _dio.get<ResponseBody>(
          url,
          options: Options(responseType: ResponseType.stream),
          cancelToken: cancelToken,
        );

        final total = response.headers.value('content-length');
        final totalBytes = total != null ? int.tryParse(total) ?? -1 : -1;
        final startTime = DateTime.now();
        int received = 0;

        await for (final chunk in response.data!.stream) {
          final bytes = chunk as List<int>;
          await raf.writeFrom(bytes);
          received += bytes.length;

          final elapsed = DateTime.now().difference(startTime).inSeconds;
          final speed = elapsed > 0 ? received / elapsed : 0.0;

          if (!controller.isClosed) {
            controller.add(DownloadProgress(
              taskId: taskId,
              downloadedBytes: received,
              totalBytes: totalBytes > 0 ? totalBytes : -1,
              speed: speed,
            ));
          }
        }

        await raf.close();

        if (!controller.isClosed) {
          if (totalBytes > 0) {
            controller.add(DownloadProgress(
              taskId: taskId,
              downloadedBytes: totalBytes,
              totalBytes: totalBytes,
              speed: 0,
            ));
          }
          await controller.close();
        }
      } on DioException catch (e) {
        await raf.close();
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
        await raf.close();
        if (!controller.isClosed) {
          controller.addError(e);
          await controller.close();
        }
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
        await controller.close();
      }
    } finally {
      _cancelTokens.remove(taskId);
      _startTimes.remove(taskId);
    }
  }

  final Map<String, DateTime> _startTimes = {};

  void cancel(String taskId) {
    _cancelTokens[taskId]?.cancel();
    _cancelTokens.remove(taskId);
    _startTimes.remove(taskId);
  }

  void cancelAll() {
    for (final token in _cancelTokens.values) {
      token.cancel();
    }
    _cancelTokens.clear();
    _startTimes.clear();
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
