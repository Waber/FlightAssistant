import 'package:flight_assistant/app/app.dart';
import 'package:flight_assistant/core/services/logger_service.dart';
import 'package:flight_assistant/features/flight_planning/application/providers/flight_planning_providers.dart';
import 'package:flight_assistant/features/flight_planning/domain/repositories/route_repository.dart';
import 'package:flight_assistant/features/flight_planning/presentation/screens/flight_planning_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fakes.dart';

Widget buildTestApp({
  RouteRepository? routeRepository,
  LoggerService? loggerService,
}) {
  final repository = routeRepository ?? TestRouteRepository();
  final logger = loggerService ?? CapturingLoggerService();

  return ProviderScope(
    overrides: [
      routeRepositoryProvider.overrideWithValue(repository),
      loggerServiceProvider.overrideWithValue(logger),
    ],
    child: const FlightAssistantApp(),
  );
}

Widget buildFlightPlanningScreen({
  RouteRepository? routeRepository,
  LoggerService? loggerService,
}) {
  final repository = routeRepository ?? TestRouteRepository();
  final logger = loggerService ?? CapturingLoggerService();

  return ProviderScope(
    overrides: [
      routeRepositoryProvider.overrideWithValue(repository),
      loggerServiceProvider.overrideWithValue(logger),
    ],
    child: const MaterialApp(
      home: FlightPlanningScreen(),
    ),
  );
}
