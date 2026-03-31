import 'package:flight_assistant/features/flight_planning/application/providers/flight_planning_providers.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flight_assistant/features/flight_planning/presentation/widgets/add_waypoint_button.dart';
import 'package:flight_assistant/features/flight_planning/presentation/widgets/route_summary_card.dart';
import 'package:flight_assistant/features/flight_planning/presentation/widgets/waypoint_list.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/flight_map_widget.dart';
import 'package:flight_assistant/features/route_storage/application/providers/route_storage_providers.dart';
import 'package:flight_assistant/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FlightPlanningScreen extends ConsumerStatefulWidget {
  const FlightPlanningScreen({super.key});

  @override
  ConsumerState<FlightPlanningScreen> createState() => _FlightPlanningScreenState();
}

class _FlightPlanningScreenState extends ConsumerState<FlightPlanningScreen> {
  final TextEditingController _routeNameController = TextEditingController();
  final TextEditingController _waypointNameController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  WaypointType _selectedType = WaypointType.userDefined;

  @override
  void initState() {
    super.initState();
    final routeName =
        ref.read(flightPlanningControllerProvider.select((state) => state.routePlan.name));
    _routeNameController.text = routeName;
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    _waypointNameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flightPlanningControllerProvider);
    final summary = ref.watch(currentRouteSummaryProvider);
    final controller = ref.read(flightPlanningControllerProvider.notifier);

    if (_routeNameController.text != state.routePlan.name) {
      _routeNameController.text = state.routePlan.name;
      _routeNameController.selection = TextSelection.fromPosition(
        TextPosition(offset: _routeNameController.text.length),
      );
    }

    return AppScaffold(
      title: 'Flight Planning',
      currentIndex: 0,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            if (state.errorMessage != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: ListTile(
                  leading: Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  title: Text(state.errorMessage!),
                  trailing: IconButton(
                    onPressed: controller.clearError,
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
            _RouteActionsCard(
              routeNameController: _routeNameController,
              isBusy: state.isBusy,
              onRenameRoute: () => controller.updateRouteName(_routeNameController.text),
              onNewRoute: () => controller.startNewRoute(),
              onSaveRoute: () async {
              controller.updateRouteName(_routeNameController.text);
              final saved = await controller.saveCurrentRoute();
              if (saved && mounted) {
                ref.invalidate(savedRoutesProvider);
                _showMessage('Route saved.');
              }
            },
            ),
            RouteSummaryCard(summary: summary),
            FlightMapWidget(waypoints: state.routePlan.waypoints),
            const SizedBox(height: 12),
            _WaypointFormCard(
              waypointNameController: _waypointNameController,
              latitudeController: _latitudeController,
              longitudeController: _longitudeController,
              selectedType: _selectedType,
              onTypeChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _selectedType = value);
              },
              onAddWaypoint: _onAddWaypoint,
            ),
            const SizedBox(height: 8),
            WaypointList(
              waypoints: state.routePlan.waypoints,
              onDelete: controller.removeWaypoint,
              onMoveUp: (index) => controller.reorderWaypoint(
                oldIndex: index,
                newIndex: index - 1,
              ),
              onMoveDown: (index) => controller.reorderWaypoint(
                oldIndex: index,
                newIndex: index + 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAddWaypoint() {
    final controller = ref.read(flightPlanningControllerProvider.notifier);
    final name = _waypointNameController.text.trim();
    final latitude = _parseCoordinate(_latitudeController.text);
    final longitude = _parseCoordinate(_longitudeController.text);

    if (name.isEmpty || latitude == null || longitude == null) {
      _showMessage('Provide waypoint name and valid coordinates.');
      return;
    }

    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      _showMessage('Coordinates are out of range.');
      return;
    }

    controller.addWaypoint(
      name: name,
      latitude: latitude,
      longitude: longitude,
      type: _selectedType,
    );

    _waypointNameController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
  }

  double? _parseCoordinate(String input) {
    final normalized = input.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _RouteActionsCard extends StatelessWidget {
  const _RouteActionsCard({
    required this.routeNameController,
    required this.isBusy,
    required this.onRenameRoute,
    required this.onNewRoute,
    required this.onSaveRoute,
  });

  final TextEditingController routeNameController;
  final bool isBusy;
  final VoidCallback onRenameRoute;
  final VoidCallback onNewRoute;
  final VoidCallback onSaveRoute;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: routeNameController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Route name',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => onRenameRoute(),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onRenameRoute,
                  icon: const Icon(Icons.edit),
                  label: const Text('Rename'),
                ),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onNewRoute,
                  icon: const Icon(Icons.add_chart),
                  label: const Text('New route'),
                ),
                FilledButton.icon(
                  onPressed: isBusy ? null : onSaveRoute,
                  icon: isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WaypointFormCard extends StatelessWidget {
  const _WaypointFormCard({
    required this.waypointNameController,
    required this.latitudeController,
    required this.longitudeController,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onAddWaypoint,
  });

  final TextEditingController waypointNameController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final WaypointType selectedType;
  final ValueChanged<WaypointType?> onTypeChanged;
  final VoidCallback onAddWaypoint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: waypointNameController,
              decoration: const InputDecoration(
                labelText: 'Waypoint name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      hintText: '52.2297',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      hintText: '21.0122',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<WaypointType>(
              initialValue: selectedType,
              decoration: const InputDecoration(
                labelText: 'Waypoint type',
                border: OutlineInputBorder(),
              ),
              items: WaypointType.values
                  .map(
                    (type) => DropdownMenuItem<WaypointType>(
                      value: type,
                      child: Text(type.name),
                    ),
                  )
                  .toList(),
              onChanged: onTypeChanged,
            ),
            const SizedBox(height: 10),
            AddWaypointButton(onPressed: onAddWaypoint),
          ],
        ),
      ),
    );
  }
}
