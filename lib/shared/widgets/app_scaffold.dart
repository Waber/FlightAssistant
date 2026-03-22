import 'package:flight_assistant/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.body,
    required this.currentIndex,
    super.key,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final int currentIndex;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onItemTap(context, index),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.save_outlined),
            selectedIcon: Icon(Icons.save),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _onItemTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.flightPlanning);
        break;
      case 1:
        context.go(AppRoutes.savedRoutes);
        break;
      case 2:
        context.go(AppRoutes.settings);
        break;
    }
  }
}

