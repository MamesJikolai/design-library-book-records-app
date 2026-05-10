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

    return Scaffold(
      // Keep this to prevent the nav bar from floating above the keyboard
      resizeToAvoidBottomInset: false,

      body: _screens[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,

        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        backgroundColor: defaultColor.shade700,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,

        iconSize: 28.0,
        selectedFontSize: 14.0,
        unselectedFontSize: 12.0,

        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.dashboard),
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.library_books),
            ),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.people),
            ),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4.0),
              child: Icon(Icons.history),
            ),
            label: 'History',
          ),
        ],
      ),
    );
  }
}