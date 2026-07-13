import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundDownloadService {
  static final BackgroundDownloadService _instance =
      BackgroundDownloadService._();
  factory BackgroundDownloadService() => _instance;
  BackgroundDownloadService._();

  bool _initialized = false;
  final _service = FlutterBackgroundService();

  Future<void> initialize() async {
    if (_initialized) return;

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        notificationChannelId: 'kinetic_download_channel',
        initialNotificationTitle: 'KFDM',
        initialNotificationContent: 'Download Manager is running',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
      ),
    );

    _initialized = true;
  }

  void _onStart(ServiceInstance service) {
    service.on('update_notification').listen((data) {
      if (service is AndroidServiceInstance) {
        final title = data!['title'] as String? ?? 'KFDM';
        final content = data['content'] as String? ?? '';
        service.setForegroundNotificationInfo(title: title, content: content);
      }
    });

    service.on('stop').listen((_) {
      service.stopSelf();
    });

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'KFDM',
        content: 'Download Manager is running',
      );
    }
  }

  Future<void> start() async {
    final running = await _service.isRunning();
    if (!running) {
      await _service.startService();
    }
  }

  void stop() {
    _service.invoke('stop');
  }

  void updateNotification({
    required int activeCount,
    required String statusText,
    String? speedText,
  }) {
    final content = activeCount > 0
        ? '$activeCount active • $statusText${speedText != null ? ' • $speedText' : ''}'
        : 'Download Manager is running';

    _service.invoke('update_notification', {
      'title': 'KFDM',
      'content': content,
    });
  }
}
