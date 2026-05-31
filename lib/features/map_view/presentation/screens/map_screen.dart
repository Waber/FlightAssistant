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

    final airportsAsync = ref.watch(airportsProvider);
    final vfrPointsAsync = ref.watch(vfrPointsProvider);
    final airspacesAsync = ref.watch(airspacesProvider);
    final meta = ref.watch(aviationDataMetaProvider).valueOrNull;

    final isLoading = airportsAsync.isLoading ||
        vfrPointsAsync.isLoading ||
        airspacesAsync.isLoading;
    final hasError = airportsAsync.hasError ||
        vfrPointsAsync.hasError ||
        airspacesAsync.hasError;

    // Surface a one-off error without blocking the map.
    if (hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load aviation data')),
        );
      });
    }

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
        builder: (context, constraints) => Stack(
          children: [
            FlightMapWidget(
              waypoints: waypoints,
              airports: airportsAsync.valueOrNull ?? const [],
              vfrPoints: vfrPointsAsync.valueOrNull ?? const [],
              airspaces: airspacesAsync.valueOrNull ?? const [],
              layerVisibility: layerVisibility,
              showControls: true,
              height: constraints.maxHeight,
            ),
            if (isLoading)
              const Positioned(
                top: 12,
                left: 12,
                child: SizedBox(
                  key: Key('aviation-loading'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (meta != null)
              Positioned(
                bottom: 8,
                left: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Data: ${meta.source}, as of ${meta.dataAsOf}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ),
          ],
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
