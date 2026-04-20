import 'package:flight_assistant/features/aviation_data/application/providers/layer_visibility_provider.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airspace.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/vfr_point.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/airport_marker_layer.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/airspace_polygon_layer.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/map_controls_overlay.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/route_polyline_layer.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/vfr_point_marker_layer.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/waypoint_marker_layer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre/maplibre.dart';

class FlightMapWidget extends StatefulWidget {
  const FlightMapWidget({
    required this.waypoints,
    super.key,
    this.height = 220,
    this.airports = const [],
    this.vfrPoints = const [],
    this.airspaces = const [],
    this.layerVisibility = const LayerVisibility(),
    this.showControls = false,
  });

  final List<Waypoint> waypoints;
  final double height;
  final List<Airport> airports;
  final List<VfrPoint> vfrPoints;
  final List<Airspace> airspaces;
  final LayerVisibility layerVisibility;
  final bool showControls;

  @override
  State<FlightMapWidget> createState() => _FlightMapWidgetState();
}

class _FlightMapWidgetState extends State<FlightMapWidget> {
  static const Geographic _fallbackCenter = Geographic(lon: 21.0122, lat: 52.2297);
  static const EdgeInsets _cameraPadding = EdgeInsets.all(36);

  MapController? _mapController;
  bool _styleLoaded = false;
  double _currentZoom = 8.0;
  bool _showCompass = false;

  @override
  void didUpdateWidget(covariant FlightMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_didWaypointsChange(oldWidget.waypoints, widget.waypoints)) {
      _fitCameraToRoute(animated: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showMap = widget.showControls || widget.waypoints.isNotEmpty;

    return Card(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: !showMap
              ? _MapEmptyState(height: widget.height)
              : !_isMapLibreSupported
                  ? const _MapUnsupportedFallback()
                  : Stack(
                      children: [
                        MapLibreMap(
                          options: MapOptions(
                            initCenter: _initialCenter(widget.waypoints),
                            initZoom: widget.waypoints.length > 1 ? 5 : 8,
                          ),
                          layers: _buildLayers(),
                          onMapCreated: _onMapCreated,
                          onStyleLoaded: (_) {
                            _styleLoaded = true;
                            _fitCameraToRoute(animated: false);
                          },
                          children: _buildChildren(),
                        ),
                        if (widget.showControls)
                          MapControlsOverlay(
                            onZoomIn: _zoomIn,
                            onZoomOut: _zoomOut,
                            onFitRoute: () => _fitCameraToRoute(animated: true),
                            onMyLocation: _goToMyLocation,
                            onResetNorth: _resetNorth,
                            showCompass: _showCompass,
                          ),
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
    if (waypoints.isEmpty) return _fallbackCenter;
    final first = waypoints.first;
    return Geographic(lon: first.longitude, lat: first.latitude);
  }

  List<Layer> _buildLayers() {
    final layers = <Layer>[];
    final routeLayer = RoutePolylineLayer.fromWaypoints(widget.waypoints);
    if (routeLayer != null) layers.add(routeLayer);
    if (widget.layerVisibility.showAirspaces) {
      final airspaceLayer = AirspacePolygonLayer.fromAirspaces(widget.airspaces);
      if (airspaceLayer != null) layers.add(airspaceLayer);
    }
    return layers;
  }

  List<Widget> _buildChildren() {
    return [
      WaypointMarkerLayer(waypoints: widget.waypoints),
      if (widget.layerVisibility.showAirports)
        AirportMarkerLayer(airports: widget.airports),
      if (widget.layerVisibility.showVfrPoints)
        VfrPointMarkerLayer(vfrPoints: widget.vfrPoints),
    ];
  }

  void _onMapCreated(MapController controller) {
    _mapController = controller;
    _fitCameraToRoute(animated: false);
  }

  Future<void> _fitCameraToRoute({required bool animated}) async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded || widget.waypoints.isEmpty) return;

    final points = widget.waypoints
        .map((w) => Geographic(lon: w.longitude, lat: w.latitude))
        .toList(growable: false);

    if (points.length == 1) {
      final point = points.first;
      _currentZoom = 9;
      if (animated) {
        await controller.animateCamera(
          center: point,
          zoom: _currentZoom,
          nativeDuration: const Duration(milliseconds: 600),
          padding: _cameraPadding,
        );
      } else {
        await controller.moveCamera(
          center: point,
          zoom: _currentZoom,
          padding: _cameraPadding,
        );
      }
      return;
    }

    final rawBounds = LngLatBounds.fromPoints(points);
    final bounds = _expandSmallBounds(rawBounds);
    await controller.fitBounds(
      bounds: bounds,
      nativeDuration: animated ? const Duration(milliseconds: 750) : Duration.zero,
      padding: _cameraPadding,
      webMaxZoom: 12,
    );
  }

  Future<void> _zoomIn() async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) return;
    _currentZoom = (_currentZoom + 1.0).clamp(0.0, 22.0);
    await controller.animateCamera(
      zoom: _currentZoom,
      nativeDuration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _zoomOut() async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) return;
    _currentZoom = (_currentZoom - 1.0).clamp(0.0, 22.0);
    await controller.animateCamera(
      zoom: _currentZoom,
      nativeDuration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _resetNorth() async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) return;
    setState(() => _showCompass = false);
    await controller.animateCamera(
      bearing: 0,
      nativeDuration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _goToMyLocation() async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied. Enable it in Settings.'),
          ),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      _currentZoom = 12;
      await controller.animateCamera(
        center: Geographic(lon: position.longitude, lat: position.latitude),
        zoom: _currentZoom,
        nativeDuration: const Duration(milliseconds: 600),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get current location.')),
        );
      }
    }
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
    if (identical(oldList, newList)) return false;
    if (oldList.length != newList.length) return true;
    for (var i = 0; i < oldList.length; i++) {
      final o = oldList[i];
      final n = newList[i];
      if (o.id != n.id || o.latitude != n.latitude || o.longitude != n.longitude) {
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
        child: Icon(Icons.map_outlined, size: 40, color: Color(0xFF0B5A8F)),
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
            const Icon(Icons.map_outlined, size: 34, color: Color(0xFF0B5A8F)),
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
