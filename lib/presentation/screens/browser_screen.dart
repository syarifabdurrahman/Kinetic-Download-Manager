import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_theme.dart';
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
        setState(() {
          tab.isLoading = true;
          tab.url = url;
          _urlController.text = url;
        });
      },
      onPageFinished: (url) {
        if (!mounted) return;
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
      },
      onProgress: (progress) {
        if (!mounted) return;
        setState(() => tab.progress = progress / 100);
      },
      onNavigationRequest: (request) {
        final url = request.url;
        if (_downloadExtensions.hasMatch(url)) {
          _prepareDownload(url);
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

  void _prepareDownload(String url) async {
    Map<String, String>? headers;
    try {
      final tab = _currentTab;
      final controller = tab.controller;
      String? userAgent;
      if (controller != null) {
        final ua = await controller.runJavaScriptReturningResult('navigator.userAgent');
        var uaStr = ua.toString();
        if (uaStr.startsWith('"') && uaStr.endsWith('"')) {
          uaStr = uaStr.substring(1, uaStr.length - 1);
        }
        uaStr = uaStr.replaceAll(r'\"', '"');
        if (uaStr.trim().isNotEmpty) {
          userAgent = uaStr.trim();
        }
      }

      final cookies = await CookieHelper.getCookies(url);
      final referrerCookies = await CookieHelper.getCookies(_currentTab.url);
      final referrer = _currentTab.url;
      final map = <String, String>{};

      final cookieMap = <String, String>{};
      void parseCookies(String? cookieStr) {
        if (cookieStr == null || cookieStr.trim().isEmpty) return;
        final pairs = cookieStr.split(';');
        for (final pair in pairs) {
          final idx = pair.indexOf('=');
          if (idx > 0) {
            final key = pair.substring(0, idx).trim();
            final val = pair.substring(idx + 1).trim();
            cookieMap[key] = val;
          }
        }
      }
      parseCookies(cookies);
      parseCookies(referrerCookies);

      if (cookieMap.isNotEmpty) {
        map['Cookie'] = cookieMap.entries.map((e) => '${e.key}=${e.value}').join('; ');
      }
      if (referrer.startsWith('http')) {
        map['Referer'] = referrer;
      }
      if (userAgent != null) {
        map['User-Agent'] = userAgent;
      }
      if (map.isNotEmpty) headers = map;
    } catch (_) {}
    _interceptDownload(url, headers);
  }

  void _interceptDownload(String url, [Map<String, String>? headers]) {
    final fileName = _detector.extractFileName(url, null) ?? 'download.bin';
    final category = _detector.categoryFromExtension(url);
    final label = _detector.getCategoryLabel(category);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.download_rounded,
                        color: AppTheme.primaryContainer, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Download File',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow('Name', fileName),
                    const SizedBox(height: 6),
                    _detailRow('Type', label),
                    const SizedBox(height: 6),
                    _detailRow('Source', url, maxLines: 2, fontSize: 11),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<DownloadBloc>().add(AddDownload(url, fileName, headers: headers));
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {int maxLines = 1, double fontSize = 13}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 0.5, color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(fontSize: fontSize, color: AppTheme.onSurface),
            maxLines: maxLines, overflow: TextOverflow.ellipsis),
      ],
    );
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
          const SizedBox(width: 8),
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
