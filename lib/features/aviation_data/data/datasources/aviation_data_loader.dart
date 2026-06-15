import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airspace.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/aviation_data_meta.dart';
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

  static Future<AviationDataMeta?> loadMeta() async {
    final raw = await rootBundle.loadString(
      'assets/aviation_data/aviation_data_meta.json',
    );
    return parseMeta(raw);
  }

  static AviationDataMeta? parseMeta(String jsonString) {
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      final counts = map['counts'] as Map<String, dynamic>;
      return AviationDataMeta(
        source: map['source'] as String,
        license: map['license'] as String,
        generatedAt: map['generatedAt'] as String,
        dataAsOf: map['dataAsOf'] as String,
        airportCount: (counts['airports'] as num).toInt(),
        vfrPointCount: (counts['vfrPoints'] as num).toInt(),
        airspaceCount: (counts['airspaces'] as num).toInt(),
      );
    } catch (e, st) {
      developer.log('parseMeta failed',
          name: 'AviationDataLoader', error: e, stackTrace: st);
      return null;
    }
  }

  static List<Airport> parseAirports(String jsonString) {
    return _parseFeatures(jsonString, 'parseAirports', (f) {
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
    });
  }

  static List<VfrPoint> parseVfrPoints(String jsonString) {
    return _parseFeatures(jsonString, 'parseVfrPoints', (f) {
      final props = f['properties'] as Map<String, dynamic>;
      final coords = f['geometry']['coordinates'] as List<dynamic>;
      return VfrPoint(
        id: props['id'] as String,
        name: props['name'] as String,
        code: props['code'] as String,
        latitude: (coords[1] as num).toDouble(),
        longitude: (coords[0] as num).toDouble(),
      );
    });
  }

  static List<Airspace> parseAirspaces(String jsonString) {
    final groups = _parseFeatures(jsonString, 'parseAirspaces', _buildAirspaces);
    return groups.expand((g) => g).toList();
  }

  /// Builds one Airspace per polygon. `Polygon` -> 1 record; `MultiPolygon` -> N.
  static List<Airspace> _buildAirspaces(Map<String, dynamic> f) {
    final props = f['properties'] as Map<String, dynamic>;
    final geometry = f['geometry'] as Map<String, dynamic>;
    final geomType = geometry['type'] as String;
    final coords = geometry['coordinates'] as List<dynamic>;

    final List<List<dynamic>> rings; // each = outer ring of one polygon
    if (geomType == 'MultiPolygon') {
      rings = coords
          .map((polygon) => (polygon as List<dynamic>)[0] as List<dynamic>)
          .toList();
    } else {
      // Polygon: coordinates[0] is the outer ring.
      rings = [coords[0] as List<dynamic>];
    }

    final type = _parseAirspaceType(props['type'] as String);
    final id = props['id'] as String;
    final name = props['name'] as String;
    final airspaceClass = props['class'] as String;
    final ceiling = props['ceiling'] as String;
    final floor = props['floor'] as String;

    return rings
        .map((ring) => Airspace(
              id: id,
              name: name,
              type: type,
              airspaceClass: airspaceClass,
              ceiling: ceiling,
              floor: floor,
              polygon: _ring(ring),
            ))
        .toList();
  }

  /// Decodes a FeatureCollection and maps each feature with [build], isolating
  /// per-feature failures: a bad feature is skipped + logged, the rest are kept.
  /// Malformed top-level JSON returns an empty list.
  static List<T> _parseFeatures<T>(
    String jsonString,
    String op,
    T Function(Map<String, dynamic> feature) build,
  ) {
    final List<dynamic> features;
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      features = map['features'] as List<dynamic>;
    } catch (e, st) {
      developer.log('$op failed (top-level)',
          name: 'AviationDataLoader', error: e, stackTrace: st);
      return [];
    }
    final result = <T>[];
    for (final f in features) {
      try {
        result.add(build(f as Map<String, dynamic>));
      } catch (e, st) {
        developer.log('$op skipped a feature',
            name: 'AviationDataLoader', error: e, stackTrace: st);
      }
    }
    return result;
  }

  static List<(double, double)> _ring(List<dynamic> rawRing) {
    return rawRing.map((c) {
      final coord = c as List<dynamic>;
      // GeoJSON uses [lon, lat]; convert to (lat, lon) record.
      return ((coord[1] as num).toDouble(), (coord[0] as num).toDouble());
    }).toList();
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
        'atz' => AirspaceType.atz,
        'danger' => AirspaceType.danger,
        'restricted' => AirspaceType.restricted,
        'prohibited' => AirspaceType.prohibited,
        'tsa' => AirspaceType.tsa,
        'tra' => AirspaceType.tra,
        'rmz' => AirspaceType.rmz,
        'tmz' => AirspaceType.tmz,
        'military_route' => AirspaceType.militaryRoute,
        'gliding_sector' => AirspaceType.glidingSector,
        'drone_zone' => AirspaceType.droneZone,
        'sporting' => AirspaceType.sporting,
        _ => AirspaceType.other,
      };
}
