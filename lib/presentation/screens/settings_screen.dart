import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _adaptiveBandwidth = true;
  double _speedLimit = 500;
  double _glassIntensity = 0.7;

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
              const SizedBox(height: 4),
              Text('Settings',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
              const Text('System Configuration v2.4.0',
                  style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              _sectionHeader('General'),
              GlassCard(
                child: Column(children: [
                  _toggleTile('Account Profile', Icons.chevron_right, null, (_) {}),
                  const Divider(color: AppTheme.outlineVariant, height: 1),
                  _toggleTile('Push Notifications', null, _notifications, (v) {
                    setState(() => _notifications = v!);
                  }),
                ]),
              ),
              const SizedBox(height: 20),
              _sectionHeader('Network & Speed'),
              GlassCard(
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Text('Global Speed Limit',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
                          const Spacer(),
                          Text('${_speedLimit.toInt()} Mbps',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryContainer)),
                        ]),
                        Slider(
                          value: _speedLimit,
                          min: 10, max: 1000,
                          activeColor: AppTheme.primaryContainer,
                          inactiveColor: AppTheme.surfaceContainerHighest,
                          onChanged: (v) => setState(() => _speedLimit = v),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppTheme.outlineVariant, height: 1),
                  _toggleTile('Adaptive Bandwidth', null, _adaptiveBandwidth, (v) {
                    setState(() => _adaptiveBandwidth = v!);
                  }),
                ]),
              ),
              const SizedBox(height: 20),
              _sectionHeader('Appearance'),
              GlassCard(
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      const Text('Theme Selection',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Dark Flux',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryContainer)),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: AppTheme.outline, size: 20),
                    ]),
                  ),
                  const Divider(color: AppTheme.outlineVariant, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Glassmorphism Intensity',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
                        Slider(
                          value: _glassIntensity,
                          min: 0.1, max: 1.0,
                          activeColor: AppTheme.primaryContainer,
                          inactiveColor: AppTheme.surfaceContainerHighest,
                          onChanged: (v) => setState(() => _glassIntensity = v),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 32),
              Center(
                child: Column(children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppTheme.primaryContainer, AppTheme.tertiary],
                    ).createShader(bounds),
                    child: const Text('KINETIC',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800,
                            letterSpacing: 4, color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _badge('Kernel 5.4'),
                      const SizedBox(width: 8),
                      _badge('Stable Build'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('© 2026 KFDM',
                      style: TextStyle(fontSize: 11, color: AppTheme.outline)),
                ]),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              letterSpacing: 0.8, color: AppTheme.onSurfaceVariant)),
    );
  }

  Widget _toggleTile(String title, IconData? trailingIcon, bool? toggle, Function(dynamic) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
        ),
        if (toggle != null)
          Switch(
            value: toggle,
            activeTrackColor: AppTheme.primaryContainer.withValues(alpha: 0.3),
            activeThumbColor: AppTheme.primaryContainer,
            onChanged: onChanged,
          )
        else if (trailingIcon != null)
          Icon(trailingIcon, color: AppTheme.outline, size: 20),
      ]),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant)),
    );
  }
}
