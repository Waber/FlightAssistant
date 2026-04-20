import 'package:flight_assistant/features/aviation_data/application/providers/aviation_data_providers.dart';
import 'package:flight_assistant/features/aviation_data/application/providers/layer_visibility_provider.dart';
import 'package:flight_assistant/features/flight_planning/application/providers/flight_planning_providers.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/flight_map_widget.dart';
import 'package:flight_assistant/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waypoints =
        ref.watch(flightPlanningControllerProvider).routePlan.waypoints;
    final layerVisibility = ref.watch(layerVisibilityProvider);
    final airports = ref.watch(airportsProvider).valueOrNull ?? [];
    final vfrPoints = ref.watch(vfrPointsProvider).valueOrNull ?? [];
    final airspaces = ref.watch(airspacesProvider).valueOrNull ?? [];

    return AppScaffold(
      title: 'Map View',
      currentIndex: 1,
      bodyPadding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.layers_outlined),
          tooltip: 'Layers',
          onPressed: () => _showLayersSheet(context),
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) => FlightMapWidget(
          waypoints: waypoints,
          airports: airports,
          vfrPoints: vfrPoints,
          airspaces: airspaces,
          layerVisibility: layerVisibility,
          showControls: true,
          height: constraints.maxHeight,
        ),
      ),
    );
  }

  void _showLayersSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      // _LayersBottomSheet is a ConsumerWidget so it reads providers itself.
      // Never pass WidgetRef into a bottom sheet builder — ref is only valid
      // during the parent's build call.
      builder: (_) => const _LayersBottomSheet(),
    );
  }
}

class _LayersBottomSheet extends ConsumerWidget {
  const _LayersBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibility = ref.watch(layerVisibilityProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Map Layers',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            secondary: const Icon(Icons.flight),
            title: const Text('Airports'),
            subtitle: const Text('Licensed fields, grass strips, heliports'),
            value: visibility.showAirports,
            onChanged: (v) => ref
                .read(layerVisibilityProvider.notifier)
                .state = visibility.copyWith(showAirports: v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.place_outlined),
            title: const Text('VFR Reporting Points'),
            subtitle: const Text('CTR entry/exit points (LIMA, PAPA…)'),
            value: visibility.showVfrPoints,
            onChanged: (v) => ref
                .read(layerVisibilityProvider.notifier)
                .state = visibility.copyWith(showVfrPoints: v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.layers_outlined),
            title: const Text('Airspaces'),
            subtitle: const Text('CTR, TMA, MCTR boundaries'),
            value: visibility.showAirspaces,
            onChanged: (v) => ref
                .read(layerVisibilityProvider.notifier)
                .state = visibility.copyWith(showAirspaces: v),
          ),
        ],
      ),
    );
  }
}
