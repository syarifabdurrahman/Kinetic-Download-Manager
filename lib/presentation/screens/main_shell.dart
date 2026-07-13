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
    );
  }
}
