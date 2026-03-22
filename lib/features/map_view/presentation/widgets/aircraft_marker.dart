import 'package:flutter/material.dart';

class AircraftMarker extends StatelessWidget {
  const AircraftMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 16,
      child: Icon(Icons.flight, size: 18),
    );
  }
}

