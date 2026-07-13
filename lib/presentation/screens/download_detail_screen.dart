import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/glass_card.dart';

class DownloadDetailScreen extends StatelessWidget {
  const DownloadDetailScreen({super.key});

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
              const SizedBox(height: 24),
              Center(
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryContainer, AppTheme.secondary],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.insert_drive_file_outlined,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text('Cyberpunk_Final_Build_v2.zip',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface),
                        textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    const Text('42.8 GB',
                        style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              const Text('TRANSFER PERFORMANCE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 0.8, color: AppTheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              GlassCard(
                height: 160,
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _metric('AVERAGE', '84.2 MB/s'),
                    _metric('CURRENT', '112.5 MB/s'),
                    _metric('PEAK', '156.3 MB/s'),
                  ]),
                  const SizedBox(height: 16),
                  Expanded(
                    child: CustomPaint(
                      size: const Size(double.infinity, 60),
                      painter: _SparklinePainter(),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              const Text('DETAILS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 0.8, color: AppTheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(children: [
                  _metaRow('Source', 'https://cdn.example.com/...'),
                  const Divider(color: AppTheme.outlineVariant, height: 1),
                  _metaRow('Save Path', '/Downloads/KFDM/'),
                  const Divider(color: AppTheme.outlineVariant, height: 1),
                  _metaRow('Completed', '2026-07-10 14:32'),
                  const Divider(color: AppTheme.outlineVariant, height: 1),
                  _metaRow('SHA-256', 'a3f8b2...c9d1e4'),
                ]),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open File'),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined, color: AppTheme.onSurfaceVariant),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                    onPressed: () {},
                  ),
                ),
              ]),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(children: [
      Text(value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
      Text(label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
              letterSpacing: 0.5, color: AppTheme.onSurfaceVariant)),
    ]);
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80,
              child: Text(label, style: const TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant))),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, color: AppTheme.onSurface)),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gradient = const LinearGradient(
      colors: [AppTheme.primaryContainer, AppTheme.secondary],
    );
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = List.generate(30, (i) => math.sin(i * 0.5) * 15 + 30 + math.sin(i * 1.3) * 10);

    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - (points[i] / 60) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
