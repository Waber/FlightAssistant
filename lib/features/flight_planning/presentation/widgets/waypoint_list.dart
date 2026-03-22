import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flutter/material.dart';

class WaypointList extends StatelessWidget {
  const WaypointList({
    required this.waypoints,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
    super.key,
  });

  final List<Waypoint> waypoints;
  final ValueChanged<String> onDelete;
  final ValueChanged<int> onMoveUp;
  final ValueChanged<int> onMoveDown;

  @override
  Widget build(BuildContext context) {
    if (waypoints.isEmpty) {
      return const Center(
        child: Text('No waypoints yet. Add your first one.'),
      );
    }

    return ListView.builder(
      itemCount: waypoints.length,
      itemBuilder: (context, index) {
        final waypoint = waypoints[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(waypoint.name),
            subtitle: Text(
              '${waypoint.latitude.toStringAsFixed(4)}, ${waypoint.longitude.toStringAsFixed(4)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Move up',
                  onPressed: index == 0 ? null : () => onMoveUp(index),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Move down',
                  onPressed: index == waypoints.length - 1
                      ? null
                      : () => onMoveDown(index),
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  tooltip: 'Delete waypoint',
                  onPressed: () => onDelete(waypoint.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

