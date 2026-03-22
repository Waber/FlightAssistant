import 'package:flight_assistant/features/navigation/domain/entities/active_navigation_state.dart';
import 'package:flutter/material.dart';

class NavigationStatusPanel extends StatelessWidget {
  const NavigationStatusPanel({
    required this.navigationState,
    super.key,
  });

  final ActiveNavigationState? navigationState;

  @override
  Widget build(BuildContext context) {
    final distance = navigationState?.distanceToNextNm;
    final bearing = navigationState?.bearingToWaypointDeg;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatusValue(
              label: 'Active leg',
              value: navigationState == null
                  ? 'N/A'
                  : (navigationState!.activeLegIndex + 1).toString(),
            ),
            _StatusValue(
              label: 'Distance',
              value: distance == null ? 'N/A' : '${distance.toStringAsFixed(2)} NM',
            ),
            _StatusValue(
              label: 'Bearing',
              value: bearing == null ? 'N/A' : '${bearing.toStringAsFixed(0)} deg',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusValue extends StatelessWidget {
  const _StatusValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }
}

