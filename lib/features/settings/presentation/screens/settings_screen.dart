import 'package:flight_assistant/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Settings',
      currentIndex: 3,
      body: _SettingsContent(),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        Card(
          child: ListTile(
            leading: Icon(Icons.map_outlined),
            title: Text('Map provider'),
            subtitle: Text('MapLibre / Mapbox selection will be added in future steps.'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.straighten),
            title: Text('Units'),
            subtitle: Text('Nautical miles and degrees true (MVP default).'),
          ),
        ),
      ],
    );
  }
}

