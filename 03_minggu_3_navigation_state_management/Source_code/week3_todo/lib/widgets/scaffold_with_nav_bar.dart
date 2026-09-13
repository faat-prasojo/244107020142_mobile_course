import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.child});
  
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    int currentIndex = 0;
    if (location == '/stats') {
      currentIndex = 1;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index == 0) {
            context.go('/');
          } else if (index == 1) {
            context.go('/stats');
          }
        },
        destinations: const [
          NavigationDestination( 
            icon: Icon(Icons.list),
            label: 'ToDo',
          ),
          NavigationDestination( 
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}