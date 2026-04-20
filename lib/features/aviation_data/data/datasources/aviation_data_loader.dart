import 'dart:convert';

import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airspace.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/vfr_point.dart';
import 'package:flutter/services.dart';

class AviationDataLoader {
  const AviationDataLoader._();

  static Future<List<Airport>> loadAirports() async {
    final raw = await rootBundle.loadString(
      'assets/aviation_data/airports_pl.geojson',
    );
    return parseAirports(raw);
  }

  static Future<List<VfrPoint>> loadVfrPoints() async {
    final raw = await rootBundle.loadString(
      'assets/aviation_data/vfr_points_pl.geojson',
    );
    return parseVfrPoints(raw);
  }

  static Future<List<Airspace>> loadAirspaces() async {
    final raw = await rootBundle.loadString(
      'assets/aviation_data/airspaces_pl.geojson',
    );
    return parseAirspaces(raw);
  }

  static List<Airport> parseAirports(String jsonString) {
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      final features = map['features'] as List<dynamic>;
      return features.map((f) {
        final props = f['properties'] as Map<String, dynamic>;
        final coords = f['geometry']['coordinates'] as List<dynamic>;
        return Airport(
          id: props['id'] as String,
          name: props['name'] as String,
          icaoCode: props['icao'] as String,
          latitude: (coords[1] as num).toDouble(),
          longitude: (coords[0] as num).toDouble(),
          type: _parseAirportType(props['type'] as String),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static List<VfrPoint> parseVfrPoints(String jsonString) {
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      final features = map['features'] as List<dynamic>;
      return features.map((f) {
        final props = f['properties'] as Map<String, dynamic>;
        final coords = f['geometry']['coordinates'] as List<dynamic>;
        return VfrPoint(
          id: props['id'] as String,
          name: props['name'] as String,
          code: props['code'] as String,
          latitude: (coords[1] as num).toDouble(),
          longitude: (coords[0] as num).toDouble(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static List<Airspace> parseAirspaces(String jsonString) {
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      final features = map['features'] as List<dynamic>;
      return features.map((f) {
        final props = f['properties'] as Map<String, dynamic>;
        final rawRing =
            (f['geometry']['coordinates'] as List<dynamic>)[0] as List<dynamic>;
        final polygon = rawRing.map((c) {
          final coord = c as List<dynamic>;
          // GeoJSON uses [lon, lat]; convert to (lat, lon) record
          return ((coord[1] as num).toDouble(), (coord[0] as num).toDouble());
        }).toList();
        return Airspace(
          id: props['id'] as String,
          name: props['name'] as String,
          type: _parseAirspaceType(props['type'] as String),
          airspaceClass: props['class'] as String,
          ceiling: props['ceiling'] as String,
          floor: props['floor'] as String,
          polygon: polygon,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static AirportType _parseAirportType(String value) => switch (value) {
        'licensed' => AirportType.licensed,
        'grass' => AirportType.grass,
        'heliport' => AirportType.heliport,
        _ => AirportType.other,
      };

  static AirspaceType _parseAirspaceType(String value) => switch (value) {
        'ctr' => AirspaceType.ctr,
        'tma' => AirspaceType.tma,
        'mctr' => AirspaceType.mctr,
        'restricted' => AirspaceType.restricted,
        'prohibited' => AirspaceType.prohibited,
        _ => AirspaceType.other,
      };
}
