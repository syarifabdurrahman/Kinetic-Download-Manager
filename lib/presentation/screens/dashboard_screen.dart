import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/file_type_detector.dart';
import '../../core/utils/link_handler.dart';
import '../../domain/entities/download_status.dart';
import '../blocs/download_bloc.dart';
import '../blocs/download_event.dart';
import '../blocs/download_state.dart';
import '../widgets/download_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_progress_bar.dart';
import '../widgets/speed_gauge.dart';
import '../widgets/storage_ring.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _detector = FileTypeDetector();
  final _linkHandler = LinkHandler();
  StreamSubscription? _linkSub;
  FileCategory _detectedCategory = FileCategory.other;
  bool _hasCheckedClipboard = false;
  double _totalSpeed = 0;
  double _globalProgress = 0;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<DownloadBloc>().add(LoadDownloads());

    _linkHandler.init().then((_) {
      _linkSub = _linkHandler.onLink.listen((url) {
        if (url.isNotEmpty && _isDownloadUrl(url)) {
          _urlController.text = url;
          _autoDetect(url);
          _showAddDialog();
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _urlController.dispose();
    _nameController.dispose();
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_hasCheckedClipboard) {
      _checkClipboard();
      _hasCheckedClipboard = true;
    } else if (state == AppLifecycleState.inactive) {
      _hasCheckedClipboard = false;
    }
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.isNotEmpty) {
        final text = data.text!.trim();
        if (_isDownloadUrl(text) && _urlController.text != text) {
          if (mounted) _showClipboardBanner(text);
        }
      }
    } catch (_) {}
  }

  bool _isDownloadUrl(String text) {
    return RegExp(r'^https?://[^\s/$.?#].[^\s]*\.\w+', caseSensitive: false)
        .hasMatch(text);
  }

  void _showClipboardBanner(String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surfaceContainer,
        content: const Text('URL detected in clipboard'),
        action: SnackBarAction(
          label: 'Add', textColor: AppTheme.primary,
          onPressed: () {
            _urlController.text = url;
            _autoDetect(url);
            _showAddDialog();
          },
        ),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _autoDetect(String url) async {
    final info = await _detector.detectFromUrl(url);
    _nameController.text = info.fileName;
    _detectedCategory = info.category;
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('New Download'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'URL', hintText: 'https://...'),
              onChanged: (val) {
                if (val.isNotEmpty) {
                  _autoDetect(val);
                  setDialogState(() {});
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'File Name', hintText: 'myfile.zip',
                suffixIcon: _detectedCategory != FileCategory.other
                    ? Chip(
                        label: Text(_detector.getCategoryLabel(_detectedCategory),
                            style: const TextStyle(fontSize: 10)),
                        backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.2),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )
                    : null,
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_urlController.text.isNotEmpty && _nameController.text.isNotEmpty) {
                  context.read<DownloadBloc>().add(AddDownload(
                      _urlController.text, _nameController.text));
                  _urlController.clear();
                  _nameController.clear();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text('KFDM',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(fontSize: 24, letterSpacing: 1)),
                  ),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.person, color: AppTheme.onSurfaceVariant, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              BlocBuilder<DownloadBloc, DownloadState>(
                builder: (context, state) {
                  if (state is DownloadLoaded) {
                    final active = state.tasks
                        .where((t) => t.status == DownloadStatus.downloading);
                    _totalSpeed = active.fold(0.0, (s, t) => s + t.speed);
                    _globalProgress = state.tasks.isEmpty
                        ? 0
                        : state.tasks.fold(0.0, (p, t) => p + t.progress) /
                            state.tasks.length;
                  }
                  return GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      const Text('GLOBAL BANDWIDTH',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                              letterSpacing: 0.8, color: AppTheme.onSurfaceVariant)),
                      SpeedGauge(speed: _totalSpeed, label: 'DOWNLOAD'),
                      const SizedBox(height: 8),
                      GlassProgressBar(progress: _globalProgress),
                    ]),
                  );
                },
              ),
              BlocBuilder<DownloadBloc, DownloadState>(
                builder: (context, state) {
                  final bytes = state is DownloadLoaded
                      ? state.tasks.fold<int>(
                          0, (b, t) => b + t.downloadedBytes)
                      : 0;
                  return GlassCard(
                    child: StorageRing(bytesUsed: bytes),
                  );
                },
              ),
              Row(
                children: [
                  Text('Active Downloads',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Text('Clear All',
                      style: TextStyle(fontSize: 12, color: AppTheme.primary)),
                ],
              ),
              const SizedBox(height: 8),
              BlocBuilder<DownloadBloc, DownloadState>(
                builder: (context, state) {
                  if (state is DownloadLoaded && state.tasks.isNotEmpty) {
                    return Column(
                      children: state.tasks.map((task) =>
                          DownloadCard(
                            task: task,
                            onPause: () => context.read<DownloadBloc>()
                                .add(PauseDownload(task.id)),
                            onResume: () => context.read<DownloadBloc>()
                                .add(ResumeDownload(task.id)),
                            onRemove: () => context.read<DownloadBloc>()
                                .add(RemoveDownload(task.id)),
                          ),
                      ).toList(),
                    );
                  }
                  return GlassCard(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: const Center(
                        child: Text('No active downloads',
                            style: TextStyle(color: AppTheme.onSurfaceVariant)),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Recently Completed',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              BlocBuilder<DownloadBloc, DownloadState>(
                builder: (context, state) {
                  if (state is DownloadLoaded) {
                    final completed = state.tasks
                        .where((t) => t.status == DownloadStatus.completed)
                        .toList();
                    if (completed.isEmpty) {
                      return GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        child: const Center(
                          child: Text('No completed downloads',
                              style: TextStyle(color: AppTheme.onSurfaceVariant)),
                        ),
                      );
                    }
                    return Column(
                      children: completed.take(5).map((task) => GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.tertiary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.check_circle_outline,
                                color: AppTheme.tertiary, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(task.fileName,
                                    style: const TextStyle(fontSize: 14,
                                        fontWeight: FontWeight.w600, color: AppTheme.onSurface),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text('${(task.totalBytes / 1073741824).toStringAsFixed(1)} GB • Completed',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          const Icon(Icons.more_horiz, color: AppTheme.outline, size: 20),
                        ]),
                      )).toList(),
                    );
                  }
                  return const SizedBox();
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primaryContainer,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
