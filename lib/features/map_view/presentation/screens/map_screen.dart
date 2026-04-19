import 'package:flight_assistant/features/flight_planning/application/providers/flight_planning_providers.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/flight_map_widget.dart';
import 'package:flight_assistant/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waypoints = ref.watch(flightPlanningControllerProvider).routePlan.waypoints;
    return AppScaffold(
      title: 'Map View',
      currentIndex: 0,
      body: FlightMapWidget(
        waypoints: waypoints,
        height: 420,
      ),
    );
  }
}
