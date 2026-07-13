import 'dart:ui';
import 'package:flutter/material.dart';
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

  final _screens = const [
    DashboardScreen(),
    LibraryScreen(),
    BrowserScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: BottomNavigationBar(
              backgroundColor: AppTheme.surfaceContainer.withValues(alpha: 0.8),
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
                  icon: Icon(Icons.grid_view_rounded), label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.folder_rounded), label: 'Library',
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
      ),
    );
  }
}
