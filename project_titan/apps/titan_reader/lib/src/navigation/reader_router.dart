import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/library_screen.dart';
import '../screens/reader_screen.dart';
import 'reader_routes.dart';

/// go_router configuration for TITAN Reader.
///
/// Two top-level routes: the document library and the per-document reader.
final GoRouter readerRouter = GoRouter(
  initialLocation: ReaderRoutes.library,
  routes: <RouteBase>[
    GoRoute(
      path: ReaderRoutes.library,
      builder: (context, state) => const LibraryScreen(),
    ),
    GoRoute(
      path: '/reader/:documentId',
      builder: (context, state) {
        final documentId = state.pathParameters['documentId'] ?? '';
        return ReaderScreen(documentId: documentId);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Navigation Error')),
    body: Center(
      child: Text('Route not found: ${state.uri}'),
    ),
  ),
);
