import 'package:flutter/material.dart';
import '../models/app_colors.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'albums_screen.dart';
import 'settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onNavigateToMap: () => _onTabTapped(1)),
      const TrailMapScreen(),
      const AlbumsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.surface, width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: AppColors.background,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "HOME"),
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: "MAP"),
            BottomNavigationBarItem(icon: Icon(Icons.photo_library_outlined), label: "ALBUMS"),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "SETTINGS"),
          ],
        ),
      ),
    );
  }
}