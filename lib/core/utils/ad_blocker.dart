import 'package:flutter/foundation.dart';
import 'package:adblocker_webview/adblocker_webview.dart';

class AdBlocker {
  static const _domains = {
    'doubleclick.net', 'googlesyndication.com', 'googleadservices.com',
    'googletagservices.com', 'googletagmanager.com', 'google-analytics.com',
    'adservice.google.com', 'adsrvr.org', 'adnxs.com', 'rubiconproject.com',
    'pubmatic.com', 'exoclick.com', 'popads.net', 'propellerads.com',
    'adsterra.com', 'exosrv.com', 'adf.ly', 'shorte.st', 'linkbucks.com',
    'ouo.io', 'adcash.com', 'adbrite.com', 'popadscdn.net', 'adreactor.com',
    'adform.com', 'adroll.com', 'advertising.com', 'appnexus.com',
    'applovin.com', 'atdmt.com', 'awin.com', 'bluekai.com', 'branch.io',
    'chartbeat.com', 'chartboost.com', 'clicksor.com', 'clickbank.com',
    'demdex.net', 'gemius.pl', 'media.net', 'mopub.com', 'onetag.com',
    'outbrain.com', 'quantcast.com', 'scorecardresearch.com',
    'sharethrough.com', 'skimresources.com', 'sovrn.com', 'taboola.com',
    'tapad.com', 'tribalfusion.com', 'vibrantmedia.com', 'yieldmo.com',
    'yieldtraffic.com', 'adsco.re', 'viinyzfu.com',
  };

  static bool shouldBlock(String url) {
    try {
      if (AdBlockerWebviewController.instance.shouldBlockResource(url)) {
        return true;
      }
    } catch (e) {
      debugPrint('AdBlocker EasyList error: $e');
    }
    try {
      final host = Uri.parse(url).host.toLowerCase();
      return _domains.any((d) => host == d || host.endsWith('.$d'));
    } catch (_) {}
    return false;
  }
}
