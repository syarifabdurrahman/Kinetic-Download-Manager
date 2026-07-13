import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SpeedGauge extends StatelessWidget {
  final double speed;
  final String label;

  const SpeedGauge({super.key, required this.speed, required this.label});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            speed >= 1000
                ? (speed / 1000).toStringAsFixed(1)
                : speed.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 36, fontWeight: FontWeight.w800,
              color: AppTheme.onSurface, letterSpacing: -0.02,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                speed >= 1000 ? 'GB/s' : 'MB/s',
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppTheme.tertiary, letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
