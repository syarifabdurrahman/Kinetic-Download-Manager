import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';

class LinkHandler {
  static final LinkHandler _instance = LinkHandler._();
  factory LinkHandler() => _instance;
  LinkHandler._();

  static const _channel = MethodChannel('kinetic_flux/share');
  final _linksController = StreamController<String>.broadcast();
  StreamSubscription? _appLinksSub;

  Stream<String> get onLink => _linksController.stream;

  Future<void> init() async {
    _appLinksSub?.cancel();

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onUrl') {
        final url = call.arguments as String?;
        if (url != null && url.isNotEmpty) {
          _linksController.add(url);
        }
      }
      return null;
    });

    try {
      final appLinks = AppLinks();
      final initial = await appLinks.getInitialLink();
      if (initial != null && initial.toString().isNotEmpty) {
        _linksController.add(initial.toString());
      }

      _appLinksSub = appLinks.uriLinkStream.listen((uri) {
        _linksController.add(uri.toString());
      }, onError: (_) {});
    } catch (_) {}
  }

  void dispose() {
    _appLinksSub?.cancel();
    _linksController.close();
  }
}
