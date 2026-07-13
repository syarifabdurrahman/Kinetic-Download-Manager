import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/download_status.dart';
import '../../domain/entities/download_task.dart';
import 'progress_bar.dart';
import 'status_chip.dart';

class DownloadCard extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onRemove;

  const DownloadCard({
    super.key,
    required this.task,
    this.onPause,
    this.onResume,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.compact();
    final progressPercent = (task.progress * 100).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF171f33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter:  ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.fileName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFdae2fd),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusChip(status: task.status),
                  ],
                ),
                const SizedBox(height: 8),
                ProgressBar(progress: task.progress),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '$progressPercent%',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFc1c6d7),
                      ),
                    ),
                    const Spacer(),
                    if (task.speed > 0)
                      Text(
                        '${format.format(task.speed.toInt())}/s',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFc1c6d7),
                        ),
                      ),
                    if (task.speed > 0) const SizedBox(width: 12),
                    Text(
                      '${format.format(task.downloadedBytes)} / ${format.format(task.totalBytes)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8b90a0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (task.status == DownloadStatus.downloading)
                      _IconButton(
                        icon: Icons.pause_rounded,
                        onTap: onPause,
                      ),
                    if (task.status == DownloadStatus.paused)
                      _IconButton(
                        icon: Icons.play_arrow_rounded,
                        onTap: onResume,
                      ),
                    _IconButton(
                      icon: Icons.delete_outline_rounded,
                      onTap: onRemove,
                      color: const Color(0xFFffb4ab),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const _IconButton({required this.icon, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2d3449),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: color ?? const Color(0xFFdae2fd),
        onPressed: onTap,
      ),
    );
  }
}
