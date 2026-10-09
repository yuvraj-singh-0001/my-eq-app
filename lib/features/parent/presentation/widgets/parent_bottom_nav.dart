import 'package:flutter/material.dart';

class ParentBottomNav extends StatelessWidget {
  const ParentBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: currentIndex,
    onDestinationSelected: onTap,
    height: 66,
    backgroundColor: Colors.white,
    indicatorColor: const Color(0xFFDFF4EE),
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.school_outlined),
        selectedIcon: Icon(Icons.school_rounded),
        label: 'Students',
      ),
      NavigationDestination(
        icon: Icon(Icons.insights_outlined),
        selectedIcon: Icon(Icons.insights_rounded),
        label: 'Progress',
      ),
      NavigationDestination(
        icon: Icon(Icons.groups_outlined),
        selectedIcon: Icon(Icons.groups_rounded),
        label: 'Teachers',
      ),
      NavigationDestination(
        icon: Icon(Icons.more_horiz_rounded),
        selectedIcon: Icon(Icons.more_rounded),
        label: 'More',
      ),
    ],
  );
}
