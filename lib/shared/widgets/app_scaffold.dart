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
    this.bodyPadding = const EdgeInsets.all(16),
    this.actions,
  });

  final String title;
  final Widget body;
  final int currentIndex;
  final Widget? floatingActionButton;
  final EdgeInsets bodyPadding;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(
        minimum: bodyPadding,
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onItemTap(context, index),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.flight_outlined),
            selectedIcon: Icon(Icons.flight),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
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
      case 1:
        context.go(AppRoutes.map);
      case 2:
        context.go(AppRoutes.savedRoutes);
      case 3:
        context.go(AppRoutes.settings);
    }
  }
}
