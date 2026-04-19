import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:maplibre_platform_interface/maplibre_platform_interface.dart';

final List<String> _mapMethodChannels = <String>[
  'plugins.flutter.io/maplibre_gl',
  'plugins.flutter.io/mapbox_gl',
  'plugins.flutter.io/maplibre_maps',
  ...List<String>.generate(6, (index) => 'plugins.flutter.io/maplibre_gl_$index'),
  ...List<String>.generate(6, (index) => 'plugins.flutter.io/mapbox_gl_$index'),
];

MapLibrePlatform? _previousMapLibrePlatform;

void installMapPlatformMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  _previousMapLibrePlatform ??= MapLibrePlatform.instance;
  MapLibrePlatform.instance = _FakeMapLibrePlatform();

  final messenger = TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(
    SystemChannels.platform_views,
    (call) async {
      switch (call.method) {
        case 'create':
          return 0;
        case 'dispose':
          return null;
        case 'resize':
          return <String, double>{
            'width': 300,
            'height': 180,
          };
        default:
          return null;
      }
    },
  );

  for (final channelName in _mapMethodChannels) {
    final channel = MethodChannel(channelName);
    messenger.setMockMethodCallHandler(channel, (call) async => null);
  }
}

void removeMapPlatformMocks() {
  final messenger = TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger;

  final previous = _previousMapLibrePlatform;
  if (previous != null) {
    MapLibrePlatform.instance = previous;
    _previousMapLibrePlatform = null;
  }

  messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);

  for (final channelName in _mapMethodChannels) {
    final channel = MethodChannel(channelName);
    messenger.setMockMethodCallHandler(channel, null);
  }
}

class _FakeMapLibrePlatform extends MapLibrePlatform {
  @override
  MapLibreMapState createWidgetState() => _FakeMapLibreMapState();
}

class _FakeMapLibreMapState extends MapLibreMapState {
  static const MapCamera _defaultCamera = MapCamera(
    center: Geographic(lon: 21.0122, lat: 52.2297),
    zoom: 7,
    bearing: 0,
    pitch: 0,
  );

  @override
  void initState() {
    super.initState();
    camera = _defaultCamera;
    isInitialized = true;
  }

  @override
  StyleController? get style => null;

  @override
  Widget buildPlatformWidget(BuildContext context) {
    return const SizedBox.expand();
  }

  @override
  Future<void> animateCamera({
    Geographic? center,
    double? zoom,
    double? bearing,
    double? pitch,
    Duration nativeDuration = const Duration(seconds: 2),
    double webSpeed = 1.2,
    Duration? webMaxDuration,
    EdgeInsets padding = EdgeInsets.zero,
  }) async {}

  @override
  List<RenderedFeature> featuresAtPoint(Offset point, {List<String>? layerIds}) {
    return const <RenderedFeature>[];
  }

  @override
  List<RenderedFeature> featuresInRect(Rect rect, {List<String>? layerIds}) {
    return const <RenderedFeature>[];
  }

  @override
  Future<void> fitBounds({
    required LngLatBounds bounds,
    double? bearing,
    double? pitch,
    Duration nativeDuration = const Duration(seconds: 2),
    double webSpeed = 1.2,
    Duration? webMaxDuration,
    Offset offset = Offset.zero,
    double webMaxZoom = double.maxFinite,
    bool webLinear = false,
    EdgeInsets padding = EdgeInsets.zero,
  }) async {}

  @override
  MapCamera getCamera() {
    return camera ?? _defaultCamera;
  }

  @override
  double getMetersPerPixelAtLatitude(double latitude) {
    return 1;
  }

  @override
  LngLatBounds getVisibleRegion() {
    return const LngLatBounds(
      longitudeWest: 20.0,
      longitudeEast: 22.0,
      latitudeSouth: 51.0,
      latitudeNorth: 53.0,
    );
  }

  @override
  Future<void> moveCamera({
    Geographic? center,
    double? zoom,
    double? bearing,
    double? pitch,
    EdgeInsets padding = EdgeInsets.zero,
  }) async {}

  @override
  List<QueriedLayer> queryLayers(Offset screenLocation) {
    return const <QueriedLayer>[];
  }

  @override
  void setStyle(String style) {}

  @override
  Geographic toLngLat(Offset screenLocation) {
    return Geographic(lon: screenLocation.dx, lat: screenLocation.dy);
  }

  @override
  List<Geographic> toLngLats(List<Offset> screenLocations) {
    return screenLocations
        .map((offset) => Geographic(lon: offset.dx, lat: offset.dy))
        .toList(growable: false);
  }

  @override
  Offset toScreenLocation(Geographic lngLat) {
    return Offset(lngLat.lon, lngLat.lat);
  }

  @override
  List<Offset> toScreenLocations(List<Geographic> lngLats) {
    return lngLats
        .map((point) => Offset(point.lon, point.lat))
        .toList(growable: false);
  }

  @override
  Future<void> enableLocation({
    Duration fastestInterval = const Duration(milliseconds: 750),
    Duration maxWaitTime = const Duration(seconds: 1),
    bool pulseFade = true,
    bool accuracyAnimation = true,
    bool compassAnimation = true,
    bool pulse = true,
    BearingRenderMode bearingRenderMode = BearingRenderMode.gps,
  }) async {}

  @override
  Future<void> trackLocation({
    bool trackLocation = true,
    BearingTrackMode trackBearing = BearingTrackMode.gps,
  }) async {}
}
