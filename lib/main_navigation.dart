import 'package:flutter/material.dart';
import 'screen_dashboard.dart';
import 'screen_library.dart';
import 'screen_students.dart';
import 'screen_history.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // The screens we want to navigate between
  final List<Widget> _screens = [
    const DashboardScreen(),
    const LibraryScreen(),
    const StudentsScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    const defaultColor = Colors.greenAccent;
    final themeColor = defaultColor.shade700;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _screens[_currentIndex],

      bottomNavigationBar: BottomAppBar(
        color: themeColor,
        padding: EdgeInsets.zero, // Removes default Flutter 3 padding
        height: 100.0,
        child: SizedBox(
          child: Row(
            children: [
              Expanded(child: _buildNavItem(icon: Icons.dashboard, label: 'Dashboard', index: 0)),
              Expanded(child: _buildNavItem(icon: Icons.library_books, label: 'Library', index: 1)),
              Expanded(child: _buildNavItem(icon: Icons.people, label: 'Students', index: 2)),
              Expanded(child: _buildNavItem(icon: Icons.history, label: 'History', index: 3)),
            ],
          ),
        ),
      ),
    );
  }

  // Custom widget to build each navigation tab
  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white60,
            size: 28.0,
          ),
          const SizedBox(height: 4.0),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              // Mimics the selected/unselected text size behavior
              fontSize: isSelected ? 14.0 : 12.0,
            ),
          ),
        ],
      ),
    );
  }
}