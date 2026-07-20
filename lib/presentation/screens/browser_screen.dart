import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:adblocker_webview/adblocker_webview.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bookmark_service.dart';
import '../../core/utils/cookie_helper.dart';
import '../../core/utils/file_type_detector.dart';
import '../blocs/download_bloc.dart';
import '../blocs/download_event.dart';

class _TabData {
  final String id;
  String url;
  String title = 'New Tab';
  WebViewController? controller;
  bool isLoading = false;
  double progress = 0;
  bool canGoBack = false;
  bool canGoForward = false;

  _TabData({
    required this.id,
    required this.url,
  });
}

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final _urlController = TextEditingController();
  final _detector = FileTypeDetector();
  int _tabCounter = 0;
  final List<_TabData> _tabs = [];
  int _currentIndex = 0;
  String? _pendingDownloadUrl;
  String? _pendingDownloadPrevUrl;
  final List<MapEntry<String, String>> _history = [];

  static final _downloadExtensions = RegExp(
    r'\.(mp4|mkv|avi|mov|wmv|flv|webm|m4v|mp3|wav|flac|aac|ogg|m4a|pdf|doc|docx|xls|xlsx|ppt|pptx|txt|csv|epub|jpg|jpeg|png|gif|bmp|webp|svg|ico|zip|rar|7z|tar|gz|bz2|xz|iso|exe|msi|apk|dmg|deb|rpm|bin)$',
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();
    _addTab();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  _TabData get _currentTab => _tabs[_currentIndex];

  void _addTab({String url = 'https://www.google.com'}) {
    _tabCounter++;
    final id = 'tab_$_tabCounter';
    final tab = _TabData(id: id, url: url);
    _tabs.add(tab);
    _currentIndex = _tabs.length - 1;
    _initTabController(tab);
    setState(() {});
  }

  void _closeTab(int index) {
    if (_tabs.length <= 1) return;
    _tabs.removeAt(index);
    if (_currentIndex >= _tabs.length) {
      _currentIndex = _tabs.length - 1;
    }
    setState(() {});
  }

  void _switchTab(int index) {
    if (index == _currentIndex) return;
    _currentIndex = index;
    _urlController.text = _currentTab.url;
    setState(() {});
  }

  void _initTabController(_TabData tab) {
    final controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setNavigationDelegate(NavigationDelegate(
      onPageStarted: (url) {
        if (!mounted || tab != _currentTab) return;
        if (_pendingDownloadUrl == null) {
          try {
            if (AdBlockerWebviewController.instance.shouldBlockResource(url)) {
              tab.controller?.goBack();
              return;
            }
          } catch (_) {}
        }
        setState(() {
          tab.isLoading = true;
          tab.url = url;
          _urlController.text = url;
        });
        _injectAdblockCss(tab.controller!, url);
      },
      onPageFinished: (url) {
        if (!mounted) return;
        _addHistory(url);
        controller.getTitle().then((title) {
          if (mounted) setState(() => tab.title = title ?? url);
        });
        controller.canGoBack().then((v) {
          if (mounted) setState(() => tab.canGoBack = v);
        });
        controller.canGoForward().then((v) {
          if (mounted) setState(() => tab.canGoForward = v);
        });
        if (mounted) {
          setState(() {
            tab.isLoading = false;
            tab.progress = 0;
          });
        }
        if (_pendingDownloadUrl != null) {
          final dlUrl = _pendingDownloadUrl!;
          final prevUrl = _pendingDownloadPrevUrl;
          _pendingDownloadUrl = null;
          _pendingDownloadPrevUrl = null;
          _executeDownloadWithCookies(dlUrl, prevUrl);
        }
      },
      onProgress: (progress) {
        if (!mounted) return;
        setState(() => tab.progress = progress / 100);
      },
      onNavigationRequest: (request) {
        if (_pendingDownloadUrl != null) return NavigationDecision.navigate;
        try {
          if (AdBlockerWebviewController.instance.shouldBlockResource(request.url)) {
            return NavigationDecision.prevent;
          }
        } catch (_) {}
        if (_downloadExtensions.hasMatch(request.url)) {
          _directDownload(request.url);
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
      onUrlChange: (change) {
        final url = change.url ?? '';
        if (!mounted) return;
        tab.url = url;
        if (tab == _currentTab) {
          _urlController.text = url;
        }
      },
    ));
    controller.loadRequest(Uri.parse(tab.url));
    tab.controller = controller;
    setState(() {});
  }

  void _loadUrl(String url) {
    final tab = _currentTab;
    if (tab.controller == null) return;

    var finalUrl = url.trim();
    if (finalUrl.isEmpty) return;
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'https://$finalUrl';
    }

    _urlController.text = finalUrl;
    tab.url = finalUrl;
    tab.controller!.loadRequest(Uri.parse(finalUrl));
    FocusScope.of(context).unfocus();
  }

  void _handleDownloadViaWebView(String url) async {
    if (_pendingDownloadUrl != null) return;
    final controller = _currentTab.controller;
    if (controller == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Loading download URL...'),
      duration: const Duration(seconds: 1),
    ));

    _pendingDownloadUrl = url;
    _pendingDownloadPrevUrl = _currentTab.url;
    await controller.loadRequest(Uri.parse(url));

    Future.delayed(const Duration(seconds: 8), () {
      if (_pendingDownloadUrl != null) {
        final dlUrl = _pendingDownloadUrl!;
        final prevUrl = _pendingDownloadPrevUrl;
        _pendingDownloadUrl = null;
        _pendingDownloadPrevUrl = null;
        _executeDownloadWithCookies(dlUrl, prevUrl);
      }
    });
  }

  Future<void> _executeDownloadWithCookies(String url, String? prevUrl) async {
    final fileName = _detector.extractFileName(url, null) ?? 'download.bin';

    Map<String, String>? headers;
    try {
      final dirCookies = await CookieHelper.getCookies(url);
      final refCookies = await CookieHelper.getCookies(_currentTab.url);
      final referrer = _currentTab.url;
      final map = <String, String>{};

      final cookieMap = <String, String>{};
      void parseCookies(String? cookieStr) {
        if (cookieStr == null || cookieStr.trim().isEmpty) return;
        for (final pair in cookieStr.split(';')) {
          final idx = pair.indexOf('=');
          if (idx > 0) {
            final key = pair.substring(0, idx).trim();
            final val = pair.substring(idx + 1).trim();
            cookieMap[key] = val;
          }
        }
      }
      parseCookies(dirCookies);
      parseCookies(refCookies);

      if (cookieMap.isNotEmpty) {
        map['Cookie'] = cookieMap.entries.map((e) => '${e.key}=${e.value}').join('; ');
      }
      if (referrer.startsWith('http')) {
        map['Referer'] = referrer;
      }
      if (map.isNotEmpty) headers = map;
    } catch (_) {}

    if (prevUrl != null) {
      try {
        await _currentTab.controller?.loadRequest(Uri.parse(prevUrl));
      } catch (_) {}
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Downloading $fileName'),
      duration: const Duration(seconds: 2),
    ));
    context.read<DownloadBloc>().add(AddDownload(url, fileName, headers: headers));
  }

  void _directDownload(String url) async {
    final fileName = _detector.extractFileName(url, null) ?? 'download.bin';
    Map<String, String>? headers;
    try {
      final dirCookies = await CookieHelper.getCookies(url);
      final refCookies = await CookieHelper.getCookies(_currentTab.url);
      final referrer = _currentTab.url;
      final map = <String, String>{};
      final cookieMap = <String, String>{};
      void parseCookies(String? s) {
        if (s == null || s.trim().isEmpty) return;
        for (final pair in s.split(';')) {
          final idx = pair.indexOf('=');
          if (idx > 0) cookieMap[pair.substring(0, idx).trim()] = pair.substring(idx + 1).trim();
        }
      }
      parseCookies(dirCookies);
      parseCookies(refCookies);
      if (cookieMap.isNotEmpty) map['Cookie'] = cookieMap.entries.map((e) => '${e.key}=${e.value}').join('; ');
      if (referrer.startsWith('http')) map['Referer'] = referrer;
      if (map.isNotEmpty) headers = map;
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Downloading $fileName'),
      duration: const Duration(seconds: 2),
    ));
    context.read<DownloadBloc>().add(AddDownload(url, fileName, headers: headers));
  }

  void _injectAdblockCss(WebViewController controller, String url) {
    try {
      final rules = AdBlockerWebviewController.instance.getCssRulesForWebsite(url);
      if (rules.isEmpty) return;
      final css = rules.map((r) => r.trim()).join(' ').replaceAll("'", "\\'").replaceAll('\n', ' ');
      controller.runJavaScript("""
        (function() {
          try {
            var s = document.createElement('style');
            s.textContent = '$css';
            document.head.appendChild(s);
          } catch(e) {}
        })();
      """);
    } catch (_) {}
  }

  void _addHistory(String url) {
    _history.removeWhere((e) => e.key == url);
    _history.insert(0, MapEntry(url, _currentTab.title));
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text('History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_sweep, size: 20, color: AppTheme.onSurfaceVariant),
                  onPressed: () { setState(() => _history.clear()); Navigator.pop(ctx); },
                ),
              ],
            ),
          ),
          if (_history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No history', style: TextStyle(color: AppTheme.onSurfaceVariant)),
            )
          else
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (_, i) {
                  final e = _history[i];
                  return ListTile(
                    dense: true,
                    title: Text(e.value == e.key ? e.key : e.value,
                        style: const TextStyle(fontSize: 13, color: AppTheme.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(e.key,
                        style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 16, color: AppTheme.error),
                      onPressed: () { setState(() => _history.removeAt(i)); Navigator.pop(ctx); _showHistory(); },
                    ),
                    onTap: () { Navigator.pop(ctx); _loadUrl(e.key); },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showBookmarks() async {
    final bookmarks = await BookmarkService.getAll();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text('Bookmarks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppTheme.onSurfaceVariant),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
          if (bookmarks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No bookmarks', style: TextStyle(color: AppTheme.onSurfaceVariant)),
            )
          else
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: ListView.builder(
                itemCount: bookmarks.length,
                itemBuilder: (_, i) {
                  final b = bookmarks[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.bookmark, size: 18, color: AppTheme.primaryContainer),
                    title: Text(b.title,
                        style: const TextStyle(fontSize: 13, color: AppTheme.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(b.url,
                        style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 16, color: AppTheme.error),
                      onPressed: () async {
                        await BookmarkService.remove(b.url);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _showBookmarks();
                      },
                    ),
                    onTap: () { Navigator.pop(ctx); _loadUrl(b.url); },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleBookmark() async {
    final url = _currentTab.url;
    final title = _currentTab.title;
    if (await BookmarkService.exists(url)) {
      await BookmarkService.remove(url);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bookmark removed'), duration: Duration(seconds: 1)));
    } else {
      await BookmarkService.add(Bookmark(url: url, title: title));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bookmark added'), duration: Duration(seconds: 1)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildUrlBar(),
            _buildNavBar(),
            Expanded(child: _buildWebView()),
            if (_currentTab.isLoading)
              LinearProgressIndicator(
                value: _currentTab.progress,
                backgroundColor: AppTheme.surfaceContainerHighest,
                color: AppTheme.primaryContainer,
                minHeight: 2,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Text('KFDM',
                  style: Theme.of(context).textTheme.headlineLarge
                      ?.copyWith(fontSize: 20, letterSpacing: 1)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.history_rounded, size: 18),
                color: AppTheme.onSurfaceVariant,
                tooltip: 'History',
                onPressed: _showHistory,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border_rounded, size: 18),
                color: AppTheme.onSurfaceVariant,
                tooltip: 'Bookmarks',
                onPressed: _showBookmarks,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('BROWSER',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                        letterSpacing: 1, color: AppTheme.primaryContainer)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _tabs.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 4),
            itemBuilder: (context, i) {
              if (i == _tabs.length) {
                return Center(
                  child: IconButton(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    color: AppTheme.onSurfaceVariant,
                    onPressed: () => _addTab(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                );
              }
              final tab = _tabs[i];
              final selected = i == _currentIndex;
              return GestureDetector(
                onTap: () => _switchTab(i),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primaryContainer.withValues(alpha: 0.2)
                        : AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: selected
                        ? Border.all(color: AppTheme.primaryContainer.withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          tab.title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? AppTheme.primaryContainer : AppTheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _closeTab(i),
                        child: Icon(Icons.close, size: 14,
                            color: selected ? AppTheme.primaryContainer : AppTheme.outline),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUrlBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'Search or enter URL...',
                hintStyle: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                prefixIcon: const Icon(Icons.search, color: AppTheme.onSurfaceVariant, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.surfaceContainerLow,
              ),
              style: const TextStyle(fontSize: 13, color: AppTheme.onSurface),
              onSubmitted: _loadUrl,
            ),
          ),
          _buildBookmarkBtn(),
          const SizedBox(width: 4),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
              onPressed: () => _loadUrl(_urlController.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkBtn() {
    return FutureBuilder<bool>(
      future: BookmarkService.exists(_currentTab.url),
      builder: (_, snap) {
        final isBookmarked = snap.data ?? false;
        return IconButton(
          icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, size: 18, color: AppTheme.primaryContainer),
          onPressed: () { _toggleBookmark(); setState(() {}); },
        );
      },
    );
  }

  Widget _buildNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            color: _currentTab.canGoBack ? AppTheme.onSurface : AppTheme.outline,
            onPressed: _currentTab.canGoBack ? () => _currentTab.controller?.goBack() : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            color: _currentTab.canGoForward ? AppTheme.onSurface : AppTheme.outline,
            onPressed: _currentTab.canGoForward ? () => _currentTab.controller?.goForward() : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: AppTheme.onSurfaceVariant,
            onPressed: () => _currentTab.controller?.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, size: 20),
            color: AppTheme.primaryContainer,
            onPressed: () => _handleDownloadViaWebView(_currentTab.url),
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded, size: 20),
            color: AppTheme.onSurfaceVariant,
            onPressed: () => _loadUrl('https://www.google.com'),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    final tab = _currentTab;
    if (tab.controller == null) return const SizedBox();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: WebViewWidget(controller: tab.controller!),
      ),
    );
  }
}
