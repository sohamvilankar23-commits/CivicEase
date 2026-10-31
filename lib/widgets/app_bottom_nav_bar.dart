import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const AppBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final routes = ['/home', '/complaint', '/add-complaint', '/emergency', '/profile'];
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => context.go(routes[index]),
      showSelectedLabels: true, // Ensure selected labels are shown
      showUnselectedLabels: true, // Ensure unselected labels are shown
      type: BottomNavigationBarType.fixed, // Ensure all items are displayed
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'Complaints',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add),
          label: 'New',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.warning),
          label: 'Emergency',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}