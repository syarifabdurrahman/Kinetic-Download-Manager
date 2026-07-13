import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StorageRing extends StatelessWidget {
  final int bytesUsed;

  const StorageRing({super.key, required this.bytesUsed});

  String get _formatted {
    if (bytesUsed < 1024) return '$bytesUsed B';
    if (bytesUsed < 1048576) return '${(bytesUsed / 1024).toStringAsFixed(1)} KB';
    if (bytesUsed < 1073741824) return '${(bytesUsed / 1048576).toStringAsFixed(1)} MB';
    return '${(bytesUsed / 1073741824).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    if (bytesUsed <= 0) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text('No data stored',
              style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant)),
        ),
      );
    }

    return SizedBox(
      height: 80,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 72, height: 72,
            child: CustomPaint(
              painter: _RingPainter(0.5),
              child: Center(
                child: const Icon(Icons.done_all, color: AppTheme.tertiary, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatted,
                style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              const Text(
                'Total Downloaded',
                style: TextStyle(
                  fontSize: 12, color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    const strokeWidth = 4.0;

    final bgPaint = Paint()
      ..color = AppTheme.surfaceContainerHighest
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final fillPaint = Paint()
      ..color = AppTheme.tertiary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, math.pi * 2 * progress, false, fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
