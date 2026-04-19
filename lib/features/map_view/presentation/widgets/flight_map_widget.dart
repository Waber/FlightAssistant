import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/route_polyline_layer.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/waypoint_marker_layer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

class FlightMapWidget extends StatefulWidget {
  const FlightMapWidget({
    required this.waypoints,
    super.key,
    this.height = 220,
  });

  final List<Waypoint> waypoints;
  final double height;

  @override
  State<FlightMapWidget> createState() => _FlightMapWidgetState();
}

class _FlightMapWidgetState extends State<FlightMapWidget> {
  static const Geographic _fallbackCenter = Geographic(lon: 21.0122, lat: 52.2297);
  static const EdgeInsets _cameraPadding = EdgeInsets.all(36);

  MapController? _mapController;
  bool _styleLoaded = false;

  @override
  void didUpdateWidget(covariant FlightMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_didWaypointsChange(oldWidget.waypoints, widget.waypoints)) {
      _fitCameraToRoute(animated: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: widget.waypoints.isEmpty
              ? _MapEmptyState(height: widget.height)
              : !_isMapLibreSupported
                  ? const _MapUnsupportedFallback()
              : MapLibreMap(
                  options: MapOptions(
                    initCenter: _initialCenter(widget.waypoints),
                    initZoom: widget.waypoints.length > 1 ? 5 : 8,
                  ),
                  layers: _buildLayers(widget.waypoints),
                  onMapCreated: _onMapCreated,
                  onStyleLoaded: (_) {
                    _styleLoaded = true;
                    _fitCameraToRoute(animated: false);
                  },
                  children: [
                    WaypointMarkerLayer(waypoints: widget.waypoints),
                  ],
                ),
        ),
      ),
    );
  }

  bool get _isMapLibreSupported {
    return kIsWeb ||
        MapController.userLocationIsSupported ||
        PermissionManager.isSupported ||
        OfflineManager.isSupported;
  }

  Geographic _initialCenter(List<Waypoint> waypoints) {
    if (waypoints.isEmpty) {
      return _fallbackCenter;
    }

    final first = waypoints.first;
    return Geographic(lon: first.longitude, lat: first.latitude);
  }

  List<Layer> _buildLayers(List<Waypoint> waypoints) {
    final layers = <Layer>[];
    final routeLayer = RoutePolylineLayer.fromWaypoints(waypoints);
    if (routeLayer != null) {
      layers.add(routeLayer);
    }
    return layers;
  }

  void _onMapCreated(MapController controller) {
    _mapController = controller;
    _fitCameraToRoute(animated: false);
  }

  Future<void> _fitCameraToRoute({required bool animated}) async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded || widget.waypoints.isEmpty) {
      return;
    }

    final points = widget.waypoints
        .map((waypoint) => Geographic(lon: waypoint.longitude, lat: waypoint.latitude))
        .toList(growable: false);

    if (points.length == 1) {
      final point = points.first;
      if (animated) {
        await controller.animateCamera(
          center: point,
          zoom: 9,
          nativeDuration: const Duration(milliseconds: 600),
          padding: _cameraPadding,
        );
      } else {
        await controller.moveCamera(
          center: point,
          zoom: 9,
          padding: _cameraPadding,
        );
      }
      return;
    }

    final rawBounds = LngLatBounds.fromPoints(points);
    final bounds = _expandSmallBounds(rawBounds);

    await controller.fitBounds(
      bounds: bounds,
      nativeDuration:
          animated ? const Duration(milliseconds: 750) : Duration.zero,
      padding: _cameraPadding,
      webMaxZoom: 12,
    );
  }

  LngLatBounds _expandSmallBounds(LngLatBounds bounds) {
    const minimumSpan = 0.02;

    final lonSpan = (bounds.longitudeEast - bounds.longitudeWest).abs();
    final latSpan = (bounds.latitudeNorth - bounds.latitudeSouth).abs();

    final lonPadding = lonSpan < minimumSpan ? (minimumSpan - lonSpan) / 2 : 0.0;
    final latPadding = latSpan < minimumSpan ? (minimumSpan - latSpan) / 2 : 0.0;

    return bounds.copyWith(
      longitudeWest: bounds.longitudeWest - lonPadding,
      longitudeEast: bounds.longitudeEast + lonPadding,
      latitudeSouth: bounds.latitudeSouth - latPadding,
      latitudeNorth: bounds.latitudeNorth + latPadding,
    );
  }

  bool _didWaypointsChange(List<Waypoint> oldList, List<Waypoint> newList) {
    if (identical(oldList, newList)) {
      return false;
    }
    if (oldList.length != newList.length) {
      return true;
    }

    for (var i = 0; i < oldList.length; i++) {
      final oldWaypoint = oldList[i];
      final newWaypoint = newList[i];
      if (oldWaypoint.id != newWaypoint.id ||
          oldWaypoint.latitude != newWaypoint.latitude ||
          oldWaypoint.longitude != newWaypoint.longitude) {
        return true;
      }
    }

    return false;
  }
}

class _MapUnsupportedFallback extends StatelessWidget {
  const _MapUnsupportedFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFDCEAF5),
      child: const Center(
        child: Icon(
          Icons.map_outlined,
          size: 40,
          color: Color(0xFF0B5A8F),
        ),
      ),
    );
  }
}

class _MapEmptyState extends StatelessWidget {
  const _MapEmptyState({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: const Color(0xFFE9F1F7),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.map_outlined,
              size: 34,
              color: Color(0xFF0B5A8F),
            ),
            const SizedBox(height: 8),
            Text(
              'Add at least one waypoint to display the map.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
