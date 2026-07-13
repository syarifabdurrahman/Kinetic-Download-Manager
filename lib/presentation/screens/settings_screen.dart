import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/download_path_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _adaptiveBandwidth = true;
  double _speedLimit = 500;
  String _downloadPath = '';
  final _pathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPath();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _loadPath() async {
    final path = await DownloadPathManager.getPath();
    if (mounted) {
      setState(() {
        _downloadPath = path;
        _pathController.text = path;
      });
    }
  }

  Future<void> _savePath(String path) async {
    if (path.trim().isEmpty) return;
    await DownloadPathManager.setPath(path.trim());
    if (mounted) {
      setState(() => _downloadPath = path.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Download path updated'),
          backgroundColor: AppTheme.surfaceContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
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
              const SizedBox(height: 4),
              const Text('Settings',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
              const Text('System Configuration v2.4.0',
                  style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              _sectionHeader('Download Location'),
              _settingsCard(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(children: [
                      const Icon(Icons.folder_outlined, size: 18, color: AppTheme.primaryContainer),
                      const SizedBox(width: 8),
                      const Text('Save files to',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () async {
                          await DownloadPathManager.resetToDefault();
                          await _loadPath();
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reset', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.primaryContainer),
                      ),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _downloadPath.isNotEmpty ? _downloadPath : 'Loading...',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.onSurfaceVariant,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _pathController,
                          decoration: InputDecoration(
                            hintText: 'Enter custom path...',
                            hintStyle: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceContainerHigh,
                          ),
                          style: const TextStyle(fontSize: 13, color: AppTheme.onSurface, fontFamily: 'monospace'),
                          onSubmitted: _savePath,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.check, color: Colors.white, size: 18),
                          onPressed: () => _savePath(_pathController.text),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              _sectionHeader('General'),
              _settingsCard(
                Column(children: [
                  _toggleTile('Push Notifications', null, _notifications, (v) {
                    setState(() => _notifications = v!);
                  }),
                ]),
              ),
              const SizedBox(height: 20),
              _sectionHeader('Network & Speed'),
              _settingsCard(
                Column(children: [
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

  Widget _settingsCard(Widget child) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
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
