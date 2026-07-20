// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import 'browser_screen.dart';
import 'dashboard_screen.dart';
import 'library_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  final _browserKey = GlobalKey<BrowserScreenState>();

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      const LibraryScreen(),
      BrowserScreen(key: _browserKey),
      const SettingsScreen(),
    ];
  }

  Future<bool> _onBack() async {
    if (_currentIndex == 2) {
      final handled = await _browserKey.currentState?.handleBack() ?? false;
      if (handled) return false;
    }
    if (!context.mounted) return false;
    final exit = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Exit App?', style: TextStyle(color: AppTheme.onSurface)),
        content: const Text('Are you sure you want to exit?', style: TextStyle(color: AppTheme.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.primaryContainer))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Exit', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (exit == true) {
      SystemNavigator.pop();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _onBack();
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: AppTheme.outline,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.download_rounded), label: 'Downloads',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.check_circle_outline_rounded), label: 'Completed',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.language_rounded), label: 'Browser',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded), label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
