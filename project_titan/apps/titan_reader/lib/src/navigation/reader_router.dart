import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/library_screen.dart';
import '../screens/reader_screen.dart';
import '../screens/vocabulary_screen.dart';
import 'reader_routes.dart';

/// go_router configuration for TITAN Reader.
///
/// Routes: the document library, the per-document reader and the
/// user-global vocabulary screen.
final GoRouter readerRouter = buildReaderRouter();

/// Builds a fresh router with the TITAN Reader route table.
///
/// Production uses the shared [readerRouter]; tests build isolated
/// instances so router state never leaks between test cases.
GoRouter buildReaderRouter({String? initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation ?? ReaderRoutes.library,
    routes: <RouteBase>[
      GoRoute(
        path: ReaderRoutes.library,
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: ReaderRoutes.vocabulary,
        builder: (context, state) => const VocabularyScreen(),
      ),
      GoRoute(
        path: '/reader/:documentId',
        builder: (context, state) {
          final documentId = state.pathParameters['documentId'] ?? '';
          final page = int.tryParse(state.uri.queryParameters['page'] ?? '');
          return ReaderScreen(
            documentId: documentId,
            initialPageOverride: page,
          );
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
}
