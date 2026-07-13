import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GlassProgressBar extends StatelessWidget {
  final double progress;
  final double height;

  const GlassProgressBar({super.key, required this.progress, this.height = 6});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: height,
        width: double.infinity,
        color: AppTheme.surfaceContainerHighest,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryContainer, AppTheme.secondary],
                begin: Alignment.centerLeft, end: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
