import 'package:flight_assistant/features/navigation/domain/entities/active_navigation_state.dart';
import 'package:flutter/material.dart';

class NextWaypointCard extends StatelessWidget {
  const NextWaypointCard({
    required this.navigationState,
    super.key,
  });

  final ActiveNavigationState? navigationState;

  @override
  Widget build(BuildContext context) {
    final waypointName = navigationState?.nextWaypoint?.name ?? 'N/A';
    final desiredTrack = navigationState?.desiredTrackDeg;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.flag_outlined),
        title: Text('Next: $waypointName'),
        subtitle: Text(
          desiredTrack == null
              ? 'Track unavailable'
              : 'Desired track: ${desiredTrack.toStringAsFixed(0)} deg',
        ),
      ),
    );
  }
}

