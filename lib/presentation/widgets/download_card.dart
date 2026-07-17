import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/file_type_detector.dart';
import '../../domain/entities/download_status.dart';
import '../../domain/entities/download_task.dart';

class DownloadCard extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onRemove;
  final VoidCallback? onOpen;
  final VoidCallback? onShowInFolder;

  const DownloadCard({
    super.key,
    required this.task,
    this.onPause,
    this.onResume,
    this.onRemove,
    this.onOpen,
    this.onShowInFolder,
  });

  static final _detector = FileTypeDetector();

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.compact();
    final category = _detector.categoryFromExtension(task.fileName);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Row(
          children: [
            _fileIcon(category),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task.fileName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.status == DownloadStatus.downloading ||
                      task.status == DownloadStatus.paused) ...[
                    const SizedBox(height: 6),
                    _progressBar(task.progress),
                    const SizedBox(height: 4),
                    _metaRow(task, format),
                  ] else ...[
                    const SizedBox(height: 4),
                    _completedRow(task, format, category),
                  ],
                ],
              ),
            ),
            _actionButton(category),
          ],
        ),
      ),
    );
  }

  Widget _fileIcon(FileCategory category) {
    final color = _colorForCategory(category);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_iconForCategory(category), color: color, size: 20),
    );
  }

  Widget _progressBar(double progress) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 4,
        width: double.infinity,
        color: AppTheme.surfaceContainerHighest,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryContainer, AppTheme.secondary],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaRow(DownloadTask task, NumberFormat format) {
    return Row(
      children: [
        Text(
          '${(task.progress * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryContainer),
        ),
        if (task.speed > 0) ...[
          const SizedBox(width: 8),
          Text(
            '${format.format(task.speed.toInt())}/s',
            style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
          ),
        ],
        const Spacer(),
        Text(
          '${format.format(task.downloadedBytes)} / ${format.format(task.totalBytes)}',
          style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _completedRow(DownloadTask task, NumberFormat format, FileCategory category) {
    return Row(
      children: [
        Icon(Icons.check_circle, size: 12, color: _colorForCategory(category)),
        const SizedBox(width: 4),
        Text(
          _detector.getCategoryLabel(category),
          style: TextStyle(fontSize: 11, color: _colorForCategory(category), fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(
          format.format(task.totalBytes),
          style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _actionButton(FileCategory category) {
    if (task.status == DownloadStatus.downloading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _miniIcon(Icons.pause_rounded, onPause, _colorForCategory(category)),
          _miniIcon(Icons.close_rounded, onRemove, AppTheme.error),
        ],
      );
    }
    if (task.status == DownloadStatus.paused) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _miniIcon(Icons.play_arrow_rounded, onResume, _colorForCategory(category)),
          _miniIcon(Icons.close_rounded, onRemove, AppTheme.error),
        ],
      );
    }
    if (task.status == DownloadStatus.completed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _miniIcon(Icons.folder_open_rounded, onShowInFolder, AppTheme.onSurfaceVariant),
          _miniIcon(Icons.open_in_new_rounded, onOpen, _colorForCategory(category)),
          _miniIcon(Icons.delete_outline_rounded, onRemove, AppTheme.onSurfaceVariant),
        ],
      );
    }
    return _miniIcon(Icons.delete_outline_rounded, onRemove, AppTheme.onSurfaceVariant);
  }

  Widget _miniIcon(IconData icon, VoidCallback? onTap, Color color) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: color,
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  IconData _iconForCategory(FileCategory cat) {
    switch (cat) {
      case FileCategory.video: return Icons.play_circle_outline;
      case FileCategory.audio: return Icons.music_note_outlined;
      case FileCategory.image: return Icons.image_outlined;
      case FileCategory.document: return Icons.description_outlined;
      case FileCategory.archive: return Icons.folder_zip_outlined;
      case FileCategory.executable: return Icons.miscellaneous_services_outlined;
      case FileCategory.other: return Icons.insert_drive_file_outlined;
    }
  }

  Color _colorForCategory(FileCategory cat) {
    switch (cat) {
      case FileCategory.video: return AppTheme.primaryContainer;
      case FileCategory.audio: return const Color(0xFFce93d8);
      case FileCategory.image: return Colors.greenAccent;
      case FileCategory.document: return AppTheme.tertiary;
      case FileCategory.archive: return Colors.orangeAccent;
      case FileCategory.executable: return const Color(0xFF90caf9);
      case FileCategory.other: return AppTheme.onSurfaceVariant;
    }
  }
}
