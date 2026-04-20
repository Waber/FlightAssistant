import 'package:flight_assistant/features/flight_planning/application/providers/flight_planning_providers.dart';
import 'package:flight_assistant/features/route_storage/application/providers/route_storage_providers.dart';
import 'package:flight_assistant/shared/widgets/app_scaffold.dart';
import 'package:flight_assistant/shared/widgets/error_view.dart';
import 'package:flight_assistant/shared/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SavedRoutesScreen extends ConsumerWidget {
  const SavedRoutesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedRoutesAsync = ref.watch(savedRoutesProvider);

    return AppScaffold(
      title: 'Saved Routes',
      currentIndex: 2,
      body: savedRoutesAsync.when(
        loading: () => const LoadingIndicator(),
        error: (_, __) => ErrorView(
          message: 'Unable to load saved routes.',
          onRetry: () => ref.invalidate(savedRoutesProvider),
        ),
        data: (routes) {
          if (routes.isEmpty) {
            return const Center(
              child: Text('No saved routes yet. Save one from planning screen.'),
            );
          }

          return ListView.builder(
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.route),
                  title: Text(route.name),
                  subtitle: Text(
                    '${route.waypoints.length} waypoints  -  ${route.totalDistanceNm.toStringAsFixed(1)} NM',
                  ),
                  trailing: IconButton(
                    tooltip: 'Delete route',
                    onPressed: () async {
                      await ref.read(routeRepositoryProvider).deleteRoute(route.id);
                      ref.invalidate(savedRoutesProvider);
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
