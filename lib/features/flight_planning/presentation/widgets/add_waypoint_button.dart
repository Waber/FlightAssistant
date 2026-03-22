import 'package:flutter/material.dart';

class AddWaypointButton extends StatelessWidget {
  const AddWaypointButton({
    required this.onPressed,
    super.key,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_location_alt_outlined),
      label: const Text('Add waypoint'),
    );
  }
}

