import 'package:flutter/material.dart';

import 'titan_routes.dart';

/// Centralized route generator and unknown-route handler for Project TITAN.
class TitanRouteGenerator {
  TitanRouteGenerator._();

  /// Map of registered page builder callbacks for route resolution.
  static final Map<String, WidgetBuilder> _routeRegistry = {
    TitanRoutes.initial: (context) =>
        const _PlaceholderHomePage(title: 'QuizForge AI Home'),
    TitanRoutes.home: (context) =>
        const _PlaceholderHomePage(title: 'QuizForge AI Home'),
    TitanRoutes.notFound: (context) =>
        const _PlaceholderNotFoundPage(routeName: 'Unknown'),
  };

  /// Register custom route builder for feature packages.
  static void registerRoute(String routeName, WidgetBuilder builder) {
    _routeRegistry[routeName] = builder;
  }

  /// Generate [Route] from [RouteSettings].
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final builder = _routeRegistry[settings.name];

    if (builder != null) {
      return MaterialPageRoute(
        builder: builder,
        settings: settings,
      );
    }

    return onUnknownRoute(settings);
  }

  /// Fallback handler for unregistered / unknown routes.
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) =>
          _PlaceholderNotFoundPage(routeName: settings.name ?? 'Unknown'),
      settings: settings,
    );
  }
}

/// Minimal placeholder home page for navigation testing and validation.
class _PlaceholderHomePage extends StatelessWidget {
  final String title;
  const _PlaceholderHomePage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

/// Minimal placeholder 404 Not Found page for unknown route validation.
class _PlaceholderNotFoundPage extends StatelessWidget {
  final String routeName;
  const _PlaceholderNotFoundPage({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('404 Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Route Not Found: $routeName',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
