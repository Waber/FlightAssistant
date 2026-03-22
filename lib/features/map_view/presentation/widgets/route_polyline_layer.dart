import 'package:flutter/material.dart';

class RoutePolylineLayer extends StatelessWidget {
  const RoutePolylineLayer({
    required this.legCount,
    super.key,
  });

  final int legCount;

  @override
  Widget build(BuildContext context) {
    return Text('Polyline placeholder: $legCount legs');
  }
}

