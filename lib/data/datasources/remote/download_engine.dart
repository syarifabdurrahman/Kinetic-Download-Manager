import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

class DownloadEngine {
  final Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};

  DownloadEngine() : _dio = Dio();

  Future<int> getFileSize(String url) async {
    try {
      final response = await _dio.head(url);
      final length = response.headers.value('content-length');
      return length != null ? int.parse(length) : 0;
    } catch (_) {
      return 0;
    }
  }

  bool supportsResume(String url) {
    return true;
  }

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

    final fileSize = await getFileSize(url);
    if (fileSize == 0) {
      controller.add(DownloadProgress(taskId: taskId, downloadedBytes: 0, totalBytes: 0, speed: 0));
      controller.close();
      return;
    }

    final chunkSize = fileSize ~/ chunks;
    final chunkPaths = List.generate(chunks, (i) => '$savePath.part$i');
    final chunkErrors = List<int>.empty(growable: true);
    int totalDownloaded = 0;
    final startTime = DateTime.now();
    final chunkCompleters = List.generate(chunks, (_) => Completer<void>());

    for (int i = 0; i < chunks; i++) {
      final start = i * chunkSize;
      final end = (i == chunks - 1) ? fileSize - 1 : start + chunkSize - 1;
      final chunkPath = chunkPaths[i];
      final chunkIndex = i;

      _downloadChunk(url, start, end, chunkPath, cancelToken).listen(
        (downloaded) {
          totalDownloaded += downloaded;
          final elapsed = DateTime.now().difference(startTime).inSeconds;
          final speed = elapsed > 0 ? totalDownloaded / elapsed : 0.0;
          controller.add(DownloadProgress(
            taskId: taskId,
            downloadedBytes: totalDownloaded,
            totalBytes: fileSize,
            speed: speed,
          ));
        },
        onError: (e) {
          chunkErrors.add(chunkIndex);
          if (!chunkCompleters[chunkIndex].isCompleted) {
            chunkCompleters[chunkIndex].complete();
          }
        },
        onDone: () {
          if (!chunkCompleters[chunkIndex].isCompleted) {
            chunkCompleters[chunkIndex].complete();
          }
        },
        cancelOnError: false,
      );
    }

    await Future.wait(chunkCompleters.map((c) => c.future));

    if (cancelToken.isCancelled || chunkErrors.length == chunks) {
      for (final p in chunkPaths) {
        await File(p).delete(recursive: true);
      }
      if (!controller.isClosed) {
        controller.add(DownloadProgress(
          taskId: taskId, downloadedBytes: totalDownloaded,
          totalBytes: fileSize, speed: 0,
        ));
        await controller.close();
      }
      _cancelTokens.remove(taskId);
      return;
    }

    final outFile = File(savePath);
    if (await outFile.exists()) {
      await outFile.delete();
    }

    final raf = await outFile.open(mode: FileMode.write);
    for (int i = 0; i < chunks; i++) {
      final partFile = File(chunkPaths[i]);
      if (await partFile.exists()) {
        await raf.writeFrom(await partFile.readAsBytes());
        await partFile.delete();
      }
    }
    await raf.close();

    controller.add(DownloadProgress(
      taskId: taskId, downloadedBytes: fileSize,
      totalBytes: fileSize, speed: 0,
    ));
    await controller.close();
    _cancelTokens.remove(taskId);
  }

  Stream<int> _downloadChunk(
    String url, int start, int end, String savePath, CancelToken cancelToken,
  ) {
    final controller = StreamController<int>();
    final file = File(savePath);

    _dio
        .get<ResponseBody>(
          url,
          options: Options(
            responseType: ResponseType.stream,
            headers: {'Range': 'bytes=$start-$end'},
          ),
          cancelToken: cancelToken,
        )
        .then((response) async {
          final raf = await file.open(mode: FileMode.write);
          await for (final data in response.data!.stream) {
            final bytes = data as List<int>;
            await raf.writeFrom(bytes);
            controller.add(bytes.length);
          }
          await raf.close();
          await controller.close();
        })
        .catchError((e) {
          if (!controller.isClosed) controller.addError(e);
        });

    return controller.stream;
  }

  void cancel(String taskId) {
    _cancelTokens[taskId]?.cancel();
    _cancelTokens.remove(taskId);
  }

  void cancelAll() {
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
