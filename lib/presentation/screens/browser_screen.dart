import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/file_type_detector.dart';
import '../blocs/download_bloc.dart';
import '../blocs/download_event.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final _urlController = TextEditingController();
  final _detector = FileTypeDetector();
  WebViewController? _controller;
  bool _isLoading = false;
  bool _canGoBack = false;
  bool _canGoForward = false;
  double _progress = 0;

  static final _downloadExtensions = RegExp(
    r'\.(mp4|mkv|avi|mov|wmv|flv|webm|m4v|mp3|wav|flac|aac|ogg|m4a|pdf|doc|docx|xls|xlsx|ppt|pptx|txt|csv|epub|jpg|jpeg|png|gif|bmp|webp|svg|ico|zip|rar|7z|tar|gz|bz2|xz|iso|exe|msi|apk|dmg|deb|rpm|bin)$',
    caseSensitive: false,
  );

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _goHome() {
    _loadUrl('https://www.google.com');
  }

  void _loadUrl(String url) {
    final controller = _controller;
    if (controller == null) return;

    var finalUrl = url.trim();
    if (finalUrl.isEmpty) return;
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'https://$finalUrl';
    }

    _urlController.text = finalUrl;
    controller.loadRequest(Uri.parse(finalUrl));
    FocusScope.of(context).unfocus();
  }

  void _interceptDownload(String url) {
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
                    _detailRow('Source', url,
                        maxLines: 2, fontSize: 11),
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
                      context.read<DownloadBloc>().add(AddDownload(url, fileName));
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
            if (_isLoading)
              LinearProgressIndicator(
                value: _progress,
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
    return Padding(
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
    );
  }

  Widget _buildUrlBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
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
            color: _canGoBack ? AppTheme.onSurface : AppTheme.outline,
            onPressed: _canGoBack ? () => _controller?.goBack() : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            color: _canGoForward ? AppTheme.onSurface : AppTheme.outline,
            onPressed: _canGoForward ? () => _controller?.goForward() : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: AppTheme.onSurfaceVariant,
            onPressed: () => _controller?.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded, size: 20),
            color: AppTheme.onSurfaceVariant,
            onPressed: _goHome,
          ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: WebViewWidget(
          controller: _createController(),
        ),
      ),
    );
  }

  WebViewController _createController() {
    if (_controller != null) return _controller!;

    final controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setNavigationDelegate(NavigationDelegate(
      onPageStarted: (url) {
        if (mounted) {
          setState(() {
            _isLoading = true;
            _urlController.text = url;
          });
        }
      },
      onPageFinished: (url) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _progress = 0;
          });
        }
        controller.canGoBack().then((v) {
          if (mounted) setState(() => _canGoBack = v);
        });
        controller.canGoForward().then((v) {
          if (mounted) setState(() => _canGoForward = v);
        });
      },
      onProgress: (progress) {
        if (mounted) setState(() => _progress = progress / 100);
      },
      onNavigationRequest: (request) {
        final url = request.url;
        if (_downloadExtensions.hasMatch(url)) {
          _interceptDownload(url);
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
      onUrlChange: (change) {
        final url = change.url ?? '';
        if (mounted && url.isNotEmpty) {
          _urlController.text = url;
        }
      },
    ));
    controller.loadRequest(Uri.parse('https://www.google.com'));

    _urlController.text = 'https://www.google.com';
    _controller = controller;
    return controller;
  }
}
