import 'package:flutter_riverpod/flutter_riverpod.dart';

class LayerVisibility {
  const LayerVisibility({
    this.showAirports = true,
    this.showVfrPoints = true,
    this.showAirspaces = true,
  });

  final bool showAirports;
  final bool showVfrPoints;
  final bool showAirspaces;

  LayerVisibility copyWith({
    bool? showAirports,
    bool? showVfrPoints,
    bool? showAirspaces,
  }) {
    return LayerVisibility(
      showAirports: showAirports ?? this.showAirports,
      showVfrPoints: showVfrPoints ?? this.showVfrPoints,
      showAirspaces: showAirspaces ?? this.showAirspaces,
    );
  }
}

final layerVisibilityProvider = StateProvider<LayerVisibility>(
  (ref) => const LayerVisibility(),
);
