import 'package:flutter/material.dart';

class MapControlsOverlay extends StatelessWidget {
  const MapControlsOverlay({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitRoute,
    required this.onMyLocation,
    required this.onResetNorth,
    required this.showCompass,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitRoute;
  final VoidCallback onMyLocation;
  final VoidCallback onResetNorth;
  final bool showCompass;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (showCompass)
          Positioned(
            top: 12,
            left: 12,
            child: _MapButton(
              onPressed: onResetNorth,
              child: const Icon(Icons.explore, size: 20),
            ),
          ),
        Positioned(
          bottom: 16,
          right: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MapButton(
                onPressed: onFitRoute,
                child: const Icon(Icons.fit_screen, size: 20),
              ),
              const SizedBox(height: 6),
              _MapButton(
                onPressed: onMyLocation,
                child: const Icon(Icons.my_location, size: 20),
              ),
              const SizedBox(height: 6),
              _MapButton(
                onPressed: onZoomIn,
                child: const Icon(Icons.add, size: 20),
              ),
              const SizedBox(height: 2),
              _MapButton(
                onPressed: onZoomOut,
                child: const Icon(Icons.remove, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.onPressed, required this.child});

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: IconTheme(
            data: const IconThemeData(color: Colors.white),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
