import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'pets/pets_screen.dart';
import 'care/care_screen.dart';
import 'health/health_screen.dart';
import 'discover/discover_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateTab: _onTabSelected),
      const PetsScreen(),
      const CareScreen(),
      const HealthScreen(),
      const DiscoverScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surf(context),
          border: Border(
            top: BorderSide(color: AppColors.brd(context), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: AppColors.surf(context),
          currentIndex: _currentIndex,
          selectedItemColor: AppColors.txt(context),
          unselectedItemColor: AppColors.txtMut(context),
          onTap: _onTabSelected,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'OVERVIEW',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets_outlined),
              activeIcon: Icon(Icons.pets),
              label: 'PETS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist_outlined),
              activeIcon: Icon(Icons.checklist),
              label: 'CARE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'HEALTH',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'DISCOVER',
            ),
          ],
        ),
      ),
    );
  }
}
