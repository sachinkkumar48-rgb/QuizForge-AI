import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/about_screen.dart';
import '../screens/home_screen.dart';
import '../screens/import_pdf_screen.dart';
import '../screens/library_screen.dart';
import '../screens/quiz_loading_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/result_screen.dart';
import '../screens/revision_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../widgets/error_card.dart';
import 'app_routes.dart';

/// Declarative GoRouter configuration for QuizForge AI.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splashPath,
  routes: <RouteBase>[
    GoRoute(
      name: AppRoutes.splash,
      path: AppRoutes.splashPath,
      builder: (BuildContext context, GoRouterState state) =>
          const SplashScreen(),
    ),
    GoRoute(
      name: AppRoutes.home,
      path: AppRoutes.homePath,
      builder: (BuildContext context, GoRouterState state) =>
          const HomeScreen(),
    ),
    GoRoute(
      name: AppRoutes.importPdf,
      path: AppRoutes.importPdfPath,
      builder: (BuildContext context, GoRouterState state) =>
          const ImportPdfScreen(),
    ),
    GoRoute(
      name: AppRoutes.quizLoading,
      path: AppRoutes.quizLoadingPath,
      builder: (BuildContext context, GoRouterState state) =>
          const QuizLoadingScreen(),
    ),
    GoRoute(
      name: AppRoutes.quiz,
      path: AppRoutes.quizPath,
      builder: (BuildContext context, GoRouterState state) {
        final sessionId = state.pathParameters['id'] ?? '';
        return QuizScreen(sessionId: sessionId);
      },
    ),
    GoRoute(
      name: AppRoutes.result,
      path: AppRoutes.resultPath,
      builder: (BuildContext context, GoRouterState state) {
        final sessionId = state.pathParameters['id'] ?? '';
        return ResultScreen(sessionId: sessionId);
      },
    ),
    GoRoute(
      name: AppRoutes.settings,
      path: AppRoutes.settingsPath,
      builder: (BuildContext context, GoRouterState state) =>
          const SettingsScreen(),
    ),
    GoRoute(
      name: AppRoutes.library,
      path: AppRoutes.libraryPath,
      builder: (BuildContext context, GoRouterState state) =>
          const LibraryScreen(),
    ),
    GoRoute(
      name: AppRoutes.revision,
      path: AppRoutes.revisionPath,
      builder: (BuildContext context, GoRouterState state) =>
          const RevisionScreen(),
    ),
    GoRoute(
      name: AppRoutes.about,
      path: AppRoutes.aboutPath,
      builder: (BuildContext context, GoRouterState state) =>
          const AboutScreen(),
    ),
  ],
  errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
    appBar: AppBar(title: const Text('Navigation Error')),
    body: Center(
      child: ErrorCard(
        message: 'Route not found: ${state.uri.toString()}',
        onRetry: () => context.go(AppRoutes.homePath),
      ),
    ),
  ),
);
