import 'package:flight_assistant/features/map_view/presentation/widgets/map_controls_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Stack(children: [child])),
    );

void main() {
  group('MapControlsOverlay', () {
    testWidgets('renders zoom in and zoom out buttons', (tester) async {
      await tester.pumpWidget(_wrap(MapControlsOverlay(
        onZoomIn: () {},
        onZoomOut: () {},
        onFitRoute: () {},
        onMyLocation: () {},
        onResetNorth: () {},
        showCompass: false,
      )));
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('renders fit route and my location buttons', (tester) async {
      await tester.pumpWidget(_wrap(MapControlsOverlay(
        onZoomIn: () {},
        onZoomOut: () {},
        onFitRoute: () {},
        onMyLocation: () {},
        onResetNorth: () {},
        showCompass: false,
      )));
      expect(find.byIcon(Icons.fit_screen), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('compass button shown when showCompass is true', (tester) async {
      await tester.pumpWidget(_wrap(MapControlsOverlay(
        onZoomIn: () {},
        onZoomOut: () {},
        onFitRoute: () {},
        onMyLocation: () {},
        onResetNorth: () {},
        showCompass: true,
      )));
      expect(find.byIcon(Icons.explore), findsOneWidget);
    });

    testWidgets('compass button hidden when showCompass is false',
        (tester) async {
      await tester.pumpWidget(_wrap(MapControlsOverlay(
        onZoomIn: () {},
        onZoomOut: () {},
        onFitRoute: () {},
        onMyLocation: () {},
        onResetNorth: () {},
        showCompass: false,
      )));
      expect(find.byIcon(Icons.explore), findsNothing);
    });

    testWidgets('zoom in callback fires on tap', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(MapControlsOverlay(
        onZoomIn: () => called = true,
        onZoomOut: () {},
        onFitRoute: () {},
        onMyLocation: () {},
        onResetNorth: () {},
        showCompass: false,
      )));
      await tester.tap(find.byIcon(Icons.add));
      expect(called, isTrue);
    });

    testWidgets('zoom out callback fires on tap', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(MapControlsOverlay(
        onZoomIn: () {},
        onZoomOut: () => called = true,
        onFitRoute: () {},
        onMyLocation: () {},
        onResetNorth: () {},
        showCompass: false,
      )));
      await tester.tap(find.byIcon(Icons.remove));
      expect(called, isTrue);
    });
  });
}
