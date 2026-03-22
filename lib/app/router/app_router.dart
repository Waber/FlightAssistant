import 'package:flight_assistant/features/flight_planning/presentation/screens/flight_planning_screen.dart';
import 'package:flight_assistant/features/route_storage/presentation/screens/saved_routes_screen.dart';
import 'package:flight_assistant/features/settings/presentation/screens/settings_screen.dart';
import 'package:go_router/go_router.dart';

class AppRoutes {
  static const String flightPlanning = '/planner';
  static const String savedRoutes = '/saved-routes';
  static const String settings = '/settings';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.flightPlanning,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.flightPlanning,
      builder: (context, state) => const FlightPlanningScreen(),
    ),
    GoRoute(
      path: AppRoutes.savedRoutes,
      builder: (context, state) => const SavedRoutesScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

