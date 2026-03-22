import 'package:flight_assistant/features/flight_planning/application/use_cases/calculate_route_summary_use_case.dart';
import 'package:flutter/material.dart';

class RouteSummaryCard extends StatelessWidget {
  const RouteSummaryCard({
    required this.summary,
    super.key,
  });

  final RouteSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SummaryItem(
              label: 'Waypoints',
              value: summary.waypointCount.toString(),
              textTheme: textTheme,
            ),
            _SummaryItem(
              label: 'Legs',
              value: summary.legCount.toString(),
              textTheme: textTheme,
            ),
            _SummaryItem(
              label: 'Distance',
              value: '${summary.totalDistanceNm.toStringAsFixed(1)} NM',
              textTheme: textTheme,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.textTheme,
  });

  final String label;
  final String value;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }
}

