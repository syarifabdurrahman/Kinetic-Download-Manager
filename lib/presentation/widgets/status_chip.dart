import 'package:flutter/material.dart';
import '../../domain/entities/download_status.dart';

class StatusChip extends StatelessWidget {
  final DownloadStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Color get _color {
    switch (status) {
      case DownloadStatus.pending:
        return Colors.grey;
      case DownloadStatus.downloading:
        return const Color(0xFF4b8eff);
      case DownloadStatus.paused:
        return Colors.orangeAccent;
      case DownloadStatus.completed:
        return const Color(0xFF00dce6);
      case DownloadStatus.failed:
        return const Color(0xFFffb4ab);
    }
  }
}
