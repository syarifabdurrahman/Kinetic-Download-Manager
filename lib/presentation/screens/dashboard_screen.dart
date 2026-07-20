import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/file_type_detector.dart';
import '../../core/utils/link_handler.dart';
import '../../domain/entities/download_status.dart';
import '../blocs/download_bloc.dart';
import '../blocs/download_event.dart';
import '../blocs/download_state.dart';
import '../widgets/download_card.dart';

const _explorerChannel = MethodChannel('kinetic_flux/file_explorer');

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
  StreamSubscription? _blocSub;
  FileCategory _detectedCategory = FileCategory.other;
  bool _hasCheckedClipboard = false;
  DownloadStatus? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForCompleted();
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
    _blocSub?.cancel();
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

  void _listenForCompleted() {
    _blocSub = context.read<DownloadBloc>().stream.listen((state) {
      if (state is DownloadLoaded && state.lastCompleted != null && mounted) {
        final task = state.lastCompleted!;
        final snackBar = SnackBar(
          backgroundColor: AppTheme.surfaceContainer,
          content: Text('${task.fileName} downloaded'),
          action: SnackBarAction(
            label: 'Show on Explorer',
            textColor: AppTheme.primary,
            onPressed: () {
              if (task.savePath != null) {
                final dir = task.savePath!.substring(0, task.savePath!.lastIndexOf('/'));
                OpenFilex.open(dir);
              }
            },
          ),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        context.read<DownloadBloc>().add(DismissCompleted());
      }
    });
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
        content: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _urlController.text = url;
            _autoDetect(url);
            _showAddDialog();
          },
          child: const Row(
            children: [
              Icon(Icons.content_paste_rounded, size: 16, color: AppTheme.primary),
              SizedBox(width: 8),
              Expanded(child: Text('URL detected in clipboard – tap to add')),
            ],
          ),
        ),
        action: SnackBarAction(
          label: 'Cancel', textColor: AppTheme.onSurfaceVariant,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _autoDetect(String url) {
    final name = _detector.extractFileName(url, null);
    if (name != null) {
      _nameController.text = name;
    }
    _detectedCategory = _detector.categoryFromExtension(url);

    _detector.detectFromUrl(url).then((info) {
      if (mounted && _urlController.text == url) {
        _nameController.text = info.fileName;
        _detectedCategory = info.category;
      }
    });
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
              onPressed: () {
                _urlController.clear();
                _nameController.clear();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_urlController.text.isNotEmpty && _nameController.text.isNotEmpty) {
                  context.read<DownloadBloc>().add(AddDownload(
                      _urlController.text, _nameController.text));
                  _urlController.clear();
                  _nameController.clear();
                  if (ctx.mounted) Navigator.pop(ctx);
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text('Downloads',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  const Spacer(),
                  Text('${_activeCount(context)} running',
                      style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildFilterChips(),
            const SizedBox(height: 8),
            Expanded(child: _buildList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primaryContainer,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = <DownloadStatus?>[
      null,
      DownloadStatus.downloading,
      DownloadStatus.paused,
      DownloadStatus.completed,
    ];
    final labels = ['All', 'Active', 'Paused', 'Completed'];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, i) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final selected = _filter == filters[i];
          return ChoiceChip(
            label: Text(labels[i], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            selected: selected,
            selectedColor: AppTheme.primaryContainer,
            backgroundColor: AppTheme.surfaceContainerHigh,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppTheme.onSurfaceVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide.none,
            ),
            onSelected: (_) => setState(() => _filter = filters[i]),
          );
        },
      ),
    );
  }

  void _openFile(String path) {
    if (!File(path).existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surfaceContainer,
            content: Text('File not found: $path'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    OpenFilex.open(path, type: '*/*').then((result) {
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surfaceContainer,
            content: Text('Cannot open file ($path): ${result.message}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _showInFolder(String path) {
    final dir = Directory(path).parent.path;
    _explorerChannel.invokeMethod('showInFolder', {'path': dir}).then((_) {
      if (!mounted) return;
      Clipboard.setData(ClipboardData(text: dir));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.surfaceContainer,
          content: Text('Backup path: $dir'),
          action: SnackBarAction(label: 'Copied', textColor: AppTheme.primary, onPressed: () => Clipboard.setData(ClipboardData(text: dir))),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }).catchError((_) {
      if (!mounted) return;
      Clipboard.setData(ClipboardData(text: dir));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.surfaceContainer,
          content: Text('Cannot open explorer. Path: $dir'),
          action: SnackBarAction(label: 'Copied', textColor: AppTheme.primary, onPressed: () => Clipboard.setData(ClipboardData(text: dir))),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    });
  }

  int _activeCount(BuildContext context) {
    final state = context.watch<DownloadBloc>().state;
    if (state is DownloadLoaded) {
      return state.tasks.where((t) => t.status == DownloadStatus.downloading).length;
    }
    return 0;
  }

  Widget _buildList() {
    return BlocBuilder<DownloadBloc, DownloadState>(
      builder: (context, state) {
        if (state is DownloadInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DownloadLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DownloadError) {
          return Center(child: Text(state.message, style: const TextStyle(color: AppTheme.error)));
        }
        if (state is DownloadLoaded) {
          var tasks = state.tasks.toList();
          if (_filter != null) {
            tasks = tasks.where((t) => t.status == _filter).toList();
          }
          tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_outlined, size: 48, color: AppTheme.outline.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text('No downloads yet',
                      style: TextStyle(fontSize: 16, color: AppTheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text('Tap + to add a download URL',
                      style: TextStyle(fontSize: 12, color: AppTheme.outline)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: tasks.length + 1,
            itemBuilder: (context, i) {
              if (i == tasks.length) return const SizedBox(height: 80);
              final task = tasks[i];
              return DownloadCard(
                task: task,
                onPause: () => context.read<DownloadBloc>().add(PauseDownload(task.id)),
                onResume: () => context.read<DownloadBloc>().add(ResumeDownload(task.id)),
                onRemove: () => context.read<DownloadBloc>().add(RemoveDownload(task.id)),
                onOpen: task.savePath != null ? () => _openFile(task.savePath!) : null,
                onShowInFolder: task.savePath != null ? () => _showInFolder(task.savePath!) : null,
              );
            },
          );
        }
        return const SizedBox();
      },
    );
  }
}
