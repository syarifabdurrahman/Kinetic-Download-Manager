import 'package:flutter/services.dart';

class CookieHelper {
  static const _channel = MethodChannel('kinetic_flux/cookies');

  static Future<String?> getCookies(String url) async {
    try {
      final cookies = await _channel.invokeMethod<String>('getCookies', {'url': url});
      return cookies;
    } catch (_) {
      return null;
    }
  }
}
