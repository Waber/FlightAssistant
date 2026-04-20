import 'package:flight_assistant/features/aviation_data/application/providers/layer_visibility_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('layerVisibilityProvider', () {
    test('starts with all layers visible', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final vis = container.read(layerVisibilityProvider);
      expect(vis.showAirports, isTrue);
      expect(vis.showVfrPoints, isTrue);
      expect(vis.showAirspaces, isTrue);
    });

    test('copyWith toggles airports independently', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(layerVisibilityProvider.notifier).state =
          container.read(layerVisibilityProvider).copyWith(showAirports: false);
      final vis = container.read(layerVisibilityProvider);
      expect(vis.showAirports, isFalse);
      expect(vis.showVfrPoints, isTrue);
      expect(vis.showAirspaces, isTrue);
    });

    test('copyWith toggles vfrPoints independently', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(layerVisibilityProvider.notifier).state =
          container.read(layerVisibilityProvider).copyWith(showVfrPoints: false);
      expect(container.read(layerVisibilityProvider).showVfrPoints, isFalse);
      expect(container.read(layerVisibilityProvider).showAirports, isTrue);
    });

    test('can turn all layers off', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(layerVisibilityProvider.notifier);
      notifier.state = notifier.state.copyWith(showAirports: false);
      notifier.state = notifier.state.copyWith(showVfrPoints: false);
      notifier.state = notifier.state.copyWith(showAirspaces: false);
      final vis = container.read(layerVisibilityProvider);
      expect(vis.showAirports, isFalse);
      expect(vis.showVfrPoints, isFalse);
      expect(vis.showAirspaces, isFalse);
    });
  });
}
